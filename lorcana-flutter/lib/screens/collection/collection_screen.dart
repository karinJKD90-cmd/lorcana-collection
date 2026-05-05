import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme.dart';
import '../../models/card_model.dart';
import '../../services/collection_service.dart';
import '../../services/lorcast_service.dart';
import '../../widgets/ink_badge.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<LorcanaCard> _allCards = [];
  bool _isLoading = true;
  String _search = '';
  bool _onlyOwned = false;
  String? _syncStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCards();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCards() async {
    setState(() => _isLoading = true);
    try {
      final service = context.read<CollectionService>();
      final cards = await service.fetchAllCards();
      setState(() { _allCards = cards; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _syncFromLorcast() async {
    setState(() => _syncStatus = 'Ophalen...');
    try {
      final lorcast = LorcastService();
      final service = context.read<CollectionService>();
      final cards = await lorcast.fetchAllCards(
        onProgress: (name, done, total) =>
            setState(() => _syncStatus = '$name ($done/$total)'),
      );
      await service.upsertCards(cards);
      await _loadCards();
      setState(() => _syncStatus = null);
    } catch (e) {
      setState(() => _syncStatus = 'Fout: $e');
    }
  }

  List<LorcanaCard> get _filtered {
    var list = _onlyOwned ? _allCards.where((c) => c.owned).toList() : _allCards;
    if (_search.isNotEmpty) {
      list = list
          .where((c) => c.name.toLowerCase().contains(_search.toLowerCase()))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collectie'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: LorcanaTheme.gold,
          unselectedLabelColor: LorcanaTheme.textMuted,
          indicatorColor: LorcanaTheme.gold,
          tabs: const [Tab(text: 'Alle kaarten'), Tab(text: 'Wishlist')],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync kaartdata',
            onPressed: _syncFromLorcast,
          ),
          IconButton(
            icon: Icon(_onlyOwned ? Icons.check_box : Icons.check_box_outline_blank),
            tooltip: 'Alleen bezit',
            onPressed: () => setState(() => _onlyOwned = !_onlyOwned),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_syncStatus != null)
            Container(
              width: double.infinity,
              color: LorcanaTheme.gold.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(_syncStatus!,
                  style: const TextStyle(color: LorcanaTheme.gold, fontSize: 12)),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(
                hintText: 'Zoek kaart...',
                prefixIcon: Icon(Icons.search, color: LorcanaTheme.textMuted),
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _CardGrid(cards: _filtered, onTap: _openCard, isLoading: _isLoading),
                _CardGrid(
                  cards: _allCards.where((c) => c.inPriorityWishlist).toList(),
                  onTap: _openCard,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openCard(LorcanaCard card) {
    context.go('/home/card/${card.id}', extra: card);
  }
}

class _CardGrid extends StatelessWidget {
  final List<LorcanaCard> cards;
  final void Function(LorcanaCard) onTap;
  final bool isLoading;

  const _CardGrid({required this.cards, required this.onTap, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: LorcanaTheme.gold));
    }
    if (cards.isEmpty) {
      return const Center(
        child: Text('Geen kaarten gevonden', style: TextStyle(color: LorcanaTheme.textMuted)),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.68,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: cards.length,
      itemBuilder: (_, i) => _CardTile(card: cards[i], onTap: () => onTap(cards[i])),
    );
  }
}

class _CardTile extends StatelessWidget {
  final LorcanaCard card;
  final VoidCallback onTap;

  const _CardTile({required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: card.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: card.imageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (_, __) => Container(color: LorcanaTheme.surface),
                    errorWidget: (_, __, ___) =>
                        Container(color: LorcanaTheme.surface,
                            child: const Icon(Icons.broken_image, color: LorcanaTheme.textMuted)),
                  )
                : Container(color: LorcanaTheme.surface),
          ),
          if (!card.owned)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          if (card.isFoil)
            Positioned(
              top: 4, right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: LorcanaTheme.gold,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text('F', style: TextStyle(color: LorcanaTheme.background, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }
}
