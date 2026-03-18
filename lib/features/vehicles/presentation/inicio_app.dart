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
import 'package:dotted_border/dotted_border.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:async';

import '../../../core/services/notification_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/vehicle_storage_service.dart';
import '../../../core/logic/app_widget_logic.dart';
import '../../../core/logic/vehicle_health_logic.dart';
import '../../../core/logic/vehicle_ai_logic.dart';
import '../../../core/theme/brand_theme.dart';
import '../../../shared/widgets/runt_webview.dart';
import '../../navigation/rutas_screen.dart';
import '../../guides/guia.dart';
import '../../auth/login_screen.dart';
import 'parametrizacion_mantenimientos.dart';
import '../../expenses/presentation/gastos_screen.dart';
import '../../../core/logic/fuel_efficiency_logic.dart';
import '../../navigation/presentation/historial_rutas_screen.dart';
import '../../../core/logic/performance_guard.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Métricas Semanales
  double _weeklyDist = 0.0;
  double _weeklyFuel = 0.0;
  double _weeklyCost = 0.0;
  int _totalRoutes = 0;
  bool _loadingWeekly = false;
  List<Map<String, dynamic>> _predictions = [];
  List<Map<String, dynamic>> _weeklyStats = []; // Nuevo campo para IA
  double _efficiencyScore = 0.0;
  double _savingsCOP = 0.0;

  Map<String, dynamic>? _cachedVehicleData;
  final Map<String, dynamic> _urlCache = {};
  bool _notificacionesProcesadas = false;

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

  double _pctRestante(DateTime? last, int cicloDias) {
    if (last == null) return 0.0;
    final dias = DateTime.now().difference(last).inDays;
    final restante = 1.0 - (dias / cicloDias);
    return restante.clamp(0.0, 1.0);
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
            'marca, modelo, apodo, kms, image_path, last_cadena, last_filtro, last_aceite, last_soat, last_tecno, soat_path, tecno_path, seguro_path, propiedad_path',
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
    final int kms = v['kms'] ?? 0;
    final marca = (v['marca'] as String? ?? '').toUpperCase();
    final bool isCarLocal = marca == 'TOYOTA' || marca == 'MAZDA' || marca == 'CHEVROLET';

    final stats = VehicleAILogic.analyzeJourneyPatterns(
      routeHistory: _weeklyStats,
      modelName: v['modelo'] ?? '',
      isCar: isCarLocal,
    );

    final aiIssues = VehicleAILogic.predictUpcomingIssues(
      totalKms: kms,
      intensity: stats['intensity'] ?? 'Baja',
    );

    if (mounted) {
      setState(() {
        _predictions = aiIssues;
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
        _notificacionesProcesadas = false;
        _cachedVehicleData = null; // Forzar recarga de ISH y gamificación
      });
      unawaited(_syncHealthWidget());
      final bool vencido = (res['vencCadena'] == true) ||
          (res['vencFiltro'] == true) ||
          (res['vencAceite'] == true) ||
          (res['vencSoat'] == true) ||
          (res['vencTecno'] == true);
      if (vencido) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Hay mantenimientos vencidos, realizar cuanto antes.'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 4),
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo subir: $e')),
        );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el archivo')),
      );
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
            Future<void> refresh() async => setM(() {});
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
                                await refresh();
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
                                                       _cachedVehicleData = null; // forzar update dashboard
                                                    }

                                                    // 6. Refrescar Modal
                                                    await refresh();
                                                    
                                                  } catch (e) {
                                                    // 7. Notificar visualmente si falla permisos / servidor
                                                    if (mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text('Error al eliminar archivo: $e'),
                                                          backgroundColor: Colors.redAccent,
                                                        ),
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
      final stats = await SupabaseService().getWeeklyStats(widget.vehiculoId);
      final totalHistory =
          await SupabaseService().getRouteHistory(widget.vehiculoId);
      final totalR = totalHistory.length;

      double d = 0, f = 0, c = 0;
      for (var s in stats) {
        // Intentar nuevos nombres, fallback a antiguos
        d += (s['distancia_km'] ?? s['distancia'] as num?)?.toDouble() ?? 0.0;
        f += (s['consumo_galones'] ?? s['consumo_estimado'] as num?)?.toDouble() ?? 0.0;
        c += (s['costo_estimado'] as num?)?.toDouble() ?? 0.0;
      }

      List<Map<String, dynamic>> preds = [];
      if (stats.isNotEmpty) {
        if (_lastAceite != null) {
          preds.add(VehicleHealthLogic.predictMaintenance(
              item: 'Aceite',
              lastDate: _lastAceite,
              baseDays: 25,
              routeHistory: stats));
        }
        if (_lastFiltro != null) {
          preds.add(VehicleHealthLogic.predictMaintenance(
              item: 'Filtro',
              lastDate: _lastFiltro,
              baseDays: 90,
              routeHistory: stats));
        }
        if (_lastCadena != null) {
          preds.add(VehicleHealthLogic.predictMaintenance(
              item: 'Cadena',
              lastDate: _lastCadena,
              baseDays: 15,
              routeHistory: stats));
        }
      }

      final vehicleData = await _cargar();
      final modelName = vehicleData['modelo'] as String? ?? '';
      final isCar = (vehicleData['marca'] as String? ?? '')
              .toUpperCase()
              .contains('CARRO') ||
          (vehicleData['apodo'] as String? ?? '')
              .toUpperCase()
              .contains('CARRO');

      final efficiency = FuelEfficiencyLogic.calculateEfficiencyScore(
          actualKm: d,
          actualFuelGallons: f,
          modelName: modelName,
          isCar: isCar);
      final aiStats = VehicleAILogic.calculateSmartSavings(
          actualKm: d,
          actualFuelGallons: f,
          modelName: modelName,
          isCar: isCar);

      if (mounted) {
        setState(() {
          _weeklyDist = d;
          _weeklyFuel = f;
          _weeklyCost = c;
          _totalRoutes = totalR;
          _weeklyStats = stats;
          _predictions = preds;
          _efficiencyScore = efficiency;
          _savingsCOP = aiStats['amount'];
          _loadingWeekly = false;
        });

        // 🚀 CÁLCULO IA DE MANTENIMIENTO PROFUNDO (Solo 1 vez tras cargar data)
        if (preds.isEmpty && vehicleData['kms'] != null) {
          _recalculateAI(vehicleData);
        }
      }
    } catch (_) {
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

          if (_lastCadena == null && dc != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _lastCadena = dc;
                  _pctCadena = _pctRestante(dc, 15);
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
                  _pctFiltro = _pctRestante(df, 90);
                });
              }
            });
          }
          if (_lastAceite == null && da != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _lastAceite = da;
                  _pctAceite = _pctRestante(da, 25);
                });
              }
            });
          }
          if (_lastSoat == null && ds != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _lastSoat = ds;
                  _pctSoat = _pctRestante(ds, 365);
                });
              }
            });
          }
          if (_lastTecno == null && dt != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _lastTecno = dt;
                  _pctTecno = _pctRestante(dt, 365);
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

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StaggeredFadeIn(
                  delay: const Duration(milliseconds: 100),
                  child: _MainHero(
                    imagePath: imagePath,
                    logoPath: logoPath,
                    modelo: modelo,
                    kms: kms,
                    brandTheme: bTheme,
                    healthIndex: currentHealthIndex,
                  ),
                ),
                const SizedBox(height: 24),
                _StaggeredFadeIn(
                  delay: const Duration(milliseconds: 200),
                  child: _AchievementsCard(
                    healthIndex: currentHealthIndex,
                    routeCount: _totalRoutes,
                    pctCadena: _pctCadena,
                    pctFiltro: _pctFiltro,
                    pctAceite: _pctAceite,
                    pctSoat: _pctSoat,
                    pctTecno: _pctTecno,
                    brandTheme: bTheme,
                  ),
                ),
                const SizedBox(height: 24),
                _StaggeredFadeIn(
                  delay: const Duration(milliseconds: 300),
                  child: RepaintBoundary(
                    child: PerformanceGuard.adaptiveBlur(
                      borderRadius: BorderRadius.circular(24),
                      fallbackColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.black.withOpacity(0.03),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: bTheme.primaryColor.withOpacity(0.1))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _SectionTitle('Documentos Legales'),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _DocTileInteractive(
                                    title: 'SOAT',
                                    url: _soatSigned,
                                    onTapUpload: () => unawaited(
                                        _openDocManager(DocType.soat, 'SOAT')),
                                    onLongPressOpen: _soatSigned == null
                                        ? null
                                        : () =>
                                            unawaited(_openUrl(_soatSigned!))),
                                _DocTileInteractive(
                                    title: 'Tecno',
                                    url: _tecnoSigned,
                                    onTapUpload: () => unawaited(
                                        _openDocManager(
                                            DocType.tecno, 'Tecno')),
                                    onLongPressOpen: _tecnoSigned == null
                                        ? null
                                        : () =>
                                            unawaited(_openUrl(_tecnoSigned!))),
                                _DocTileInteractive(
                                    title: 'Seguro',
                                    url: _seguroSigned,
                                    onTapUpload: () => unawaited(
                                        _openDocManager(
                                            DocType.seguro, 'Seguro')),
                                    onLongPressOpen: _seguroSigned == null
                                        ? null
                                        : () => unawaited(
                                            _openUrl(_seguroSigned!))),
                                _DocTileInteractive(
                                    title: 'T. Propied',
                                    url: _propSigned,
                                    onTapUpload: () => unawaited(
                                        _openDocManager(DocType.propiedad,
                                            'Tarjeta de Propiedad')),
                                    onLongPressOpen: _propSigned == null
                                        ? null
                                        : () =>
                                            unawaited(_openUrl(_propSigned!))),
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
                      const _SectionTitle('Estado de Mantenimiento y Trámites'),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _IndicatorTile(
                                title: 'Cadena',
                                value: _pctCadena,
                                color: _colorFor(_pctCadena)),
                            const SizedBox(width: 12),
                            _IndicatorTile(
                                title: 'Filtro Aire',
                                value: _pctFiltro,
                                color: _colorFor(_pctFiltro)),
                            const SizedBox(width: 12),
                            _IndicatorTile(
                                title: 'Aceite',
                                value: _pctAceite,
                                color: _colorFor(_pctAceite)),
                            const SizedBox(width: 12),
                            _IndicatorTile(
                                title: 'SOAT',
                                value: _pctSoat,
                                color: _colorFor(_pctSoat)),
                            const SizedBox(width: 12),
                            _IndicatorTile(
                                title: 'Tecno',
                                value: _pctTecno,
                                color: _colorFor(_pctTecno)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _StaggeredFadeIn(
                  delay: const Duration(milliseconds: 500),
                  child: _WeeklyInsightCard(
                    pctCadena: _pctCadena,
                    pctFiltro: _pctFiltro,
                    pctAceite: _pctAceite,
                    pctSoat: _pctSoat,
                    pctTecno: _pctTecno,
                    brandTheme: bTheme,
                    weeklyDist: _weeklyDist,
                    weeklyFuel: _weeklyFuel,
                    weeklyCost: _weeklyCost,
                    efficiencyScore: _efficiencyScore,
                    savingsCOP: _savingsCOP,
                    predictions: _predictions,
                    stats: _weeklyStats, // Necesito asegurar que esta variable exista
                    modelName: modelo,
                    isCar: marca.contains('CARRO') || apodo.contains('CARRO'),
                    isLoading: _loadingWeekly,
                  ),
                ),
                const SizedBox(height: 24),
                _StaggeredFadeIn(
                  delay: const Duration(milliseconds: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionTitle('Herramientas y Servicios'),
                      const SizedBox(height: 12),
                      _GradientButton(
                          icon: Icons.map_rounded,
                          text: 'Navegación GPS',
                          onTap: () => _abrirRutas(int.tryParse(kms) ?? 0),
                          brandTheme: bTheme),
                      const SizedBox(height: 12),
                      _GradientButton(
                          icon: Icons.menu_book_rounded,
                          text: 'Guía y Manuales',
                          onTap: _abrirGuias,
                          brandTheme: bTheme),
                      const SizedBox(height: 12),
                      _GradientButton(
                          icon: Icons.settings_suggest_rounded,
                          text: 'Gestionar Mantenimientos',
                          onTap: _abrirParametrizacion,
                          brandTheme: bTheme),
                      const SizedBox(height: 12),
                      _GradientButton(
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
                      _GradientButton(
                          icon: Icons.search_rounded,
                          text: 'Consultar RUNT',
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => RuntWebViewScreen(
                                      placa: 'ABC123',
                                      cedula: '12345678',
                                      vehiculoId: widget.vehiculoId))),
                          brandTheme: bTheme),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MainHero extends StatelessWidget {
  final String imagePath;
  final String? logoPath;
  final String modelo;
  final String kms;
  final BrandTheme brandTheme;
  final double healthIndex;

  const _MainHero(
      {required this.imagePath,
      required this.logoPath,
      required this.modelo,
      required this.kms,
      required this.brandTheme,
      required this.healthIndex});

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
                          '${int.tryParse(kms)?.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.") ?? kms} KM',
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
                    child: Hero(
                        tag: 'vehicle_main_image',
                        child: imagePath.isNotEmpty
                            ? Image.asset(imagePath,
                                fit: BoxFit.contain, cacheWidth: 800)
                            : Icon(Icons.motorcycle,
                                size: 100,
                                color:
                                    brandTheme.primaryColor.withOpacity(0.2)))),
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

class _WeeklyInsightCard extends StatelessWidget {
  final double pctCadena,
      pctFiltro,
      pctAceite,
      pctSoat,
      pctTecno,
      weeklyDist,
      weeklyFuel,
      weeklyCost,
      efficiencyScore,
      savingsCOP;
  final BrandTheme brandTheme;
  final bool isLoading;
  final List<Map<String, dynamic>> predictions;
  final List<Map<String, dynamic>> stats;
  final String modelName;
  final bool isCar;

  const _WeeklyInsightCard(
      {required this.pctCadena,
      required this.pctFiltro,
      required this.pctAceite,
      required this.pctSoat,
      required this.pctTecno,
      required this.brandTheme,
      required this.weeklyDist,
      required this.weeklyFuel,
      required this.weeklyCost,
      required this.efficiencyScore,
      required this.savingsCOP,
      required this.predictions,
      required this.stats,
      required this.modelName,
      required this.isCar,
      this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final healthIndex = VehicleHealthLogic.calculateHealthIndex(
        pctCadena: pctCadena,
        pctFiltro: pctFiltro,
        pctAceite: pctAceite,
        pctSoat: pctSoat,
        pctTecno: pctTecno);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: brandTheme.primaryColor.withOpacity(0.1)),
          boxShadow: [
            if (!PerformanceGuard().isLowEnd)
              BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: brandTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle),
                child: Icon(Icons.insights_rounded,
                    color: brandTheme.primaryColor, size: 22)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Resumen de los últimos 7 días',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white54 : Colors.black54)),
                  Text(VehicleHealthLogic.getVehicleStatus(healthIndex),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                ])),
            if (isLoading)
              const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
          ]),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _StatItem(
                label: 'Distancia',
                value: '${weeklyDist.toStringAsFixed(1)} km',
                icon: Icons.route_outlined,
                color: Colors.blue),
            _StatItem(
                label: 'Consumo',
                value: '${weeklyFuel.toStringAsFixed(1)} gal',
                icon: Icons.local_gas_station_rounded,
                color: Colors.orange),
            _StatItem(
                label: 'Gasto',
                value: '\$${(weeklyCost / 1000).toStringAsFixed(1)}k',
                icon: Icons.payments_rounded,
                color: Colors.green),
          ]),
          const Divider(height: 32),
          Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Icon(Icons.eco_rounded,
                        color: efficiencyScore >= 95
                            ? Colors.green
                            : Colors.orange,
                        size: 16),
                    const SizedBox(width: 6),
                    Text(
                        FuelEfficiencyLogic.getEfficiencyLabel(efficiencyScore),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13))
                  ]),
                  const SizedBox(height: 8),
                  Stack(children: [
                    Container(
                        height: 8,
                        decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white10
                                : Colors.black.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(4))),
                    FractionallySizedBox(
                        widthFactor: (efficiencyScore / 120).clamp(0.01, 1.0),
                        child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  Colors.green.shade300,
                                  Colors.green.shade600
                                ]),
                                borderRadius: BorderRadius.circular(4))))
                  ]),
                ])),
            const SizedBox(width: 24),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(savingsCOP >= 0 ? 'Ahorro Real' : 'Sobre-costo',
                  style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white54 : Colors.black54)),
              Text(
                  '${savingsCOP >= 0 ? '+' : ''}\$${(savingsCOP / 1000).toStringAsFixed(1)}k',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color:
                          savingsCOP >= 0 ? Colors.green : Colors.redAccent)),
            ]),
          ]),
          const Divider(height: 32),
          // --- IA INSIGHTS SECTION ---
          _AIInsightsPanel(
            routeHistory: stats,
            modelName: modelName,
            isCar: isCar,
          ),
          if (predictions.isNotEmpty) ...[
            const Divider(height: 32),
            _ProactivePredictionsCard(predictions: predictions)
          ],
          const Divider(height: 32),
          Row(children: [
            Expanded(
                child: Text(VehicleHealthLogic.getWeeklySummary(healthIndex),
                    style: TextStyle(
                        height: 1.4,
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black87))),
            IconButton(
                onPressed: () {
                  final state =
                      context.findAncestorStateOfType<_InicioAppState>();
                  state?._abrirHistorialRutas();
                },
                icon: Icon(Icons.history_toggle_off_rounded,
                    color: brandTheme.primaryColor)),
          ]),
        ],
      ),
    );
  }
}

