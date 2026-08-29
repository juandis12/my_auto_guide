// =============================================================================
// captura_360_screen.dart — SELECTOR GUIADO Y PROCESAMIENTO 360° (CARRO / MOTO)
// =============================================================================
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image/image.dart' as img;
import '../../../core/services/vehicle_storage_service.dart';
import '../../../core/services/vehicle_catalog_service.dart';
import '../../../shared/widgets/liquid_glass_fab.dart';
import '../../../shared/widgets/app_snack_bar.dart';

class Angle360Guide {
  final String id;
  final String title;
  final String angleDegrees;
  final String carAsset;
  final String motoAsset;
  final String tips;

  const Angle360Guide({
    required this.id,
    required this.title,
    required this.angleDegrees,
    required this.carAsset,
    required this.motoAsset,
    required this.tips,
  });
}

const List<Angle360Guide> kAngles360 = [
  Angle360Guide(
    id: 'frontal',
    title: 'FOTO FRONTAL',
    angleDegrees: '0°',
    carAsset: 'assets/360_guide/car/frontal.jpg',
    motoAsset: 'assets/360_guide/moto/frontal.jpg',
    tips: 'Ubícate directamente frente al vehículo a 2.5 metros. Mantén la cámara a la altura de la parrilla / farolas delanteras.',
  ),
  Angle360Guide(
    id: 'diagonal_delantera_derecha',
    title: 'DIAGONAL DELANTERA DERECHA',
    angleDegrees: '45°',
    carAsset: 'assets/360_guide/car/diagonal_delantera_derecha.jpg',
    motoAsset: 'assets/360_guide/moto/diagonal_delantera_derecha.jpg',
    tips: 'Gira 45° hacia la derecha del vehículo. Asegúrate de encuadrar el frente y el lateral derecho de manera balanceada.',
  ),
  Angle360Guide(
    id: 'lateral_derecha',
    title: 'LATERAL DERECHA',
    angleDegrees: '90°',
    carAsset: 'assets/360_guide/car/lateral_derecha.jpg',
    motoAsset: 'assets/360_guide/moto/lateral_derecha.jpg',
    tips: 'Toma la foto completamente de perfil lateral derecho. Ambas llantas deben quedar alineadas horizontalmente.',
  ),
  Angle360Guide(
    id: 'diagonal_trasera_derecha',
    title: 'DIAGONAL TRASERA DERECHA',
    angleDegrees: '135°',
    carAsset: 'assets/360_guide/car/diagonal_trasera_derecha.jpg',
    motoAsset: 'assets/360_guide/moto/diagonal_trasera_derecha.jpg',
    tips: 'Ubícate en la esquina trasera derecha (45° traseros). Muestra la parte posterior y el costado lateral derecho.',
  ),
  Angle360Guide(
    id: 'trasera',
    title: 'FOTO TRASERA',
    angleDegrees: '180°',
    carAsset: 'assets/360_guide/car/trasera.jpg',
    motoAsset: 'assets/360_guide/moto/trasera.jpg',
    tips: 'Párate justo detrás del vehículo a 2.5 metros. Mantén la cámara a la altura del baúl / placa para un encuadre centrado.',
  ),
  Angle360Guide(
    id: 'diagonal_trasera_izquierda',
    title: 'DIAGONAL TRASERA IZQUIERDA',
    angleDegrees: '225°',
    carAsset: 'assets/360_guide/car/diagonal_trasera_izquierda.jpg',
    motoAsset: 'assets/360_guide/moto/diagonal_trasera_izquierda.jpg',
    tips: 'Ubícate en la esquina trasera izquierda (45° traseros). Muestra la parte posterior y el costado lateral izquierdo.',
  ),
  Angle360Guide(
    id: 'lateral_izquierda',
    title: 'LATERAL IZQUIERDA',
    angleDegrees: '270°',
    carAsset: 'assets/360_guide/car/lateral_izquierda.jpg',
    motoAsset: 'assets/360_guide/moto/lateral_izquierda.jpg',
    tips: 'Toma la foto completamente de perfil lateral izquierdo. Mantén la misma distancia de las tomas anteriores.',
  ),
  Angle360Guide(
    id: 'diagonal_delantera_izquierda',
    title: 'DIAGONAL DELANTERA IZQUIERDA',
    angleDegrees: '315°',
    carAsset: 'assets/360_guide/car/diagonal_delantera_izquierda.jpg',
    motoAsset: 'assets/360_guide/moto/diagonal_delantera_izquierda.jpg',
    tips: 'Gira hacia la esquina delantera izquierda (45° frontales). Encuadra el frente y el lateral izquierdo para cerrar el ciclo 360°.',
  ),
];

