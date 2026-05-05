import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme.dart';
import '../../services/auth_service.dart';
import '../../services/collection_service.dart';
import '../../services/lorcast_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Instellingen')),
      body: ListView(
        children: [
          const SizedBox(height: 16),

          // Account info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              user?.email ?? '',
              style: const TextStyle(color: LorcanaTheme.textMuted, fontSize: 13),
            ),
          ),
          const Divider(color: LorcanaTheme.borderColor),

          // Sync
          ListTile(
            leading: const Icon(Icons.sync, color: LorcanaTheme.gold),
            title: const Text('Kaartdatabase synchen', style: TextStyle(color: LorcanaTheme.textPrimary)),
            subtitle: const Text('Haalt alle Lorcana-kaarten op van Lorcast', style: TextStyle(color: LorcanaTheme.textMuted, fontSize: 12)),
            onTap: () => _syncCards(context),
          ),
          const Divider(color: LorcanaTheme.borderColor),

          // Uitloggen
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Uitloggen', style: TextStyle(color: Colors.redAccent)),
            onTap: () async {
              await context.read<AuthService>().signOut();
              if (context.mounted) context.go('/auth');
            },
          ),
        ],
      ),
    );
  }

  Future<void> _syncCards(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('Sync gestart...')));
    try {
      final cards = await LorcastService().fetchAllCards();
      await context.read<CollectionService>().upsertCards(cards);
      messenger.showSnackBar(SnackBar(
        content: Text('${cards.length} kaarten bijgewerkt'),
        backgroundColor: LorcanaTheme.gold,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Fout: $e')));
    }
  }
}
