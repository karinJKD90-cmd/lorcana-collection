import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme.dart';
import '../../models/card_model.dart';
import '../../services/ocr_service.dart';
import '../../services/collection_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _ocr = OcrService();
  final _picker = ImagePicker();
  bool _isAnalyzing = false;
  OcrResult? _result;
  File? _image;
  List<LorcanaCard> _allCards = [];

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  @override
  void dispose() {
    _ocr.dispose();
    super.dispose();
  }

  Future<void> _loadCards() async {
    final cards = await context.read<CollectionService>().fetchAllCards();
    setState(() => _allCards = cards);
  }

  Future<void> _scan() async {
    final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 90);
    if (picked == null) return;
    final file = File(picked.path);
    setState(() { _image = file; _isAnalyzing = true; _result = null; });
    final result = await _ocr.scanCard(imageFile: file, allCards: _allCards);
    setState(() { _result = result; _isAnalyzing = false; });
  }

  Future<void> _markOwned(LorcanaCard card, bool isFoil) async {
    card.owned = true;
    card.isFoil = isFoil || card.alwaysFoil;
    if (card.quantity == 0) card.quantity = 1;
    await context.read<CollectionService>().updateCardStatus(card);
    setState(() { _image = null; _result = null; });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${card.name} toegevoegd!'),
        backgroundColor: LorcanaTheme.gold,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scannen')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_image == null && _result == null) ...[
              const Icon(Icons.camera_alt_outlined, size: 64, color: LorcanaTheme.textMuted),
              const SizedBox(height: 16),
              const Text(
                'Richt de camera op een Lorcana-kaart',
                textAlign: TextAlign.center,
                style: TextStyle(color: LorcanaTheme.textMuted),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _scan,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Kaart scannen'),
              ),
            ],

            if (_isAnalyzing)
              const Column(
                children: [
                  CircularProgressIndicator(color: LorcanaTheme.gold),
                  SizedBox(height: 16),
                  Text('Kaart herkennen...', style: TextStyle(color: LorcanaTheme.textMuted)),
                ],
              ),

            if (_result != null) ...[
              if (_result!.exactMatch != null)
                _MatchCard(
                  card: _result!.exactMatch!,
                  onNormaal: () => _markOwned(_result!.exactMatch!, false),
                  onFoil: () => _markOwned(_result!.exactMatch!, true),
                )
              else if (_result!.candidates.isNotEmpty)
                _CandidateList(
                  candidates: _result!.candidates,
                  onSelect: (c) => _markOwned(c, false),
                )
              else
                const Text('Kaart niet herkend', style: TextStyle(color: LorcanaTheme.textMuted)),

              const SizedBox(height: 24),
              TextButton(
                onPressed: () => setState(() { _image = null; _result = null; }),
                child: const Text('Opnieuw scannen', style: TextStyle(color: LorcanaTheme.textMuted)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final LorcanaCard card;
  final VoidCallback onNormaal;
  final VoidCallback onFoil;

  const _MatchCard({required this.card, required this.onNormaal, required this.onFoil});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Dit is:', style: TextStyle(color: LorcanaTheme.textMuted, fontSize: 12)),
        const SizedBox(height: 12),
        if (card.imageUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(card.imageUrl!, width: 140),
          ),
        const SizedBox(height: 12),
        Text(card.name, style: const TextStyle(fontFamily: 'Georgia', fontSize: 18, color: LorcanaTheme.textPrimary)),
        Text('${card.setName} · #${card.cardNumber}', style: const TextStyle(color: LorcanaTheme.textMuted, fontSize: 12)),
        const SizedBox(height: 20),
        if (card.alwaysFoil)
          ElevatedButton(onPressed: onNormaal, child: const Text('Toevoegen (altijd foil)'))
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(onPressed: onNormaal, child: const Text('Normaal')),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: onFoil,
                style: OutlinedButton.styleFrom(foregroundColor: LorcanaTheme.gold, side: const BorderSide(color: LorcanaTheme.gold)),
                child: const Text('Foil'),
              ),
            ],
          ),
      ],
    );
  }
}

class _CandidateList extends StatelessWidget {
  final List<LorcanaCard> candidates;
  final void Function(LorcanaCard) onSelect;

  const _CandidateList({required this.candidates, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Bedoel je één van deze?', style: TextStyle(color: LorcanaTheme.textMuted)),
        const SizedBox(height: 12),
        ...candidates.map((c) => ListTile(
          leading: c.imageUrl != null
              ? ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.network(c.imageUrl!, width: 36))
              : null,
          title: Text(c.name, style: const TextStyle(color: LorcanaTheme.textPrimary, fontSize: 14)),
          subtitle: Text('${c.setName} · #${c.cardNumber}', style: const TextStyle(color: LorcanaTheme.textMuted, fontSize: 11)),
          trailing: const Icon(Icons.chevron_right, color: LorcanaTheme.gold),
          onTap: () => onSelect(c),
        )),
      ],
    );
  }
}