class Captura360Screen extends StatefulWidget {
  final String vehiculoId;
  final bool? isCar;
  final String? marca;
  final String? modelo;

  const Captura360Screen({
    super.key,
    required this.vehiculoId,
    this.isCar,
    this.marca,
    this.modelo,
  });

  @override
  State<Captura360Screen> createState() => _Captura360ScreenState();
}

class _Captura360ScreenState extends State<Captura360Screen> {
  bool _isLoadingVehicle = true;
  bool _isCar = false;
  String _marca = '';
  String _modelo = '';
  String _placa = '';

  // Fotos tomadas indexadas por el índice del ángulo (0 a 7)
  final Map<int, XFile> _capturedAngles = {};

  bool _isProcessing = false;
  String _processingMessage = '';

  @override
  void initState() {
    super.initState();
    _determinarTipoVehiculo();
  }

  Future<void> _determinarTipoVehiculo() async {
    if (widget.isCar != null) {
      setState(() {
        _isCar = widget.isCar!;
        _marca = widget.marca ?? '';
        _modelo = widget.modelo ?? '';
        _isLoadingVehicle = false;
      });
      return;
    }

    try {
      final res = await Supabase.instance.client
          .from('vehiculos')
          .select('marca, modelo, apodo, placa, image_path')
          .eq('id', widget.vehiculoId)
          .single();

      final marcaStr = (res['marca'] as String? ?? '').toUpperCase();
      final apodoStr = (res['apodo'] as String? ?? '').toUpperCase();
      final imgPath = (res['image_path'] as String? ?? '').toLowerCase();

      final isCarCatalog = VehicleCatalogService().getCarCatalog().containsKey(marcaStr);
      final isCarCalculated = isCarCatalog ||
          marcaStr.contains('CARRO') ||
          apodoStr.contains('CARRO') ||
          imgPath.contains('carros/');

      if (mounted) {
        setState(() {
          _isCar = isCarCalculated;
          _marca = res['marca'] ?? '';
          _modelo = res['modelo'] ?? '';
          _placa = res['placa'] ?? '';
          _isLoadingVehicle = false;
        });
      }
    } catch (e) {
      debugPrint('Error determinando tipo de vehículo en 360: $e');
      if (mounted) {
        setState(() => _isLoadingVehicle = false);
      }
    }
  }

  int get _completedCount => _capturedAngles.length;

