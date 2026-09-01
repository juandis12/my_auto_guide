// =============================================================================
// parametrizacion_mantenimientos.dart — CONFIGURACIÓN DE MANTENIMIENTOS (APPLE HIG)
// =============================================================================
//
// Módulo de configuración y diagnóstico de mantenimientos con diseño estilo Apple:
// - Inset Grouped layout (Mantenimientos Mecánicos vs Trámites Legales)
// - Selector de fecha nativo iOS (CupertinoDatePicker Wheel Sheet)
// - Chips de autocompletado y ajuste de kilometraje (+1,000, +3,000, +5,000 km)
// - Anillos de salud en tiempo real (Apple Health Activity Rings)
// - Barra flotante de guardado translúcida (Frosted Glass Action Bar)
//
// =============================================================================

import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/logic/vehicle_health_logic.dart';
import '../../../core/services/ocr_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_apple_theme.dart';
import '../../../shared/widgets/app_snack_bar.dart';
import 'widgets/ios_health_gauge.dart';
import 'widgets/ios_maintenance_card.dart';

class ParametrizacionMantenimientosScreen extends StatefulWidget {
  final String vehiculoId;
  final DateTime? lastCadena;
  final DateTime? lastFiltro;
  final DateTime? lastAceite;
  final DateTime? lastSoat;
  final DateTime? lastTecno;
  final double currentKms;
  final double? lastKmCadena;
  final double? lastKmFiltro;
  final double? lastKmAceite;

  const ParametrizacionMantenimientosScreen({
    super.key,
    required this.vehiculoId,
    this.lastCadena,
    this.lastFiltro,
    this.lastAceite,
    this.lastSoat,
    this.lastTecno,
    this.lastKmCadena,
    this.lastKmFiltro,
    this.lastKmAceite,
    required this.currentKms,
  });

  @override
  State<ParametrizacionMantenimientosScreen> createState() =>
      _ParametrizacionMantenimientosScreenState();
}

