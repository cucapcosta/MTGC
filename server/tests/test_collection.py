import main


def sample_card(scryfall_id="abc", quantity=1):
    return {
        "scryfall_id": scryfall_id,
        "name": "Black Lotus",
        "type_line": "Artifact",
        "rarity": "rare",
        "set_code": "lea",
        "image_url": "http://img/x.png",
        "finish": "nonfoil",
        "treatment": "normal",
        "available_finishes": ["nonfoil"],
        "price_usd": 9999.99,
        "price_usd_foil": None,
        "price_usd_etched": None,
        "quantity": quantity,
    }


async def auth_headers(client):
    res = await client.post(
        "/auth/register",
        json={"username": "ash", "email": "ash@x.com", "senha": "pw"},
    )
    return {"Authorization": f"Bearer {res.json()['token']}"}


async def test_collection_requires_auth(client):
    res = await client.get("/collection")
    assert res.status_code == 401


async def test_empty_collection(client):
    headers = await auth_headers(client)
    res = await client.get("/collection", headers=headers)
    assert res.status_code == 200
    assert res.json() == {"cards": []}


async def test_post_cards_then_list(client):
    headers = await auth_headers(client)
    post = await client.post(
        "/collection/cards",
        json={"cards": [sample_card("a"), sample_card("b")]},
        headers=headers,
    )
    assert post.status_code == 200
    assert len(post.json()["cards"]) == 2

    listed = await client.get("/collection", headers=headers)
    names = {c["scryfall_id"] for c in listed.json()["cards"]}
    assert names == {"a", "b"}


async def test_duplicate_card_bumps_quantity(client):
    headers = await auth_headers(client)
    await client.post(
        "/collection/cards", json={"cards": [sample_card("a")]}, headers=headers
    )
    await client.post(
        "/collection/cards",
        json={"cards": [sample_card("a", quantity=2)]},
        headers=headers,
    )
    listed = await client.get("/collection", headers=headers)
    cards = listed.json()["cards"]
    assert len(cards) == 1
    assert cards[0]["quantity"] == 3


async def test_post_returns_only_posted_variant(client):
    headers = await auth_headers(client)
    # user already owns a FOIL copy of card "a"
    foil = sample_card("a")
    foil["finish"] = "foil"
    await client.post("/collection/cards", json={"cards": [foil]}, headers=headers)

    # now they open a NONFOIL copy of the same card
    nonfoil = sample_card("a")  # finish defaults to "nonfoil"
    res = await client.post(
        "/collection/cards", json={"cards": [nonfoil]}, headers=headers
    )
    cards = res.json()["cards"]
    # response must contain only the just-posted nonfoil row, not the foil
    assert len(cards) == 1
    assert cards[0]["finish"] == "nonfoil"

    # but the full collection still has both variants
    listed = await client.get("/collection", headers=headers)
    finishes = {c["finish"] for c in listed.json()["cards"]}
    assert finishes == {"foil", "nonfoil"}
