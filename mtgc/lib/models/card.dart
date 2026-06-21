enum CardFinish { nonfoil, foil, etched }

enum CardTreatment { normal, showcase, borderless, extendedArt, retro }

class MtgCard {
  final String id;
  final String name;
  final String typeLine;
  final String rarity;
  final String setCode;
  final String? imageUrl;
  final CardFinish finish; // which finish this copy is
  final CardTreatment treatment;
  final List<CardFinish> availableFinishes; // finishes this printing supports
  final double? priceUsd;
  final double? priceUsdFoil;
  final double? priceUsdEtched;

  MtgCard({
    required this.id,
    required this.name,
    required this.typeLine,
    required this.rarity,
    required this.setCode,
    this.imageUrl,
    this.finish = CardFinish.nonfoil,
    this.treatment = CardTreatment.normal,
    this.availableFinishes = const [CardFinish.nonfoil],
    this.priceUsd,
    this.priceUsdFoil,
    this.priceUsdEtched,
  });

  factory MtgCard.fromJson(Map<String, dynamic> json) {
    final prices = json['prices'] as Map?;
    return MtgCard(
      id: json['id'] as String,
      name: json['name'] as String,
      typeLine: json['type_line'] as String? ?? '',
      rarity: json['rarity'] as String,
      setCode: json['set'] as String,
      imageUrl: (json['image_uris'] as Map?)?['normal'] as String?,
      treatment: _treatmentFrom(json),
      availableFinishes: _finishesFrom(json),
      priceUsd: double.tryParse(prices?['usd'] as String? ?? ''),
      priceUsdFoil: double.tryParse(prices?['usd_foil'] as String? ?? ''),
      priceUsdEtched: double.tryParse(prices?['usd_etched'] as String? ?? ''),
    );
  }

  static CardTreatment _treatmentFrom(Map<String, dynamic> json) {
    if (json['border_color'] == 'borderless') return CardTreatment.borderless;
    final fx = (json['frame_effects'] as List?)?.cast<String>() ?? const [];
    if (fx.contains('showcase')) return CardTreatment.showcase;
    if (fx.contains('extendedart')) return CardTreatment.extendedArt;
    if (json['frame'] == '1997') return CardTreatment.retro;
    return CardTreatment.normal;
  }

  static List<CardFinish> _finishesFrom(Map<String, dynamic> json) {
    final raw = (json['finishes'] as List?)?.cast<String>() ?? const ['nonfoil'];
    final out = <CardFinish>[];
    for (final f in raw) {
      switch (f) {
        case 'nonfoil':
          out.add(CardFinish.nonfoil);
        case 'foil':
          out.add(CardFinish.foil);
        case 'etched':
          out.add(CardFinish.etched);
      }
    }
    return out.isEmpty ? const [CardFinish.nonfoil] : out;
  }

  bool get foil => finish != CardFinish.nonfoil;

  double? get price => switch (finish) {
    CardFinish.etched => priceUsdEtched,
    CardFinish.foil => priceUsdFoil,
    CardFinish.nonfoil => priceUsd,
  };

  String get priceLabel {
    final p = price;
    return p == null ? '—' : '\$${p.toStringAsFixed(2)}';
  }

  String get variationLabel {
    final t = switch (treatment) {
      CardTreatment.showcase => 'Showcase',
      CardTreatment.borderless => 'Borderless',
      CardTreatment.extendedArt => 'Extended Art',
      CardTreatment.retro => 'Retro',
      CardTreatment.normal => '',
    };
    final f = switch (finish) {
      CardFinish.etched => 'Etched Foil',
      CardFinish.foil => 'Foil',
      CardFinish.nonfoil => '',
    };
    final parts = [t, f].where((s) => s.isNotEmpty);
    return parts.isEmpty ? 'Normal' : parts.join(' ');
  }

  MtgCard copyWith({CardFinish? finish, CardTreatment? treatment}) {
    return MtgCard(
      id: id,
      name: name,
      typeLine: typeLine,
      rarity: rarity,
      setCode: setCode,
      imageUrl: imageUrl,
      finish: finish ?? this.finish,
      treatment: treatment ?? this.treatment,
      availableFinishes: availableFinishes,
      priceUsd: priceUsd,
      priceUsdFoil: priceUsdFoil,
      priceUsdEtched: priceUsdEtched,
    );
  }

  static String _finishToString(CardFinish f) => switch (f) {
    CardFinish.nonfoil => 'nonfoil',
    CardFinish.foil => 'foil',
    CardFinish.etched => 'etched',
  };

  static CardFinish _finishFromString(String? s) => switch (s) {
    'foil' => CardFinish.foil,
    'etched' => CardFinish.etched,
    _ => CardFinish.nonfoil,
  };

  static String _treatmentToString(CardTreatment t) => switch (t) {
    CardTreatment.showcase => 'showcase',
    CardTreatment.borderless => 'borderless',
    CardTreatment.extendedArt => 'extendedArt',
    CardTreatment.retro => 'retro',
    CardTreatment.normal => 'normal',
  };

  static CardTreatment _treatmentFromString(String? s) => switch (s) {
    'showcase' => CardTreatment.showcase,
    'borderless' => CardTreatment.borderless,
    'extendedArt' => CardTreatment.extendedArt,
    'retro' => CardTreatment.retro,
    _ => CardTreatment.normal,
  };

  /// Flat JSON matching the MTGC server's `cards` contract (snake_case).
  /// `quantity` is 1 — the server increments on duplicates.
  Map<String, dynamic> toServerJson() => {
    'scryfall_id': id,
    'name': name,
    'type_line': typeLine,
    'rarity': rarity,
    'set_code': setCode,
    'image_url': imageUrl,
    'finish': _finishToString(finish),
    'treatment': _treatmentToString(treatment),
    'available_finishes': availableFinishes.map(_finishToString).toList(),
    'price_usd': priceUsd,
    'price_usd_foil': priceUsdFoil,
    'price_usd_etched': priceUsdEtched,
    'quantity': 1,
  };

  /// Parses a card row returned by the MTGC server (flat snake_case fields).
  factory MtgCard.fromServerJson(Map<String, dynamic> json) {
    double? toDouble(dynamic v) => (v as num?)?.toDouble();
    final finishes = (json['available_finishes'] as List?)
        ?.map((e) => _finishFromString(e as String?))
        .toList();
    return MtgCard(
      id: json['scryfall_id'] as String,
      name: json['name'] as String,
      typeLine: json['type_line'] as String? ?? '',
      rarity: json['rarity'] as String? ?? '',
      setCode: json['set_code'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      finish: _finishFromString(json['finish'] as String?),
      treatment: _treatmentFromString(json['treatment'] as String?),
      availableFinishes: (finishes == null || finishes.isEmpty)
          ? const [CardFinish.nonfoil]
          : finishes,
      priceUsd: toDouble(json['price_usd']),
      priceUsdFoil: toDouble(json['price_usd_foil']),
      priceUsdEtched: toDouble(json['price_usd_etched']),
    );
  }
}
