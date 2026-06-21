import 'card.dart';

/// One row of the user's server-side collection: a card variant plus how many
/// copies they own. Quantity is only meaningful in the collection view.
class CollectionEntry {
  const CollectionEntry({required this.card, required this.quantity});

  final MtgCard card;
  final int quantity;

  factory CollectionEntry.fromServerJson(Map<String, dynamic> json) =>
      CollectionEntry(
        card: MtgCard.fromServerJson(json),
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      );
}
