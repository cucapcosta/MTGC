import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/card.dart';

/// Caption shared alongside the card image: name · variation · price.
String shareCaption(MtgCard card) =>
    '${card.name} · ${card.variationLabel} · ${card.priceLabel}';

class CardShareService {
  /// Shares the card's image (downloaded to a temp file) with a caption.
  /// Falls back to text-only when the card has no image. Throws on failure so
  /// the caller can surface a message.
  Future<void> shareCard(MtgCard card) async {
    final caption = shareCaption(card);
    final url = card.imageUrl;
    if (url == null) {
      await SharePlus.instance.share(ShareParams(text: caption));
      return;
    }
    final res =
        await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) {
      throw Exception('image download failed (${res.statusCode})');
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${card.id}.jpg');
    await file.writeAsBytes(res.bodyBytes);
    try {
      await SharePlus.instance.share(
        ShareParams(text: caption, files: [XFile(file.path)]),
      );
    } finally {
      if (file.existsSync()) file.deleteSync();
    }
  }
}