class _AIInsightsPanel extends StatelessWidget {
  final List<Map<String, dynamic>> routeHistory;
  final String modelName;
  final bool isCar;

  const _AIInsightsPanel({
    required this.routeHistory,
    required this.modelName,
    required this.isCar,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final aiInsights = VehicleAILogic.analyzeJourneyPatterns(
      routeHistory: routeHistory,
      modelName: modelName,
      isCar: isCar,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.blueAccent.withOpacity(0.05) : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Diagnóstico IA My Auto Guide',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.blue.shade200 : Colors.blue.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              _AIBadge(label: 'Uso: ${aiInsights['intensity']}', color: Colors.orange),
              _AIBadge(label: 'IA Care: ${aiInsights['careScore'].round()}%', color: Colors.blueAccent),
              _AIBadge(label: 'Consistencia: ${aiInsights['consistency']}', color: Colors.green),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            aiInsights['advice'],
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: isDark ? Colors.white70 : Colors.black87,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _AIBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _AIBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatItem(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 6),
      Text(value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      Text(label,
          style: TextStyle(
              fontSize: 10, color: isDark ? Colors.white54 : Colors.black54))
    ]);
  }
}

class _ProactivePredictionsCard extends StatelessWidget {
  final List<Map<String, dynamic>> predictions;
  const _ProactivePredictionsCard({required this.predictions});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.auto_graph_rounded, size: 16, color: Colors.purple[400]),
        const SizedBox(width: 8),
        const Text('Diagnóstico Predictivo (IA)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))
      ]),
      const SizedBox(height: 12),
      ...predictions.map((p) {
        final days = p['days'] as int? ?? 0;
        final item = p['item'] as String;
        final status = p['status'] as String;
        final color = days <= 7
            ? Colors.redAccent
            : (days <= 20 ? Colors.orangeAccent : Colors.purpleAccent);
        return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Container(
                  width: 4,
                  height: 30,
                  decoration: BoxDecoration(
                      color: color, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(
                        status == 'Proyectado'
                            ? 'Próximo servicio de $item: est. $days días'
                            : '$item: $status',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500)),
                    if (status == 'Proyectado')
                      Text(
                          'Basado en recorrido diario de ${(p['kmPerDay'] as double).toStringAsFixed(1)} km',
                          style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.white38 : Colors.black38))
                  ])),
              Icon(Icons.chevron_right,
                  size: 14, color: isDark ? Colors.white24 : Colors.black12),
            ]));
      }),
    ]);
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(text.toUpperCase(),
        style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 1.2,
            color: isDark ? Colors.white54 : Colors.black45));
  }
}

