import pytest_asyncio
from httpx import ASGITransport, AsyncClient

import main


@pytest_asyncio.fixture
async def client():
    async with main.app.router.lifespan_context(main.app):
        async with main.app.state.pool.acquire() as con:
            await con.execute("TRUNCATE cards, users CASCADE")
        transport = ASGITransport(app=main.app)
        async with AsyncClient(transport=transport, base_url="http://test") as c:
            yield c
