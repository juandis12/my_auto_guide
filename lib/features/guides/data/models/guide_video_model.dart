/// Modelo que representa un video tutorial con metadatos optimizados para la visualización estilo Apple TV / iOS.
class GuideVideo {
  final String id;
  final String title;
  final String subtitle;
  final String duration;
  final String tag;
  final String url;
  final String customThumbnailUrl;

  const GuideVideo({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.tag,
    required this.url,
    this.customThumbnailUrl = '',
  });

  /// Extrae de forma segura el ID del video de YouTube para cargar la miniatura HQ
  String get youtubeId {
    final uri = Uri.tryParse(url);
    if (uri == null) return '';

    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
    }
    if (uri.host.contains('youtube.com')) {
      return uri.queryParameters['v'] ?? '';
    }
    return '';
  }

  /// URL de la miniatura de alta definición de YouTube
  String get thumbnailUrl {
    if (customThumbnailUrl.isNotEmpty) return customThumbnailUrl;
    final yId = youtubeId;
    if (yId.isNotEmpty) {
      return 'https://img.youtube.com/vi/$yId/hqdefault.jpg';
    }
    return '';
  }

  /// Colección por defecto de video tutoriales de mantenimiento y seguridad vial
  static const List<GuideVideo> defaultVideos = [
    GuideVideo(
      id: 'aceite',
      title: 'Paso a Paso: Cambio de Aceite y Filtro',
      subtitle: 'Aprende a inspeccionar el nivel, viscosidad y realizar el cambio preventivo.',
      duration: '8:45 min',
      tag: 'Mecánica Básica',
      url: 'https://youtu.be/C0AkRhAwKzU?si=xKcXHaK218qjJUdI',
    ),
    GuideVideo(
      id: 'liquidos',
      title: 'Inspección de Líquidos y Niveles Esenciales',
      subtitle: 'Líquido de frenos, refrigerante, dirección y limpiaparabrisas.',
      duration: '6:30 min',
      tag: 'Mantenimiento Preventivo',
      url: 'https://youtu.be/8DAbvfPURz8?si=AZdWU7bOeVxROT-z',
    ),
    GuideVideo(
      id: 'accidente',
      title: 'Protocolo Legal y Técnico ante Accidentes',
      subtitle: 'Cómo documentar un siniestro correctamente ante aseguradoras y peritos.',
      duration: '11:15 min',
      tag: 'Seguridad Legal',
      url: 'https://youtu.be/j3EqmPwY9oc?si=_hNNHQbjpUZitlAb',
    ),
  ];
}
