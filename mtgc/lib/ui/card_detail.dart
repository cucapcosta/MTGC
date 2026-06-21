import 'package:flutter/material.dart';

import '../models/card.dart';
import '../services/card_share_service.dart';

/// Full-screen-ish card view: tappable image, name, variation/price, and an
/// optional copies count. Tapping anywhere dismisses it.
void showCardDetail(BuildContext context, MtgCard card, {int? quantity}) {
  showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () async {
                  try {
                    await CardShareService().shareCard(card);
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Não foi possível compartilhar.'),
                        ),
                      );
                    }
                  }
                },
              ),
            ),
            Flexible(
              child: card.imageUrl != null
                  ? InteractiveViewer(
                      child: Image.network(card.imageUrl!, fit: BoxFit.contain),
                    )
                  : const Icon(Icons.style, size: 120, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              card.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${card.variationLabel} · ${card.priceLabel}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (quantity != null && quantity > 1) ...[
              const SizedBox(height: 4),
              Text(
                '×$quantity',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
