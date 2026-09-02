import 'package:flutter/material.dart';
import '../../../core/services/app_update_service.dart';

class AppUpdateLockScreen extends StatefulWidget {
  final AppUpdateInfo updateInfo;

  const AppUpdateLockScreen({
    super.key,
    required this.updateInfo,
  });

  @override
  State<AppUpdateLockScreen> createState() => _AppUpdateLockScreenState();
}

class _AppUpdateLockScreenState extends State<AppUpdateLockScreen> with SingleTickerProviderStateMixin {
  final _updateService = AppUpdateService();

  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _statusText = '';
  String? _extractedApkPath;
  String? _errorMessage;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _iniciarActualizacion() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.05;
      _statusText = 'Iniciando descarga...';
      _errorMessage = null;
    });

    final apkPath = await _updateService.downloadAndExtractApk(
      zipUrl: widget.updateInfo.zipUrl,
      onProgress: (progress, status) {
        if (mounted) {
          setState(() {
            _downloadProgress = progress;
            _statusText = status;
          });
        }
      },
    );

    if (!mounted) return;

    if (apkPath != null) {
      setState(() {
        _extractedApkPath = apkPath;
        _isDownloading = false;
        _downloadProgress = 1.0;
        _statusText = 'Abriendo instalador del sistema...';
      });

      await _updateService.installApk(apkPath);
    } else {
      setState(() {
        _isDownloading = false;
        _errorMessage = 'Ocurrió un error al descargar o descomprimir la actualización. Verifica tu conexión a internet e inténtalo de nuevo.';
        _statusText = 'Descarga fallida';
      });
    }
  }

  Future<void> _reinstalarApk() async {
    if (_extractedApkPath != null) {
      await _updateService.installApk(_extractedApkPath!);
    } else {
      await _iniciarActualizacion();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMandatory = widget.updateInfo.isMandatory;

    return PopScope(
      canPop: !isMandatory,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0C10),
        body: Stack(
          children: [
            // Círculos de luz de fondo con efecto Glassmorphism
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00FF87).withValues(alpha: 0.12),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -50,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0A84FF).withValues(alpha: 0.10),
                ),
              ),
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Ícono animado de actualización
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00FF87), Color(0xFF00A86B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00FF87).withValues(alpha: 0.35),
                                blurRadius: 28,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.system_update_rounded,
                            color: Colors.black,
                            size: 44,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Título principal
                      const Text(
                        'MY AUTO GUIDE',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.5,
                          color: Color(0xFF00FF87),
                        ),
                      ),
                      const SizedBox(height: 8),

                      const Text(
                        'Actualización Disponible',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),

                      Text(
                        'Versión ${widget.updateInfo.versionName}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tarjeta de Notas de la Versión
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF14171F),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF1F2430), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.stars_rounded, color: Color(0xFF00FF87), size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Novedades de la actualización',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.updateInfo.releaseNotes,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFE2E8F0),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Sección de Progreso o Error
                      if (_isDownloading || _downloadProgress > 0) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: _downloadProgress > 0 ? _downloadProgress : null,
                            minHeight: 10,
                            backgroundColor: const Color(0xFF1F2430),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00FF87)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _statusText,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFA0AEC0),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${(_downloadProgress * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00FF87),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFFF6B6B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Botón de Acción Principal
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isDownloading
                              ? null
                              : (_extractedApkPath != null ? _reinstalarApk : _iniciarActualizacion),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00FF87),
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isDownloading
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Actualizando...',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  _extractedApkPath != null ? 'Completar Instalación' : 'Descargar e Instalar Ahora',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        isMandatory
                            ? '🔒 Actualización requerida para garantizar la seguridad y sincronización.'
                            : 'Puedes posponer esta actualización en este momento.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF718096),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
