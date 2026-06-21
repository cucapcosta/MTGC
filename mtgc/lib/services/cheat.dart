import '../models/booster_product.dart';
import '../models/card.dart';

/// Cheat opener: same slot structure as the real openers, but always picks the
/// most valuable matching printing instead of drawing at random.
class CheatService {
  double _rank(MtgCard c, CardFinish finish) {
    final v = switch (finish) {
      CardFinish.etched => c.priceUsdEtched,
      CardFinish.foil => c.priceUsdFoil,
      CardFinish.nonfoil => c.priceUsd,
    };
    return v ?? 0;
  }

  bool _isLand(MtgCard c) => c.typeLine.toLowerCase().contains('land');

  List<MtgCard> openBest(List<MtgCard> pool, BoosterType type) =>
      type == BoosterType.collector ? _collector(pool) : _play(pool);

  List<MtgCard> _play(List<MtgCard> pool) {
    final base = pool.where((c) => c.treatment == CardTreatment.normal).toList();
    final used = <String>{};

    List<MtgCard> best(bool Function(MtgCard) test, int n, CardFinish finish) {
      final cands = base
          .where((c) => !used.contains(c.id) && test(c))
          .toList()
        ..sort((a, b) => _rank(b, finish).compareTo(_rank(a, finish)));
      final picked = cands.take(n).map((c) => c.copyWith(finish: finish)).toList();
      used.addAll(picked.map((c) => c.id));
      return picked;
    }

    bool common(MtgCard c) => c.rarity == 'common';
    bool uncommon(MtgCard c) => c.rarity == 'uncommon';
    bool rareMythic(MtgCard c) => c.rarity == 'rare' || c.rarity == 'mythic';

    return <MtgCard>[
      ...best(common, 7, CardFinish.nonfoil),
      ...best(uncommon, 3, CardFinish.nonfoil),
      ...best(rareMythic, 1, CardFinish.nonfoil),
      ...best(_isLand, 1, CardFinish.nonfoil),
      ...best((c) => true, 1, CardFinish.nonfoil), // slot 13 wildcard
      ...best((c) => true, 1, CardFinish.foil), // slot 14 foil wildcard
    ];
  }

  List<MtgCard> _collector(List<MtgCard> pool) {
    final used = <String>{};

    List<MtgCard> best(bool Function(MtgCard) test, int n, CardFinish finish) {
      final cands = pool
          .where((c) => !used.contains(c.id) && test(c))
          .toList()
        ..sort((a, b) => _rank(b, finish).compareTo(_rank(a, finish)));
      final picked = cands.take(n).map((c) => c.copyWith(finish: finish)).toList();
      used.addAll(picked.map((c) => c.id));
      return picked;
    }

    // Best matching, with fallback when a treatment is absent.
    List<MtgCard> bestOr(
      List<bool Function(MtgCard)> matchers,
      int n,
      CardFinish finish,
    ) {
      final out = <MtgCard>[];
      for (var i = 0; i < n; i++) {
        for (final m in matchers) {
          final got = best(m, 1, finish);
          if (got.isNotEmpty) {
            out.addAll(got);
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
      ...best(common, 5, CardFinish.foil),
      ...best(uncommon, 2, CardFinish.foil),
      ...bestOr([(c) => special(c) && lowSlot(c), lowSlot], 1, CardFinish.foil),
      ...best(rareMythic, 1, CardFinish.foil),
      ...bestOr([(c) => special(c) && rareMythic(c), rareMythic], 1, CardFinish.foil),
      ...bestOr([(c) => extended(c) && rareMythic(c), rareMythic], 1, CardFinish.foil),
      ...best(_isLand, 1, CardFinish.foil),
      ...bestOr([(c) => special(c) && lowSlot(c), lowSlot], 2, CardFinish.foil),
    ];
    final etched = bestOr(
      [(c) => etchedAvail(c) && rareMythic(c), etchedAvail],
      1,
      CardFinish.etched,
    );
    pack.addAll(etched.isNotEmpty ? etched : best(rareMythic, 1, CardFinish.foil));
    return pack;
  }
}
