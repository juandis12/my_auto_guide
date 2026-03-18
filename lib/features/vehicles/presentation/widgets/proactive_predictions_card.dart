import 'package:flutter/material.dart';
import '../../domain/models/maintenance_prediction.dart';

class ProactivePredictionsCard extends StatelessWidget {
  final List<MaintenancePrediction> predictions;

  const ProactivePredictionsCard({
    super.key,
    required this.predictions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_graph_rounded, size: 16, color: Colors.purple[400]),
            const SizedBox(width: 8),
            const Text(
              'Diagnóstico Predictivo (IA)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...predictions.map((p) {
          final color = p.isCritical ? Colors.redAccent : Colors.orangeAccent;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${p.item}: ${p.reason}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Riesgo: ${p.risk}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: isDark ? Colors.white24 : Colors.black12,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