class _ParametrizacionMantenimientosScreenState
    extends State<ParametrizacionMantenimientosScreen> {
  final _ocrService = OCRService();
  final _picker = ImagePicker();

  DateTime? _cadena;
  DateTime? _filtro;
  DateTime? _aceite;
  DateTime? _soat;
  DateTime? _tecno;

  final _kmCadenaCtrl = TextEditingController();
  final _kmFiltroCtrl = TextEditingController();
  final _kmAceiteCtrl = TextEditingController();

  bool _isSaving = false;
  double _btnScale = 1.0;

  @override
  void initState() {
    super.initState();
    _cadena = widget.lastCadena;
    _filtro = widget.lastFiltro;
    _aceite = widget.lastAceite;
    _soat = widget.lastSoat;
    _tecno = widget.lastTecno;

    _kmCadenaCtrl.text = widget.lastKmCadena?.toStringAsFixed(0) ?? '';
    _kmFiltroCtrl.text = widget.lastKmFiltro?.toStringAsFixed(0) ?? '';
    _kmAceiteCtrl.text = widget.lastKmAceite?.toStringAsFixed(0) ?? '';

    _kmCadenaCtrl.addListener(() => setState(() {}));
    _kmFiltroCtrl.addListener(() => setState(() {}));
    _kmAceiteCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ocrService.dispose();
    _kmCadenaCtrl.dispose();
    _kmFiltroCtrl.dispose();
    _kmAceiteCtrl.dispose();
    super.dispose();
  }

  String _fmt(DateTime? d) => d == null
      ? 'Sin seleccionar'
      : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // Cálculos reactivos de porcentaje de salud
  double get _pctCadena => VehicleHealthLogic.calculateHybridPercentage(
        lastDate: _cadena,
        lastKms: double.tryParse(_kmCadenaCtrl.text) ?? 0.0,
        cycleDays: 15,
        cycleKms: 500,
        currentKms: widget.currentKms,
      );

  double get _pctFiltro => VehicleHealthLogic.calculateHybridPercentage(
        lastDate: _filtro,
        lastKms: double.tryParse(_kmFiltroCtrl.text) ?? 0.0,
        cycleDays: 90,
        cycleKms: 5000,
        currentKms: widget.currentKms,
      );

  double get _pctAceite => VehicleHealthLogic.calculateHybridPercentage(
        lastDate: _aceite,
        lastKms: double.tryParse(_kmAceiteCtrl.text) ?? 0.0,
        cycleDays: 90,
        cycleKms: 3000,
        currentKms: widget.currentKms,
      );

  double get _pctSoat => VehicleHealthLogic.calculateHybridPercentage(
        lastDate: _soat,
        lastKms: 0,
        cycleDays: 365,
        cycleKms: 1,
        currentKms: 0,
      );

  double get _pctTecno => VehicleHealthLogic.calculateHybridPercentage(
        lastDate: _tecno,
        lastKms: 0,
        cycleDays: 365,
        cycleKms: 1,
        currentKms: 0,
      );

  double get _averageHealth {
    final list = [_pctCadena, _pctFiltro, _pctAceite, _pctSoat, _pctTecno];
    return list.reduce((a, b) => a + b) / list.length;
  }

  bool _vencidoHybrid(DateTime? last, double lastKm, int cycleDays, int cycleKms) {
    final pct = VehicleHealthLogic.calculateHybridPercentage(
      lastDate: last,
      lastKms: lastKm,
      cycleDays: cycleDays,
      cycleKms: cycleKms,
      currentKms: widget.currentKms,
    );
    return pct <= 0.0;
  }

  Future<void> _escanearDocumento(
      String nombreDoc, void Function(DateTime) onFound) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (photo == null) return;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(width: 14),
              Text('Analizando $nombreDoc con IA...'),
            ],
          ),
          backgroundColor: const Color(0xFF0F172A),
          duration: const Duration(seconds: 3),
        ),
      );

      final date = await _ocrService.extractExpirationDate(File(photo.path));

      if (date != null) {
        onFound(date);
        if (!mounted) return;
        AppSnackBar.show(
          context,
          'Fecha detectada con éxito: ${_fmt(date)}',
          backgroundColor: const Color(0xFF10B981),
        );
      } else {
        if (!mounted) return;
        AppSnackBar.show(
          context,
          'No se pudo extraer la fecha. Intenta con mejor iluminación.',
          backgroundColor: const Color(0xFFF59E0B),
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, 'Error al procesar documento: $e');
    }
  }

  Future<void> _guardar() async {
    setState(() => _isSaving = true);
    try {
      final kCad = double.tryParse(_kmCadenaCtrl.text);
      final kFil = double.tryParse(_kmFiltroCtrl.text);
      final kAce = double.tryParse(_kmAceiteCtrl.text);

      await SupabaseService().updateMaintenanceDates(widget.vehiculoId, {
        'last_cadena': _cadena == null ? null : _fmt(_cadena),
        'last_filtro': _filtro == null ? null : _fmt(_filtro),
        'last_aceite': _aceite == null ? null : _fmt(_aceite),
        'last_soat': _soat == null ? null : _fmt(_soat),
        'last_tecno': _tecno == null ? null : _fmt(_tecno),
        'kms_last_cadena': kCad,
        'kms_last_filtro': kFil,
        'kms_last_aceite': kAce,
      });

      final kCadVal = kCad ?? 0.0;
      final kFilVal = kFil ?? 0.0;
      final kAceVal = kAce ?? 0.0;

      final result = {
        'lastCadena': _cadena,
        'lastFiltro': _filtro,
        'lastAceite': _aceite,
        'lastSoat': _soat,
        'lastTecno': _tecno,
        'lastKmCadena': kCadVal,
        'lastKmFiltro': kFilVal,
        'lastKmAceite': kAceVal,
        'pctCadena': _pctCadena,
        'pctFiltro': _pctFiltro,
        'pctAceite': _pctAceite,
        'pctSoat': _pctSoat,
        'pctTecno': _pctTecno,
        'vencCadena': _vencidoHybrid(_cadena, kCadVal, 15, 500),
        'vencFiltro': _vencidoHybrid(_filtro, kFilVal, 90, 5000),
        'vencAceite': _vencidoHybrid(_aceite, kAceVal, 25, 3000),
        'vencSoat': _vencidoHybrid(_soat, 0, 365, 1),
        'vencTecno': _vencidoHybrid(_tecno, 0, 365, 1),
      };

      if (!mounted) return;
      Navigator.pop(context, result);
    } on PostgrestException catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, 'Error en el servidor: ${e.message}');
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, 'Error al guardar: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
          'Mantenimientos',
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
      body: Stack(
        children: [
          ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              top: 10,
              bottom: 110, // Espacio para la barra flotante inferior
            ),
            children: [
              // Panel Resumen de Salud del Vehículo (Apple Health Gauge Hero)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF2563EB).withValues(alpha: 0.85),
                      const Color(0xFF0284C7).withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ESTADO GENERAL',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Salud Preventiva',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Odómetro registrado: ${widget.currentKms.toStringAsFixed(0)} km',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IosHealthGauge(
                      percentage: _averageHealth,
                      size: 64,
                      strokeWidth: 6.5,
                      showLabel: false,
                    ),
                  ],
                ),
              ),

              // SECCIÓN 1: Mantenimientos Mecánicos Periódicos
              _buildSectionHeader('MANTENIMIENTOS MECÁNICOS', isDark),
              const SizedBox(height: 10),

              IosMaintenanceCard(
                title: 'Lubricación de Cadena',
                subtitle: 'Ciclo recomendado: cada 15 días o 500 km',
                icon: Icons.build_circle_outlined,
                date: _cadena,
                onDateChanged: (d) => setState(() => _cadena = d),
                kmController: _kmCadenaCtrl,
                currentKms: widget.currentKms,
                healthPercentage: _pctCadena,
              ),

              IosMaintenanceCard(
                title: 'Filtro de Aire',
                subtitle: 'Ciclo recomendado: cada 90 días o 5,000 km',
                icon: Icons.filter_alt_outlined,
                date: _filtro,
                onDateChanged: (d) => setState(() => _filtro = d),
                kmController: _kmFiltroCtrl,
                currentKms: widget.currentKms,
                healthPercentage: _pctFiltro,
              ),

              IosMaintenanceCard(
                title: 'Cambio de Aceite de Motor',
                subtitle: 'Ciclo recomendado: cada 90 días o 3,000 km',
                icon: Icons.water_drop_outlined,
                date: _aceite,
                onDateChanged: (d) => setState(() => _aceite = d),
                kmController: _kmAceiteCtrl,
                currentKms: widget.currentKms,
                healthPercentage: _pctAceite,
              ),

              const SizedBox(height: 16),

              // SECCIÓN 2: Documentación Legal y Tránsito
              _buildSectionHeader('DOCUMENTACIÓN Y TRÁMITES LEGALES', isDark),
              const SizedBox(height: 10),

              IosMaintenanceCard(
                title: 'Seguro Obligatorio (SOAT)',
                subtitle: 'Vigencia anual obligatoria por ley',
                icon: Icons.health_and_safety_outlined,
                date: _soat,
                onDateChanged: (d) => setState(() => _soat = d),
                currentKms: widget.currentKms,
                healthPercentage: _pctSoat,
                isLegalDoc: true,
                onScan: () => _escanearDocumento(
                    'SOAT', (d) => setState(() => _soat = d)),
              ),

              IosMaintenanceCard(
                title: 'Revisión Técnico-Mecánica',
                subtitle: 'Certificación anual de estado técnico',
                icon: Icons.car_crash_outlined,
                date: _tecno,
                onDateChanged: (d) => setState(() => _tecno = d),
                currentKms: widget.currentKms,
                healthPercentage: _pctTecno,
                isLegalDoc: true,
                onScan: () => _escanearDocumento(
                    'Revisión Técnico-Mecánica', (d) => setState(() => _tecno = d)),
              ),

              const SizedBox(height: 20),
            ],
          ),

          // Barra Inferior Flotante Translúcida con botón Spring
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: AppAppleTheme.glassBlurSigma,
                  sigmaY: AppAppleTheme.glassBlurSigma,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF080C14).withValues(alpha: 0.85)
                        : Colors.white.withValues(alpha: 0.85),
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: AnimatedScale(
                      scale: _btnScale,
                      duration: const Duration(milliseconds: 120),
                      curve: Curves.easeOutCubic,
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _guardar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isSaving
                              ? const CupertinoActivityIndicator(
                                  color: Colors.white)
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle_outline_rounded,
                                        size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Guardar y Calcular Métricas',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white54 : Colors.black45,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
