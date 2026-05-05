class Deck {
  final String id;
  String name;
  String? notes;
  final DateTime createdAt;
  DateTime lastModified;
  List<DeckEntry> entries;

  Deck({
    required this.id,
    required this.name,
    this.notes,
    required this.createdAt,
    required this.lastModified,
    this.entries = const [],
  });

  int get totalCards => entries.fold(0, (sum, e) => sum + e.quantity);
  bool get isValid => totalCards == 60;

  factory Deck.fromSupabase(Map<String, dynamic> json) => Deck(
        id: json['id'],
        name: json['name'],
        notes: json['notes'],
        createdAt: DateTime.parse(json['created_at']),
        lastModified: DateTime.parse(json['last_modified']),
      );

  Map<String, dynamic> toSupabase(String userId) => {
        'id': id,
        'user_id': userId,
        'name': name,
        'notes': notes,
        'last_modified': lastModified.toIso8601String(),
      };
}

class DeckEntry {
  final String id;
  final String deckId;
  final String cardId;
  final String cardName;
  final String? imageUrl;
  int quantity;

  DeckEntry({
    required this.id,
    required this.deckId,
    required this.cardId,
    required this.cardName,
    this.imageUrl,
    this.quantity = 1,
  });

  factory DeckEntry.fromSupabase(Map<String, dynamic> json) => DeckEntry(
        id: json['id'],
        deckId: json['deck_id'],
        cardId: json['card_id'],
        cardName: json['card_name'] ?? '',
        imageUrl: json['image_url'],
        quantity: json['quantity'] ?? 1,
      );

  Map<String, dynamic> toSupabase() => {
        'id': id,
        'deck_id': deckId,
        'card_id': cardId,
        'card_name': cardName,
        'image_url': imageUrl,
        'quantity': quantity,
      };
}
