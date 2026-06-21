import 'package:flutter_test/flutter_test.dart';
import 'package:mtgc/models/card.dart';
import 'package:mtgc/services/card_share_service.dart';

MtgCard _card({double? price}) => MtgCard(
      id: 'x',
      name: 'Sol Ring',
      typeLine: 'Artifact',
      rarity: 'uncommon',
      setCode: 'TST',
      priceUsd: price,
    );

void main() {
  test('shareCaption formats name, variation and price', () {
    expect(shareCaption(_card(price: 2.5)), 'Sol Ring · Normal · \$2.50');
  });

  test('shareCaption uses the dash placeholder when price is null', () {
    expect(shareCaption(_card()), 'Sol Ring · Normal · —');
  });
}
