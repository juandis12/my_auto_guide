import 'package:flutter/material.dart';
import '../../domain/models/vehicle_analytics.dart';

class AIInsightsPanel extends StatelessWidget {
  final VehicleAnalytics analytics;

  const AIInsightsPanel({
    super.key,
    required this.analytics,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.blueAccent.withOpacity(0.05) : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Diagnóstico IA My Auto Guide',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.blue.shade200 : Colors.blue.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              _AIBadge(label: 'Uso: ${analytics.intensity}', color: Colors.orange),
              _AIBadge(label: 'IA Care: ${analytics.careScore.round()}%', color: Colors.blueAccent),
              _AIBadge(label: 'Consistencia: ${analytics.consistency}', color: Colors.green),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            analytics.advice,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: isDark ? Colors.white70 : Colors.black87,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _AIBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _AIBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
