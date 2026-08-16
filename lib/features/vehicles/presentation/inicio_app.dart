// =============================================================================
// inicio_app.dart — PANTALLA PRINCIPAL (DASHBOARD)
// =============================================================================
//
// Pantalla central de la aplicación. Muestra toda la información del vehículo
// seleccionado y provee acceso a todas las funcionalidades.
//
// SECCIONES DE LA INTERFAZ:
//   1. HEADER: Imagen del vehículo, marca, modelo, apodo y kilometraje.
//   2. INDICADORES CIRCULARES: Porcentaje de vida útil restante para cada
//      mantenimiento (cadena, filtro, aceite, SOAT, tecnomecánica).
//      - Verde: >50% | Amarillo: 25-50% | Rojo: <25% | Rojo parpadeante: vencido.
//   3. DOCUMENTOS: Grid de tarjetas (SOAT, Tecno, Seguro, T. Propiedad) donde
//      el usuario sube archivos/imágenes a Supabase Storage y los visualiza.
//   4. HERRAMIENTAS: Botones con gradiente para acceder a:
//      - Parametrización de mantenimientos.
//      - Consulta RUNT (WebView).
//      - Guías de seguridad vial.
//      - Navegación GPS (Rutas con OpenStreetMap).
//
// FUNCIONALIDADES CLAVE:
//   - Carga datos del vehículo desde la tabla `vehiculos` de Supabase.
//   - Calcula porcentajes de mantenimiento basados en fechas (last_cadena, etc.).
//   - Programa notificaciones locales cuando un mantenimiento está por vencer.
//   - Gestión de documentos: subir, ver, eliminar archivos en Supabase Storage.
//   - Visor de PDF integrado (Syncfusion) y visor de imágenes (PhotoView).
//   - Logout y cambio de vehículo.
//   - [NUEVO] Gamificación: Niveles de usuario y medallas de calidad.
//
// =============================================================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:photo_view/photo_view.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:async';

import '../../../core/services/notification_service.dart';
import '../../../core/services/vehicle_storage_service.dart';
import '../../../core/logic/app_widget_logic.dart';
import '../../../core/logic/vehicle_health_logic.dart';
import '../../../core/logic/vehicle_ai_logic.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/theme/brand_theme.dart';
import '../../../shared/widgets/runt_webview.dart';
import '../../navigation/rutas_screen.dart';
import '../../guides/guia.dart';
import '../../auth/login_screen.dart';
import 'parametrizacion_mantenimientos.dart';
import '../../expenses/presentation/gastos_screen.dart';
import '../../navigation/presentation/historial_rutas_screen.dart';
import '../../marketplace/presentation/marketplace_talleres_screen.dart';
import '../../../core/services/vehicle_pdf_report_service.dart';
import '../../../core/services/calendar_sync_service.dart';
import '../../expenses/presentation/bitacora_tanqueo_screen.dart';
import '../../../shared/widgets/simit_webview.dart';
import '../../../shared/widgets/liquid_glass_fab.dart';
import '../../../shared/widgets/app_snack_bar.dart';
import '../../../core/utils/formatters.dart';
import 'captura_360_screen.dart';
import '../../ai_bot/presentation/ai_chat_screen.dart';
import '../../../core/logic/performance_guard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'Agregar_vehiculo.dart';
import 'Agregar_carro.dart';
import '../../../core/services/supabase_service.dart';

// Modelos Refactorizados
import '../domain/models/vehicle_analytics.dart';
import '../domain/models/weekly_stats.dart';
import '../domain/models/maintenance_prediction.dart';

// Widgets Refactorizados
import 'widgets/achievements_card.dart';
import 'widgets/weekly_insight_card.dart';
import 'widgets/dashboard_widgets.dart';

enum DocType { soat, tecno, seguro, propiedad }

class InicioApp extends StatefulWidget {
  final String vehiculoId;
  const InicioApp({super.key, required this.vehiculoId});
  @override
  State<InicioApp> createState() => _InicioAppState();
}

class _InicioAppState extends State<InicioApp> {
  final supabase = Supabase.instance.client;
  final _storage = VehicleStorageService();

  static const Map<String, String> brandLogos = {
    'YAMAHA': 'assets/logos/yamaha_logo.png',
    'SUZUKI': 'assets/logos/suzuki_logo.png',
    'BMW': 'assets/logos/bmw_logo.png',
    'KAWASAKI': 'assets/logos/kawa_logo.png',
    'HONDA': 'assets/logos/honda_logo.png',
    'DUCATI': 'assets/logos/ducati_logo.png',
    'KTM': 'assets/logos/ktm_logo.png',
    'BAJAJ': 'assets/logos/bajaj_logo.png',
  };

  double _pctCadena = 0.0;
  double _pctFiltro = 0.0;
  double _pctAceite = 0.0;
  double _pctSoat = 0.0;
  double _pctTecno = 0.0;
  DateTime? _lastCadena, _lastFiltro, _lastAceite, _lastSoat, _lastTecno;

  String? _soatPath, _tecnoPath, _seguroPath, _propPath;
  String? _soatSigned, _tecnoSigned, _seguroSigned, _propSigned;

  // Métricas Semanales (Refactorizadas)
  bool _loadingWeekly = false;
  List<MaintenancePrediction> _predictionsList = [];
  WeeklyStats _weeklyStatsModel = WeeklyStats.empty();

  Map<String, dynamic>? _cachedVehicleData;
  final Map<String, dynamic> _urlCache = {};
  bool _notificacionesProcesadas = false;
  bool _checkedKm24h = false;

  Color _getSimitColor() {
    final status = _cachedVehicleData?['simit_status'] ?? 'unchecked';
    if (status == 'clean') {
      return Colors.green;
    } else if (status == 'has_fines') {
      return Colors.redAccent;
    }
    return Colors.blueAccent;
  }

