// =============================================================================
// guia.dart — GUÍAS DE SEGURIDAD VIAL Y VIDEO TUTORIALES
// =============================================================================
//
// Módulo educativo y de apoyo para el usuario con dos secciones principales:
//
// 1. GUÍAS DE SEGURIDAD VIAL: Cuatro escenarios con pasos interactivos:
//    - Accidente Leve (azul): Mantén calma, intercambia datos, documenta.
//    - Accidente Grave (rojo): Llama emergencias, señaliza, coopera.
//    - Clima Lluvioso (teal): Reduce velocidad, enciende luces, no inundes.
//    - Viaje Largo (naranja): Revisa vehículo, descansa cada 2h, lleva kit.
//    Cada guía tiene pasos que se pueden marcar como completados (checkbox)
//    y la posibilidad de tomar fotos del incidente con la cámara.
//    Los datos se guardan localmente con [SharedPreferences].
//
// 2. VIDEO TUTORIALES: Tarjetas con miniaturas de YouTube que al tocarlas
//    abren el video en la app de YouTube. Incluye tutoriales de:
//    - Cambio de aceite, revisión de líquidos, manejo de accidentes, etc.
//
// Widgets:
//   - [GuiaScreen]: Pantalla principal con las opciones y videos.
//   - [AccidenteScreen]: Pantalla de pasos interactivos con check y fotos.
//   - [_OpcionCard]: Tarjeta de opción en la lista principal.
//   - [_PasoCard]: Widget de cada paso con checkbox circular.
//   - [_VideoTutorialCard]: Tarjeta con miniatura de YouTube y botón play.
//
// =============================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// =============================================================
//                   GUIA DE CONDUCCIÓN Y ACCIDENTES
// =============================================================
class GuiaScreen extends StatelessWidget {
  const GuiaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Guía de Seguridad Vial',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: isDark ? Colors.white : Colors.black87,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _OpcionCard(
            icon: Icons.car_crash_outlined,
            titulo: 'Accidente Leve',
            subtitulo: 'Gestión de incidentes menores',
            color: const Color(0xFF42A5F5), // Azul armónico
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AccidenteScreen(
                    tipo: 'leve',
                    color: Color(0xFF42A5F5),
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
            icon: Icons.warning_amber_rounded,
            titulo: 'Accidente Grave',
            subtitulo: 'Protocolo de emergencia crítica',
            color: const Color(0xFFFF7043), // Naranja-rojo armónico
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AccidenteScreen(
                    tipo: 'grave',
                    color: Color(0xFFFF7043),
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
            icon: Icons.umbrella_outlined,
            titulo: 'Clima Lluvioso',
            subtitulo: 'Consejos para asfalto mojado',
            color: const Color(0xFF26A69A), // Teal armónico
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AccidenteScreen(
                    tipo: 'lluvia',
                    color: Color(0xFF26A69A),
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
            icon: Icons.map_outlined,
            titulo: 'Viaje Largo',
            subtitulo: 'Preparación para carretera',
            color: const Color(0xFFFFA726), // Ámbar armónico
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AccidenteScreen(
                    tipo: 'viaje',
                    color: Color(0xFFFFA726),
                    pasos: [
                      'Verifica el estado del vehículo antes de salir.',
                      'Asegúrate de descansar bien antes del viaje.',
                      'Planea tus paradas cada 2 horas.',
                      'Lleva agua, botiquín, y herramientas básicas.',
                      'Usa cinturón de seguridad siempre.',
                      'Mantente atento al clima y condiciones.',
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Video Tutoriales',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: 0.5,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF035880),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
          const _VideoTutorialCard(
            url: 'https://youtu.be/C0AkRhAwKzU?si=xKcXHaK218qjJUdI',
            titulo: 'Cómo cambiar el aceite',
          ),
          const _VideoTutorialCard(
            url: 'https://youtu.be/8DAbvfPURz8?si=AZdWU7bOeVxROT-z',
            titulo: 'Revisión de líquidos y niveles',
          ),
          const _VideoTutorialCard(
            url: 'https://youtu.be/j3EqmPwY9oc?si=_hNNHQbjpUZitlAb',
            titulo: 'Qué hacer en caso de accidente',
          ),
        ],
      ),
    );
  }
}

class _OpcionCard extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String subtitulo;
  final Color color;
  final VoidCallback onTap;

