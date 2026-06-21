enum BoosterType { play, collector }

class BoosterProduct {
  final String id; // also the asset basename, e.g. 'sos_play'
  final String name;
  final String setCode;
  final BoosterType type;
  final double price;
  final String art; // 'assets/boosters/sos_play.png'

  const BoosterProduct({
    required this.id,
    required this.name,
    required this.setCode,
    required this.type,
    required this.price,
    required this.art,
  });
}

/// Add boosters by editing this list. The [art] file must exist under
/// assets/boosters/ (see pubspec.yaml).
const List<BoosterProduct> boosterCatalog = [
  BoosterProduct(
    id: 'sos_play',
    name: 'Secrets of Strixhaven — Play Booster',
    setCode: 'SOS',
    type: BoosterType.play,
    price: 5.52,
    art: 'assets/boosters/sos.png',
  ),
  BoosterProduct(
    id: 'sos_collector',
    name: 'Secrets of Strixhaven — Collector Booster',
    setCode: 'SOS',
    type: BoosterType.collector,
    price: 24.99,
    art: 'assets/boosters/sos_collector.png',
  ),
  BoosterProduct(
    id: 'inr_collector',
    name: 'Innistrad Remastered — Collector Booster',
    setCode: 'INR',
    type: BoosterType.collector,
    price: 26.99,
    art: 'assets/boosters/innistrad_remastered_collector.png',
  ),
];
