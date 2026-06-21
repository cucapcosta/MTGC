# MTGC Server

FastAPI + Postgres API for the mtgc app: signup/login, register booster cards, fetch collection.

## Endpoints

| Method | Path | Auth | Body | Returns |
|---|---|---|---|---|
| GET | `/health` | — | — | `{"status":"ok"}` |
| POST | `/auth/register` | — | `{username,email,senha}` | `201 {token}` |
| POST | `/auth/login` | — | `{username,senha}` | `200 {token}` |
| GET | `/collection` | Bearer | — | `{cards:[...]}` |
| POST | `/collection/cards` | Bearer | `{cards:[...]}` | `{cards:[...]}` |

Auth: send `Authorization: Bearer <token>` on protected routes. Tokens expire after 30 days.

## Local development

```bash
docker run -d --name mtgc-pg -e POSTGRES_PASSWORD=pg -p 5432:5432 postgres:16
python -m venv .venv && . .venv/bin/activate
pip install -r requirements-dev.txt
export DATABASE_URL="postgresql://postgres:pg@localhost:5432/postgres"
export JWT_SECRET="dev-secret"
uvicorn main:app --reload
```

Run tests: `pytest -v` (requires `DATABASE_URL` + `JWT_SECRET` set).

## Deploy to Railway

1. New Railway project → add the **Postgres** plugin (auto-injects `DATABASE_URL`).
2. Add the `server/` directory as a service (Nixpacks auto-detects Python via `requirements.txt`).
3. Set service variable `JWT_SECRET` to a long random string.
4. Railway runs the `Procfile` start command. The schema is applied automatically on startup.
5. Point the mtgc app's API base URL at the generated Railway domain.