  Future<void> _abrirSimit() async {
    final placa = _cachedVehicleData?['placa'] ?? '';
    final cedula = _cachedVehicleData?['cedula'] ?? '';
    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SimitWebViewScreen(
          placa: placa.isNotEmpty ? placa : 'ABC123',
          cedula: cedula.isNotEmpty ? cedula : '12345678',
          vehiculoId: widget.vehiculoId,
        ),
      ),
    );
    if (res == true) {
      setState(() {
        _cachedVehicleData = null; // forzar recarga
      });
    }
  }

  Future<void> _verificarKilometraje24h(Map<String, dynamic> vehicleData) async {
    final vehicleId = widget.vehiculoId;
    final prefs = await SharedPreferences.getInstance();
    final lastCheckStr = prefs.getString('last_km_check_$vehicleId');
    final now = DateTime.now();

    bool shouldShowDialog = false;
    if (lastCheckStr == null) {
      await prefs.setString('last_km_check_$vehicleId', now.toIso8601String());
    } else {
      final lastCheck = DateTime.parse(lastCheckStr);
      final difference = now.difference(lastCheck).inHours;
      if (difference >= 24) {
        shouldShowDialog = true;
      }
    }

    if (shouldShowDialog && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;

      final currentKms = _asDouble(vehicleData['kms']).toInt();
      final TextEditingController kmController = TextEditingController(text: currentKms.toString());

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.speed, color: Colors.blueAccent),
                SizedBox(width: 10),
                Text('Actualizar Kilometraje'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Por favor, ingresa el kilometraje actual de tu vehículo para mantener los mantenimientos al día:',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: kmController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Kilómetros actuales',
                    suffixText: 'KM',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  final nextAsk = DateTime.now().subtract(const Duration(hours: 20));
                  await prefs.setString('last_km_check_$vehicleId', nextAsk.toIso8601String());
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Más tarde'),
              ),
              FilledButton(
                onPressed: () async {
                  final newKms = int.tryParse(kmController.text) ?? currentKms;
                  if (newKms >= currentKms) {
                    await SupabaseService().updateVehicleKms(vehicleId, newKms);
                    await prefs.setString('last_km_check_$vehicleId', DateTime.now().toIso8601String());
                    setState(() {
                      _cachedVehicleData = null;
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                  } else {
                    AppSnackBar.show(
                      context,
                      'El kilometraje no puede ser menor al actual.',
                      backgroundColor: Colors.orange,
                    );
                  }
                },
                child: const Text('Actualizar'),
              ),
            ],
          );
        },
      );
    }
  }

  int get _simitFinesCount {
    final status = _cachedVehicleData?['simit_status'] ?? 'unchecked';
    if (status != 'has_fines') return 0;
    final fines = _cachedVehicleData?['simit_fines_data'] as List<dynamic>?;
    if (fines == null || fines.isEmpty) return 0;
    final fine = fines.first;
    return (fine['cantidad'] as num?)?.toInt() ?? 1;
  }

  Widget _buildSimitAlertCard() {
    final status = _cachedVehicleData?['simit_status'] ?? 'unchecked';
    if (status != 'has_fines') return const SizedBox.shrink();

    final List<dynamic> fines = _cachedVehicleData?['simit_fines_data'] ?? [];
    if (fines.isEmpty) return const SizedBox.shrink();

    final String dismissKey = 'simit_dismissed_${widget.vehiculoId}';

    return FutureBuilder<bool>(
      future: SharedPreferences.getInstance().then((prefs) {
        final int? dismissedUntil = prefs.getInt(dismissKey);
        if (dismissedUntil == null) return false;
        return DateTime.now().millisecondsSinceEpoch < dismissedUntil;
      }),
      builder: (context, snapshot) {
        if (snapshot.data == true) return const SizedBox.shrink();

        final fine = fines.first;
        final double amount = _asDouble(fine['valor_total']);
        final int count = fine['cantidad'] ?? 1;
        final String category = fine['categoria'] ?? 'Tránsito';
        final List<dynamic> codes = fine['codigos'] ?? [];

        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 26),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Comparendos Pendientes ($count)',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Valor Total: \$${amount.toStringAsFixed(0)} COP  •  $category',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          if (codes.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Infracciones: ${codes.join(', ')}',
                              style: const TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Botón X: descarta la alerta por 24 horas
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 20),
                      tooltip: 'Ocultar durante 24 horas',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        final dismissUntil = DateTime.now()
                            .add(const Duration(hours: 24))
                            .millisecondsSinceEpoch;
                        await prefs.setInt(dismissKey, dismissUntil);
                        if (mounted) setState(() {});
                      },
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 36),
                  child: TextButton.icon(
                    onPressed: () => _abrirSimit(),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 30)),
                    icon: const Icon(Icons.open_in_new, size: 13, color: Colors.redAccent),
                    label: const Text('Consultar en SIMIT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _docFolder(DocType type) => {
        DocType.soat: 'soat',
        DocType.tecno: 'tecno',
        DocType.seguro: 'seguro',
        DocType.propiedad: 'propiedad',
      }[type]!;

  String _folderPath(DocType type) =>
      '${widget.vehiculoId}/${_docFolder(type)}';

  Future<String> _signedUrlCachedFor(String path) async {
    final signed = await _storage.getSignedUrl(path, _urlCache);
    return signed ?? '';
  }

  Color _colorFor(double pct) {
    if (pct < 0.2) {
      return const Color(0xFFFF5252).withOpacity(0.8);
    }
    if (pct < 0.5) {
      return const Color(0xFFFFAB40).withOpacity(0.8);
    }
    return const Color(0xFF69F0AE).withOpacity(0.8);
  }



  double _asDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  Future<Map<String, dynamic>> _cargar() async {
    if (!mounted) return {};
    if (_cachedVehicleData != null) {
      return _cachedVehicleData!;
    }
    try {
      final row = await supabase
          .from('vehiculos')
          .select(
            'marca, modelo, apodo, kms, image_path, last_cadena, last_filtro, last_aceite, last_soat, last_tecno, soat_path, tecno_path, seguro_path, propiedad_path, kms_last_cadena, kms_last_filtro, kms_last_aceite, placa, cedula, simit_status, simit_fines_data, simit_last_check, has_360_view, images_360_urls',
          )
          .eq('id', widget.vehiculoId)
          .single();
      _cachedVehicleData = row;
      return row;
    } catch (e) {
      debugPrint('Error cargando datos del vehículo: $e');
      return {};
    }
  }

  Future<void> _syncHealthWidget() async {
    await AppWidgetLogic.updateHealthWidget(
      pctCadena: _pctCadena,
      pctFiltro: _pctFiltro,
      pctAceite: _pctAceite,
      pctSoat: _pctSoat,
      pctTecno: _pctTecno,
    );
  }

  Future<void> _recalculateAI(Map<String, dynamic> v) async {
    final int kms = _asDouble(v['kms']).toInt();
    final marca = (v['marca'] as String? ?? '').toUpperCase();
    final bool isCarLocal = marca.contains('CARRO') || (v['apodo'] as String? ?? '').toUpperCase().contains('CARRO');

    final aiMap = VehicleAILogic.analyzeJourneyPatterns(
      routeHistory: _weeklyStatsModel.routeHistory,
      modelName: v['modelo'] ?? '',
      isCar: isCarLocal,
    );
    final analytics = VehicleAnalytics.fromMap(aiMap);

    final aiIssues = VehicleAILogic.predictUpcomingIssues(
      totalKms: kms,
      intensity: analytics.intensity,
    );

    if (mounted) {
      setState(() {
        _predictionsList = MaintenancePrediction.fromList(aiIssues);
      });
    }
  }

  Future<void> _cerrarSesion() async {
    await supabase.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const CarRentalLoginScreen()),
      (route) => false,
    );
  }

  Future<void> _confirmarYEliminar(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar vehículo'),
        content: const Text('¿Seguro que deseas eliminar este vehículo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await supabase.from('vehiculos').delete().eq('id', id);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const CarRentalLoginScreen()),
      (route) => false,
    );
  }

  Future<void> _compartirVehiculo(Map<String, dynamic> v, double healthIndex) async {
    final String brand = (v['marca'] as String? ?? '').toUpperCase();
    final String model = v['modelo'] as String? ?? '';
    final String nickname = v['apodo'] as String? ?? '';
    final dynamic kms = v['kms'] ?? 0;
    
    final text = '🚗 ¡Te comparto el estado de mi vehículo en My Auto Guide! 🏍️\n\n'
        '• Apodo: $nickname\n'
        '• Marca y Modelo: $brand $model\n'
        '• Kilometraje: $kms KM\n'
        '• Índice de Salud (ISH): ${healthIndex.toStringAsFixed(0)}%\n\n'
        '¡Mantén tu vehículo al día y seguro con My Auto Guide!';
         
    await Share.share(text);
  }
        
  Future<void> _exportarPdfHojaVida() async {
    final vData = _cachedVehicleData;
    final String placa = vData?['placa'] ?? 'MOTO-360';
    final String marca = vData?['marca'] ?? 'Moto';
    final String modelo = vData?['modelo'] ?? '2024';
    final String apodo = vData?['apodo'] ?? '';
    final double kms = ((vData?['kms'] ?? 0) as num).toDouble();
    final String? lastSoat = vData?['last_soat'];
    final String? lastTecno = vData?['last_tecno'];
    final String? lastAceite = vData?['last_aceite'];
    final double kmsLastAceite = ((vData?['kms_last_aceite'] ?? 0) as num).toDouble();
    final String? imagePath = vData?['image_path'];

    AppSnackBar.show(
      context,
      '📄 Generando Hoja de Vida PDF...',
      duration: const Duration(seconds: 2),
    );

    final String simitStatus = vData?['simit_status'] ?? 'unchecked';
    final List finesData = vData?['simit_fines_data'] ?? [];
    double simitTotalAmount = 0.0;
    for (final f in finesData) {
      if (f is Map && f['total'] != null) {
        simitTotalAmount += ((f['total'] ?? 0) as num).toDouble();
      }
    }

    try {
      final pdfBytes = await VehiclePdfReportService.generatePdfReport(
        placa: placa,
        marca: marca,
        modelo: modelo,
        apodo: apodo,
        kms: kms,
        healthIndex: 95.0,
        simitStatus: simitStatus,
        simitFinesCount: _simitFinesCount,
        simitTotalAmount: simitTotalAmount,
        lastSoat: lastSoat,
        lastTecno: lastTecno,
        lastAceite: lastAceite,
        kmsLastAceite: kmsLastAceite,
        vehicleImageUrl: imagePath,
      );

      await VehiclePdfReportService.sharePdfReport(
        filename: 'Hoja_de_Vida_$placa.pdf',
        pdfBytes: pdfBytes,
      );
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, 'Error al generar PDF: $e');
      }
    }
  }

  void _abrirBitacoraTanqueo() {
    final vData = _cachedVehicleData;
    final String marca = vData?['marca'] ?? 'Vehículo';
    final String modelo = vData?['modelo'] ?? '';
    final double kms = ((vData?['kms'] ?? 0) as num).toDouble();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BitacoraTanqueoScreen(
          vehiculoId: widget.vehiculoId,
          marcaModelo: '$marca $modelo',
          currentKms: kms,
        ),
      ),
    );
  }

  void _agendarCalendarioDoc(DocType type, String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      AppSnackBar.show(context,
          'Registra primero la fecha de vencimiento de este documento.');
      return;
    }

    final date = DateTime.tryParse(dateStr);
    if (date == null) return;

    final String placaStr = _cachedVehicleData?['placa'] ?? '';
    final name = {
      DocType.soat: 'SOAT',
      DocType.tecno: 'Tecnomecánica',
      DocType.seguro: 'Seguro Todo Riesgo',
      DocType.propiedad: 'Tarjeta de Propiedad',
    }[type]!;

    CalendarSyncService.addEventToCalendar(
      title: '⚠️ Vencimiento de $name ($placaStr)',
      description: 'Recordatorio automático de My Auto Guide para renovar tu $name.',
      eventDate: date,
      context: context,
    );
  }

  Future<void> _abrirGarajeSelector() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Mi Garaje',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: SupabaseService().getVehicles(),
                builder: (ctx, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Error: ${snap.error}'));
                  }
                  final list = snap.data ?? [];
                  if (list.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No tienes vehículos registrados.'),
                      ),
                    );
                  }
                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: list.length,
                      itemBuilder: (ctx, index) {
                        final item = list[index];
                        final id = item['id'] as String;
                        final String brand = (item['marca'] as String? ?? '').toUpperCase();
                        final String model = item['modelo'] as String? ?? '';
                        final String nickname = item['apodo'] as String? ?? '';
                        final isCurrent = id == widget.vehiculoId;

                        return Card(
                          elevation: 0,
                          color: isCurrent
                              ? Theme.of(context).primaryColor.withOpacity(0.1)
                              : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isCurrent
                                  ? Theme.of(context).primaryColor
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.directions_car_filled_outlined),
                            title: Text(
                              nickname.isNotEmpty ? nickname : '$brand $model',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('$brand $model • ${item['kms'] ?? 0} KM'),
                            trailing: isCurrent
                                ? const Icon(Icons.check_circle_rounded, color: Colors.green)
                                : IconButton(
                                    icon: const Icon(Icons.swap_horiz_rounded),
                                    onPressed: () {
                                      Navigator.pop(ctx); // Close sheet
                                      // Switch vehicle!
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => InicioApp(vehiculoId: id),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AgregarVehiculoScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.motorcycle_rounded),
                      label: const Text('Agregar Moto'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AgregarCarroScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.directions_car_rounded),
                      label: const Text('Agregar Carro'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _abrirGuias() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GuiaScreen()),
    );
  }

  void _abrirRutas(int kmsActuales) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RutasScreen(
          vehiculoId: widget.vehiculoId,
          kmsActuales: kmsActuales,
        ),
      ),
    ).then((recargar) {
      if (recargar == true) {
        setState(() {
          _cachedVehicleData = null;
        });
        // Refrescar resumen semanal tras volver de navegación (Bug #3)
        unawaited(_cargarWeeklyStats());
      }
    });
  }

  void _abrirHistorialRutas() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HistorialRutasScreen(vehiculoId: widget.vehiculoId),
      ),
    );
  }

  Widget _buildLegalAlerts() {
    final alerts = <Widget>[];
    final now = DateTime.now();

    void checkDoc(String name, DateTime? lastDate) {
      if (lastDate == null) return;
      final expiration = lastDate.add(const Duration(days: 365));
      final daysLeft = expiration.difference(now).inDays;

      if (daysLeft <= 30) {
        final isCritical = daysLeft <= 7;
        alerts.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isCritical ? Colors.redAccent : Colors.orangeAccent).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: (isCritical ? Colors.redAccent : Colors.orangeAccent).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(isCritical ? Icons.warning_amber_rounded : Icons.info_outline,
                      color: isCritical ? Colors.redAccent : Colors.orangeAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(daysLeft < 0 ? '¡$name Vencido!' : 'Vencimiento de $name',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isCritical ? Colors.redAccent : Colors.orangeAccent)),
                        Text(
                          daysLeft < 0
                              ? 'Tu $name venció hace ${daysLeft.abs()} días.'
                              : 'Te quedan $daysLeft días para renovar tu $name.',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _abrirParametrizacion(),
                    child: const Text('Arreglar', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    checkDoc('SOAT', _lastSoat);
    checkDoc('Tecnomecánica', _lastTecno);

    if (alerts.isEmpty) return const SizedBox.shrink();
    return Column(children: alerts);
  }



  Future<void> _abrirParametrizacion() async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ParametrizacionMantenimientosScreen(
          vehiculoId: widget.vehiculoId,
          lastCadena: _lastCadena,
          lastFiltro: _lastFiltro,
          lastAceite: _lastAceite,
          lastSoat: _lastSoat,
          lastTecno: _lastTecno,
          lastKmCadena: _asDouble(_cachedVehicleData?['kms_last_cadena']),
          lastKmFiltro: _asDouble(_cachedVehicleData?['kms_last_filtro']),
          lastKmAceite: _asDouble(_cachedVehicleData?['kms_last_aceite']),
          currentKms: _asDouble(_cachedVehicleData?['kms']),
        ),
      ),
    );
    if (res is Map) {
      setState(() {
        _lastCadena = res['lastCadena'] as DateTime?;
        _lastFiltro = res['lastFiltro'] as DateTime?;
        _lastAceite = res['lastAceite'] as DateTime?;
        _lastSoat = res['lastSoat'] as DateTime?;
        _lastTecno = res['lastTecno'] as DateTime?;
        _pctCadena = (res['pctCadena'] as double?) ?? 0.0;
        _pctFiltro = (res['pctFiltro'] as double?) ?? 0.0;
        _pctAceite = (res['pctAceite'] as double?) ?? 0.0;
        _pctSoat = (res['pctSoat'] as double?) ?? 0.0;
        _pctTecno = (res['pctTecno'] as double?) ?? 0.0;
        
        // Actualizar caché para que la próxima apertura tenga los KMs correctos
        if (_cachedVehicleData != null) {
          _cachedVehicleData!['kms_last_cadena'] = res['lastKmCadena'];
          _cachedVehicleData!['kms_last_filtro'] = res['lastKmFiltro'];
          _cachedVehicleData!['kms_last_aceite'] = res['lastKmAceite'];
        }

        _notificacionesProcesadas = false;
        _cachedVehicleData = null; // Forzar recarga total para asegurar consistencia
      });
      unawaited(_syncHealthWidget());
      final bool vencido = (res['vencCadena'] == true) ||
          (res['vencFiltro'] == true) ||
          (res['vencAceite'] == true) ||
          (res['vencSoat'] == true) ||
          (res['vencTecno'] == true);
      if (vencido) {
        if (!mounted) return;
        AppSnackBar.show(
          context,
          'Hay mantenimientos vencidos, realizar cuanto antes.',
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 4),
        );
      }
    }
  }

  Future<List<(String name, String url)>> _listDocsSigned(DocType type) async {
    try {
      final folder = _folderPath(type);
      final objs = await _storage.listFolder(folder);
      final futures = objs.map((o) async {
        final path = '$folder/${o.name}';
        final signed = await _signedUrlCachedFor(path);
        return (o.name, signed);
      });
      return await Future.wait(futures);
    } catch (e) {
      return [];
    }
  }

  Future<String?> _uploadDoc(DocType type) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp', 'heic', 'gif'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return null;

      final f = result.files.single;
      final bytes = f.bytes ?? await File(f.path!).readAsBytes();
      final ext = (f.extension ?? 'bin').toLowerCase();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final folder = _folderPath(type);
      final path = '$folder/$ts.$ext';

      await _storage.uploadBinary(path, bytes);

      final col = {
        DocType.soat: 'soat_path',
        DocType.tecno: 'tecno_path',
        DocType.seguro: 'seguro_path',
        DocType.propiedad: 'propiedad_path',
      }[type]!;
      await supabase
          .from('vehiculos')
          .update({col: path}).eq('id', widget.vehiculoId);

      _cachedVehicleData = null;
      return path;
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, 'No se pudo subir: $e');
      }
      return null;
    }
  }

  Future<void> _deleteStorageFile(String path) async {
    await _storage.deleteDocument(path);
  }

  Future<void> _openUrl(String url) async {
    final ok =
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      AppSnackBar.show(context, 'No se pudo abrir el archivo');
    }
  }

  Future<void> _openDocManager(DocType type, String titulo) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setM) {
            Future<void> refreshModal() async {
              setM(() {});
              if (mounted) setState(() {}); // Llama al setState del Dashboard para limpiar variables
            }
            final folder = _folderPath(type);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Documentos: $titulo',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const Spacer(),
                          FilledButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar archivo'),
                            onPressed: () async {
                              final newPath = await _uploadDoc(type);
                              if (newPath != null && mounted) {
                                final signed =
                                    await _signedUrlCachedFor(newPath);
                                setState(() {
                                  switch (type) {
                                    case DocType.soat:
                                      _soatPath = newPath;
                                      _soatSigned = signed;
                                      break;
                                    case DocType.tecno:
                                      _tecnoPath = newPath;
                                      _tecnoSigned = signed;
                                      break;
                                    case DocType.seguro:
                                      _seguroPath = newPath;
                                      _seguroSigned = signed;
                                      break;
                                    case DocType.propiedad:
                                      _propPath = newPath;
                                      _propSigned = signed;
                                      break;
                                  }
                                });
                                await refreshModal();
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<List<(String name, String url)>>(
                        future: _listDocsSigned(type),
                        builder: (ctx, snap) {
                          if (snap.connectionState != ConnectionState.done) {
                            return const Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final files = snap.data ?? const [];
                          if (files.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(child: Text('Aún no hay archivos')),
                            );
                          }
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 1,
                            ),
                            itemCount: files.length,
                            itemBuilder: (ctx, i) {
                              final (name, url) = files[i];
                              final isImg =
                                  url.toLowerCase().contains('.jpg') ||
                                      url.toLowerCase().contains('.png') ||
                                      url.toLowerCase().contains('.jpeg');
                              return InkWell(
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => DocumentViewerScreen(
                                            url: url, fileName: name))),
                                onLongPress: () => unawaited(_openUrl(url)),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.black12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        if (isImg)
                                          Image.network(url, fit: BoxFit.cover)
                                        else
                                          const Center(
                                              child: Icon(Icons.picture_as_pdf,
                                                  color: Colors.redAccent,
                                                  size: 36)),
                                        Positioned(
                                          left: 4,
                                          right: 4,
                                          bottom: 4,
                                          child: Container(
                                            color: Colors.black54,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 4, vertical: 2),
                                            child: Text(name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10)),
                                          ),
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: Material(
                                            color: Colors.black45,
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              onTap: () async {
                                                final ok =
                                                    await showDialog<bool>(
                                                  context: context,
                                                  builder: (_) => AlertDialog(
                                                    title: const Text(
                                                        'Eliminar archivo'),
                                                    content: Text(
                                                        '¿Deseas eliminar "$name"?'),
                                                    actions: [
                                                      TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  context,
                                                                  false),
                                                          child: const Text(
                                                              'Cancelar')),
                                                      FilledButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  context,
                                                                  true),
                                                          child: const Text(
                                                              'Eliminar')),
                                                    ],
                                                  ),
                                                );
                                                if (ok == true) {
                                                  try {
                                                    // 1. Mostrar estado de carga temporal en UI si se desea o solo await
                                                    final path = '$folder/$name';
                                                    
                                                    // 2. Eliminar de Bucket Storage
                                                    await _deleteStorageFile(path);
                                                    
                                                    // 3. Remover del Caché en Memoria
                                                    _urlCache.remove(path);

                                                    // 4. Limpiar Variables de la UI
                                                    setState(() {
                                                      if (_soatPath == path) {
                                                        _soatPath = null;
                                                        _soatSigned = null;
                                                      }
                                                      if (_tecnoPath == path) {
                                                        _tecnoPath = null;
                                                        _tecnoSigned = null;
                                                      }
                                                      if (_seguroPath == path) {
                                                        _seguroPath = null;
                                                        _seguroSigned = null;
                                                      }
                                                      if (_propPath == path) {
                                                        _propPath = null;
                                                        _propSigned = null;
                                                      }
                                                    });

                                                    // 5. Limpiar en PostgreSQL si la referencia Padre fue borrada
                                                    final dbCol = {
                                                      DocType.soat: 'soat_path',
                                                      DocType.tecno: 'tecno_path',
                                                      DocType.seguro: 'seguro_path',
                                                      DocType.propiedad: 'propiedad_path',
                                                    }[type]!;

                                                    final varCheck = {
                                                      DocType.soat: _soatPath,
                                                      DocType.tecno: _tecnoPath,
                                                      DocType.seguro: _seguroPath,
                                                      DocType.propiedad: _propPath,
                                                    }[type];

                                                    if (varCheck == null) {
                                                       await supabase
                                                          .from('vehiculos')
                                                          .update({dbCol: null}).eq('id', widget.vehiculoId);
                                                    }

                                                    // 6. Refrescar Modal y Dashboard
                                                    await refreshModal();
                                                    
                                                  } catch (e) {
                                                    // 7. Notificar visualmente si falla permisos / servidor
                                                    if (mounted) {
                                                      AppSnackBar.show(
                                                        context,
                                                        'Error al eliminar archivo: $e',
                                                        backgroundColor:
                                                            Colors.redAccent,
                                                      );
                                                    }
                                                  }
                                                }
                                              },
                                              child: const Padding(
                                                  padding: EdgeInsets.all(6),
                                                  child: Icon(Icons.delete,
                                                      color: Colors.white,
                                                      size: 16)),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    unawaited(_cargarWeeklyStats());
  }

  Future<void> _cargarWeeklyStats() async {
    if (!mounted) return;
    try {
      if (mounted) setState(() => _loadingWeekly = true);
      
      final totalHistory = await SyncService().getCombinedRouteHistory(widget.vehiculoId);
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final recentStatsData = totalHistory.where((s) {
        final dateStr = s['fecha'] ?? s['created_at'] ?? '';
        final date = DateTime.tryParse(dateStr);
        return date != null && date.isAfter(weekAgo);
      }).toList();

      double km = 0, gallons = 0, cost = 0;
      for (var s in recentStatsData) {
        km += _asDouble(s['distancia_km'] ?? s['distancia']);
        gallons += _asDouble(s['consumo_galones'] ?? s['consumo_estimado']);
        cost += _asDouble(s['costo_estimado']);
      }

      // Cargar datos del vehículo PRIMERO para que las fechas estén disponibles
      // al calcular predicciones (Bug #4: antes dependía de _lastX que se seteaban tarde)
      final vehicleData = await _cargar();
      final modelName = vehicleData['modelo'] as String? ?? '';
      final marca = (vehicleData['marca'] as String? ?? '').toUpperCase();
      final isCar = marca.contains('CARRO') ||
          (vehicleData['apodo'] as String? ?? '').toUpperCase().contains('CARRO');

      final aiMap = VehicleAILogic.analyzeJourneyPatterns(
        routeHistory: recentStatsData,
        modelName: modelName,
        isCar: isCar,
      );
      final analytics = VehicleAnalytics.fromMap(aiMap);

      final lastAceite = vehicleData['last_aceite'] != null ? DateTime.tryParse(vehicleData['last_aceite']) : null;
      final lastFiltro = vehicleData['last_filtro'] != null ? DateTime.tryParse(vehicleData['last_filtro']) : null;

      List<Map<String, dynamic>> rawPreds = [];
      if (recentStatsData.isNotEmpty) {
        if (lastAceite != null) {
          rawPreds.add(VehicleHealthLogic.predictMaintenance(
            item: isCar ? 'Aceite Motor' : 'Aceite/Lubricación',
            lastDate: lastAceite,
            avgKmPerDay: analytics.avgDailyKm,
            cycleDays: 180,
          ));
        }
        if (lastFiltro != null) {
          rawPreds.add(VehicleHealthLogic.predictMaintenance(
            item: 'Filtro de Aire',
            lastDate: lastFiltro,
            avgKmPerDay: analytics.avgDailyKm,
            cycleDays: 365,
          ));
        }
      }

      if (mounted) {
        setState(() {
          _weeklyStatsModel = WeeklyStats.fromData(
            km: km,
            gallons: gallons,
            cost: cost,
            count: totalHistory.length,
            history: recentStatsData,
            analytics: analytics,
          );
          _predictionsList = MaintenancePrediction.fromList(rawPreds);
          _loadingWeekly = false;
        });

        if (rawPreds.isEmpty && vehicleData['kms'] != null) {
          _recalculateAI(vehicleData);
        }
      }
    } catch (e) {
      debugPrint('Error en _cargarWeeklyStats: $e');
      if (mounted) setState(() => _loadingWeekly = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_notificacionesProcesadas &&
        (_lastCadena != null ||
            _lastFiltro != null ||
            _lastAceite != null ||
            _lastSoat != null ||
            _lastTecno != null)) {
      _notificacionesProcesadas = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        void checkAndSchedule(String tipo, DateTime? last, int days) async {
          if (last == null) return;
          final vencimiento = last.add(Duration(days: days));
          if (vencimiento.isAfter(DateTime.now())) {
            // Antes de programar, intentamos asegurarnos del permiso de alarmas exactas.
            await NotificationService().ensureExactAlarmsEnabled(context);

            await NotificationService().showMaintenanceNotification(
                id: tipo.hashCode,
                title: '¡Mantenimiento requerido!',
                body: 'Debes realizar el mantenimiento de $tipo.',
                scheduledDate: vencimiento,
                context: context);
          }
        }

        checkAndSchedule('lubricación de cadena', _lastCadena, 15);
        checkAndSchedule('filtro de aire', _lastFiltro, 90);
        checkAndSchedule('cambio de aceite', _lastAceite, 25);
        checkAndSchedule('SOAT', _lastSoat, 365);
        checkAndSchedule('Tecnomecánica', _lastTecno, 365);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          IconButton(
            tooltip: 'Compartir vehículo',
            icon: const Icon(Icons.share_rounded),
            onPressed: () {
              if (_cachedVehicleData != null) {
                final double currentHealthIndex =
                    VehicleHealthLogic.calculateHealthIndex(
                  pctCadena: _pctCadena,
                  pctFiltro: _pctFiltro,
                  pctAceite: _pctAceite,
                  pctSoat: _pctSoat,
                  pctTecno: _pctTecno,
                );
                _compartirVehiculo(_cachedVehicleData!, currentHealthIndex);
              }
            },
          ),
          IconButton(
            tooltip: 'Mi Garaje',
            icon: const Icon(Icons.directions_car_rounded),
            onPressed: _abrirGarajeSelector,
          ),
          IconButton(
              tooltip: 'Eliminar vehículo',
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmarYEliminar(widget.vehiculoId)),
          IconButton(
              tooltip: 'Cerrar sesión',
              icon: const Icon(Icons.logout),
              onPressed: _cerrarSesion),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _cargar(),
        builder: (context, s) {
          if (s.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (s.hasError) return Center(child: Text('Error: ${s.error}'));
          if (!s.hasData) {
            return const Center(child: Text('No se encontró el vehículo'));
          }

          final v = s.data!;
          if (!_checkedKm24h) {
            _checkedKm24h = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _verificarKilometraje24h(v);
            });
          }
          final marca = (v['marca'] as String? ?? '').toUpperCase();
          final modelo = v['modelo'] as String? ?? '';
          final apodo = v['apodo'] as String? ?? 'Mi Vehículo';
          final kms = v['kms']?.toString() ?? '0';
          final imagePath = v['image_path'] as String? ?? '';

          // La llamada a IA ya no se hará aquí en build(). Fue transportada
          // a `_cargarWeeklyStats()` para integrarse limpiamente con la data local.

          _soatPath ??= v['soat_path'] as String?;
          _tecnoPath ??= v['tecno_path'] as String?;
          _seguroPath ??= v['seguro_path'] as String?;
          _propPath ??= v['propiedad_path'] as String?;

          if (_soatSigned == null && _soatPath != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              final u = await _signedUrlCachedFor(_soatPath!);
              if (mounted) setState(() => _soatSigned = u);
            });
          }
          if (_tecnoSigned == null && _tecnoPath != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              final u = await _signedUrlCachedFor(_tecnoPath!);
              if (mounted) setState(() => _tecnoSigned = u);
            });
          }
          if (_seguroSigned == null && _seguroPath != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              final u = await _signedUrlCachedFor(_seguroPath!);
              if (mounted) setState(() => _seguroSigned = u);
            });
          }
          if (_propSigned == null && _propPath != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              final u = await _signedUrlCachedFor(_propPath!);
              if (mounted) setState(() => _propSigned = u);
            });
          }

          final dc = v['last_cadena'] != null
              ? DateTime.parse(v['last_cadena'])
              : null;
          final df = v['last_filtro'] != null
              ? DateTime.parse(v['last_filtro'])
              : null;
          final da = v['last_aceite'] != null
              ? DateTime.parse(v['last_aceite'])
              : null;
          final ds =
              v['last_soat'] != null ? DateTime.parse(v['last_soat']) : null;
          final dt =
              v['last_tecno'] != null ? DateTime.parse(v['last_tecno']) : null;

          final currentKms = _asDouble(v['kms']);
          final kmc = _asDouble(v['kms_last_cadena']);
          final kmf = _asDouble(v['kms_last_filtro']);
          final kma = _asDouble(v['kms_last_aceite']);

          if (_lastCadena == null && dc != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _lastCadena = dc;
                  _pctCadena = VehicleHealthLogic.calculateHybridPercentage(
                    lastDate: dc,
                    lastKms: kmc,
                    cycleDays: 15,
                    cycleKms: 500,
                    currentKms: currentKms,
                  );
                });
                unawaited(_syncHealthWidget());
              }
            });
          }
          if (_lastFiltro == null && df != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _lastFiltro = df;
                  _pctFiltro = VehicleHealthLogic.calculateHybridPercentage(
                    lastDate: df,
                    lastKms: kmf,
                    cycleDays: 90,
                    cycleKms: 5000,
                    currentKms: currentKms,
                  );
                });
              }
            });
          }
          if (_lastAceite == null && da != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _lastAceite = da;
                  _pctAceite = VehicleHealthLogic.calculateHybridPercentage(
                    lastDate: da,
                    lastKms: kma,
                    cycleDays: 25,
                    cycleKms: 3000,
                    currentKms: currentKms,
                  );
                });
              }
            });
          }
          if (_lastSoat == null && ds != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _lastSoat = ds;
                  _pctSoat = VehicleHealthLogic.calculateHybridPercentage(
                    lastDate: ds,
                    lastKms: 0,
                    cycleDays: 365,
                    cycleKms: 1, // Irrelevante ya que kms=0
                    currentKms: 0,
                  );
                });
              }
            });
          }
          if (_lastTecno == null && dt != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _lastTecno = dt;
                  _pctTecno = VehicleHealthLogic.calculateHybridPercentage(
                    lastDate: dt,
                    lastKms: 0,
                    cycleDays: 365,
                    cycleKms: 1,
                    currentKms: 0,
                  );
                });
              }
            });
          }

          // Sincronizar TODOS los porcentajes al widget
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) unawaited(_syncHealthWidget());
          });

          // Verificar si la app se abrió desde el widget para auto-iniciar tracking
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) return;
            final prefs = await SharedPreferences.getInstance();
            final shouldStartTracking = prefs.getBool('widget_start_tracking') ?? false;
            if (shouldStartTracking) {
              await prefs.setBool('widget_start_tracking', false);
              if (mounted) {
                _abrirRutas(int.tryParse(kms) ?? 0);
              }
            }
          });

          final bTheme = BrandTheme.getTheme(marca);
          final logoPath = brandLogos[marca.toUpperCase()];

          final double currentHealthIndex =
              VehicleHealthLogic.calculateHealthIndex(
            pctCadena: _pctCadena,
            pctFiltro: _pctFiltro,
            pctAceite: _pctAceite,
            pctSoat: _pctSoat,
            pctTecno: _pctTecno,
          );

          final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
          final isDark = Theme.of(context).brightness == Brightness.dark;

          final mainContent = SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StaggeredFadeIn(
                  delay: const Duration(milliseconds: 100),
                  child: _MainHero(
                    vehicleId: widget.vehiculoId,
                    imagePath: imagePath,
                    logoPath: logoPath,
                    modelo: modelo,
                    kms: kms,
                    brandTheme: bTheme,
                    healthIndex: currentHealthIndex,
                    has360: v['has_360_view'] as bool? ?? false,
                    images360: List<String>.from(v['images_360_urls'] ?? []),
                    onCapture360: () async {
                      final res = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Captura360Screen(vehiculoId: widget.vehiculoId),
                        ),
                      );
                      if (res == true) {
                        setState(() {
                          _cachedVehicleData = null; // forzar recarga
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 24),
                StaggeredFadeIn(
                  delay: const Duration(milliseconds: 200),
                  child: AchievementsCard(
                    stats: _weeklyStatsModel,
                    pctCadena: _pctCadena,
                    pctFiltro: _pctFiltro,
                    pctAceite: _pctAceite,
                    pctSoat: _pctSoat,
                    pctTecno: _pctTecno,
                    brandTheme: bTheme,
                    documentsComplete: _soatPath != null && _tecnoPath != null && _seguroPath != null && _propPath != null,
                    modelName: modelo,
                  ),
                ),
                _buildLegalAlerts(),
                _buildSimitAlertCard(),
                const SizedBox(height: 24),
                _StaggeredFadeIn(
                  delay: const Duration(milliseconds: 300),
                  child: RepaintBoundary(
                    child: PerformanceGuard.adaptiveBlur(
                      borderRadius: BorderRadius.circular(24),
                      sigma: 15.0,
                      fallbackColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.black.withOpacity(0.03),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    Colors.white.withOpacity(0.08),
                                    Colors.white.withOpacity(0.02),
                                  ]
                                : [
                                    Colors.black.withOpacity(0.03),
                                    Colors.black.withOpacity(0.01),
                                  ],
                          ),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.15)
                                : Colors.black.withOpacity(0.08),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.15 : 0.05),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionTitle(text: 'Documentos Legales'),
                            const SizedBox(height: 16),
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.35,
                              children: [
                                DocTileInteractive(
                                    title: 'SOAT',
                                    path: _soatSigned,
                                    icon: Icons.shield_rounded,
                                    onUpload: () => unawaited(
                                        _openDocManager(DocType.soat, 'SOAT')),
                                    onView: _soatSigned == null
                                        ? null
                                        : () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) => DocumentViewerScreen(
                                                    url: _soatSigned!,
                                                    fileName: 'SOAT')))),
                                DocTileInteractive(
                                    title: 'Tecno mechanical',
                                    path: _tecnoSigned,
                                    icon: Icons.precision_manufacturing_rounded,
                                    onUpload: () => unawaited(
                                        _openDocManager(
                                            DocType.tecno, 'Tecno')),
                                    onView: _tecnoSigned == null
                                        ? null
                                        : () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) => DocumentViewerScreen(
                                                    url: _tecnoSigned!,
                                                    fileName: 'Tecno')))),
                                DocTileInteractive(
                                    title: 'Seguro Todo Riesgo',
                                    path: _seguroSigned,
                                    icon: Icons.verified_user_rounded,
                                    onUpload: () => unawaited(
                                        _openDocManager(
                                            DocType.seguro, 'Seguro')),
                                    onView: _seguroSigned == null
                                        ? null
                                        : () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) => DocumentViewerScreen(
                                                    url: _seguroSigned!,
                                                    fileName: 'Seguro')))),
                                DocTileInteractive(
                                    title: 'T. de Propiedad',
                                    path: _propSigned,
                                    icon: Icons.article_rounded,
                                    onUpload: () => unawaited(
                                        _openDocManager(DocType.propiedad,
                                            'Tarjeta de Propiedad')),
                                    onView: _propSigned == null
                                        ? null
                                        : () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) => DocumentViewerScreen(
                                                    url: _propSigned!,
                                                    fileName: 'Tarjeta de Propiedad')))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _StaggeredFadeIn(
                  delay: const Duration(milliseconds: 400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionTitle(text: 'Estado de Mantenimiento y Trámites'),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            IndicatorTile(
                                title: 'Cadena',
                                value: _pctCadena,
                                color: _colorFor(_pctCadena)),
                            const SizedBox(width: 12),
                            IndicatorTile(
                                title: 'Filtro Aire',
                                value: _pctFiltro,
                                color: _colorFor(_pctFiltro)),
                            const SizedBox(width: 12),
                            IndicatorTile(
                                title: 'Aceite',
                                value: _pctAceite,
                                color: _colorFor(_pctAceite)),
                            const SizedBox(width: 12),
                            IndicatorTile(
                                title: 'SOAT',
                                value: _pctSoat,
                                color: _colorFor(_pctSoat)),
                            const SizedBox(width: 12),
                            IndicatorTile(
                                title: 'Tecno',
                                value: _pctTecno,
                                color: _colorFor(_pctTecno)),
                            const SizedBox(width: 12),
                            IndicatorTile(
                              title: 'SIMIT',
                              value: 1.0,
                              color: _getSimitColor(),
                              isSimit: true,
                              finesCount: _simitFinesCount,
                              onTap: _abrirSimit,
                            ),
                            const SizedBox(width: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _StaggeredFadeIn(
                  delay: const Duration(milliseconds: 500),
                  child: PerformanceGuard.adaptiveBlur(
                    borderRadius: BorderRadius.circular(24),
                    sigma: 15.0,
                    fallbackColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.white,
                    child: WeeklyInsightCard(
                      pctCadena: _pctCadena,
                      pctFiltro: _pctFiltro,
                      pctAceite: _pctAceite,
                      pctSoat: _pctSoat,
                      pctTecno: _pctTecno,
                      brandTheme: bTheme,
                      stats: _weeklyStatsModel,
                      predictions: _predictionsList,
                      modelName: modelo,
                      onHistoryTap: _abrirHistorialRutas,
                      isLoading: _loadingWeekly,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _StaggeredFadeIn(
                  delay: const Duration(milliseconds: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionTitle(text: 'Herramientas y Servicios'),
                      const SizedBox(height: 12),
                      GradientButton(
                          icon: Icons.map_rounded,
                          text: 'Navegación GPS',
                          onTap: () => _abrirRutas(int.tryParse(kms) ?? 0),
                          brandTheme: bTheme),
                      const SizedBox(height: 12),
                      GradientButton(
                          icon: Icons.menu_book_rounded,
                          text: 'Guía y Manuales',
                          onTap: _abrirGuias,
                          brandTheme: bTheme),
                      const SizedBox(height: 12),
                      GradientButton(
                          icon: Icons.settings_suggest_rounded,
                          text: 'Gestionar Mantenimientos',
                          onTap: _abrirParametrizacion,
                          brandTheme: bTheme),
                      const SizedBox(height: 12),
                      GradientButton(
                          icon: Icons.account_balance_wallet_rounded,
                          text: 'Gestión de Gastos',
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => GastosScreen(
                                      vehiculoId: widget.vehiculoId,
                                      apodo: apodo,
                                      marcaModelo: '$marca $modelo',
                                      brandLogoPath: brandLogos[marca],
                                      vehicleImagePath: imagePath))),
                          brandTheme: bTheme),
                      const SizedBox(height: 12),
                      GradientButton(
                          icon: Icons.picture_as_pdf_rounded,
                          text: 'Hoja de Vida PDF',
                          onTap: _exportarPdfHojaVida,
                          brandTheme: bTheme),
                      const SizedBox(height: 12),
                      GradientButton(
                          icon: Icons.local_gas_station_rounded,
                          text: 'Bitácora de Tanqueo',
                          onTap: _abrirBitacoraTanqueo,
                          brandTheme: bTheme),
                      const SizedBox(height: 12),
                      GradientButton(
                          icon: Icons.search_rounded,
                          text: 'Consultar RUNT',
                          onTap: () async {
                            final String realPlaca = _cachedVehicleData?['placa'] ?? '';
                            final String realCedula = _cachedVehicleData?['cedula'] ?? '';
                            final updated = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => RuntWebViewScreen(
                                        placa: realPlaca,
                                        cedula: realCedula,
                                        vehiculoId: widget.vehiculoId)));
                            if (updated == true && mounted) {
                              _cargarDatosIniciales();
                            }
                          },
                          brandTheme: bTheme),
                      const SizedBox(height: 16),
                      GradientButton(
                          icon: Icons.store_rounded,
                          text: 'Marketplace de Talleres',
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const MarketplaceTalleresScreen())),
                          brandTheme: bTheme),
                      const SizedBox(height: 12),
                      GradientButton(
                          icon: Icons.auto_awesome,
                          text: 'Consultar al Experto IA',
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AIChatScreen())),
                          brandTheme: bTheme,
                          isSpecial: true),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );

          return Stack(
            children: [
              Positioned(
                top: -80,
                left: -80,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: bTheme.primaryColor.withOpacity(isDark ? 0.15 : 0.1),
                  ),
                ),
              ),
              Positioned(
                top: 350,
                right: -100,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blueAccent.withOpacity(isDark ? 0.12 : 0.08),
                  ),
                ),
              ),
              Positioned(
                bottom: 100,
                left: -120,
                child: Container(
                  width: 380,
                  height: 380,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.purpleAccent.withOpacity(isDark ? 0.1 : 0.06),
                  ),
                ),
              ),
              mainContent,
            ],
          );
        },
      ),
      floatingActionButton: LiquidGlassFAB(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AIChatScreen()),
        ),
        icon: Icons.auto_awesome,
        label: 'IA Experto',
      ),
    );
  }
}