class _DocTileInteractive extends StatelessWidget {
  final String title;
  final String? url;
  final VoidCallback onTapUpload;
  final VoidCallback? onLongPressOpen;
  const _DocTileInteractive(
      {required this.title,
      required this.url,
      required this.onTapUpload,
      this.onLongPressOpen});
  @override
  Widget build(BuildContext context) {
    Widget content = url == null
        ? const Icon(Icons.cloud_upload, size: 18, color: Colors.blue)
        : (url!.toLowerCase().contains('.jpg') ||
                url!.toLowerCase().contains('.png')
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(url!,
                    fit: BoxFit.cover,
                    width: 28,
                    height: 28,
                    cacheWidth: 100,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.image_not_supported,
                        size: 20,
                        color: Colors.grey)))
            : const Icon(Icons.picture_as_pdf,
                size: 20, color: Colors.redAccent));
    return _ScaleButton(
        onTap: onTapUpload,
        onLongPress: onLongPressOpen,
        child: DottedBorder(
            options: const RoundedRectDottedBorderOptions(
                dashPattern: [6, 4],
                strokeWidth: 1.6,
                radius: Radius.circular(12),
                color: Colors.blueGrey,
                padding: EdgeInsets.all(0)),
            child: Container(
                width: 64,
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                child: Column(children: [
                  Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8)),
                      child: Center(child: content)),
                  const SizedBox(height: 6),
                  Text(title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis)
                ]))));
  }
}

