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
//
// WIDGETS AUXILIARES:
//   - [_CircularIndicator]: Indicador circular animado de mantenimiento.
//   - [_GradientButton]: Botón con gradiente para la sección Herramientas.
//   - [_DocumentCard]: Tarjeta de documento con estado visual.
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
import 'dart:math' as math;

import '../../../core/services/notification_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/widgets/runt_webview.dart';
import '../../navigation/rutas_screen.dart';
import '../../guides/guia.dart';
import '../../auth/login_screen.dart';
import 'parametrizacion_mantenimientos.dart';

enum DocType { soat, tecno, seguro, propiedad }

class InicioApp extends StatefulWidget {
  final String vehiculoId;
  const InicioApp({super.key, required this.vehiculoId});
  @override
  State<InicioApp> createState() => _InicioAppState();
}

class _InicioAppState extends State<InicioApp> {
  final supabase = Supabase.instance.client;

  static const String _docsBucket = 'vehiculos-docs';

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

  // Cache de URLs firmadas
  final Map<String, (String url, DateTime expires)> _urlCache = {};
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
    final cached = _urlCache[path];
    if (cached != null && DateTime.now().isBefore(cached.$2)) {
      return cached.$1;
    }
    final signed = await _signedUrlFor(path);
    if (!mounted) return '';
    final expires = DateTime.now().add(const Duration(seconds: 3500));
    _urlCache[path] = (signed, expires);
    return signed;
  }

  Future<String> _signedUrlFor(String path) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado');
    }
    return await supabase.storage.from(_docsBucket).createSignedUrl(path, 3600);
  }

  Color _colorFor(double v) {
    if (v < 0.20) return Colors.red;
    if (v < 0.50) return Colors.amber;
    return Colors.green;
  }

  double _pctRestante(DateTime? last, int cicloDias) {
    if (last == null) return 0.0;
    final dias = DateTime.now().difference(last).inDays;
    final restante = 1.0 - (dias / cicloDias);
    return restante.clamp(0.0, 1.0);
  }

  Future<Map<String, dynamic>> _cargar() async {
    if (!mounted) return {};
    final row = await supabase
        .from('vehiculos')
        .select(
          'marca, modelo, apodo, kms, image_path, last_cadena, last_filtro, last_aceite, last_soat, last_tecno, soat_path, tecno_path, seguro_path, propiedad_path',
        )
        .eq('id', widget.vehiculoId)
        .single();
    return row;
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
        setState(() {}); // Recargar datos para ver kms actualizados
      }
    });
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
      });
      final bool vencido = (res['vencCadena'] == true) ||
          (res['vencFiltro'] == true) ||
          (res['vencAceite'] == true) ||
          (res['vencSoat'] == true) ||
          (res['vencTecno'] == true);
      if (vencido) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Hay mantenimientos vencidos, realizar cuanto antes.',
            ),
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
      final objs = await supabase.storage.from(_docsBucket).list(
            path: folder,
            searchOptions: const SearchOptions(
              limit: 100,
              sortBy: SortBy(column: 'name', order: 'asc'),
            ),
          );
      final futures = objs.map((o) async {
        final path = '$folder/${o.name}';
        final signed = await _signedUrlCachedFor(path);
        return (o.name, signed);
      });
      return await Future.wait(futures);
    } on StorageException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al listar: ${e.message}')),
        );
      }
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

      await supabase.storage.from(_docsBucket).uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: false),
          );

      final col = {
        DocType.soat: 'soat_path',
        DocType.tecno: 'tecno_path',
        DocType.seguro: 'seguro_path',
        DocType.propiedad: 'propiedad_path',
      }[type]!;
      await SupabaseService().client
          .from('vehiculos')
          .update({col: path})
          .eq('id', widget.vehiculoId);

      return path;
    } on StorageException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo subir: ${e.message}')),
        );
      }
      return null;
    }
  }

  Future<void> _deleteStorageFile(String path) async {
    await supabase.storage.from(_docsBucket).remove([path]);
  }

  Future<void> _openUrl(String url) async {
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
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
                          Text(
                            'Documentos: $titulo',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          FilledButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar archivo'),
                            onPressed: () async {
                              final newPath = await _uploadDoc(type);
                              if (newPath != null && mounted) {
                                final signed = await _signedUrlCachedFor(
                                  newPath,
                                );
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
                              final l = url.toLowerCase();
                              final isImg = l.endsWith('.png') ||
                                  l.endsWith('.jpg') ||
                                  l.endsWith('.jpeg') ||
                                  l.endsWith('.webp') ||
                                  l.endsWith('.heic') ||
                                  l.endsWith('.gif');
                              return InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DocumentViewerScreen(
                                        url: url,
                                        fileName: name,
                                      ),
                                    ),
                                  );
                                },
                                onLongPress: () {
                                  unawaited(_openUrl(url));
                                },
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
                                          Image.network(
                                            url,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return const Center(
                                                child: Icon(
                                                  Icons.broken_image,
                                                  color: Colors.grey,
                                                  size: 36,
                                                ),
                                              );
                                            },
                                          )
                                        else
                                          const Center(
                                            child: Icon(
                                              Icons.picture_as_pdf,
                                              color: Colors.redAccent,
                                              size: 36,
                                            ),
                                          ),
                                        Positioned(
                                          left: 4,
                                          right: 4,
                                          bottom: 4,
                                          child: Container(
                                            color: Colors.black54,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 2,
                                            ),
                                            child: Text(
                                              name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: Material(
                                            color: Colors.black45,
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              onTap: () async {
                                                final ok =
                                                    await showDialog<bool>(
                                                  context: context,
                                                  builder: (_) => AlertDialog(
                                                    title: const Text(
                                                      'Eliminar archivo',
                                                    ),
                                                    content: Text(
                                                      '¿Deseas eliminar "$name"?',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                          context,
                                                          false,
                                                        ),
                                                        child: const Text(
                                                          'Cancelar',
                                                        ),
                                                      ),
                                                      FilledButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                          context,
                                                          true,
                                                        ),
                                                        child: const Text(
                                                          'Eliminar',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                                if (ok == true) {
                                                  final path = '$folder/$name';
                                                  await _deleteStorageFile(
                                                    path,
                                                  );
                                                  // Si este archivo era el asignado en cabecera, limpiar
                                                  setState(() {
                                                    final full = path;
                                                    switch (type) {
                                                      case DocType.soat:
                                                        if (_soatPath == full) {
                                                          _soatPath = null;
                                                          _soatSigned = null;
                                                        }
                                                        break;
                                                      case DocType.tecno:
                                                        if (_tecnoPath ==
                                                            full) {
                                                          _tecnoPath = null;
                                                          _tecnoSigned = null;
                                                        }
                                                        break;
                                                      case DocType.seguro:
                                                        if (_seguroPath ==
                                                            full) {
                                                          _seguroPath = null;
                                                          _seguroSigned = null;
                                                        }
                                                        break;
                                                      case DocType.propiedad:
                                                        if (_propPath == full) {
                                                          _propPath = null;
                                                          _propSigned = null;
                                                        }
                                                        break;
                                                    }
                                                  });
                                                  await refresh();
                                                }
                                              },
                                              child: const Padding(
                                                padding: EdgeInsets.all(6),
                                                child: Icon(
                                                  Icons.delete,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                              ),
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
    // La inicialización de TZ y notificaciones ya se realiza en main.dart
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    const double kSpecPillHeight = 112;
    const double kSpecGap = 8;
    final double heroHeight = math.max(
      w * 0.50,
      kSpecPillHeight * 3 + kSpecGap * 2,
    );

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
            await NotificationService().showMaintenanceNotification(
              id: tipo.hashCode,
              title: '¡Mantenimiento requerido!',
              body: 'Debes realizar el mantenimiento de $tipo.',
              scheduledDate: vencimiento,
            );
          } else {
            await NotificationService().showMaintenanceNotification(
              id: 0,
              title: '¡Mantenimiento requerido!',
              body: 'Debes realizar el mantenimiento de $tipo.',
            );
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
            onPressed: () => _confirmarYEliminar(widget.vehiculoId),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _cargar(),
        builder: (context, s) {
          if (s.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (s.hasError) {
            return Center(child: Text('Error: ${s.error}'));
          }
          if (!s.hasData) {
            return const Center(child: Text('No se encontró el vehículo'));
          }

          final v = s.data!;
          final marca = (v['marca'] as String? ?? '').toUpperCase();
          final modelo = v['modelo'] as String? ?? '';
          final apodo = v['apodo'] as String? ?? '';
          final kms = v['kms']?.toString() ?? '0';
          final imagePath = v['image_path'] as String? ?? '';
          final logoPath = brandLogos[marca];

          _soatPath ??= v['soat_path'] as String?;
          _tecnoPath ??= v['tecno_path'] as String?;
          _seguroPath ??= v['seguro_path'] as String?;
          _propPath ??= v['propiedad_path'] as String?;

          // Firmar URLs si aún no están
          if (_soatSigned == null && _soatPath != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              final u = await _signedUrlCachedFor(_soatPath!);
              if (!mounted) return;
              setState(() => _soatSigned = u);
            });
          }
          if (_tecnoSigned == null && _tecnoPath != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              final u = await _signedUrlCachedFor(_tecnoPath!);
              if (!mounted) return;
              setState(() => _tecnoSigned = u);
            });
          }
          if (_seguroSigned == null && _seguroPath != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              final u = await _signedUrlCachedFor(_seguroPath!);
              if (!mounted) return;
              setState(() => _seguroSigned = u);
            });
          }
          if (_propSigned == null && _propPath != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              final u = await _signedUrlCachedFor(_propPath!);
              if (!mounted) return;
              setState(() => _propSigned = u);
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

          if (_lastCadena == null && dc != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                _lastCadena = dc;
                _pctCadena = _pctRestante(dc, 15);
              });
            });
          }
          if (_lastFiltro == null && df != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                _lastFiltro = df;
                _pctFiltro = _pctRestante(df, 90);
              });
            });
          }
          if (_lastAceite == null && da != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                _lastAceite = da;
                _pctAceite = _pctRestante(da, 25);
              });
            });
          }

          final ds =
              v['last_soat'] != null ? DateTime.parse(v['last_soat']) : null;
          final dt =
              v['last_tecno'] != null ? DateTime.parse(v['last_tecno']) : null;

          if (_lastSoat == null && ds != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                _lastSoat = ds;
                _pctSoat = _pctRestante(ds, 365);
              });
            });
          }
          if (_lastTecno == null && dt != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                _lastTecno = dt;
                _pctTecno = _pctRestante(dt, 365);
              });
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        marca,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        '$modelo - $apodo',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _MainHero(
                        imagePath: imagePath,
                        logoPath: logoPath,
                        modelo: modelo,
                        kms: kms,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _IndicatorTile(
                            title: 'SOAT',
                            value: _pctSoat,
                            color: _colorFor(_pctSoat),
                          ),
                          const SizedBox(width: 10),
                          _IndicatorTile(
                            title: 'Tecnomecánica',
                            value: _pctTecno,
                            color: _colorFor(_pctTecno),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const _SectionTitle('Documentos'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _DocTileInteractive(
                      title: 'SOAT',
                      url: _soatSigned,
                      onTapUpload: () {
                        unawaited(_openDocManager(DocType.soat, 'SOAT'));
                      },
                      onLongPressOpen: _soatSigned == null
                          ? null
                          : () {
                              unawaited(_openUrl(_soatSigned!));
                            },
                    ),
                    _DocTileInteractive(
                      title: 'Tecno',
                      url: _tecnoSigned,
                      onTapUpload: () {
                        unawaited(_openDocManager(DocType.tecno, 'Tecno'));
                      },
                      onLongPressOpen: _tecnoSigned == null
                          ? null
                          : () {
                              unawaited(_openUrl(_tecnoSigned!));
                            },
                    ),
                    _DocTileInteractive(
                      title: 'Seguro',
                      url: _seguroSigned,
                      onTapUpload: () {
                        unawaited(_openDocManager(DocType.seguro, 'Seguro'));
                      },
                      onLongPressOpen: _seguroSigned == null
                          ? null
                          : () {
                              unawaited(_openUrl(_seguroSigned!));
                            },
                    ),
                    _DocTileInteractive(
                      title: 'T. Propied',
                      url: _propSigned,
                      onTapUpload: () {
                        unawaited(
                          _openDocManager(
                            DocType.propiedad,
                            'Tarjeta de Propiedad',
                          ),
                        );
                      },
                      onLongPressOpen: _propSigned == null
                          ? null
                          : () {
                              unawaited(_openUrl(_propSigned!));
                            },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _SectionTitle('Indicadores'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _IndicatorTile(
                      title: 'Lubricación de cadena',
                      value: _pctCadena,
                      color: _colorFor(_pctCadena),
                    ),
                    const SizedBox(width: 10),
                    _IndicatorTile(
                      title: 'Filtro de aire',
                      value: _pctFiltro,
                      color: _colorFor(_pctFiltro),
                    ),
                    const SizedBox(width: 10),
                    _IndicatorTile(
                      title: 'Cambio de aceite',
                      value: _pctAceite,
                      color: _colorFor(_pctAceite),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _SectionTitle('Herramientas'),
                const SizedBox(height: 8),
                _GradientButton(
                  icon: Icons.settings_suggest,
                  text: 'Parametrización\nmantenimientos',
                  onTap: _abrirParametrizacion,
                ),
                const SizedBox(height: 8),
                _GradientButton(
                  icon: Icons.menu_book,
                  text: 'Guía',
                  onTap: _abrirGuias,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RuntWebViewScreen(
                          placa: 'ABC123',
                          cedula: '12345678',
                          vehiculoId: '1',
                        ),
                      ),
                    ).then((recargar) {
                      if (recargar == true) {
                        setState(() {}); // Recarga los datos
                      }
                    });
                  },
                  child: const Text('Consultar RUNT'),
                ),
                const SizedBox(height: 8),
                _GradientButton(
                  icon: Icons.route,
                  text: 'Rutas',
                  onTap: () => _abrirRutas(int.tryParse(kms) ?? 0),
                ),
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
  const _MainHero({
    required this.imagePath,
    required this.logoPath,
    required this.modelo,
    required this.kms,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    const double kSpecPillHeight = 112;
    const double kSpecGap = 8;
    final double heroHeight = math.max(
      w * 0.50,
      kSpecPillHeight * 3 + kSpecGap * 2,
    );

    Widget buildVehicleImage() {
      if (imagePath.isEmpty) {
        return const Icon(Icons.motorcycle, size: 96, color: Colors.black26);
      }
      return Image.asset(
        imagePath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.motorcycle, size: 96, color: Colors.black26),
      );
    }

    return SizedBox(
      height: heroHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _SpecPill(
                icon: Icons.public,
                title: 'Kilometraje',
                value: '$kms km',
                height: kSpecPillHeight,
              ),
              const SizedBox(height: kSpecGap),
              const _SpecPill(
                icon: Icons.event_seat,
                title: 'Asientos',
                value: '2 Personas',
                height: kSpecPillHeight,
              ),
              const SizedBox(height: kSpecGap),
              _SpecPill(
                icon: Icons.calendar_month,
                title: 'Linea',
                value: modelo,
                height: kSpecPillHeight,
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/lineasfondo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Center(child: buildVehicleImage()),
                  if (logoPath != null)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: Image.asset(logoPath!, fit: BoxFit.contain),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
}

class _SpecPill extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final double height;
  const _SpecPill({
    required this.icon,
    required this.title,
    required this.value,
    required this.height,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: 86,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.blueGrey, size: 18),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: Colors.black54),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _DocTileInteractive extends StatelessWidget {
  final String title;
  final String? url; // URL firmada para miniatura
  final VoidCallback onTapUpload;
  final VoidCallback? onLongPressOpen;
  const _DocTileInteractive({
    required this.title,
    required this.url,
    required this.onTapUpload,
    this.onLongPressOpen,
  });

  bool _isImageUrl(String u) {
    final lu = u.toLowerCase();
    return lu.endsWith('.png') ||
        lu.endsWith('.jpg') ||
        lu.endsWith('.jpeg') ||
        lu.endsWith('.webp') ||
        lu.endsWith('.heic') ||
        lu.endsWith('.gif');
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (url == null) {
      content = const Icon(Icons.cloud_upload, size: 18, color: Colors.blue);
    } else if (_isImageUrl(url!)) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url!,
          fit: BoxFit.cover,
          width: 28,
          height: 28,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.image_not_supported,
            size: 20,
            color: Colors.grey,
          ),
        ),
      );
    } else {
      content = const Icon(
        Icons.picture_as_pdf,
        size: 20,
        color: Colors.redAccent,
      );
    }
    return GestureDetector(
      onTap: onTapUpload,
      onLongPress: onLongPressOpen,
      child: DottedBorder(
        options: const RoundedRectDottedBorderOptions(
          dashPattern: [6, 4],
          strokeWidth: 1.6,
          radius: Radius.circular(12),
          color: Colors.blueGrey,
          padding: EdgeInsets.all(0),
        ),
        child: Container(
          width: 64,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(child: content),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IndicatorTile extends StatelessWidget {
  final String title;
  final double value; // 0..1
  final Color color;
  const _IndicatorTile({
    required this.title,
    required this.value,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).round();
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 56,
              width: 56,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: value,
                    strokeWidth: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                  Center(
                    child: Text(
                      '$pct%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  const _GradientButton({
    required this.icon,
    required this.text,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFF66A6FF), Color(0xFF6E8EF5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x406E8EF5),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

// ====== VISOR EMBEBIDO ======
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

  // Nombre de archivo legible
  String _getCleanFileName(String url) {
    String name = url.split('/').last;
    if (name.contains('?')) name = name.split('?').first;
    return name.isEmpty ? 'tempfile' : name;
  }

  bool _isImage(String u) {
    final l = u.toLowerCase();
    return l.endsWith('.png') ||
        l.endsWith('.jpg') ||
        l.endsWith('.jpeg') ||
        l.endsWith('.gif') ||
        l.endsWith('.webp') ||
        l.endsWith('.heic');
  }

  bool _isPdf(String u) => u.toLowerCase().endsWith('.pdf');

  Future<File> _downloadFile(String url, String name) async {
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode} al descargar $name');
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(res.bodyBytes);
    return file;
  }

  Future<void> _prepareFile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final name = widget.fileName ?? _getCleanFileName(widget.url);
      final file = widget.url.startsWith('http')
          ? await _downloadFile(widget.url, name)
          : File(widget.url);
      setState(() {
        _localFile = file;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar archivo: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _openFileExternal() async {
    if (_localFile == null) return;
    final result = await OpenFilex.open(_localFile!.path);
    if (result.type != ResultType.done && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo abrir el archivo: ${result.message}'),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _prepareFile();
  }

  @override
  Widget build(BuildContext context) {
    final isImage = _isImage(widget.url);
    final isPdf = _isPdf(widget.url);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName ?? (isImage ? 'Imagen' : 'Documento')),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: _openFileExternal,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null)
              ? Center(
                  child:
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                )
              : isImage
                  ? PhotoView(
                      imageProvider: FileImage(_localFile!),
                      backgroundDecoration:
                          const BoxDecoration(color: Colors.black),
                    )
                  : isPdf
                      ? SfPdfViewer.file(
                          _localFile!,
                          onDocumentLoadFailed: (details) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Error cargando PDF: ${details.error}'),
                                ),
                              );
                            }
                          },
                        )
                      : Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.insert_drive_file,
                                  size: 80,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 20),
                                const Text('No se puede mostrar este archivo.'),
                                const SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: _openFileExternal,
                                  child: const Text('Abrir archivo'),
                                ),
                              ],
                            ),
                          ),
                        ),
    );
  }
}
