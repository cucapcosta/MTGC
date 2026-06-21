import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/card.dart';
import '../models/collection_entry.dart';
import 'auth_storage.dart';
import 'server_config.dart';

/// Thrown when an API call fails. [message] is safe to show to the user.
class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ApiClient {
  /// Logs in and returns the JWT token.
  Future<String> login(String username, String senha) =>
      _authRequest('/auth/login', {'username': username, 'senha': senha});

  /// Registers a new user and returns the JWT token.
  Future<String> register(String username, String email, String senha) =>
      _authRequest('/auth/register', {
        'username': username,
        'email': email,
        'senha': senha,
      });

  Future<String> _authRequest(String path, Map<String, String> body) async {
    final baseUrl = await ServerConfig.baseUrl();
    if (baseUrl == null) {
      throw ApiException('Configure o servidor antes de continuar.');
    }

    final http.Response res;
    try {
      res = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
    } catch (_) {
      throw ApiException('Não foi possível conectar ao servidor.');
    }

    final data = _tryDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final token = data?['token'];
      if (token is String) return token;
      throw ApiException('Resposta inválida do servidor.');
    }
    throw ApiException(_errorMessage(res.statusCode, data));
  }

  /// Registers opened cards in the user's collection. The server upserts and
  /// increments quantity on duplicates, so a whole booster can be sent at once.
  Future<void> registerCards(List<MtgCard> cards) async {
    if (cards.isEmpty) return;
    final baseUrl = await ServerConfig.baseUrl();
    if (baseUrl == null) {
      throw ApiException('Configure o servidor antes de continuar.');
    }
    final headers = await _authHeaders();
    final http.Response res;
    try {
      res = await http.post(
        Uri.parse('$baseUrl/collection/cards'),
        headers: headers,
        body: jsonEncode({
          'cards': cards.map((c) => c.toServerJson()).toList(),
        }),
      );
    } catch (_) {
      throw ApiException('Não foi possível conectar ao servidor.');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(_errorMessage(res.statusCode, _tryDecode(res.body)));
    }
  }

  /// Convenience wrapper to register a single card.
  Future<void> registerNewCard(MtgCard card) => registerCards([card]);

  Future<List<CollectionEntry>> fetchCollection() async {
    final baseUrl = await ServerConfig.baseUrl();
    if (baseUrl == null) {
      throw ApiException('Configure o servidor antes de continuar.');
    }
    final headers = await _authHeaders();
    final http.Response res;
    try {
      res = await http.get(
        Uri.parse('$baseUrl/collection'),
        headers: headers,
      );
    } catch (_) {
      throw ApiException('Não foi possível conectar ao servidor.');
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = _tryDecode(res.body);
      if (data == null || data['cards'] is! List) {
        throw ApiException('Resposta inválida do servidor.');
      }
      return (data['cards'] as List)
          .map((c) => CollectionEntry.fromServerJson(c as Map<String, dynamic>))
          .toList(growable: false);
    }
    throw ApiException(_errorMessage(res.statusCode, _tryDecode(res.body)));
  }

  /// Builds request headers with the stored JWT. Throws if there is no token.
  Future<Map<String, String>> _authHeaders() async {
    final token = await AuthStorage.readToken();
    if (token == null || token.isEmpty) {
      throw ApiException('Sessão expirada. Faça login novamente.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic>? _tryDecode(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  String _errorMessage(int status, Map<String, dynamic>? data) {
    final detail = data?['detail'];
    if (detail is String && detail.isNotEmpty) return detail;
    return switch (status) {
      401 => 'Credenciais inválidas.',
      409 => 'Usuário ou e-mail já cadastrado.',
      422 => 'Dados inválidos.',
      _ => 'Erro do servidor ($status).',
    };
  }
}
