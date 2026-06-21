# Scryfall API — Reference for MTGCollector

Base URL: `https://api.scryfall.com`
Docs: https://scryfall.com/docs/api

## Required for every request

Scryfall **rejects requests without headers** (returns `403`). Always send:

```
User-Agent: mtgc/1.0 (contact@example.com)
Accept: application/json
```

- Free, no API key / auth.
- Rate limit: **~10 requests/sec**. Insert **50–100 ms** delay between calls. Abuse → `429` then IP ban.
- Card images: download once and cache locally. Do **not** hot-link `cards.scryfall.io` per render.
- Bulk data: for the whole card DB use the [bulk data files](https://scryfall.com/docs/api/bulk-data) instead of hammering endpoints.

---

## 1. Get card name / type / info

### By exact name
```
GET /cards/named?exact=Llanowar+Elves
```
### By fuzzy name (typo-tolerant)
```
GET /cards/named?fuzzy=llanow+elf
```
### By Scryfall id
```
GET /cards/{id}
```
### By set code + collector number (exact print)
```
GET /cards/{set}/{collector_number}
e.g. GET /cards/dom/168
```
### Full-text search (returns a list, paginated)
```
GET /cards/search?q=lightning+bolt
```

### Card object — relevant fields
```jsonc
{
  "object": "card",
  "id": "...",                 // unique print id (this printing)
  "oracle_id": "...",          // identity shared across ALL printings
  "name": "Llanowar Elves",
  "type_line": "Creature — Elf Druid",
  "oracle_text": "{T}: Add {G}.",
  "mana_cost": "{G}",
  "cmc": 1.0,
  "colors": ["G"],
  "color_identity": ["G"],
  "rarity": "common",          // common | uncommon | rare | mythic | special | bonus
  "collector_number": "227",
  "set": "fdn",                // set CODE  (see section 2)
  "set_name": "Foundations",
  "set_id": "a7ecb771-...",
  "set_type": "core",
  "prints_search_uri": "...",  // see section 2 (all printings)
  "image_uris": {
    "small":  "...jpg",
    "normal": "...jpg",
    "large":  "...jpg",
    "png":    "...png",
    "art_crop":    "...jpg",
    "border_crop": "...jpg"
  }
}
```
> Double-faced cards have no top-level `image_uris`/`mana_cost`; read `card_faces[]` instead.

---

## 2. Get which pack (set) a card is from

A single card object already carries its printing's set: `set`, `set_name`, `set_id`, `set_type`.

**That is one printing.** A card reprinted across many sets → use `prints_search_uri`
(or build it yourself) to list every set it appears in:

```
GET /cards/search?q=oracleid:68954295-...&unique=prints&order=released
```
Each result row has its own `set` / `set_name`. Collect those to know all packs.

Get full details of a set by its code:
```
GET /sets/{code}        e.g. GET /sets/dom
```
Set object fields:
```jsonc
{
  "object": "set",
  "code": "dom",
  "name": "Dominaria",
  "set_type": "expansion",     // core | expansion | masters | commander | ...
  "card_count": 280,
  "released_at": "2018-04-27",
  "icon_svg_uri": "https://svgs.scryfall.io/sets/dom.svg",
  "search_uri": "https://api.scryfall.com/cards/search?...q=e%3Adom..." // section 3
}
```

List every set:
```
GET /sets
```

---

## 3. Get the cards in a certain pack (set)

Use search with the set filter `e:` (alias `set:`):
```
GET /cards/search?q=e:dom&unique=prints&order=set
```
Or just GET the `search_uri` returned by the set object — same thing, pre-built.

### Search response is paginated
```jsonc
{
  "object": "list",
  "total_cards": 280,
  "has_more": true,
  "next_page": "https://api.scryfall.com/cards/search?...&page=2",
  "data": [ /* card objects */ ]
}
```
- **175 cards per page.**
- While `has_more` is `true`, follow `next_page` (respecting the rate limit) until false.

### Useful query refinements (`q=`)
| Want | Query |
|------|-------|
| Only this set | `e:dom` |
| Set + rarity | `e:dom r:mythic` |
| Set, no basic lands / tokens | `e:dom -t:basic` exclude `include_extras` |
| Default (no variants/extras) | drop `unique=prints`, defaults to `unique=cards` |

`unique` values: `cards` (default, one per oracle), `prints` (every printing), `art`.

---

## Quick recipe (booster flow)

1. Pick a set code → `GET /sets/{code}` for `card_count`, name, icon.
2. Page through `GET /cards/search?q=e:{code}&unique=prints` to load the pool.
3. Roll rarities client-side; pull cards by rarity from the loaded pool.
4. Cache `image_uris.normal` images locally on first fetch.

## Errors
```jsonc
{ "object": "error", "code": "not_found", "status": 404, "details": "..." }
```
`404` not found · `422` bad query · `429` rate limited (back off).
