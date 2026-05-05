import 'package:flutter/material.dart';

class InkBadge extends StatelessWidget {
  final String ink;
  const InkBadge({super.key, required this.ink});

  Color get _color => switch (ink.toLowerCase()) {
        'amber' => const Color(0xFFF59E0B),
        'amethyst' => const Color(0xFF8B5CF6),
        'emerald' => const Color(0xFF10B981),
        'ruby' => const Color(0xFFEF4444),
        'sapphire' => const Color(0xFF3B82F6),
        'steel' => const Color(0xFF6B7280),
        _ => const Color(0xFF9CA3AF),
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        border: Border.all(color: _color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        ink,
        style: TextStyle(color: _color, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}
