import datetime as dt
import os
import pathlib
import uuid
from contextlib import asynccontextmanager

import asyncpg
import bcrypt
import jwt
from fastapi import Depends, FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pydantic import BaseModel

JWT_SECRET = os.environ["JWT_SECRET"]
JWT_ALG = "HS256"
TOKEN_TTL = dt.timedelta(days=30)


def hash_pw(password: str) -> str:
    return bcrypt.hashpw(password.encode()[:72], bcrypt.gensalt()).decode()


def verify_pw(password: str, hashed: str) -> bool:
    return bcrypt.checkpw(password.encode()[:72], hashed.encode())


def make_token(user_id: uuid.UUID) -> str:
    payload = {
        "sub": str(user_id),
        "exp": dt.datetime.now(dt.timezone.utc) + TOKEN_TTL,
    }
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALG)


def decode_token(token: str) -> uuid.UUID:
    payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALG])
    return uuid.UUID(payload["sub"])


DATABASE_URL = os.environ["DATABASE_URL"]
SCHEMA_PATH = pathlib.Path(__file__).parent / "schema.sql"


@asynccontextmanager
async def lifespan(app: FastAPI):
    app.state.pool = await asyncpg.create_pool(DATABASE_URL)
    async with app.state.pool.acquire() as con:
        await con.execute(SCHEMA_PATH.read_text())
    yield
    await app.state.pool.close()


app = FastAPI(lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

bearer = HTTPBearer(auto_error=False)


class RegisterIn(BaseModel):
    username: str
    email: str
    senha: str


class LoginIn(BaseModel):
    username: str
    senha: str


class CardIn(BaseModel):
    scryfall_id: str
    name: str
    type_line: str | None = None
    rarity: str | None = None
    set_code: str | None = None
    image_url: str | None = None
    finish: str
    treatment: str
    available_finishes: list[str] = []
    price_usd: float | None = None
    price_usd_foil: float | None = None
    price_usd_etched: float | None = None
    quantity: int = 1


class CardsIn(BaseModel):
    cards: list[CardIn]


async def current_user(
    cred: HTTPAuthorizationCredentials | None = Depends(bearer),
) -> uuid.UUID:
    if cred is None:
        raise HTTPException(status_code=401, detail="missing token")
    try:
        return decode_token(cred.credentials)
    except (jwt.PyJWTError, KeyError, ValueError):
        raise HTTPException(status_code=401, detail="invalid token")


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.post("/auth/register", status_code=201)
async def register(body: RegisterIn):
    async with app.state.pool.acquire() as con:
        try:
            row = await con.fetchrow(
                "INSERT INTO users (username, email, senha) "
                "VALUES ($1, $2, $3) RETURNING id",
                body.username,
                body.email,
                hash_pw(body.senha),
            )
        except asyncpg.UniqueViolationError:
            raise HTTPException(status_code=409, detail="username or email already taken")
    return {"token": make_token(row["id"])}


@app.post("/auth/login")
async def login(body: LoginIn):
    async with app.state.pool.acquire() as con:
        row = await con.fetchrow(
            "SELECT id, senha FROM users WHERE username = $1", body.username
        )
    if row is None or not verify_pw(body.senha, row["senha"]):
        raise HTTPException(status_code=401, detail="bad credentials")
    return {"token": make_token(row["id"])}


CARD_COLS = (
    "scryfall_id, name, type_line, rarity, set_code, image_url, finish, treatment, "
    "available_finishes, price_usd, price_usd_foil, price_usd_etched, quantity"
)


@app.get("/collection")
async def collection(uid: uuid.UUID = Depends(current_user)):
    async with app.state.pool.acquire() as con:
        rows = await con.fetch(
            f"SELECT {CARD_COLS} FROM cards WHERE user_id = $1 ORDER BY name", uid
        )
    return {"cards": [dict(r) for r in rows]}


@app.post("/collection/cards")
async def add_cards(body: CardsIn, uid: uuid.UUID = Depends(current_user)):
    if not body.cards:
        return {"cards": []}
    rows = []
    async with app.state.pool.acquire() as con:
        async with con.transaction():
            for c in body.cards:
                row = await con.fetchrow(
                    f"""
                    INSERT INTO cards (
                        user_id, scryfall_id, name, type_line, rarity, set_code,
                        image_url, finish, treatment, available_finishes,
                        price_usd, price_usd_foil, price_usd_etched, quantity
                    ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14)
                    ON CONFLICT (user_id, scryfall_id, finish, treatment)
                    DO UPDATE SET quantity = cards.quantity + EXCLUDED.quantity
                    RETURNING {CARD_COLS}
                    """,
                    uid, c.scryfall_id, c.name, c.type_line, c.rarity, c.set_code,
                    c.image_url, c.finish, c.treatment, c.available_finishes,
                    c.price_usd, c.price_usd_foil, c.price_usd_etched, c.quantity,
                )
                rows.append(row)
    return {"cards": [dict(r) for r in rows]}
