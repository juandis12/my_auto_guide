// =============================================================================
// guia.dart — GUÍA DE SEGURIDAD VIAL Y ASISTENCIA (APPLE HIG & DYNAMIC MIDNIGHT)
// =============================================================================
//
// Módulo interactivo con experiencia nativa estilo iPhone (iOS & Android):
// - Cupertino Sliding Segmented Control para alternar entre Protocolos y Videoteca
// - Tarjetas Squircle Glassmorphism con Heavy Blur (Sigma 20) y física Spring
// - Checklist interactivo con animación Apple Check y barra de progreso dinámica
// - Galería de evidencias estilo Apple Photos con visor de zoom a pantalla completa
//
// =============================================================================

import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_apple_theme.dart';
import '../../shared/widgets/app_snack_bar.dart';
import 'data/models/guide_protocol_model.dart';
import 'data/models/guide_video_model.dart';
import 'data/repositories/guide_storage_repository.dart';
import 'presentation/widgets/ios_evidence_gallery.dart';
import 'presentation/widgets/ios_protocol_card.dart';
import 'presentation/widgets/ios_segmented_header.dart';
import 'presentation/widgets/ios_step_item.dart';
import 'presentation/widgets/ios_video_card.dart';

// =============================================================
//                   PANTALLA PRINCIPAL DE GUÍAS
// =============================================================
class GuiaScreen extends StatefulWidget {
  const GuiaScreen({super.key});

  @override
  State<GuiaScreen> createState() => _GuiaScreenState();
}