class _MainHero extends StatelessWidget {
  final String vehicleId;
  final String imagePath;
  final String? logoPath;
  final String modelo;
  final String kms;
  final BrandTheme brandTheme;
  final double healthIndex;
  final bool has360;
  final List<String> images360;
  final VoidCallback onCapture360;

  const _MainHero({
    required this.vehicleId,
    required this.imagePath,
    required this.logoPath,
    required this.modelo,
    required this.kms,
    required this.brandTheme,
    required this.healthIndex,
    required this.onCapture360,
    this.has360 = false,
    this.images360 = const [],
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: PerformanceGuard().isLowEnd
            ? null
            : LinearGradient(
                colors: isDark
                    ? [brandTheme.primaryColor.withOpacity(0.1), Colors.black12]
                    : [brandTheme.primaryColor.withOpacity(0.05), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
        color: PerformanceGuard().isLowEnd
            ? (isDark ? Colors.grey[900] : Colors.grey[100])
            : null,
      ),
      child: Stack(
        children: [
          Positioned(
              right: -20,
              bottom: -20,
              child: Icon(Icons.motorcycle,
                  size: 200, color: brandTheme.primaryColor.withOpacity(0.05))),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (logoPath != null)
                        Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  if (!PerformanceGuard().isLowEnd)
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10)
                                ]),
                            child: Image.asset(logoPath!,
                                height: 30,
                                fit: BoxFit.contain,
                                cacheHeight: 60)),
                      const SizedBox(height: 16),
                      Text(modelo,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      Text(
                          '${AppFormat.thousandsOrRaw(kms)} KM',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : Colors.black54,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 8),
                      _HealthBar(
                          healthIndex: healthIndex, brandTheme: brandTheme),
                      const SizedBox(height: 4),
                      Text(VehicleHealthLogic.getVehicleStatus(healthIndex),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: brandTheme.primaryColor)),
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Hero(
                        tag: 'vehicle_main_image',
                        child: has360 && images360.isNotEmpty
                            ? Interactive360Spinner(imageUrls: images360)
                            : (imagePath.isNotEmpty
                                ? Image.asset(imagePath,
                                    fit: BoxFit.contain, cacheWidth: 800)
                                : Icon(Icons.motorcycle,
                                    size: 100,
                                    color: brandTheme.primaryColor.withOpacity(0.2))),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: LiquidGlassIconButton(
                          icon: Icons.camera_alt,
                          onTap: onCapture360,
                          size: 32,
                          iconSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthBar extends StatelessWidget {
  final double healthIndex;
  final BrandTheme brandTheme;
  const _HealthBar({required this.healthIndex, required this.brandTheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('ISH',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          Text('${healthIndex.toInt()}%',
              style:
                  const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 4),
        Container(
          height: 6,
          width: 120,
          decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10)),
          child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: healthIndex / 100,
              child: Container(
                  decoration: BoxDecoration(
                      gradient: PerformanceGuard().isLowEnd
                          ? null
                          : LinearGradient(colors: [
                              brandTheme.primaryColor,
                              brandTheme.primaryColor.withOpacity(0.6)
                            ]),
                      color: PerformanceGuard().isLowEnd
                          ? brandTheme.primaryColor
                          : null,
                      borderRadius: BorderRadius.circular(10)))),
        ),
      ],
    );
  }
}

class DocumentViewerScreen extends StatefulWidget {
  final String url;
  final String? fileName;
  const DocumentViewerScreen({super.key, required this.url, this.fileName});
  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  File? _localFile;
  bool _isLoading = true;
  String? _error;
  Future<void> _prepareFile() async {
    try {
      final res = await http.get(Uri.parse(widget.url));
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${widget.fileName ?? "tempfile"}');
      await file.writeAsBytes(res.bodyBytes);
      if (mounted) {
        setState(() {
          _localFile = file;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _prepareFile();
  }

  @override
  Widget build(BuildContext context) {
    final isImage = widget.url.toLowerCase().contains('.jpg') ||
        widget.url.toLowerCase().contains('.png');
    return Scaffold(
      appBar: AppBar(title: Text(widget.fileName ?? 'Visor'), actions: [
        IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: () async {
              if (_localFile != null) OpenFilex.open(_localFile!.path);
            })
      ]),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null
              ? Center(child: Text(_error!))
              : (isImage
                  ? PhotoView(imageProvider: FileImage(_localFile!))
                  : SfPdfViewer.file(_localFile!))),
    );
  }
}

class _StaggeredFadeIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const _StaggeredFadeIn({required this.child, required this.delay});
  @override
  State<_StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<_StaggeredFadeIn> {
  bool _show = false;
  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) setState(() => _show = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
        opacity: _show ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 600),
        child: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            transform: Matrix4.translationValues(0, _show ? 0 : 30, 0),
            child: widget.child));
  }
}

