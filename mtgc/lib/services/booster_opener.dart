import 'dart:math';

import '../models/booster_product.dart';
import '../models/card.dart';

/// Builds a pack from a set's full printing pool.
abstract class BoosterOpener {
  List<MtgCard> open(List<MtgCard> pool);
}

BoosterOpener openerFor(BoosterType type) =>
    type == BoosterType.collector
        ? CollectorBoosterOpener()
        : PlayBoosterOpener();

bool _isLand(MtgCard c) => c.typeLine.toLowerCase().contains('land');

/// Play Booster: normal-frame cards, one guaranteed foil (slot 14).
/// See docs/mtg-boosters.md. The List (slot 7) is treated as a 7th common and
/// the non-playable slot 15 is skipped. Returns up to 13 cards.
class PlayBoosterOpener implements BoosterOpener {
  final Random _rng;
  PlayBoosterOpener([Random? rng]) : _rng = rng ?? Random();

  @override
  List<MtgCard> open(List<MtgCard> pool) {
    // Play boosters use the standard (normal-treatment) printings only.
    final base = pool.where((c) => c.treatment == CardTreatment.normal);

    final commons = <MtgCard>[];
    final uncommons = <MtgCard>[];
    final rares = <MtgCard>[];
    final mythics = <MtgCard>[];
    final lands = <MtgCard>[];
    for (final card in base) {
      if (_isLand(card)) lands.add(card);
      switch (card.rarity) {
        case 'common':
          commons.add(card);
        case 'uncommon':
          uncommons.add(card);
        case 'rare':
          rares.add(card);
        case 'mythic':
          mythics.add(card);
      }
    }

    final used = <String>{};
    List<MtgCard> draw(List<MtgCard> pool, int n) {
      final available = pool.where((c) => !used.contains(c.id)).toList()
        ..shuffle(_rng);
      final picked = available.take(n).toList();
      used.addAll(picked.map((c) => c.id));
      return picked;
    }

    MtgCard? wildcard() {
      const weights = {
        'common': 0.58,
        'uncommon': 0.28,
        'rare': 0.11,
        'mythic': 0.03,
      };
      final buckets = {
        'common': commons,
        'uncommon': uncommons,
        'rare': rares,
        'mythic': mythics,
      };
      var roll = _rng.nextDouble();
      for (final entry in weights.entries) {
        roll -= entry.value;
        if (roll <= 0) {
          final picked = draw(buckets[entry.key]!, 1);
          if (picked.isNotEmpty) return picked.first;
          break;
        }
      }
      final fallback = draw(commons, 1);
      return fallback.isEmpty ? null : fallback.first;
    }

    final pack = <MtgCard>[
      ...draw(commons, 7),
      ...draw(uncommons, 3),
      ...draw(
        mythics.isNotEmpty && _rng.nextDouble() < 0.143 ? mythics : rares,
        1,
      ),
      ...draw(lands, 1),
    ];
    for (var i = 0; i < 2; i++) {
      final card = wildcard();
      if (card != null) {
        pack.add(i == 1 ? card.copyWith(finish: CardFinish.foil) : card);
      }
    }
    return pack;
  }
}

/// Collector Booster: 15 cards, all foil, heavy on special treatments.
/// Canonical modern sheet — see docs/mtg-boosters.md. Slot matchers fall back
/// to the nearest available printing when a treatment is missing in the set.
class CollectorBoosterOpener implements BoosterOpener {
  final Random _rng;
  CollectorBoosterOpener([Random? rng]) : _rng = rng ?? Random();

  @override
  List<MtgCard> open(List<MtgCard> pool) {
    final used = <String>{};

    MtgCard? pick(bool Function(MtgCard) test, CardFinish finish) {
      final cands = pool.where((c) => !used.contains(c.id) && test(c)).toList()
        ..shuffle(_rng);
      if (cands.isEmpty) return null;
      final c = cands.first;
      used.add(c.id);
      return c.copyWith(finish: finish);
    }

    // Try each matcher in order until one yields a card; repeat n times.
    List<MtgCard> many(
      int n,
      List<bool Function(MtgCard)> matchers,
      CardFinish finish,
    ) {
      final out = <MtgCard>[];
      for (var i = 0; i < n; i++) {
        for (final m in matchers) {
          final c = pick(m, finish);
          if (c != null) {
            out.add(c);
            break;
          }
        }
      }
      return out;
    }

    bool common(MtgCard c) => c.rarity == 'common';
    bool uncommon(MtgCard c) => c.rarity == 'uncommon';
    bool rareMythic(MtgCard c) => c.rarity == 'rare' || c.rarity == 'mythic';
    bool lowSlot(MtgCard c) => common(c) || uncommon(c);
    bool special(MtgCard c) =>
        c.treatment == CardTreatment.showcase ||
        c.treatment == CardTreatment.borderless;
    bool extended(MtgCard c) => c.treatment == CardTreatment.extendedArt;
    bool etchedAvail(MtgCard c) =>
        c.availableFinishes.contains(CardFinish.etched);

    final pack = <MtgCard>[
      ...many(5, [common], CardFinish.foil), // 1-5
      ...many(2, [uncommon], CardFinish.foil), // 6-7
      ...many(1, [(c) => special(c) && lowSlot(c), lowSlot], CardFinish.foil), // 8
      ...many(1, [rareMythic], CardFinish.foil), // 9
      ...many(1, [(c) => special(c) && rareMythic(c), rareMythic], CardFinish.foil), // 10
      ...many(1, [(c) => extended(c) && rareMythic(c), rareMythic], CardFinish.foil), // 11
      ...many(1, [_isLand], CardFinish.foil), // 12
      ...many(2, [(c) => special(c) && lowSlot(c), lowSlot], CardFinish.foil), // 13-14
    ];

    // Slot 15: etched rare/mythic if any etched printings exist, else foil.
    final etched = many(
      1,
      [(c) => etchedAvail(c) && rareMythic(c), etchedAvail],
      CardFinish.etched,
    );
    pack.addAll(etched.isNotEmpty ? etched : many(1, [rareMythic], CardFinish.foil));

    return pack;
  }
}
