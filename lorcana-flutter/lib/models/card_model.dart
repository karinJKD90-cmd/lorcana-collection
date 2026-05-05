class LorcanaCard {
  final String id;
  final String name;
  final String setName;
  final int setNumber;
  final int cardNumber;
  final String rarity;
  final String ink;
  final int cost;
  final int strength;
  final int willpower;
  final int lore;
  final String cardType;
  final String? imageUrl;

  // Gebruikersstatus
  bool owned;
  bool isFoil;
  bool isSigned;
  bool inPriorityWishlist;
  int quantity;

  // Persoonlijk
  double? purchasePrice;
  String? notes;

  // Prijzen
  double? currentPriceNormal;
  double? currentPriceFoil;

  LorcanaCard({
    required this.id,
    required this.name,
    required this.setName,
    required this.setNumber,
    required this.cardNumber,
    required this.rarity,
    required this.ink,
    required this.cost,
    required this.strength,
    required this.willpower,
    required this.lore,
    required this.cardType,
    this.imageUrl,
    this.owned = false,
    this.isFoil = false,
    this.isSigned = false,
    this.inPriorityWishlist = false,
    this.quantity = 0,
    this.purchasePrice,
    this.notes,
    this.currentPriceNormal,
    this.currentPriceFoil,
  });

  /// Rarities die altijd foil zijn
  bool get alwaysFoil =>
      rarity == 'Enchanted' || rarity == 'Special' || rarity == 'Legendary';

  factory LorcanaCard.fromLorcastJson(Map<String, dynamic> json) {
    return LorcanaCard(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      setName: json['set']?['name'] ?? '',
      setNumber: json['set']?['id'] ?? 0,
      cardNumber: json['collector_number'] ?? 0,
      rarity: json['rarity'] ?? '',
      ink: json['ink'] ?? '',
      cost: json['cost'] ?? 0,
      strength: json['strength'] ?? 0,
      willpower: json['willpower'] ?? 0,
      lore: json['lore'] ?? 0,
      cardType: json['type'] ?? '',
      imageUrl: json['image'] ?? json['images']?['full'],
    );
  }

  factory LorcanaCard.fromSupabase(Map<String, dynamic> json) {
    return LorcanaCard(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      setName: json['set_name'] ?? '',
      setNumber: json['set_number'] ?? 0,
      cardNumber: json['card_number'] ?? 0,
      rarity: json['rarity'] ?? '',
      ink: json['ink'] ?? '',
      cost: json['cost'] ?? 0,
      strength: json['strength'] ?? 0,
      willpower: json['willpower'] ?? 0,
      lore: json['lore'] ?? 0,
      cardType: json['card_type'] ?? '',
      imageUrl: json['image_url'],
      owned: json['owned'] ?? false,
      isFoil: json['is_foil'] ?? false,
      isSigned: json['is_signed'] ?? false,
      inPriorityWishlist: json['in_priority_wishlist'] ?? false,
      quantity: json['quantity'] ?? 0,
      purchasePrice: (json['purchase_price'] as num?)?.toDouble(),
      notes: json['notes'],
      currentPriceNormal: (json['current_price_normal'] as num?)?.toDouble(),
      currentPriceFoil: (json['current_price_foil'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toSupabase(String userId) => {
        'id': id,
        'user_id': userId,
        'name': name,
        'set_name': setName,
        'set_number': setNumber,
        'card_number': cardNumber,
        'rarity': rarity,
        'ink': ink,
        'cost': cost,
        'strength': strength,
        'willpower': willpower,
        'lore': lore,
        'card_type': cardType,
        'image_url': imageUrl,
        'owned': owned,
        'is_foil': isFoil,
        'is_signed': isSigned,
        'in_priority_wishlist': inPriorityWishlist,
        'quantity': quantity,
        'purchase_price': purchasePrice,
        'notes': notes,
        'current_price_normal': currentPriceNormal,
        'current_price_foil': currentPriceFoil,
      };
}
