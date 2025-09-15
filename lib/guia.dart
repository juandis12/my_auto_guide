import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Pantalla principal de Guías
class GuiasScreen extends StatelessWidget {
  const GuiasScreen({Key? key}) : super(key: key);

  // URL entregada
  static const String kVideoUrl =
      'https://youtu.be/h22GM8p2_9I?si=wHA5l46JAbyw8ZTt';

  @override
  Widget build(BuildContext context) {
    // Convierte URL -> videoId de forma robusta
    final String? parsed = YoutubePlayerController.convertUrlToId(kVideoUrl);
    final String kVideoId = parsed ?? 'h22GM8p2_9I';

    final guias = <_GuiaItem>[
      _GuiaItem(icon: Icons.car_crash, title: 'Accidente leve'),
      _GuiaItem(icon: Icons.report, title: 'Accidente grave'),
      _GuiaItem(icon: Icons.cloud, title: 'Ambiente Lluvioso'),
      _GuiaItem(icon: Icons.terrain, title: 'Viaje Largo'),
    ];

    final articulos = <_ArticuloItem>[
      _ArticuloItem(
        title:
            '¿Cómo realizar un correcto cambio de aceite de motor para su vehículo?',
        isVideo: true,
        videoId: kVideoId, // se reproduce dentro de la app
      ),
      _ArticuloItem(
        title: '¿Cómo cambiar un neumático de su vehículo?',
        isVideo: false,
      ),
      _ArticuloItem(
        title:
            '¿Cómo pasar corriente de un auto a otro cuando tu batería está descargada?',
        isVideo: false,
      ),
      _ArticuloItem(
        title: '¿Cómo CAMBIAR el FILTRO del AIRE del motor?',
        isVideo: true,
      ),
      _ArticuloItem(
        title: 'Cómo cambiar la batería de tu coche correctamente',
        isVideo: false,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Guías',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 4),
            const Text(
              '¿Problemas? Calma, te ayudaremos',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),

            // Lista de guías
            ListView.separated(
              itemCount: guias.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) =>
                  _GuiaButton(item: guias[i], onTap: () {}),
            ),
            const SizedBox(height: 20),

            const Text(
              'Conoce más a detalle',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Lista de artículos / videos
            ListView.separated(
              itemCount: articulos.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _ArticuloCard(
                item: articulos[i],
                onTap: () {
                  final it = articulos[i];
                  if (it.isVideo && it.videoId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VideoPlayerScreen(videoId: it.videoId!),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuiaItem {
  final IconData icon;
  final String title;
  const _GuiaItem({required this.icon, required this.title});
}

class _GuiaButton extends StatelessWidget {
  final _GuiaItem item;
  final VoidCallback onTap;
  const _GuiaButton({Key? key, required this.item, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon, color: Colors.black87),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black45),
          ],
        ),
      ),
    );
  }
}

class _ArticuloItem {
  final String title;
  final bool isVideo;
  final String? videoId;
  const _ArticuloItem({
    required this.title,
    required this.isVideo,
    this.videoId,
  });
}

class _ArticuloCard extends StatelessWidget {
  final _ArticuloItem item;
  final VoidCallback onTap;
  const _ArticuloCard({Key? key, required this.item, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final thumb = item.videoId != null
        ? YoutubePlayerController.getThumbnail(
            videoId: item.videoId!,
            webp: true,
          )
        : null;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 70,
                height: 50,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (thumb != null)
                      Image.network(thumb, fit: BoxFit.cover)
                    else
                      Container(color: Colors.black12),
                    if (item.isVideo)
                      const Center(
                        child: Icon(
                          Icons.play_circle_fill,
                          color: Colors.white70,
                          size: 28,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(fontSize: 13.5, height: 1.2),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Pantalla del reproductor con iFrame y fallback WebView
class VideoPlayerScreen extends StatefulWidget {
  final String videoId; // ej: 'h22GM8p2_9I'
  const VideoPlayerScreen({Key? key, required this.videoId}) : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final YoutubePlayerController _controller;
  bool _loaded = false;
  bool _useFallback = false;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        strictRelatedVideos: true,
        enableCaption: true,
      ),
    ); // API vigente: fromVideoId + params dentro del Scaffold del paquete. [1]

    // Marcar cargado cuando el estado pasa a 'playing'
    _controller.stream.listen((value) {
      if (!_loaded && value.playerState == PlayerState.playing) {
        setState(() => _loaded = true);
      }
    }); // Observa cambios del controlador vía stream como indica la API. [21]

    // Si no cargó en 3s, usa fallback WebView
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_loaded) {
        setState(() => _useFallback = true);
      }
    }); // Evita pantalla en blanco si el iFrame no renderiza. [1]
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_useFallback) {
      final embedUrl = Uri.parse(
        'https://www.youtube.com/embed/${widget.videoId}?autoplay=1&playsinline=1&modestbranding=1&rel=0',
      );
      final webCtrl = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(embedUrl);
      return Scaffold(
        appBar: AppBar(title: const Text('Video')),
        body: WebViewWidget(controller: webCtrl),
      ); // Fallback WebView con webview_flutter bien soportado. [7]
    }

    return YoutubePlayerScaffold(
      controller: _controller,
      aspectRatio: 16 / 9,
      builder: (context, player) => Scaffold(
        appBar: AppBar(title: const Text('Video')),
        body: Center(child: player),
      ),
    ); // Contenedor recomendado para fullscreen correcto con iFrame. [1]
  }
}
