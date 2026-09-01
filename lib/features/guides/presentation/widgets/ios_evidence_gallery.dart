import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

/// Galería de evidencias fotográficas estilo Apple Photos con soporte de zoom a pantalla completa
class IosEvidenceGallery extends StatelessWidget {
  final List<File> photos;
  final VoidCallback onTakePhoto;
  final ValueChanged<int> onDeletePhoto;
  final Color accentColor;

  const IosEvidenceGallery({
    super.key,
    required this.photos,
    required this.onTakePhoto,
    required this.onDeletePhoto,
    required this.accentColor,
  });

  void _openFullScreenViewer(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(
              'Evidencia ${initialIndex + 1} de ${photos.length}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          body: PageView.builder(
            itemCount: photos.length,
            controller: PageController(initialPage: initialIndex),
            itemBuilder: (context, index) {
              return PhotoView(
                imageProvider: FileImage(photos[index]),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2.5,
                heroAttributes: PhotoViewHeroAttributes(tag: 'photo_$index'),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Botón estilo iOS para capturar evidencia
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: onTakePhoto,
            icon: const Icon(Icons.camera_alt_outlined, size: 20),
            label: const Text(
              'Tomar Evidencia Fotográfica',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),

        // Carrusel de miniaturas estilo Apple Photos
        if (photos.isNotEmpty) ...[
          const SizedBox(height: 14),
          SizedBox(
            height: 105,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: photos.length,
              itemBuilder: (context, i) {
                final photo = photos[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        onTap: () => _openFullScreenViewer(context, i),
                        child: Hero(
                          tag: 'photo_$i',
                          child: Container(
                            width: 105,
                            height: 105,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                      alpha: isDark ? 0.4 : 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              image: DecorationImage(
                                image: FileImage(photo),
                                fit: BoxFit.cover,
                              ),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.15)
                                    : Colors.black.withValues(alpha: 0.08),
                                width: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: GestureDetector(
                          onTap: () => onDeletePhoto(i),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE11D48),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
