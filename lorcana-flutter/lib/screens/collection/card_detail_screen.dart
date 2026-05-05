import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme.dart';
import '../../models/card_model.dart';
import '../../services/collection_service.dart';
import '../../widgets/ink_badge.dart';

class CardDetailScreen extends StatefulWidget {
  final LorcanaCard card;
  const CardDetailScreen({super.key, required this.card});

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  late LorcanaCard _card;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _card = widget.card;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<CollectionService>().updateCardStatus(_card);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_card.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_card.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: _card.imageUrl!,
                  width: 220,
                  fit: BoxFit.fitWidth,
                ),
              ),
            const SizedBox(height: 24),

            Text(
              _card.name,
              style: const TextStyle(fontFamily: 'Georgia', fontSize: 22, color: LorcanaTheme.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '${_card.setName} · #${_card.cardNumber}',
              style: const TextStyle(color: LorcanaTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 8),
            InkBadge(ink: _card.ink),
            const SizedBox(height: 24),

            // Stat row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _stat('Kosten', '${_card.cost}'),
                _stat('Kracht', '${_card.strength}'),
                _stat('Wilskracht', '${_card.willpower}'),
                _stat('Queeste', '${_card.lore}'),
              ],
            ),
            const SizedBox(height: 32),

            // Status toggles
            _toggle('In bezit', _card.owned, (v) {
              setState(() { _card.owned = v; if (!v) _card.quantity = 0; else if (_card.quantity == 0) _card.quantity = 1; });
              _save();
            }),
            if (!_card.alwaysFoil)
              _toggle('Foil', _card.isFoil, (v) { setState(() => _card.isFoil = v); _save(); }),
            _toggle('Gesigneerd', _card.isSigned, (v) { setState(() => _card.isSigned = v); _save(); }),
            _toggle('Prioriteit wishlist', _card.inPriorityWishlist, (v) { setState(() => _card.inPriorityWishlist = v); _save(); }),

            if (_saving)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: CircularProgressIndicator(color: LorcanaTheme.gold, strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) => Column(
    children: [
      Text(value, style: const TextStyle(fontSize: 20, color: LorcanaTheme.textPrimary, fontFamily: 'Georgia')),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 11, color: LorcanaTheme.textMuted)),
    ],
  );

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) => SwitchListTile(
    title: Text(label, style: const TextStyle(color: LorcanaTheme.textPrimary, fontSize: 15)),
    value: value,
    onChanged: onChanged,
    activeColor: LorcanaTheme.gold,
    contentPadding: EdgeInsets.zero,
  );
}