class _IndicatorTile extends StatelessWidget {
  final String title;
  final double value;
  final Color color;
  const _IndicatorTile(
      {required this.title, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      width: 100,
      decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.white.withOpacity(0.2))),
      child: Column(children: [
        Text(title,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87)),
        const SizedBox(height: 12),
        SizedBox(
            height: 50,
            width: 50,
            child: Stack(fit: StackFit.expand, children: [
              CircularProgressIndicator(
                  value: value,
                  strokeWidth: 6,
                  backgroundColor:
                      isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                  valueColor: AlwaysStoppedAnimation<Color>(color)),
              Center(
                  child: Text('${(value * 100).round()}%',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isDark ? Colors.white : Colors.black)))
            ]))
      ]),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final BrandTheme? brandTheme;
  const _GradientButton(
      {required this.icon,
      required this.text,
      required this.onTap,
      this.brandTheme});
  @override
  Widget build(BuildContext context) {
    final theme = brandTheme ?? BrandTheme.defaultTheme;
    return _ScaleButton(
        onTap: onTap,
        child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: theme.gradient),
            child: Row(children: [
              Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: Colors.white, size: 22)),
              const SizedBox(width: 16),
              Expanded(
                  child: Text(text,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16))),
              const Icon(Icons.arrow_forward_ios,
                  color: Colors.white70, size: 16)
            ])));
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

