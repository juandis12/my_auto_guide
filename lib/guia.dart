import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vision_gallery_saver/vision_gallery_saver.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// =============================================================
//                   GUIA DE CONDUCCIÓN Y ACCIDENTES
// =============================================================
class GuiaScreen extends StatelessWidget {
  const GuiaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guía de Seguridad Vial'),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black87,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _OpcionCard(
            icon: Icons.car_crash,
            titulo: 'Accidente Leve',
            color: Colors.blueAccent,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AccidenteScreen(
                    tipo: 'leve',
                    color: Colors.blueAccent,
                    pasos: [
                      'Mantén la calma y verifica que todos estén bien.',
                      'Muévete a un lugar seguro para evitar otro accidente.',
                      'Evalúa los daños y verifica si hay lesiones leves.',
                      'Intercambia datos con el otro conductor (nombre, placa, aseguradora).',
                      'Documenta la escena (toma fotos).',
                      'Notifica a tu aseguradora lo ocurrido.',
                    ],
                  ),
                ),
              );
            },
          ),
          _OpcionCard(
            icon: Icons.warning_rounded,
            titulo: 'Accidente Grave',
            color: Colors.redAccent,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AccidenteScreen(
                    tipo: 'grave',
                    color: Colors.redAccent,
                    pasos: [
                      'Mantén la calma y evalúa tu seguridad.',
                      'Llama a los servicios de emergencia de inmediato.',
                      'Evita mover a los heridos si no es necesario.',
                      'Coloca triángulos de seguridad y balizas para señalizar.',
                      'Documenta la escena (toma fotos).',
                      'Informa a tu aseguradora y coopera con las autoridades.',
                    ],
                  ),
                ),
              );
            },
          ),
          _OpcionCard(
            icon: Icons.cloud,
            titulo: 'Clima Lluvioso',
            color: Colors.teal,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AccidenteScreen(
                    tipo: 'lluvia',
                    color: Colors.teal,
                    pasos: [
                      'Reduce la velocidad y aumenta la distancia de seguridad.',
                      'Enciende las luces bajas para mayor visibilidad.',
                      'Evita frenar bruscamente o girar de manera abrupta.',
                      'Si hay mucha agua, no cruces zonas inundadas.',
                      'Mantén el parabrisas limpio y el desempañador encendido.',
                    ],
                  ),
                ),
              );
            },
          ),
          _OpcionCard(
            icon: Icons.route,
            titulo: 'Viaje Largo',
            color: Colors.orangeAccent,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AccidenteScreen(
                    tipo: 'viaje',
                    color: Colors.orangeAccent,
                    pasos: [
                      'Verifica el estado del vehículo antes de salir (luces, frenos, llantas).',
                      'Asegúrate de descansar bien antes del viaje.',
                      'Planea tus paradas cada 2 horas para estirarte y descansar.',
                      'Lleva agua, botiquín, y herramientas básicas.',
                      'Usa cinturón de seguridad siempre y evita distracciones.',
                      'Mantente atento al clima y condiciones de la carretera.',
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 30),
          const Padding(
            padding: EdgeInsets.only(left: 8.0, bottom: 15.0),
            child: Text(
              'Video Tutoriales',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          // Puedes poner más links de YouTube agregando más tarjetas _VideoTutorialCard aquí
          // Solo pega el link completo de YouTube en el campo 'url'
          const _VideoTutorialCard(
            url: 'https://youtu.be/C0AkRhAwKzU?si=xKcXHaK218qjJUdI',
            titulo: 'Cómo cambiar el aceite',
          ),
          const _VideoTutorialCard(
            url: 'https://youtu.be/8DAbvfPURz8?si=AZdWU7bOeVxROT-z',
            titulo: 'Revisión de líquidos y niveles del vehículo',
          ),
          const _VideoTutorialCard(
            url: 'https://youtu.be/j3EqmPwY9oc?si=_hNNHQbjpUZitlAb',
            titulo: 'Qué hacer en caso de accidente de tránsito',
          ),
          const _VideoTutorialCard(
            url: 'https://youtu.be/r6VAKTDIggY?si=hJSTIJySLm5wCSzW',
            titulo: 'Como Lubricar Las Guayas De La Motocicleta Hazlo Tu Mismo',
          ),
          const _VideoTutorialCard(
            url: 'https://youtu.be/xAnMqIzCSdQ?si=UF4rbwTA_HgYk6DV',
            titulo:
                'Cambio o Purga del Liquido de Frenos de Moto - Freno Delantero',
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// Tarjeta de opciones principales
// -------------------------------------------------------------
class _OpcionCard extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final Color color;
  final VoidCallback onTap;

  const _OpcionCard({
    required this.icon,
    required this.titulo,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

// =============================================================
//       PANTALLA GENERAL (Leve, Grave, Lluvia, Viaje Largo)
// =============================================================
class AccidenteScreen extends StatefulWidget {
  final String tipo;
  final Color color;
  final List<String> pasos;

  const AccidenteScreen({
    super.key,
    required this.tipo,
    required this.color,
    required this.pasos,
  });

  @override
  State<AccidenteScreen> createState() => _AccidenteScreenState();
}

class _AccidenteScreenState extends State<AccidenteScreen> {
  List<bool> pasosCompletos = [];
  final List<File> _imagenes = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  // ------------------ CARGAR DATOS ------------------
  Future<void> _cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    final completados = prefs.getStringList('pasos_${widget.tipo}');
    final fotosGuardadas = prefs.getStringList('fotos_${widget.tipo}');

    List<bool> pasos = completados?.map((e) => e == 'true').toList() ?? [];
    if (pasos.length != widget.pasos.length) {
      pasos = List.filled(widget.pasos.length, false);
    }

    setState(() {
      pasosCompletos = pasos;
      if (fotosGuardadas != null) {
        _imagenes.addAll(fotosGuardadas.map((p) => File(p)));
      }
    });
  }

  // ------------------ GUARDAR DATOS ------------------
  Future<void> _guardarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'pasos_${widget.tipo}',
      pasosCompletos.map((e) => e.toString()).toList(),
    );
    await prefs.setStringList(
      'fotos_${widget.tipo}',
      _imagenes.map((e) => e.path).toList(),
    );
  }

  // ------------------ TOMAR FOTO ------------------
  Future<void> _tomarFoto() async {
    final XFile? foto = await _picker.pickImage(source: ImageSource.camera);
    if (foto != null) {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = await File(foto.path).copy(path);
      setState(() => _imagenes.add(file));
      await _guardarDatos();
    }
  }

  // ------------------ ELIMINAR FOTO ------------------
  void _eliminarFoto(int index) async {
    setState(() => _imagenes.removeAt(index));
    await _guardarDatos();
  }

  // ------------------ GUARDAR EN GALERÍA ------------------
  Future<void> _guardarEnGaleria(File file) async {
    try {
      final Uint8List bytes = await file.readAsBytes();
      final result = await VisionGallerySaver.saveImage(
        bytes,
        quality: 100,
        name: 'guia_${widget.tipo}_${DateTime.now().millisecondsSinceEpoch}',
      );

      final bool success = (result is Map &&
              (result['isSuccess'] == true || result['success'] == true)) ||
          (result == true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Imagen guardada en galería ✅'
                : 'No se pudo guardar la imagen',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar imagen: $e')));
    }
  }

  // ------------------ MARCAR PASO ------------------
  void _togglePaso(int index) async {
    setState(() => pasosCompletos[index] = !pasosCompletos[index]);
    await _guardarDatos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.tipo == 'leve'
              ? 'Accidente Leve'
              : widget.tipo == 'grave'
                  ? 'Accidente Grave'
                  : widget.tipo == 'lluvia'
                      ? 'Conducción con Lluvia'
                      : 'Viaje Largo',
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black87,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: widget.pasos.length,
        itemBuilder: (context, index) {
          final esFotoPaso = widget.pasos[index].contains('fotos');
          return _PasoCard(
            titulo: widget.pasos[index],
            color: widget.color,
            completado: pasosCompletos[index],
            onToggle: () => _togglePaso(index),
            contenidoExtra: esFotoPaso
                ? Column(
                    children: [
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _tomarFoto,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Tomar Foto'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.color,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(_imagenes.length, (i) {
                          final img = _imagenes[i];
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  img,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.download,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        onPressed: () => _guardarEnGaleria(img),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.redAccent,
                                          size: 18,
                                        ),
                                        onPressed: () => _eliminarFoto(i),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ],
                  )
                : null,
          );
        },
      ),
    );
  }
}

// =============================================================
//                 WIDGET DE CADA PASO
// =============================================================
class _PasoCard extends StatelessWidget {
  final String titulo;
  final Color color;
  final bool completado;
  final VoidCallback onToggle;
  final Widget? contenidoExtra;

  const _PasoCard({
    required this.titulo,
    required this.color,
    required this.completado,
    required this.onToggle,
    this.contenidoExtra,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                    color: completado ? color : Colors.transparent,
                  ),
                  child: completado
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          if (contenidoExtra != null) ...[
            const SizedBox(height: 10),
            contenidoExtra!,
          ],
        ],
      ),
    );
  }
}

