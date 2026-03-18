// =============================================================================
// parametrizacion_mantenimientos.dart — CONFIGURACIÓN DE MANTENIMIENTOS
// =============================================================================
//
// Pantalla donde el usuario configura las fechas de los últimos mantenimientos
// realizados a su vehículo. Los intervalos de vencimiento son:
//
//   - Lubricación de cadena: cada 15 días.
//   - Filtro de aire: cada 90 días.
//   - Cambio de aceite: cada 25 días.
//   - SOAT: cada 365 días (1 año).
//   - Tecnomecánica: cada 365 días (1 año).
//
// Al guardar, calcula el porcentaje restante de vida útil de cada
// mantenimiento y detecta si alguno está vencido. Retorna los resultados
// a [InicioApp] mediante Navigator.pop() para actualizar los indicadores
// circulares y disparar las notificaciones de vencimiento.
//
// Base de datos:
//   Columnas actualizadas en tabla `vehiculos`:
//     last_cadena, last_filtro, last_aceite, last_soat, last_tecno
//
// =============================================================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/services/supabase_service.dart';
import '../../../core/logic/vehicle_health_logic.dart';
import '../../../core/services/ocr_service.dart';

class ParametrizacionMantenimientosScreen extends StatefulWidget {
  final String vehiculoId;
  final DateTime? lastCadena;
  final DateTime? lastFiltro;
  final DateTime? lastAceite;
  final DateTime? lastSoat;
  final DateTime? lastTecno;
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

