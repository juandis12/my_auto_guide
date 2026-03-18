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
import '../../../core/services/supabase_service.dart';

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
  });

  @override
  State<ParametrizacionMantenimientosScreen> createState() =>
      _ParametrizacionMantenimientosScreenState();
}

class _ParametrizacionMantenimientosScreenState
    extends State<ParametrizacionMantenimientosScreen> {

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
  }

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

  double _pctRestante(DateTime? last, int cicloDias) {
    if (last == null) return 0.0;
    final dias =
        DateTime.now().difference(last).inDays; // días entre fechas [23]
    final restante = 1.0 - (dias / cicloDias);
    return restante.clamp(0.0, 1.0);
  }

  bool _vencido(DateTime? last, int cicloDias) {
    if (last == null) return false;
    final dias = DateTime.now().difference(last).inDays;
    return dias > cicloDias;
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
      });

      final result = {
        'lastCadena': _cadena,
        'lastFiltro': _filtro,
        'lastAceite': _aceite,
        'lastSoat': _soat,
        'lastTecno': _tecno,
        'pctCadena': _pctRestante(_cadena, 15),
        'pctFiltro': _pctRestante(_filtro, 90),
        'pctAceite': _pctRestante(_aceite, 25),
        'pctSoat': _pctRestante(_soat, 365),
        'pctTecno': _pctRestante(_tecno, 365),
        'vencCadena': _vencido(_cadena, 15),
        'vencFiltro': _vencido(_filtro, 90),
        'vencAceite': _vencido(_aceite, 25),
        'vencSoat': _vencido(_soat, 365),
        'vencTecno': _vencido(_tecno, 365),
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
            child: Row(
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
          ),
        ),
      ),
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