class _ScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  const _ScaleButton({required this.child, this.onTap, this.onLongPress});
  @override
  State<_ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<_ScaleButton> {
  bool _isPressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedScale(
            scale: _isPressed ? 0.96 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: widget.child));
  }
}

class Interactive360Spinner extends StatefulWidget {
  final List<String> imageUrls;
  const Interactive360Spinner({super.key, required this.imageUrls});

  @override
  State<Interactive360Spinner> createState() => _Interactive360SpinnerState();
}

class _Interactive360SpinnerState extends State<Interactive360Spinner> {
  int _currentIndex = 0;
  double _dragStart = 0.0;

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onHorizontalDragStart: (details) {
        _dragStart = details.localPosition.dx;
      },
      onHorizontalDragUpdate: (details) {
        double offset = details.localPosition.dx - _dragStart;
        // Sensibilidad de la rotación
        int change = (offset / 12).round();
        if (change != 0) {
          setState(() {
            _currentIndex = (_currentIndex - change) % widget.imageUrls.length;
            if (_currentIndex < 0) _currentIndex += widget.imageUrls.length;
          });
          _dragStart = details.localPosition.dx;
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.network(
            widget.imageUrls[_currentIndex],
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 60),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.threed_rotation, color: Colors.white, size: 12),
                  SizedBox(width: 4),
                  Text('360°', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