// =============================================================
//               TARJETA DE VIDEO TUTORIAL
// =============================================================
class _VideoTutorialCard extends StatelessWidget {
  final String url; // Pega aquí el link completo de YouTube
  final String titulo;

  const _VideoTutorialCard({
    required this.url,
    required this.titulo,
  });

  /// Extrae el ID del video de cualquier formato de URL de YouTube
  static String extraerVideoId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;

    // Formato corto: youtu.be/VIDEO_ID
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : url;
    }

    // Formato largo: youtube.com/watch?v=VIDEO_ID
    if (uri.host.contains('youtube.com')) {
      return uri.queryParameters['v'] ?? url;
    }

    return url;
  }

  Future<void> _abrirVideo() async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoId = extraerVideoId(url);
    // YouTube ofrece miniaturas en esta URL
    final thumbnailUrl = 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _abrirVideo,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Miniatura del video con botón de play
            Stack(
              alignment: Alignment.center,
              children: [
                Image.network(
                  thumbnailUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(Icons.video_library,
                        size: 60, color: Colors.grey),
                  ),
                ),
                // Botón de play
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ],
            ),
            // Título del video
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Row(
                children: [
                  const Icon(Icons.play_circle_fill,
                      color: Colors.red, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const Icon(Icons.open_in_new, color: Colors.grey, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
