import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/card.dart';

class ScryfallService {
  static const String baseURL = 'https://api.scryfall.com';
  static const headers = {
    "User-Agent": "MTGC/1.0",
    'Accept': 'application/json',
  };

  final Map<String, List<MtgCard>> _setCache = {};

  Future<MtgCard> fetchCardByName(String name) async {
    final response = await http.get(
      Uri.parse('$baseURL/cards/named?exact=$name'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return MtgCard.fromJson(data);
    } else {
      throw Exception('Failed to load card: ${response.reasonPhrase}');
    }
  }

  Future<List<MtgCard>> fetchCardsBySet(String setCode) async {
    final cached = _setCache[setCode];
    if (cached != null) return cached;
    String? url =
        '$baseURL/cards/search?q=s%3A$setCode+unique%3Aprints';
    final List<MtgCard> cards = [];
    while (url != null) {
      final res = await http.get(Uri.parse(url), headers: headers);
      if (res.statusCode != 200) throw Exception('Scryfall ${res.statusCode}');
      final body = jsonDecode(res.body) as Map<String, dynamic>;

      for (final c in body['data'] as List) {
        cards.add(MtgCard.fromJson(c as Map<String, dynamic>));
      }
      url = body['has_more'] == true ? body['next_page'] as String : null;
    }
    _setCache[setCode] = cards;
    return cards;
  }
}
