import 'package:flutter/material.dart';

class MarketplaceTalleresScreen extends StatelessWidget {
  const MarketplaceTalleresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace de Talleres'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSpecialOffer(isDark),
          const SizedBox(height: 24),
          Text(
            'Recomendados por tu IA',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _WorkshopCard(
            name: 'Taller Central Specialized',
            category: 'Mecánica General • Motos',
            rating: 4.8,
            distance: '1.2 km',
            imageUrl: 'https://images.unsplash.com/photo-1590674824053-48b4369e96e7?q=80&w=200&auto=format&fit=crop',
            isDark: isDark,
          ),
          _WorkshopCard(
            name: 'Auto Fix Elite',
            category: 'Frenos y Suspensión • Carros',
            rating: 4.9,
            distance: '2.5 km',
            imageUrl: 'https://images.unsplash.com/photo-1486006920555-c77dcf18193c?q=80&w=200&auto=format&fit=crop',
            isDark: isDark,
          ),
          _WorkshopCard(
            name: 'LubriExpress Premium',
            category: 'Cambio de Aceite',
            rating: 4.5,
            distance: '0.8 km',
            imageUrl: 'https://images.unsplash.com/photo-1619641782822-233bbd4051b7?q=80&w=200&auto=format&fit=crop',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialOffer(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
            ? [const Color(0xFF11998e), const Color(0xFF38ef7d)]
            : [Colors.teal[700]!, Colors.teal[400]!],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Beneficio My Auto Guide',
                  style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  '15% OFF en Frenos',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Válido en talleres aliados por diagnóstico de tu IA.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.qr_code, color: Colors.white, size: 40),
          ),
        ],
      ),
    );
  }
}

class _WorkshopCard extends StatelessWidget {
  final String name, category, distance, imageUrl;
  final double rating;
  final bool isDark;

  const _WorkshopCard({
    required this.name,
    required this.category,
    required this.distance,
    required this.imageUrl,
    required this.rating,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              bottomLeft: Radius.circular(20),
            ),
            child: Image.network(
              imageUrl,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 100, height: 100, color: Colors.grey[200],
                child: const Icon(Icons.build, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  category,
                  style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Text(rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        distance,
                        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