class _GuiaScreenState extends State<GuiaScreen> {
  final _repository = GuideStorageRepository();
  int _selectedSegment = 0; // 0: Protocolos, 1: Videos
  Map<String, int> _completedCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllProgress();
  }

  Future<void> _loadAllProgress() async {
    final counts = <String, int>{};
    for (final p in GuideProtocol.defaultProtocols) {
      final steps = await _repository.loadCompletedSteps(p.id, p.steps.length);
      counts[p.id] = steps.where((s) => s).length;
    }
    if (mounted) {
      setState(() {
        _completedCounts = counts;
        _isLoading = false;
      });
    }
  }

  void _openProtocolDetail(GuideProtocol protocol) async {
    await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => AccidenteScreen(
          tipo: protocol.id,
          color: protocol.accentColor,
          pasos: protocol.steps,
          protocol: protocol,
        ),
      ),
    );
    _loadAllProgress();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppAppleTheme.midnightBackground
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Seguridad Vial',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black87,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Segmented Header Deslizable estilo Apple
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: IosSegmentedHeader(
                selectedIndex: _selectedSegment,
                onSegmentChanged: (index) {
                  setState(() => _selectedSegment = index);
                },
                segments: const ['Protocolos', 'Videoteca & Tips'],
              ),
            ),

            const SizedBox(height: 8),

            // Contenido dinámico según la pestaña activa
            Expanded(
              child: _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: _selectedSegment == 0
                          ? _buildProtocolsList()
                          : _buildVideosList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProtocolsList() {
    return ListView.builder(
      key: const ValueKey('protocols_list'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      physics: const BouncingScrollPhysics(),
      itemCount: GuideProtocol.defaultProtocols.length,
      itemBuilder: (context, index) {
        final protocol = GuideProtocol.defaultProtocols[index];
        final completedCount = _completedCounts[protocol.id] ?? 0;
        return IosProtocolCard(
          protocol: protocol,
          completedStepsCount: completedCount,
          onTap: () => _openProtocolDetail(protocol),
        );
      },
    );
  }

  Widget _buildVideosList() {
    return ListView.builder(
      key: const ValueKey('videos_list'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      physics: const BouncingScrollPhysics(),
      itemCount: GuideVideo.defaultVideos.length,
      itemBuilder: (context, index) {
        final video = GuideVideo.defaultVideos[index];
        return IosVideoCard(video: video);
      },
    );
  }
}

// =============================================================
//       PANTALLA DE DETALLE DE PROTOCOLO / ACCIDENTES
// =============================================================
class AccidenteScreen extends StatefulWidget {
  final String tipo;
  final Color color;
  final List<String> pasos;
  final GuideProtocol? protocol;

  const AccidenteScreen({
    super.key,
    required this.tipo,
    required this.color,
    required this.pasos,
    this.protocol,
  });

  @override
  State<AccidenteScreen> createState() => _AccidenteScreenState();
}

class _AccidenteScreenState extends State<AccidenteScreen> {
  final _repository = GuideStorageRepository();
  final _picker = ImagePicker();

  late GuideProtocol _activeProtocol;
  List<bool> _pasosCompletos = [];
  List<File> _imagenes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _activeProtocol = widget.protocol ??
        GuideProtocol.defaultProtocols.firstWhere(
          (p) => p.id == widget.tipo,
          orElse: () => GuideProtocol(
            id: widget.tipo,
            title: widget.tipo.toUpperCase(),
            subtitle: 'Protocolo de seguridad',
            category: 'Guía',
            icon: Icons.shield_outlined,
            accentColor: widget.color,
            steps: widget.pasos,
            bannerDescription:
                'Sigue las recomendaciones paso a paso para gestionar la situación.',
          ),
        );
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final steps = await _repository.loadCompletedSteps(
      _activeProtocol.id,
      _activeProtocol.steps.length,
    );
    final photos = await _repository.loadEvidencePhotos(_activeProtocol.id);

    if (mounted) {
      setState(() {
        _pasosCompletos = steps;
        _imagenes = photos;
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePaso(int index) async {
    setState(() {
      _pasosCompletos[index] = !_pasosCompletos[index];
    });
    await _repository.saveCompletedSteps(_activeProtocol.id, _pasosCompletos);
  }

  Future<void> _tomarFoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (photo != null) {
        final saved = await _repository.saveEvidencePhoto(
          _activeProtocol.id,
          photo,
        );
        if (saved != null && mounted) {
          setState(() => _imagenes.add(saved));
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, 'Error al capturar evidencia: $e');
      }
    }
  }

  Future<void> _eliminarFoto(int index) async {
    await _repository.deleteEvidencePhoto(
      _activeProtocol.id,
      _imagenes,
      index,
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final completedCount = _pasosCompletos.where((s) => s).length;
    final totalSteps = _activeProtocol.steps.length;
    final progress = totalSteps > 0 ? (completedCount / totalSteps) : 0.0;

    return Scaffold(
      backgroundColor: isDark
          ? AppAppleTheme.midnightBackground
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _activeProtocol.title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black87,
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Banner Hero estilo Apple con degradado cinemático
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _activeProtocol.accentColor.withValues(alpha: 0.9),
                          _activeProtocol.accentColor.withValues(alpha: 0.65),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: _activeProtocol.accentColor
                              .withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _activeProtocol.icon,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'GUÍA DE ACCIÓN OFICIAL',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _activeProtocol.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _activeProtocol.bannerDescription,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Barra de progreso y contador
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 6,
                                  backgroundColor:
                                      Colors.black.withValues(alpha: 0.2),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              '$completedCount/$totalSteps Pasos',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Checklist de Pasos
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final stepText = _activeProtocol.steps[index];
                        final isPhotoStep = stepText.toLowerCase().contains('foto') ||
                            stepText.toLowerCase().contains('documenta');
                        final isLastStep = index == _activeProtocol.steps.length - 1;

                        Widget? extra;
                        if (isPhotoStep && _activeProtocol.allowsPhotoEvidence) {
                          extra = IosEvidenceGallery(
                            photos: _imagenes,
                            onTakePhoto: _tomarFoto,
                            onDeletePhoto: _eliminarFoto,
                            accentColor: _activeProtocol.accentColor,
                          );
                        }

                        return IosStepItem(
                          index: index + 1,
                          text: stepText,
                          isCompleted: _pasosCompletos.length > index
                              ? _pasosCompletos[index]
                              : false,
                          accentColor: _activeProtocol.accentColor,
                          onToggle: () => _togglePaso(index),
                          extraContent: extra,
                        );
                      },
                      childCount: _activeProtocol.steps.length,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
    );
  }
}
