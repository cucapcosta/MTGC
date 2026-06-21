# How MTG Boosters Work — Reference for MTGCollector

Goal: simulate opening a booster. This documents the **Play Booster** (the current
standard since 2024, used by Foundations/`fdn` and all modern Standard sets), plus
the older **Draft Booster** for context.

> Rarities in Scryfall's `rarity` field: `common`, `uncommon`, `rare`, `mythic`
> (also `special`, `bonus` for some inserts). See `docs/scryfall-api.md`.

---

## Play Booster (current — use this)

**14 playable cards** + 1 non-playable card (token / art / ad) = 15 physical items.

### The 8 "slots"
| Slot(s) | Contents |
|---------|----------|
| 1–6 | **6 commons** from the set |
| 7 | A 7th **common** — but **12.5%** chance it's a card from "The List" (reprint/bonus) instead |
| 8–10 | **3 uncommons** |
| 11 | **1 rare or mythic** (the "rare slot") |
| 12 | **1 land** (basic or common land; 20% of packs it's a traditional foil land) |
| 13 | **Wildcard** — any rarity, any card from the set, **non-foil** |
| 14 | **Wildcard** — any rarity, **guaranteed traditional foil** |
| 15 | Non-playable: token, play aid, ad card, or **art card** |

### Odds that matter for simulation

**Rare slot (slot 11):**
- Mythic: **~14.3%** (1 in 7)
- Rare: **~85.7%**

**Wildcard slots (13 & 14):** can be *any* rarity. Wizards does **not** publish exact
percentages. They skew heavily toward common/uncommon (mirroring how many such cards
exist in a set). Reasonable model for a sim — weight by rarity:

| Rarity | Approx weight (wildcard) |
|--------|--------------------------|
| common | ~58% |
| uncommon | ~28% |
| rare | ~11% |
| mythic | ~3% |

> These wildcard weights are community estimates, **not official**. Tune to taste.

**Net effect across a whole pack** (because of the 2 wildcards):
- ~**28%** of packs have **2** rares/mythics
- ~**3%** have **3**
- **<1%** have **4**
- Every pack has **1 guaranteed traditional foil** (slot 14)

---

## Draft Booster (legacy — pre-2024 sets)

If you simulate older sets, use this instead:

**15 cards:**
| Count | Rarity |
|-------|--------|
| 10 | commons (1 replaced by a foil of any rarity in ~1 of 3 packs) |
| 3 | uncommons |
| 1 | rare **or** mythic (mythic ~1 in 7.4, ≈13.5%) |
| 1 | basic land |

Simpler: no wildcards, no guaranteed foil.

---

## Suggested simulation algorithm (Play Booster)

Given a card pool already grouped by rarity (from `ScryfallService.cardsInSet`):

```
pool = { common: [...], uncommon: [...], rare: [...], mythic: [...], land: [...] }

pack = []
pack += pickN(common, 6)                       // slots 1–6
pack += roll(0.125) ? pickFromList()           // slot 7
                    : pickN(common, 1)
pack += pickN(uncommon, 3)                      // slots 8–10
pack += roll(0.143) ? pickN(mythic, 1)         // slot 11 (rare slot)
                    : pickN(rare, 1)
pack += pickN(land, 1)                          // slot 12
pack += pickWildcard(foil=false)               // slot 13
pack += pickWildcard(foil=true)                // slot 14
// slot 15 (token/art) — skip or model separately

// pickWildcard: weighted-random a rarity, then pick a card of it
function pickWildcard(foil):
  r = weightedRarity({common:0.58, uncommon:0.28, rare:0.11, mythic:0.03})
  card = randomFrom(pool[r])
  card.foil = foil
  return card
```

Helpers:
- `pickN(list, n)` — n distinct random cards (shuffle + take, avoid dupes within a pack).
- `roll(p)` — `random < p`.
- `weightedRarity(weights)` — cumulative-sum pick.

### Simplifications worth making for a first version
- Ignore "The List" (slot 7) → just always a 7th common.
- Ignore slot 15 (non-playable).
- Treat foil as a boolean flag on the card, not a separate fetch.
- If a set has no mythics, send the rare slot to `rare` always.

---

## Sources
- [What Are Play Boosters? — Wizards of the Coast (official)](https://magic.wizards.com/en/news/making-magic/what-are-play-boosters)
- [Play Booster — MTG Wiki (Fandom)](https://mtg.fandom.com/wiki/Play_Booster)
- [Everything You Need to Know About Play Boosters — Draftsim](https://draftsim.com/mtg-play-booster/)
- [Play Booster Fact Sheet — MTG Scribe](https://mtgscribe.com/2024/01/30/play-booster-fact-sheet/)

## Collector Booster (as implemented)

15 cards, **all foil**. Canonical modern template used for every Collector
product (per-set sheets are out of scope). Slot matchers fall back to the
nearest available printing when a set lacks a treatment.

| Slot | Content |
|------|---------|
| 1–5 | 5 foil commons |
| 6–7 | 2 foil uncommons |
| 8 | 1 showcase/borderless common-or-uncommon (foil) |
| 9 | 1 foil rare/mythic |
| 10 | 1 showcase or borderless rare/mythic (foil) |
| 11 | 1 extended-art rare/mythic (foil) |
| 12 | 1 foil land |
| 13–14 | 2 showcase/borderless commons/uncommons (foil) |
| 15 | 1 etched-foil rare/mythic if any etched printings exist, else foil rare/mythic |

Treatments are read from Scryfall: `border_color == "borderless"` → borderless;
`frame_effects` contains `showcase`/`extendedart`; `frame == "1997"` → retro.
Finishes come from the printing's `finishes` array; prices from
`usd` / `usd_foil` / `usd_etched`.