  Future<void> _tomarFotoIndividual(int index) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF1E222A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  kAngles360[index].title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Elige cómo deseas capturar este ángulo (${kAngles360[index].angleDegrees})',
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF30D158)),
                  title: const Text('Tomar con la Cámara', style: TextStyle(color: Colors.white)),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded, color: Colors.blueAccent),
                  title: const Text('Elegir de la Galería', style: TextStyle(color: Colors.white)),
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source != null) {
      try {
        final photo = await picker.pickImage(
          source: source,
          imageQuality: 90,
          maxWidth: 1920,
          maxHeight: 1080,
        );

        if (photo != null && mounted) {
          setState(() {
            _capturedAngles[index] = photo;
          });
          AppSnackBar.show(
            context,
            '✅ ${kAngles360[index].title} guardada con éxito',
            backgroundColor: const Color(0xFF1E7E34),
          );
        }
      } catch (e) {
        if (mounted) {
          AppSnackBar.show(context, 'Error al capturar imagen: $e');
        }
      }
    }
  }

  void _verDetallesAngulo(Angle360Guide angle) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF181B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      angle.angleDegrees,
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      angle.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Guía de Captura y Encuadre:',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Text(
                angle.tips,
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text('Entendido', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF035880),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _iniciarCapturaGuiada() async {
    for (int i = 0; i < kAngles360.length; i++) {
      if (!_capturedAngles.containsKey(i)) {
        await _tomarFotoIndividual(i);
      }
    }
  }

  Future<void> _procesarImagenesFinales() async {
    if (_capturedAngles.isEmpty) {
      AppSnackBar.show(
        context,
        '📷 Toma al menos 1 foto para generar tu vista 360°',
        backgroundColor: Colors.orangeAccent,
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _processingMessage = 'Preparando fotos y limpiando anteriores...';
    });

    final storage = VehicleStorageService();
    try {
      // 0. Purgar archivos 360 previos en Supabase Storage
      try {
        final List<FileObject> oldFiles =
            await storage.listFolder('${widget.vehiculoId}/processed_360');
        if (oldFiles.isNotEmpty) {
          for (final f in oldFiles) {
            try {
              await storage.deleteDocument('${widget.vehiculoId}/processed_360/${f.name}');
            } catch (_) {}
          }
        }
      } catch (e) {
        debugPrint('Aviso al purgar archivos 360 previos: $e');
      }

      // Ordenar las fotos por ángulo cronológico
      final List<int> sortedIndices = _capturedAngles.keys.toList()..sort();
      final List<String> uploadedSignedUrls = [];

      int processedCount = 0;
      for (final idx in sortedIndices) {
        final photo = _capturedAngles[idx]!;
        setState(() {
          _processingMessage =
              'Removiendo fondo con IA (${processedCount + 1}/${sortedIndices.length})...';
        });

        final bytes = await photo.readAsBytes();
        final transparentBytes = await _removerFondoHibrido(bytes);

        final remotePath = '${widget.vehiculoId}/processed_360/img_$idx.png';
        await storage.uploadBinary(remotePath, transparentBytes, upsert: true);

        final signedUrl = await storage.getSignedUrl(remotePath, {});
        if (signedUrl != null) {
          uploadedSignedUrls.add(signedUrl);
        }
        processedCount++;
      }

      setState(() {
        _processingMessage = 'Guardando vista 360° en tu garaje...';
      });

      final supabase = Supabase.instance.client;
      await supabase.from('vehiculos').update({
        'has_360_view': true,
        'images_360_urls': uploadedSignedUrls,
      }).eq('id', widget.vehiculoId);

      if (mounted) {
        setState(() => _isProcessing = false);
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1C1F26),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF30D158), size: 28),
                SizedBox(width: 10),
                Text('¡Vista 360° Creada!', style: TextStyle(color: Colors.white)),
              ],
            ),
            content: Text(
              'Se procesaron ${_capturedAngles.length} fotos de tu ${_isCar ? 'automóvil' : 'motocicleta'}. La vista 360° ya está activa en tu Garaje.',
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
            actions: [
              LiquidGlassButton(
                label: 'Ver mi Garaje',
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context, true);
                },
                width: 140,
                height: 42,
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1C1F26),
            title: const Text('Error de Procesamiento', style: TextStyle(color: Colors.white)),
            content: Text('Ocurrió un problema procesando las fotos: $e', style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Aceptar'),
              ),
            ],
          ),
        );
      }
    }
  }

  /// Motor Híbrido en Cascada para Remoción de Fondo 360°
  Future<Uint8List> _removerFondoHibrido(Uint8List imageBytes) async {
    final removeBgKey = (dotenv.env['REMOVE_BG_API_KEY'] != null &&
            dotenv.env['REMOVE_BG_API_KEY']!.isNotEmpty)
        ? dotenv.env['REMOVE_BG_API_KEY']
        : 'CY5vT77YYVndE7tvA1HBYgM8';
    if (removeBgKey != null && removeBgKey.isNotEmpty) {
      try {
        final res = await _removerConRemoveBg(imageBytes, removeBgKey);
        if (res != null) return res;
      } catch (e) {
        debugPrint('Remove.bg API no disponible: $e');
      }
    }

    try {
      final resCloud = await _removerConCloudIA(imageBytes);
      if (resCloud != null) return resCloud;
    } catch (e) {
      debugPrint('Cloud IA no disponible: $e');
    }

    try {
      final resLocal = await _removerFondoLocalDart(imageBytes);
      if (resLocal != null) return resLocal;
    } catch (e) {
      debugPrint('Error en remoción local: $e');
    }

    return imageBytes;
  }

  Future<Uint8List?> _removerConRemoveBg(Uint8List bytes, String apiKey) async {
    try {
      final compressedBytes = await _comprimirParaApi(bytes);
      final base64Img = base64Encode(compressedBytes);

      final response = await http.post(
        Uri.parse('https://api.remove.bg/v1.0/removebg'),
        headers: {
          'X-Api-Key': apiKey.trim(),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'image_file_b64': base64Img,
          'size': 'auto',
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (_) {}
    return null;
  }

  Future<Uint8List> _comprimirParaApi(Uint8List bytes) async {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return bytes;
      if (decoded.width <= 1200) return bytes;
      final resized = img.copyResize(decoded, width: 1024);
      return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
    } catch (_) {
      return bytes;
    }
  }

  Future<Uint8List?> _removerConCloudIA(Uint8List imageBytes) async {
    final String base64Image = base64Encode(imageBytes);
    final String dataUri = 'data:image/jpeg;base64,$base64Image';

    final List<String> endpoints = [
      'https://briaai-bria-rmbg-2-0.hf.space/call/predict',
      'https://briaai-bria-rmbg-1-4.hf.space/api/predict',
    ];

    for (final endpoint in endpoints) {
      try {
        final response = await http.post(
          Uri.parse(endpoint),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'data': [dataUri]
          }),
        ).timeout(const Duration(seconds: 20));

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);
          final listData = jsonResponse['data'] as List?;
          if (listData != null && listData.isNotEmpty) {
            final String raw = listData[0].toString();
            final String base64Str = raw.contains(',') ? raw.split(',').last : raw;
            return base64Decode(base64Str);
          }
        }
      } catch (_) {}
    }
    return null;
  }

  Future<Uint8List?> _removerFondoLocalDart(Uint8List bytes) async {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;

    final resized = (decoded.width > 1000) ? img.copyResize(decoded, width: 800) : decoded;
    final width = resized.width;
    final height = resized.height;

    final topLeft = resized.getPixel(10, 10);
    final topRight = resized.getPixel(width - 10, 10);
    final bottomLeft = resized.getPixel(10, height - 10);
    final bottomRight = resized.getPixel(width - 10, height - 10);

    final bgR = (topLeft.r + topRight.r + bottomLeft.r + bottomRight.r) / 4;
    final bgG = (topLeft.g + topRight.g + bottomLeft.g + bottomRight.g) / 4;
    final bgB = (topLeft.b + topRight.b + bottomLeft.b + bottomRight.b) / 4;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final p = resized.getPixel(x, y);
        final dist = (p.r - bgR).abs() + (p.g - bgG).abs() + (p.b - bgB).abs();
        final isMargin = (x < width * 0.12 || x > width * 0.88 || y < height * 0.12 || y > height * 0.88);
        if (isMargin && dist < 80) {
          p.a = 0;
        } else if (dist < 40) {
          p.a = 0;
        }
      }
    }
    return Uint8List.fromList(img.encodePng(resized));
  }

  @override
  Widget build(BuildContext context) {
    if (_isProcessing) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F1116),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Color(0xFF30D158)),
                const SizedBox(height: 24),
                Text(
                  _processingMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Removiendo el fondo con Inteligencia Artificial para el visor 360°...',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isLoadingVehicle) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F1116),
        body: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14171E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vista 360° (${_isCar ? 'Carro' : 'Moto'})',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${_completedCount}/${kAngles360.length} fotos capturadas',
              style: TextStyle(
                color: _completedCount == kAngles360.length ? const Color(0xFF30D158) : Colors.white60,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          if (_completedCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: _procesarImagenesFinales,
                icon: const Icon(Icons.cloud_upload_rounded, color: Color(0xFF30D158), size: 18),
                label: const Text('Procesar', style: TextStyle(color: Color(0xFF30D158), fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 90),
        itemCount: kAngles360.length,
        itemBuilder: (context, index) {
          final angle = kAngles360[index];
          final isCaptured = _capturedAngles.containsKey(index);
          final capturedFile = _capturedAngles[index];
          final guideAsset = _isCar ? angle.carAsset : angle.motoAsset;

          return _buildAngleCard(
            index: index,
            angle: angle,
            isCaptured: isCaptured,
            capturedFile: capturedFile,
            guideAsset: guideAsset,
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.camera_rounded, color: Colors.white),
                label: Text(
                  _completedCount == 0 ? 'Iniciar Captura Guiada' : 'Continuar Captura (${_completedCount}/8)',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF035880),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
                onPressed: _iniciarCapturaGuiada,
              ),
            ),
            if (_completedCount > 0) ...[
              const SizedBox(width: 12),
              FloatingActionButton.extended(
                backgroundColor: const Color(0xFF30D158),
                icon: const Icon(Icons.done_all_rounded, color: Colors.black),
                label: const Text('Listo', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                onPressed: _procesarImagenesFinales,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAngleCard({
    required int index,
    required Angle360Guide angle,
    required bool isCaptured,
    required XFile? capturedFile,
    required String guideAsset,
  }) {
    final borderColor = isCaptured ? const Color(0xFF30D158) : Colors.white12;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF161920),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCaptured ? const Color(0xFF30D158).withValues(alpha: 0.6) : Colors.white10,
          width: isCaptured ? 1.8 : 1.0,
        ),
        boxShadow: isCaptured
            ? [
                BoxShadow(
                  color: const Color(0xFF30D158).withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header de la tarjeta: Estado PENDIENTE / COMPLETADA
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isCaptured
                  ? const Color(0xFF30D158).withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.03),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isCaptured ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                      color: isCaptured ? const Color(0xFF30D158) : Colors.amberAccent,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isCaptured ? 'COMPLETADA' : 'PENDIENTE',
                      style: TextStyle(
                        color: isCaptured ? const Color(0xFF30D158) : Colors.amberAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                Text(
                  angle.angleDegrees,
                  style: TextStyle(
                    color: isCaptured ? const Color(0xFF30D158) : Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // 2. Recuadro Central con Guía 3D o Foto Capturada
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCaptured ? const Color(0xFF30D158) : Colors.white24,
                    width: isCaptured ? 2.0 : 1.2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (isCaptured && capturedFile != null)
                        Image.file(
                          File(capturedFile.path),
                          fit: BoxFit.cover,
                        )
                      else
                        Image.asset(
                          guideAsset,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.directions_car_filled, color: Colors.white24, size: 50),
                          ),
                        ),

                      // Badge flotante en esquina si está tomada
                      if (isCaptured)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF30D158),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, color: Colors.black, size: 16),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Botón de Acción y Botón de Ver Detalles
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _tomarFotoIndividual(index),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isCaptured ? Icons.replay_rounded : Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              isCaptured ? 'RETOMAR ${angle.title}' : angle.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(height: 18, width: 1, color: Colors.white24),
                TextButton.icon(
                  onPressed: () => _verDetallesAngulo(angle),
                  icon: const Icon(Icons.visibility_rounded, color: Colors.white60, size: 15),
                  label: const Text(
                    'Ver detalles',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
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