// ─── WIDGETS DE GAMIFICACIÓN ─────────────────────────────

class _AchievementsCard extends StatelessWidget {
  final double healthIndex;
  final int routeCount;
  final double pctCadena, pctFiltro, pctAceite, pctSoat, pctTecno;
  final BrandTheme brandTheme;
  const _AchievementsCard(
      {required this.healthIndex,
      required this.routeCount,
      required this.pctCadena,
      required this.pctFiltro,
      required this.pctAceite,
      required this.pctSoat,
      required this.pctTecno,
      required this.brandTheme});

  @override
  Widget build(BuildContext context) {
    final level = VehicleHealthLogic.getUserLevel(healthIndex);
    final medallas = VehicleHealthLogic.getQualityCertifications(
        pctCadena: pctCadena,
        pctFiltro: pctFiltro,
        pctAceite: pctAceite,
        pctSoat: pctSoat,
        pctTecno: pctTecno,
        routeCount: routeCount);
    return PerformanceGuard.adaptiveBlur(
      borderRadius: BorderRadius.circular(24),
      fallbackColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.white.withOpacity(0.05)
          : Colors.black.withOpacity(0.02),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border:
                Border.all(color: brandTheme.primaryColor.withOpacity(0.1))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _SectionTitle('Logros y Nivel'),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: Color(int.parse(level['color'])).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: Color(int.parse(level['color'])))),
                  child: Row(children: [
                    Icon(Icons.workspace_premium,
                        size: 16, color: Color(int.parse(level['color']))),
                    const SizedBox(width: 6),
                    Text('Nivel ${level['name']}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(int.parse(level['color'])),
                            fontSize: 12))
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (medallas.isEmpty)
              const Text(
                  'Aún no tienes medallas. ¡Mantén tu vehículo al día para ganarlas!',
                  style: TextStyle(fontSize: 13, color: Colors.grey))
            else
              SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                      children: medallas
                          .map((m) => Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: _AchievementMedal(
                                  icon: _getIconData(m['icon']),
                                  label: m['label'],
                                  color: Color(int.parse(m['color'])))))
                          .toList())),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'verified':
        return Icons.verified_user_rounded;
      case 'gavel':
        return Icons.gavel_rounded;
      case 'settings_input_component':
        return Icons.settings_applications_rounded;
      case 'map':
        return Icons.map_rounded;
      default:
        return Icons.star_rounded;
    }
  }
}

class _AchievementMedal extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _AchievementMedal(
      {required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3), width: 2)),
          child: Icon(icon, color: color, size: 28)),
      const SizedBox(height: 8),
      Text(label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center),
    ]);
  }
}
