import 'package:flutter/material.dart';

import '../models/card.dart';
import '../ui/layout_metrics.dart';

export '../ui/layout_metrics.dart';

/// A single card image with foil marker and price overlay.
class CardFace extends StatelessWidget {
  const CardFace({super.key, required this.card, this.width = 280});

  final MtgCard card;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: AspectRatio(
        aspectRatio: kCardAspect,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: card.imageUrl != null
                  ? Image.network(card.imageUrl!, fit: BoxFit.cover)
                  : Container(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(12),
                      child: Text(card.name, textAlign: TextAlign.center),
                    ),
            ),
            if (card.foil)
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(Icons.auto_awesome, color: Colors.amberAccent),
              ),
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  card.priceLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared empty-state placeholder shown by the reveal side panels.
class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Aguardando cartas...',
        style: TextStyle(color: Theme.of(context).disabledColor),
      ),
    );
  }
}

/// Text rows of revealed cards: name + type/rarity/variation + price.
class RevealedInfoList extends StatelessWidget {
  const RevealedInfoList({super.key, required this.cards});

  final List<MtgCard> cards;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return const _EmptyPanel();
    }
    return ListView.builder(
      itemCount: cards.length,
      itemBuilder: (context, i) {
        final card = cards[i];
        return ListTile(
          dense: true,
          title: Text(card.name, style: const TextStyle(fontSize: 16)),
          subtitle: Text(
            '${card.typeLine} · ${card.rarity} · '
            '${card.variationLabel}',
          ),
          trailing: Text(
            card.priceLabel,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        );
      },
    );
  }
}

/// Scrollable column of revealed card faces.
class RevealedCardScroll extends StatelessWidget {
  const RevealedCardScroll({super.key, required this.cards});

  final List<MtgCard> cards;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return const _EmptyPanel();
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: cards.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) =>
          Center(child: CardFace(card: cards[i], width: 200)),
    );
  }
}

/// Arranges the booster panels for the current window width.
class BoosterLayout extends StatelessWidget {
  const BoosterLayout({
    super.key,
    required this.main,
    required this.infoList,
    required this.cardScroll,
  });

  final Widget main;
  final Widget infoList;
  final Widget cardScroll;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        switch (modeFor(constraints.maxWidth)) {
          case ScreenMode.single:
            return main;
          case ScreenMode.dual:
            return Row(
              children: [
                Expanded(child: main),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: infoList),
              ],
            );
          case ScreenMode.triple:
            return Row(
              children: [
                Expanded(child: infoList),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: main),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: cardScroll),
              ],
            );
        }
      },
    );
  }
}