  const _OpcionCard({
    required this.icon,
    required this.titulo,
    required this.subtitulo,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitulo,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: isDark ? Colors.white24 : Colors.black12,
                ),
              ],
            ),
          ),
        ),
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
    try {
      final XFile? foto = await _picker.pickImage(source: ImageSource.camera);
      if (foto != null) {
        final dir = await getApplicationDocumentsDirectory();
        final path = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final file = await File(foto.path).copy(path);
        setState(() => _imagenes.add(file));
        await _guardarDatos();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al usar la cámara o guardar foto: $e')),
        );
      }
    }
  }

  // ------------------ ELIMINAR FOTO ------------------
  void _eliminarFoto(int index) async {
    setState(() => _imagenes.removeAt(index));
    await _guardarDatos();
  }

  // ------------------ MARCAR PASO ------------------
  void _togglePaso(int index) async {
    setState(() => pasosCompletos[index] = !pasosCompletos[index]);
    await _guardarDatos();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = widget.color.withOpacity(0.9);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          widget.tipo == 'leve'
              ? 'Accidente Leve'
              : widget.tipo == 'grave'
                  ? 'Accidente Grave'
                  : widget.tipo == 'lluvia'
                      ? 'Conducción con Lluvia'
                      : 'Viaje Largo',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black87,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Banner informativo superior
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, primaryColor.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                   Icon(
                    widget.tipo == 'grave' ? Icons.emergency : Icons.info_outline,
                    color: Colors.white,
                    size: 40,
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Guía de Acción',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Sigue estos pasos para gestionar la situación correctamente.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Lista de pasos
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final esFotoPaso = widget.pasos[index].contains('fotos');
                  return _PasoCard(
                    titulo: widget.pasos[index],
                    color: primaryColor,
                    completado: pasosCompletos[index],
                    onToggle: () => _togglePaso(index),
                    index: index + 1,
                    contenidoExtra: esFotoPaso
                        ? Column(
                            children: [
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _tomarFoto,
                                  icon: const Icon(Icons.camera_alt_outlined),
                                  label: const Text('Tomar Evidencia Fotográfica'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                              if (_imagenes.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 120,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _imagenes.length,
                                    itemBuilder: (context, i) {
                                      final img = _imagenes[i];
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 12),
                                        child: Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: Image.file(
                                                img,
                                                width: 120,
                                                height: 120,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            Positioned(
                                              right: 4,
                                              top: 4,
                                              child: InkWell(
                                                onTap: () => _eliminarFoto(i),
                                                child: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  decoration: const BoxDecoration(
                                                    color: Colors.white,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.close,
                                                    size: 16,
                                                    color: Colors.red,
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
                          )
                        : null,
                  );
                },
                childCount: widget.pasos.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
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
  final int index;

  const _PasoCard({
    required this.titulo,
    required this.color,
    required this.completado,
    required this.onToggle,
    required this.index,
    this.contenidoExtra,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: completado ? color.withOpacity(0.3) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: completado ? color : color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: completado
                            ? const Icon(Icons.check, size: 18, color: Colors.white)
                            : Text(
                                '$index',
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        titulo,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : Colors.black87,
                          decoration: completado ? TextDecoration.lineThrough : null,
                          decorationColor: color.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ],
                ),
                if (contenidoExtra != null) ...[
                  const SizedBox(height: 4),
                  contenidoExtra!,
                ],
              ],
            ),
          ),
        ),
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
                        color: Colors.black.withOpacity(0.3),
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
