import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/card_model.dart';

/// Haalt kaartdata op van de Lorcast API (dezelfde als de iOS app).
class LorcastService {
  static const String _baseUrl = 'https://api.lorcast.com/v0';

  Future<List<Map<String, dynamic>>> fetchSets() async {
    final res = await http.get(Uri.parse('$_baseUrl/sets'));
    if (res.statusCode != 200) throw Exception('Kon sets niet ophalen');
    final json = jsonDecode(res.body);
    final results = json['results'] as List;
    // Alleen Engelstalige sets (zoals de iOS app)
    return results
        .cast<Map<String, dynamic>>()
        .where((s) => s['language'] == 'English')
        .toList();
  }

  Future<List<LorcanaCard>> fetchCardsForSet(int setId) async {
    final List<LorcanaCard> cards = [];
    String? nextUrl = '$_baseUrl/sets/$setId/cards?limit=100';

    while (nextUrl != null) {
      final res = await http.get(Uri.parse(nextUrl));
      if (res.statusCode != 200) break;
      final json = jsonDecode(res.body);
      final results = (json['results'] as List).cast<Map<String, dynamic>>();
      cards.addAll(results.map(LorcanaCard.fromLorcastJson));
      nextUrl = json['next'];
    }

    return cards;
  }

  /// Haalt alle kaarten van alle Engelse sets op.
  Future<List<LorcanaCard>> fetchAllCards({
    void Function(String setName, int done, int total)? onProgress,
  }) async {
    final sets = await fetchSets();
    final List<LorcanaCard> all = [];

    for (int i = 0; i < sets.length; i++) {
      final set = sets[i];
      onProgress?.call(set['name'] ?? '', i, sets.length);
      final cards = await fetchCardsForSet(set['id']);
      all.addAll(cards);
    }

    return all;
  }
}
