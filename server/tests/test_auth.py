import uuid
import main


def test_hash_roundtrip():
    h = main.hash_pw("hunter2")
    assert h != "hunter2"
    assert main.verify_pw("hunter2", h) is True
    assert main.verify_pw("wrong", h) is False


def test_token_roundtrip():
    uid = uuid.uuid4()
    token = main.make_token(uid)
    assert main.decode_token(token) == uid


async def test_health(client):
    res = await client.get("/health")
    assert res.status_code == 200
    assert res.json() == {"status": "ok"}


async def test_register_returns_token(client):
    res = await client.post(
        "/auth/register",
        json={"username": "ash", "email": "ash@x.com", "senha": "pw"},
    )
    assert res.status_code == 201
    assert "token" in res.json()


async def test_register_duplicate_username_conflicts(client):
    body = {"username": "ash", "email": "ash@x.com", "senha": "pw"}
    await client.post("/auth/register", json=body)
    dup = {"username": "ash", "email": "other@x.com", "senha": "pw"}
    res = await client.post("/auth/register", json=dup)
    assert res.status_code == 409


async def test_login_success_and_failure(client):
    await client.post(
        "/auth/register",
        json={"username": "ash", "email": "ash@x.com", "senha": "pw"},
    )
    ok = await client.post("/auth/login", json={"username": "ash", "senha": "pw"})
    assert ok.status_code == 200
    assert "token" in ok.json()

    bad = await client.post("/auth/login", json={"username": "ash", "senha": "no"})
    assert bad.status_code == 401
