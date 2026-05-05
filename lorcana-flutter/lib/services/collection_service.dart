import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/card_model.dart';
import '../models/deck_model.dart';

/// Beheert alle lees- en schrijfacties voor de collectie in Supabase.
class CollectionService {
  final _client = Supabase.instance.client;

  String get _userId => _client.auth.currentUser!.id;

  // ─── Kaarten ───────────────────────────────────────────────────────────────

  Future<List<LorcanaCard>> fetchAllCards() async {
    final data = await _client
        .from('cards')
        .select()
        .eq('user_id', _userId)
        .order('set_number')
        .order('card_number');
    return data.map((e) => LorcanaCard.fromSupabase(e)).toList();
  }

  Future<List<LorcanaCard>> fetchOwnedCards() async {
    final data = await _client
        .from('cards')
        .select()
        .eq('user_id', _userId)
        .eq('owned', true)
        .order('set_number')
        .order('card_number');
    return data.map((e) => LorcanaCard.fromSupabase(e)).toList();
  }

  Future<List<LorcanaCard>> fetchWishlist() async {
    final data = await _client
        .from('cards')
        .select()
        .eq('user_id', _userId)
        .eq('in_priority_wishlist', true)
        .order('set_number');
    return data.map((e) => LorcanaCard.fromSupabase(e)).toList();
  }

  /// Voeg alle kaarten van een set in bulk in (bij eerste sync).
  Future<void> upsertCards(List<LorcanaCard> cards) async {
    final rows = cards.map((c) => c.toSupabase(_userId)).toList();
    await _client.from('cards').upsert(rows, onConflict: 'id,user_id');
  }

  /// Sla gebruikersstatus op van één kaart (owned, foil, wishlist, etc.).
  Future<void> updateCardStatus(LorcanaCard card) async {
    await _client.from('cards').upsert(
      card.toSupabase(_userId),
      onConflict: 'id,user_id',
    );
  }

  // ─── Decks ─────────────────────────────────────────────────────────────────

  Future<List<Deck>> fetchDecks() async {
    final data = await _client
        .from('decks')
        .select('*, deck_entries(*)')
        .eq('user_id', _userId)
        .order('last_modified', ascending: false);

    return data.map((d) {
      final deck = Deck.fromSupabase(d);
      final entries = (d['deck_entries'] as List)
          .map((e) => DeckEntry.fromSupabase(e))
          .toList();
      deck.entries = entries;
      return deck;
    }).toList();
  }

  Future<Deck> createDeck(String name) async {
    final data = await _client.from('decks').insert({
      'user_id': _userId,
      'name': name,
      'last_modified': DateTime.now().toIso8601String(),
    }).select().single();
    return Deck.fromSupabase(data);
  }

  Future<void> updateDeck(Deck deck) async {
    await _client
        .from('decks')
        .update(deck.toSupabase(_userId))
        .eq('id', deck.id);
  }

  Future<void> deleteDeck(String deckId) async {
    await _client.from('decks').delete().eq('id', deckId).eq('user_id', _userId);
  }

  Future<void> upsertDeckEntry(DeckEntry entry) async {
    await _client.from('deck_entries').upsert(
      entry.toSupabase(),
      onConflict: 'id',
    );
  }

  Future<void> removeDeckEntry(String entryId) async {
    await _client.from('deck_entries').delete().eq('id', entryId);
  }
}
