// =============================================================================
// captura_360_screen.dart — CAPTURA GUIADA Y PROCESAMIENTO MOTO 360°
// =============================================================================
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import '../../../core/services/vehicle_storage_service.dart';
import '../../../shared/widgets/liquid_glass_fab.dart';

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
          ResolutionPreset.medium,
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
    // Escuchar giroscopio para estimar el giro horizontal del usuario
    _gyroSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      if (!mounted) return;
      // Rotación en el eje vertical (Y en modo retrato vertical estándar)
      // Multiplicamos por la fracción de tiempo aproximada (60Hz -> 0.016s) y convertimos a grados (1 rad = 57.2958 deg)
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
        // Avanzar el objetivo 20 grados para el siguiente paso
        _targetAngle = (_targetAngle + 20.0) % 360.0;
      });

      // Si completamos todas las fotos, iniciar procesamiento
      if (_capturedPhotos.length >= _totalPhotos) {
        _procesarImagenes();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al capturar foto: $e')),
      );
    }
  }

  // Enviar a API pública de Hugging Face y subir a Supabase
  Future<void> _procesarImagenes() async {
    setState(() {
      _isProcessing = true;
      _processingMessage = 'Iniciando optimización de imágenes...';
    });

    final storage = VehicleStorageService();
    final List<String> uploadedSignedUrls = [];

    try {
      for (int i = 0; i < _capturedPhotos.length; i++) {
        setState(() {
          _processingMessage = 'Eliminando fondo con IA: Imagen ${i + 1} de $_totalPhotos...';
        });

        // 1. Cargar bytes de la foto local
        final bytes = await _capturedPhotos[i].readAsBytes();

        // 2. Enviar a API gratuita BRIA RMBG 1.4 en la nube
        Uint8List? transparentBytes;
        try {
          transparentBytes = await _removerFondoGratis(bytes);
        } catch (e) {
          debugPrint('Error en API para foto $i: $e (se usará original con fondo como respaldo)');
        }

        // Si la IA falla, usamos los bytes originales para no romper el flujo
        final finalBytes = transparentBytes ?? bytes;

        setState(() {
          _processingMessage = 'Subiendo a la nube: Imagen ${i + 1} de $_totalPhotos...';
        });

        // 3. Subir a Supabase Storage
        final remotePath = 'processed_360/${widget.vehiculoId}/img_$i.png';
        
        // Eliminar existente si hay (para sobrescribir)
        try {
          await storage.deleteDocument(remotePath);
        } catch (_) {}

        await storage.uploadBinary(remotePath, finalBytes);

        // 4. Obtener URL firmada de largo vencimiento (1 año)
        final signedUrl = await storage.getSignedUrl(remotePath, {});
        if (signedUrl != null) {
          uploadedSignedUrls.add(signedUrl);
        }
      }

      setState(() {
        _processingMessage = 'Guardando vista 360° en tu garaje...';
      });

      // 5. Actualizar registro en base de datos de Supabase
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
            content: const Text(
              'Las fotos de tu motocicleta han sido procesadas, el fondo fue removido y ahora puedes verla rotar interactivamente en tu pantalla principal.',
              style: TextStyle(fontSize: 14),
            ),
            actions: [
              LiquidGlassButton(
                label: 'Entendido',
                onTap: () {
                  Navigator.pop(ctx); // Cierra diálogo
                  Navigator.pop(context, true); // Vuelve a Dashboard con indicador de actualización
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

  // LLamada a API Gratuita de BRIA AI en Hugging Face
  Future<Uint8List?> _removerFondoGratis(Uint8List imageBytes) async {
    final String base64Image = base64Encode(imageBytes);
    final String dataUri = 'data:image/jpeg;base64,$base64Image';

    final response = await http.post(
      Uri.parse('https://briaai-bria-rmbg-1-4.hf.space/api/predict'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'data': [
          {'data': dataUri, 'name': 'moto_captura.jpg'}
        ]
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final listData = jsonResponse['data'] as List;
      
      if (listData.isNotEmpty) {
        final result = listData[0];
        
        // Caso A: Imagen en Base64 directo
        if (result is String) {
          final String base64Str = result.split(',').last;
          return base64Decode(base64Str);
        }
        
        // Caso B: URL temporal provista por Gradio
        if (result is Map) {
          final String? urlStr = result['url'] ?? result['path'];
          if (urlStr != null) {
            final downloadRes = await http.get(Uri.parse(urlStr));
            if (downloadRes.statusCode == 200) {
              return downloadRes.bodyBytes;
            }
          }
        }
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
                  'Este proceso utiliza Inteligencia Artificial gratuita en la nube. Por favor, no cierres la aplicación.',
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

    // Calcular desviación del ángulo del giroscopio
    double angleDiff = (_currentAngle - _targetAngle).abs();
    if (angleDiff > 180) angleDiff = 360 - angleDiff;
    bool isAligned = angleDiff < 8.0; // Margen de alineación de 8 grados

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Vista previa de la cámara
          CameraPreview(_cameraCtrl!),

          // Máscara / Silueta guía de moto en el centro
          Center(
            child: CustomPaint(
              size: const Size(280, 200),
              painter: MotorcycleSilhouettePainter(color: isAligned ? Colors.green.withOpacity(0.5) : Colors.white30),
            ),
          ),

          // Interfaz superior: Título e indicador de progreso
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
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
                    'Captura 360°: Foto ${_currentStep + 1}/$_totalPhotos',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
          ),

          // Interfaz inferior: Controles, Giros y Botón
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Indicador de ángulo giroscópico (Dial de nivelación)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black80,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isAligned ? Colors.green : Colors.white24, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isAligned ? Icons.check_circle : Icons.navigation_rounded,
                        color: isAligned ? Colors.green : Colors.orangeAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isAligned 
                          ? '¡Posición Perfecta! Toma la foto' 
                          : 'Gira el celular unos ${(angleDiff).round()}° hacia la marca',
                        style: TextStyle(
                          color: isAligned ? Colors.green : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Botón disparador de fotos
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Círculos de progreso
                    SizedBox(
                      width: 50,
                      height: 50,
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
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    // Botón de obturador principal estilo Liquid Glass
                    LiquidGlassIconButton(
                      icon: Icons.camera_alt,
                      onTap: _capturarFoto,
                      size: 76,
                      iconSize: 32,
                    ),
                    // Botón para saltarse alineación estilo Liquid Glass
                    LiquidGlassIconButton(
                      icon: Icons.skip_next,
                      onTap: _capturarFoto,
                      size: 44,
                      iconSize: 20,
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

// Pintor personalizado para dibujar la silueta esquemática de la moto en el visor de cámara
class MotorcycleSilhouettePainter extends CustomPainter {
  final Color color;
  const MotorcycleSilhouettePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    
    // Esquema de ruedas
    path.addOval(Rect.fromCircle(center: Offset(size.width * 0.25, size.height * 0.75), radius: 30));
    path.addOval(Rect.fromCircle(center: Offset(size.width * 0.75, size.height * 0.75), radius: 30));

    // Manubrio y horquilla delantera
    path.moveTo(size.width * 0.75, size.height * 0.75); // Eje rueda delantera
    path.lineTo(size.width * 0.68, size.height * 0.35); // Horquilla
    path.lineTo(size.width * 0.60, size.height * 0.32); // Manubrio

    // Chasis y Tanque
    path.moveTo(size.width * 0.25, size.height * 0.75); // Eje rueda trasera
    path.lineTo(size.width * 0.35, size.height * 0.50); // Horquilla trasera
    path.lineTo(size.width * 0.50, size.height * 0.45); // Motor
    path.lineTo(size.width * 0.65, size.height * 0.48); // Conexión delantera
    
    // Tanque de combustible
    path.moveTo(size.width * 0.50, size.height * 0.45);
    path.quadraticBezierTo(size.width * 0.58, size.height * 0.35, size.width * 0.68, size.height * 0.42);
    
    // Asiento
    path.moveTo(size.width * 0.32, size.height * 0.52);
    path.lineTo(size.width * 0.48, size.height * 0.48);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
