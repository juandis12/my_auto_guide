import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_apple_theme.dart';
import '../../data/models/guide_video_model.dart';

/// Tarjeta de video tutorial estilo Apple TV / iOS App Store con Glassmorphism y badges
class IosVideoCard extends StatefulWidget {
  final GuideVideo video;

  const IosVideoCard({
    super.key,
    required this.video,
  });

  @override
  State<IosVideoCard> createState() => _IosVideoCardState();
}

class _IosVideoCardState extends State<IosVideoCard> {
  double _scale = 1.0;

  Future<void> _openVideo() async {
    final uri = Uri.tryParse(widget.video.url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: AppAppleTheme.glassBlurSigma,
              sigmaY: AppAppleTheme.glassBlurSigma,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _openVideo,
                onTapDown: (_) => setState(() => _scale = 0.97),
                onTapUp: (_) => setState(() => _scale = 1.0),
                onTapCancel: () => setState(() => _scale = 1.0),
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A).withValues(alpha: 0.85)
                        : Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.06),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Portada del Video con badges y play overlay
                      Stack(
                        children: [
                          Container(
                            height: 180,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFE2E8F0),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(22),
                              ),
                            ),
                            child: widget.video.thumbnailUrl.isNotEmpty
                                ? Image.network(
                                    widget.video.thumbnailUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _buildFallbackThumbnail(),
                                  )
                                : _buildFallbackThumbnail(),
                          ),

                          // Gradiente de contraste sobre la imagen
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withValues(alpha: 0.6),
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.7),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ),

                          // Badge superior de categoría
                          Positioned(
                            top: 12,
                            left: 12,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  color: Colors.black.withValues(alpha: 0.5),
                                  child: Text(
                                    widget.video.tag.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Badge de duración
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  color: Colors.black.withValues(alpha: 0.6),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.schedule_rounded,
                                        color: Colors.white,
                                        size: 13,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        widget.video.duration,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Botón Play Central Frosted Glass
                          Positioned.fill(
                            child: Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(25),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.25),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.6),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Detalles del video
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.video.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.black87,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.video.subtitle,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white70 : Colors.black54,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackThumbnail() {
    return const Center(
      child: Icon(
        Icons.smart_display_outlined,
        size: 54,
        color: Colors.white54,
      ),
    );
  }
}
