import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../models/deck_model.dart';
import '../../services/collection_service.dart';

class DeckListScreen extends StatefulWidget {
  const DeckListScreen({super.key});

  @override
  State<DeckListScreen> createState() => _DeckListScreenState();
}

class _DeckListScreenState extends State<DeckListScreen> {
  List<Deck> _decks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    _decks = await context.read<CollectionService>().fetchDecks();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _newDeck() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: LorcanaTheme.surface,
        title: const Text('Nieuw deck', style: TextStyle(color: LorcanaTheme.textPrimary, fontFamily: 'Georgia')),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Naam...')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuleren', style: TextStyle(color: LorcanaTheme.textMuted))),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Aanmaken')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await context.read<CollectionService>().createDeck(name);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Decks'),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: _newDeck)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: LorcanaTheme.gold))
          : _decks.isEmpty
              ? const Center(child: Text('Nog geen decks', style: TextStyle(color: LorcanaTheme.textMuted)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _decks.length,
                  separatorBuilder: (_, __) => const Divider(color: LorcanaTheme.borderColor),
                  itemBuilder: (_, i) {
                    final deck = _decks[i];
                    return ListTile(
                      title: Text(deck.name, style: const TextStyle(color: LorcanaTheme.textPrimary, fontFamily: 'Georgia')),
                      subtitle: Text(
                        '${deck.totalCards}/60 kaarten${deck.isValid ? " ✓" : ""}',
                        style: TextStyle(
                          color: deck.isValid ? LorcanaTheme.gold : LorcanaTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: LorcanaTheme.textMuted),
                    );
                  },
                ),
    );
  }
}
