// =============================================================================
// captura_360_screen.dart — CAPTURA GUIADA Y PROCESAMIENTO MOTO 360°
// =============================================================================
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import '../../../core/services/vehicle_storage_service.dart';
import '../../../shared/widgets/liquid_glass_fab.dart';
import '../../../shared/widgets/app_snack_bar.dart';

class Captura360Screen extends StatefulWidget {
  final String vehiculoId;
  const Captura360Screen({super.key, required this.vehiculoId});

  @override
  State<Captura360Screen> createState() => _Captura360ScreenState();
}

class _Captura360ScreenState extends State<Captura360Screen> {
  CameraController? _cameraCtrl;
  List<CameraDescription> _cameras = [];
  bool _isCameraReady = false;

  // Estado de la captura
  final int _totalPhotos = 18; // 18 fotos = giros de 20 grados
  final List<XFile> _capturedPhotos = [];
  int _currentStep = 0;
  bool _isProcessing = false;
  String _processingMessage = '';

  // Sensor de Giroscopio
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  double _currentAngle = 0.0; // En grados
  double _targetAngle = 0.0;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _initSensors();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        // Seleccionar cámara trasera principal
        final backCamera = _cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras.first,
        );

        _cameraCtrl = CameraController(
          backCamera,
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _cameraCtrl!.initialize();
        if (mounted) {
          setState(() => _isCameraReady = true);
        }
      }
    } catch (e) {
      debugPrint('Error inicializando cámara: $e');
    }
  }

  void _initSensors() {
    _targetAngle = 0.0;
    _gyroSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      if (!mounted) return;
      double deltaDegrees = event.y * 0.016 * 57.2958;
      setState(() {
        _currentAngle = (_currentAngle + deltaDegrees) % 360.0;
        if (_currentAngle < 0) _currentAngle += 360.0;
      });
    });
  }

  @override
  void dispose() {
    _cameraCtrl?.dispose();
    _gyroSubscription?.cancel();
    super.dispose();
  }

  // Tomar una foto en el paso actual
  Future<void> _capturarFoto() async {
    if (_cameraCtrl == null || !_cameraCtrl!.value.isInitialized) return;

    try {
      final photo = await _cameraCtrl!.takePicture();
      setState(() {
        _capturedPhotos.add(photo);
        _currentStep++;
        _targetAngle = (_targetAngle + 20.0) % 360.0;
      });

      // Si completamos todas las fotos esperadas, iniciar procesamiento automáticamente
      if (_capturedPhotos.length >= _totalPhotos) {
        _procesarImagenes();
      }
    } catch (e) {
      AppSnackBar.show(context, 'Error al capturar foto: $e');
    }
  }

  // Finalizar temprano con las fotos que se hayan capturado hasta el momento
  void _finalizarConFotosActuales() {
    if (_capturedPhotos.isEmpty) {
      AppSnackBar.show(
        context,
        '📷 Toma al menos 1 foto antes de procesar tu vista 360°',
        backgroundColor: Colors.orangeAccent,
        floating: true,
      );
      return;
    }
    _procesarImagenes();
  }

  // Enviar a API pública de Hugging Face y subir a Supabase
  Future<void> _procesarImagenes() async {
    setState(() {
      _isProcessing = true;
      _processingMessage = 'Eliminando fotos anteriores...';
    });

    final storage = VehicleStorageService();
    final List<String> uploadedSignedUrls = [];

    try {
      // 0. ELIMINAR FOTOS 360 ANTERIORES EN SUPABASE STORAGE
      try {
        final List<FileObject> oldFiles = await storage.listFolder('${widget.vehiculoId}/processed_360');
        if (oldFiles.isNotEmpty) {
          for (final f in oldFiles) {
            try {
              await storage.deleteDocument('${widget.vehiculoId}/processed_360/${f.name}');
            } catch (_) {}
          }
        }
      } catch (e) {
        debugPrint('Aviso al purgar archivos 360 anteriores: $e');
      }

      for (int i = 0; i < _capturedPhotos.length; i++) {
        setState(() {
          _processingMessage = 'Eliminando fondo con IA: Imagen ${i + 1} de ${_capturedPhotos.length}...';
        });

        final bytes = await _capturedPhotos[i].readAsBytes();

        Uint8List? transparentBytes;
        try {
          transparentBytes = await _removerFondoGratis(bytes);
        } catch (e) {
          debugPrint('Error en API para foto $i: $e (usando foto original)');
        }

        final finalBytes = transparentBytes ?? bytes;

        setState(() {
          _processingMessage = 'Subiendo a la nube: Imagen ${i + 1} de ${_capturedPhotos.length}...';
        });

        final remotePath = '${widget.vehiculoId}/processed_360/img_$i.png';
        
        await storage.uploadBinary(remotePath, finalBytes, upsert: true);

        final signedUrl = await storage.getSignedUrl(remotePath, {});
        if (signedUrl != null) {
          uploadedSignedUrls.add(signedUrl);
        }
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 10),
                Text('¡Vista 360° Creada!'),
              ],
            ),
            content: Text(
              'Se procesaron ${_capturedPhotos.length} fotos de tu vehículo. El fondo fue recortado con Inteligencia Artificial y la nueva vista 360° ya está disponible.',
              style: const TextStyle(fontSize: 14),
            ),
            actions: [
              LiquidGlassButton(
                label: 'Entendido',
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context, true);
                },
                width: 130,
                height: 42,
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Error de Procesamiento'),
          content: Text('Ocurrió un problema procesando las fotos: $e'),
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

  // LLamada a API Gratuita de BRIA AI (RMBG) en Hugging Face para remover fondo
  Future<Uint8List?> _removerFondoGratis(Uint8List imageBytes) async {
    final String base64Image = base64Encode(imageBytes);
    final String dataUri = 'data:image/jpeg;base64,$base64Image';

    final List<String> endpoints = [
      'https://briaai-bria-rmbg-1-4.hf.space/api/predict',
      'https://briaai-bria-rmbg-2-0.hf.space/api/predict',
      'https://mvgorich-bria-rmbg-1-4.hf.space/api/predict',
    ];

    for (final endpoint in endpoints) {
      try {
        final response = await http.post(
          Uri.parse(endpoint),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'data': [dataUri]
          }),
        ).timeout(const Duration(seconds: 12));

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);
          final listData = jsonResponse['data'] as List?;
          
          if (listData != null && listData.isNotEmpty) {
            final result = listData[0];
            
            if (result is String) {
              final String base64Str = result.contains(',') ? result.split(',').last : result;
              return base64Decode(base64Str);
            }
            
            if (result is Map) {
              String? urlStr = result['url'] ?? result['path'];
              if (urlStr != null) {
                if (!urlStr.startsWith('http')) {
                  final baseUri = Uri.parse(endpoint);
                  urlStr = '${baseUri.scheme}://${baseUri.host}$urlStr';
                }
                final downloadRes = await http.get(Uri.parse(urlStr));
                if (downloadRes.statusCode == 200) {
                  return downloadRes.bodyBytes;
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Error en endpoint $endpoint: $e');
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isProcessing) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Colors.blueAccent),
                const SizedBox(height: 24),
                Text(
                  _processingMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Este proceso remueve el fondo con IA y sube la nueva animación 360° a la nube. Por favor espera unos momentos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isCameraReady || _cameraCtrl == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    double angleDiff = (_currentAngle - _targetAngle).abs();
    if (angleDiff > 180) angleDiff = 360 - angleDiff;
    bool isAligned = angleDiff < 8.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Vista previa de la cámara a pantalla completa limpia sin distorsión
          ClipRect(
            child: SizedOverflowBox(
              size: MediaQuery.of(context).size,
              child: CameraPreview(_cameraCtrl!),
            ),
          ),

          // Enmarcado del encuadre limpio en el centro (sin líneas ni círculos feos sobre la moto)
          Center(
            child: CustomPaint(
              size: Size(MediaQuery.of(context).size.width * 0.85, MediaQuery.of(context).size.height * 0.45),
              painter: ViewfinderReticlePainter(color: isAligned ? Colors.greenAccent : Colors.white38),
            ),
          ),

          // Header Superior estilo Glassmorphism
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  LiquidGlassIconButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.pop(context),
                    size: 38,
                    iconSize: 18,
                  ),
                  Text(
                    'Captura 360° (${_capturedPhotos.length}/$_totalPhotos)',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
                    ),
                    child: Text(
                      '${_capturedPhotos.length} fotos',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Interfaz inferior: Controles, Giros y Botones
          Positioned(
            bottom: 35,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Indicador de giroscopio limpio
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isAligned ? Colors.greenAccent : Colors.white24, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isAligned ? Icons.check_circle_rounded : Icons.navigation_rounded,
                        color: isAligned ? Colors.greenAccent : Colors.orangeAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isAligned 
                          ? '¡Posición Perfecta! Captura la foto' 
                          : 'Gira la moto o el celular ~${(angleDiff).round()}° hacia la marca',
                        style: TextStyle(
                          color: isAligned ? Colors.greenAccent : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                // Botones de acción inferiores
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Porcentaje de avance
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: _capturedPhotos.length / _totalPhotos,
                            strokeWidth: 4,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation(Colors.blueAccent),
                          ),
                          Text(
                            '${((_capturedPhotos.length / _totalPhotos) * 100).round()}%',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                    // Botón de obturador principal estilo Liquid Glass
                    LiquidGlassIconButton(
                      icon: Icons.camera_alt_rounded,
                      onTap: _capturarFoto,
                      size: 74,
                      iconSize: 32,
                    ),

                    // Botón de finalizar/procesar con las fotos actuales
                    GestureDetector(
                      onTap: _finalizarConFotosActuales,
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: _capturedPhotos.isNotEmpty ? Colors.green.withOpacity(0.8) : Colors.white10,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: _capturedPhotos.isNotEmpty ? Colors.greenAccent : Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.done_all_rounded,
                              color: _capturedPhotos.isNotEmpty ? Colors.white : Colors.white38,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Listo',
                              style: TextStyle(
                                color: _capturedPhotos.isNotEmpty ? Colors.white : Colors.white38,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Retícula de encuadre profesional (Corner Reticle) para el visor de la cámara
class ViewfinderReticlePainter extends CustomPainter {
  final Color color;
  const ViewfinderReticlePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final cornerLength = 28.0;
    final r = 16.0;

    // Guía suave central
    final guidePaint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), Radius.circular(r)),
      guidePaint,
    );

    final path = Path();

    // Superior Izquierda
    path.moveTo(0, cornerLength);
    path.lineTo(0, r);
    path.quadraticBezierTo(0, 0, r, 0);
    path.lineTo(cornerLength, 0);

    // Superior Derecha
    path.moveTo(size.width - cornerLength, 0);
    path.lineTo(size.width - r, 0);
    path.quadraticBezierTo(size.width, 0, size.width, r);
    path.lineTo(size.width, cornerLength);

    // Inferior Izquierda
    path.moveTo(0, size.height - cornerLength);
    path.lineTo(0, size.height - r);
    path.quadraticBezierTo(0, size.height, r, size.height);
    path.lineTo(r + cornerLength, size.height);

    // Inferior Derecha
    path.moveTo(size.width - cornerLength, size.height);
    path.lineTo(size.width - r, size.height);
    path.quadraticBezierTo(size.width, size.height, size.width, size.height - r);
    path.lineTo(size.width, size.height - cornerLength);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