  final double currentKms;
  final double? lastKmCadena;
  final double? lastKmFiltro;
  final double? lastKmAceite;

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
  }

  final _kmCadenaCtrl = TextEditingController();
  final _kmFiltroCtrl = TextEditingController();
  final _kmAceiteCtrl = TextEditingController();



  Future<void> _pickDate(
    ValueChanged<DateTime> onPicked, {
    DateTime? initial,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    ); // selector recomendado [28]
    if (picked != null) {
      onPicked(DateTime(picked.year, picked.month, picked.day));
    }
  }

  @override
  void dispose() {
    _ocrService.dispose();
    _kmCadenaCtrl.dispose();
    _kmFiltroCtrl.dispose();
    _kmAceiteCtrl.dispose();
    super.dispose();
  }

  Future<void> _escanearDocumento(void Function(DateTime) onFound) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (photo == null) return;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Analizando documento...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      final date = await _ocrService.extractExpirationDate(File(photo.path));
      
      if (date != null) {
        onFound(date);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fecha detectada: ${_fmt(date)}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se detectó fecha. Intenta con mejor luz.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
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

  String _fmt(DateTime? d) => d == null
      ? 'Sin seleccionar'
      : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _guardar() async {
    try {
      await SupabaseService().updateMaintenanceDates(widget.vehiculoId, {
        'last_cadena': _cadena == null ? null : _fmt(_cadena),
        'last_filtro': _filtro == null ? null : _fmt(_filtro),
        'last_aceite': _aceite == null ? null : _fmt(_aceite),
        'last_soat': _soat == null ? null : _fmt(_soat),
        'last_tecno': _tecno == null ? null : _fmt(_tecno),
        'kms_last_cadena': double.tryParse(_kmCadenaCtrl.text),
        'kms_last_filtro': double.tryParse(_kmFiltroCtrl.text),
        'kms_last_aceite': double.tryParse(_kmAceiteCtrl.text),
      });

      final kCad = double.tryParse(_kmCadenaCtrl.text) ?? 0.0;
      final kFil = double.tryParse(_kmFiltroCtrl.text) ?? 0.0;
      final kAce = double.tryParse(_kmAceiteCtrl.text) ?? 0.0;

      final result = {
        'lastCadena': _cadena,
        'lastFiltro': _filtro,
        'lastAceite': _aceite,
        'lastSoat': _soat,
        'lastTecno': _tecno,
        'lastKmCadena': kCad,
        'lastKmFiltro': kFil,
        'lastKmAceite': kAce,
        'pctCadena': VehicleHealthLogic.calculateHybridPercentage(
          lastDate: _cadena,
          lastKms: kCad,
          cycleDays: 15,
          cycleKms: 500,
          currentKms: widget.currentKms,
        ),
        'pctFiltro': VehicleHealthLogic.calculateHybridPercentage(
          lastDate: _filtro,
          lastKms: kFil,
          cycleDays: 90,
          cycleKms: 5000,
          currentKms: widget.currentKms,
        ),
        'pctAceite': VehicleHealthLogic.calculateHybridPercentage(
          lastDate: _aceite,
          lastKms: kAce,
          cycleDays: 25,
          cycleKms: 3000,
          currentKms: widget.currentKms,
        ),
        'pctSoat': VehicleHealthLogic.calculateHybridPercentage(
          lastDate: _soat,
          lastKms: 0,
          cycleDays: 365,
          cycleKms: 1,
          currentKms: 0,
        ),
        'pctTecno': VehicleHealthLogic.calculateHybridPercentage(
          lastDate: _tecno,
          lastKms: 0,
          cycleDays: 365,
          cycleKms: 1,
          currentKms: 0,
        ),
        'vencCadena': _vencidoHybrid(_cadena, kCad, 15, 500),
        'vencFiltro': _vencidoHybrid(_filtro, kFil, 90, 5000),
        'vencAceite': _vencidoHybrid(_aceite, kAce, 25, 3000),
        'vencSoat': _vencidoHybrid(_soat, 0, 365, 1),
        'vencTecno': _vencidoHybrid(_tecno, 0, 365, 1),
      }; // retorna para actualizar UI [23][24]

      if (!mounted) return;
      Navigator.pop(context, result);
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar: ${e.message}')),
      );
    }
  }

  Widget _buildMaintenanceCard({
    required BuildContext context,
    required String title,
    required DateTime? date,
    required IconData icon,
    required VoidCallback onTap,
    Widget? trailingInput,
    VoidCallback? onScan,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    // Icono
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, color: primaryColor, size: 28),
                    ),
                    const SizedBox(width: 16),
                    // Textos
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_month,
                                size: 14,
                                color: date == null ? Colors.redAccent : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                date == null ? 'Fecha requerida' : _fmt(date),
                                style: TextStyle(
                                  color: date == null
                                      ? Colors.redAccent
                                      : Colors.grey[600],
                                  fontSize: 13,
                                  fontWeight: date == null
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (onScan != null)
                      IconButton.filledTonal(
                        onPressed: onScan,
                        icon: const Icon(Icons.document_scanner_rounded, size: 20),
                        tooltip: 'Escanear Documento',
                        style: IconButton.styleFrom(
                          backgroundColor: primaryColor.withOpacity(0.1),
                          foregroundColor: primaryColor,
                        ),
                      ),
                    // Botón Editar
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.edit_calendar,
                        size: 20,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
                if (trailingInput != null) ...[
                  const Divider(height: 24, indent: 70),
                  Padding(
                    padding: const EdgeInsets.only(left: 70),
                    child: trailingInput,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKmInput(TextEditingController ctrl, String hint) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kilometraje en el mantenimiento:',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white38 : Colors.black38,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            suffixText: 'km',
            suffixStyle: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Mantenimientos', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                children: [
                   const Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: Text(
                      'Configura la fecha de los últimos mantenimientos que le hiciste a tu vehículo para recibir recordatorios exactos.',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  _buildMaintenanceCard(
                    context: context,
                    title: 'Lubricación de Cadena',
                    date: _cadena,
                    icon: Icons.build_circle_outlined,
                    onTap: () => _pickDate(
                      (d) => setState(() => _cadena = d),
                      initial: _cadena,
                    ),
                    trailingInput: _buildKmInput(_kmCadenaCtrl, 'Ej: 5000'),
                  ),
                  _buildMaintenanceCard(
                    context: context,
                    title: 'Filtro de Aire',
                    date: _filtro,
                    icon: Icons.filter_alt_outlined,
                    onTap: () => _pickDate(
                      (d) => setState(() => _filtro = d),
                      initial: _filtro,
                    ),
                    trailingInput: _buildKmInput(_kmFiltroCtrl, 'Ej: 15400'),
                  ),
                  _buildMaintenanceCard(
                    context: context,
                    title: 'Cambio de Aceite',
                    date: _aceite,
                    icon: Icons.water_drop_outlined,
                    onTap: () => _pickDate(
                      (d) => setState(() => _aceite = d),
                      initial: _aceite,
                    ),
                    trailingInput: _buildKmInput(_kmAceiteCtrl, 'Ej: 21000'),
                  ),
                  _buildMaintenanceCard(
                    context: context,
                    title: 'Seguro Obligatorio (SOAT)',
                    date: _soat,
                    icon: Icons.health_and_safety_outlined,
                    onTap: () => _pickDate(
                      (d) => setState(() => _soat = d),
                      initial: _soat,
                    ),
                    onScan: () => _escanearDocumento((d) => setState(() => _soat = d)),
                  ),
                  _buildMaintenanceCard(
                    context: context,
                    title: 'Revisión Técnico-Mecánica',
                    date: _tecno,
                    icon: Icons.car_crash_outlined,
                    onTap: () => _pickDate(
                      (d) => setState(() => _tecno = d),
                      initial: _tecno,
                    ),
                    onScan: () => _escanearDocumento((d) => setState(() => _tecno = d)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            // Panel Inferior Flotante
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -5),
                    blurRadius: 20,
                  )
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.save_rounded),
                  label: const Text(
                    'Guardar y Calcular',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _guardar,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
