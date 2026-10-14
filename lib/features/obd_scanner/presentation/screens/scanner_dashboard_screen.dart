import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/app_apple_theme.dart';
import '../../../../core/services/ai_bot_service.dart';
import '../providers/scanner_provider.dart';
import 'widgets/bluetooth_device_list.dart';

class ScannerDashboardScreen extends StatefulWidget {
  const ScannerDashboardScreen({super.key});

  @override
  State<ScannerDashboardScreen> createState() => _ScannerDashboardScreenState();
}

class _ScannerDashboardScreenState extends State<ScannerDashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _requestPermissions();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ScannerProvider(),
      child: Scaffold(
        backgroundColor: AppAppleTheme.midnightBackground,
        body: Stack(
          children: [
            // Ambient Apple Glows de fondo (Iluminación sutil de Medianoche)
            Positioned(
              top: -80,
              right: -50,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppAppleTheme.electricBlue.withValues(alpha: 0.14),
                  boxShadow: [
                    BoxShadow(
                      color: AppAppleTheme.electricBlue.withValues(alpha: 0.20),
                      blurRadius: 100,
                      spreadRadius: 40,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 120,
              left: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppAppleTheme.electricCyan.withValues(alpha: 0.08),
                  boxShadow: [
                    BoxShadow(
                      color: AppAppleTheme.electricCyan.withValues(alpha: 0.12),
                      blurRadius: 90,
                      spreadRadius: 30,
                    ),
                  ],
                ),
              ),
            ),

            // Contenido Principal
            SafeArea(
              child: Consumer<ScannerProvider>(
                builder: (context, provider, _) {
                  return Column(
                    children: [
                      // Header estilo iOS NavigationBar con efecto translúcido
                      _buildCupertinoHeader(context, provider),

                      // Cuerpo con scroll fluido tipo iOS
                      Expanded(
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          children: [
                            // 1. Tarjeta Live Activity / Estado de Conexión
                            _buildHeroStatusCard(context, provider),

                            const SizedBox(height: 18),

                            // 2. Banner de Error si existe
                            if (provider.errorMessage.isNotEmpty && provider.state == ScannerState.error) ...[
                              _buildErrorCard(provider.errorMessage),
                              const SizedBox(height: 18),
                            ],

                            // 3. Vista de Telemetría (si está Conectado) o Guía de Inicio (si está Desconectado)
                            if (provider.state == ScannerState.connected) ...[
                              _buildLiveTelemetrySection(context, provider),
                              const SizedBox(height: 20),
                              _buildDtcSection(context, provider),
                            ] else ...[
                              _buildQuickGuideSection(context, provider),
                            ],

                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Barra de navegación superior estilo Apple iOS
  Widget _buildCupertinoHeader(BuildContext context, ScannerProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: AppAppleTheme.midnightBackground.withValues(alpha: 0.75),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        children: [
          // Botón Regresar estilo Cupertino
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 38,
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).maybePop();
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(
                CupertinoIcons.chevron_back,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Título y Subtítulo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Diagnóstico OBD2',
                  style: GoogleFonts.outfit(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
                Text(
                  'Telemetría en Vivo • Spark ECU',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),

          // Badge de estado estilo iOS Live Activity
          _buildLiveStatusBadge(provider.state),
        ],
      ),
    );
  }

  /// Chip de estado con micro-pulsación animada
  Widget _buildLiveStatusBadge(ScannerState state) {
    Color badgeColor;
    String badgeText;

    switch (state) {
      case ScannerState.connected:
        badgeColor = const Color(0xFF10B981);
        badgeText = 'EN VIVO';
        break;
      case ScannerState.initializing:
        badgeColor = const Color(0xFFF59E0B);
        badgeText = 'SYNC';
        break;
      case ScannerState.connecting:
      case ScannerState.scanning:
        badgeColor = AppAppleTheme.electricCyan;
        badgeText = 'BLE';
        break;
      case ScannerState.error:
        badgeColor = const Color(0xFFEF4444);
        badgeText = 'ERROR';
        break;
      case ScannerState.disconnected:
      default:
        badgeColor = Colors.white38;
        badgeText = 'STANDBY';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: state == ScannerState.connected ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: badgeColor.withValues(alpha: 0.6),
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            badgeText,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: badgeColor,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  /// Tarjeta Hero estilo Live Activity / Apple Card
  Widget _buildHeroStatusCard(BuildContext context, ScannerProvider provider) {
    final isConnected = provider.state == ScannerState.connected;
    final isWorking = provider.state == ScannerState.connecting || provider.state == ScannerState.initializing;

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppAppleTheme.midnightSurface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: isConnected
                  ? const Color(0xFF10B981).withValues(alpha: 0.35)
                  : (isWorking
                      ? AppAppleTheme.electricCyan.withValues(alpha: 0.35)
                      : Colors.white.withValues(alpha: 0.10)),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  // Icono en contenedor circular de vidrio
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: isConnected
                          ? const Color(0xFF10B981).withValues(alpha: 0.16)
                          : (isWorking
                              ? AppAppleTheme.electricBlue.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.06)),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isConnected
                            ? const Color(0xFF10B981).withValues(alpha: 0.4)
                            : (isWorking
                                ? AppAppleTheme.electricCyan.withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.1)),
                      ),
                    ),
                    child: Icon(
                      isConnected
                          ? CupertinoIcons.check_mark_circled_solid
                          : (isWorking ? CupertinoIcons.arrow_2_circlepath : CupertinoIcons.car_detailed),
                      color: isConnected
                          ? const Color(0xFF10B981)
                          : (isWorking ? AppAppleTheme.electricCyan : Colors.white70),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Textos de estado
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getStatusTitle(provider.state),
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getStatusSubtitle(provider.state),
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.6),
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Botones de acción estilo iOS
              if (provider.state == ScannerState.disconnected || provider.state == ScannerState.error)
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  color: AppAppleTheme.electricBlue,
                  borderRadius: BorderRadius.circular(16),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    provider.startScanning();
                    _showDeviceListBottomSheet(context, provider);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(CupertinoIcons.bluetooth, color: Colors.white, size: 19),
                      const SizedBox(width: 8),
                      Text(
                        'Vincular Escáner OBD2',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

              if (isWorking)
                Row(
                  children: [
                    const CupertinoActivityIndicator(
                      radius: 12,
                      color: AppAppleTheme.electricCyan,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        provider.state == ScannerState.connecting
                            ? 'Conectando con ScanMate...'
                            : 'Negociando bus CAN del Spark...',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: Colors.redAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      minSize: 32,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        provider.disconnect();
                      },
                      child: Text(
                        'Cancelar',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                ),

              if (isConnected)
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  color: Colors.redAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    provider.disconnect();
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(CupertinoIcons.clear_circled, color: Colors.redAccent, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Desconectar Escáner',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tarjeta de error estilo iOS
  Widget _buildErrorCard(String errorMsg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.exclamationmark_circle, color: Color(0xFFEF4444), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              errorMsg,
              style: GoogleFonts.outfit(
                color: const Color(0xFFFCA5A5),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Cockpit de Telemetría en Vivo (RPM Hero + Cuadrícula de Métricas)
  Widget _buildLiveTelemetrySection(BuildContext context, ScannerProvider provider) {
    final rpmVal = provider.liveMetrics['RPM']?['value'];
    final speedVal = provider.liveMetrics['Speed']?['value'];
    final tempVal = provider.liveMetrics['CoolantTemp']?['value'];

    final numRpm = (rpmVal is num) ? rpmVal.toDouble() : 0.0;
    final rpmPercentage = (numRpm / 7000.0).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Título de Sección estilo iOS
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MÉTRICAS DEL MOTOR',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.5),
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                'ISO 15765-4 CAN',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppAppleTheme.electricCyan.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),

        // 1. Tarjeta Hero Tachometer (RPM del Motor)
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppAppleTheme.midnightSurface.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppAppleTheme.electricCyan.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ],
                            child: const Icon(
                              CupertinoIcons.gauge,
                              color: AppAppleTheme.electricCyan,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Tacómetro (RPM)',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: numRpm > 5500
                              ? Colors.redAccent.withValues(alpha: 0.2)
                              : AppAppleTheme.electricBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          numRpm > 5500
                              ? 'LÍMITE'
                              : (numRpm > 1200 ? 'ACELERANDO' : 'RALENTÍ'),
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: numRpm > 5500 ? Colors.redAccent : AppAppleTheme.electricCyan,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Display gigante de RPM
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        rpmVal != null ? '$rpmVal' : '---',
                        style: GoogleFonts.outfit(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -1.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'rpm',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Barra dinámica de tacómetro con zonas de color
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      height: 8,
                      width: double.infinity,
                      color: Colors.white.withValues(alpha: 0.08),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: rpmPercentage == 0 ? 0.02 : rpmPercentage,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppAppleTheme.electricCyan,
                                AppAppleTheme.electricBlue,
                                if (numRpm > 4500) Colors.amber,
                                if (numRpm > 5800) Colors.redAccent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('0', style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38)),
                      Text('2000', style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38)),
                      Text('4000', style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38)),
                      Text('6000', style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38)),
                      Text('7000', style: GoogleFonts.outfit(fontSize: 10, color: Colors.redAccent.withValues(alpha: 0.6))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // 2. Grilla de Tarjetas Secundarias (Velocidad + Temperatura)
        Row(
          children: [
            // Velocidad
            Expanded(
              child: _buildMetricTile(
                title: 'Velocidad',
                value: speedVal != null ? '$speedVal' : '---',
                unit: 'km/h',
                icon: CupertinoIcons.speedometer,
                accentColor: AppAppleTheme.electricCyan,
                statusTag: (speedVal is num && speedVal > 0) ? 'En marcha' : 'Detenido',
              ),
            ),
            const SizedBox(width: 14),

            // Temperatura de Refrigerante
            Expanded(
              child: _buildMetricTile(
                title: 'Temp. Motor',
                value: tempVal != null ? '$tempVal' : '---',
                unit: '°C',
                icon: CupertinoIcons.thermometer,
                accentColor: _getTempColor(tempVal),
                statusTag: _getTempStatus(tempVal),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Tarjeta de Métrica estilo Apple Health Tile
  Widget _buildMetricTile({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color accentColor,
    required String statusTag,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppAppleTheme.midnightSurface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: accentColor, size: 18),
                  ),
                  Text(
                    statusTag,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tarjeta de Diagnóstico y Códigos de Error (DTC)
  Widget _buildDtcSection(BuildContext context, ScannerProvider provider) {
    final hasDtcs = provider.currentDtcs.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'DIAGNÓSTICO COMPUTARIZADO (DTC)',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.5),
              letterSpacing: 0.8,
            ),
          ),
        ),

        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppAppleTheme.midnightSurface.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: hasDtcs
                      ? Colors.redAccent.withValues(alpha: 0.35)
                      : const Color(0xFF10B981).withValues(alpha: 0.3),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: hasDtcs
                              ? Colors.redAccent.withValues(alpha: 0.15)
                              : const Color(0xFF10B981).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          hasDtcs
                              ? CupertinoIcons.exclamationmark_triangle_fill
                              : CupertinoIcons.checkmark_shield_fill,
                          color: hasDtcs ? Colors.redAccent : const Color(0xFF10B981),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasDtcs ? 'Códigos de Falla Detectados' : 'Sistemas de Motor OK',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              hasDtcs
                                  ? '${provider.currentDtcs.length} alerta(s) registradas en la ECU'
                                  : 'No se encontraron códigos de error en el Spark.',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (hasDtcs) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: provider.currentDtcs.map((dtc) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.redAccent.withValues(alpha: 0.45),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(CupertinoIcons.ant_fill, color: Colors.redAccent, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                dtc,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 18),

                    // Botón Apple Intelligence (IA Mecánica)
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF8B5CF6), // Violeta Siri
                            Color(0xFFEC4899), // Magenta Apple Intelligence
                            Color(0xFF3B82F6), // Azul Eléctrico
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                            blurRadius: 15,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                        borderRadius: BorderRadius.circular(18),
                        onPressed: () {
                          HapticFeedback.heavyImpact();
                          _diagnoseWithAI(context, provider.currentDtcs);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(CupertinoIcons.sparkles, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'Diagnosticar con IA Mecánica',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Guía rápida de inicio cuando no hay conexión
  Widget _buildQuickGuideSection(BuildContext context, ScannerProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'INSTRUCCIONES DE CONEXIÓN',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.5),
              letterSpacing: 0.8,
            ),
          ),
        ),

        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppAppleTheme.midnightSurface.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1.2,
                ),
              ),
              child: Column(
                children: [
                  _buildGuideStep(
                    stepNumber: '1',
                    title: 'Inserta el Escáner',
                    description: 'Conecta tu ScanMate en el puerto OBD2 del Spark (ubicado debajo del volante).',
                    icon: CupertinoIcons.bolt_horizontal_circle,
                  ),
                  const Divider(color: Colors.white12, height: 26),
                  _buildGuideStep(
                    stepNumber: '2',
                    title: 'Enciende el Motor',
                    description: 'Para leer RPM, Velocidad y Temperatura en tiempo real, el motor debe estar en marcha.',
                    icon: CupertinoIcons.flame_fill,
                  ),
                  const Divider(color: Colors.white12, height: 26),
                  _buildGuideStep(
                    stepNumber: '3',
                    title: 'Vincula vía Bluetooth BLE',
                    description: 'Presiona "Vincular Escáner OBD2" arriba y selecciona tu dispositivo en la lista.',
                    icon: CupertinoIcons.radiowaves_right,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuideStep({
    required String stepNumber,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppAppleTheme.electricBlue.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppAppleTheme.electricCyan.withValues(alpha: 0.35),
            ),
          ),
          child: Center(
            child: Text(
              stepNumber,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppAppleTheme.electricCyan,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.6),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helpers de color y textos
  Color _getTempColor(dynamic tempVal) {
    if (tempVal is num) {
      if (tempVal > 98) return Colors.redAccent;
      if (tempVal < 70) return AppAppleTheme.electricCyan;
      return const Color(0xFF10B981);
    }
    return Colors.white54;
  }

  String _getTempStatus(dynamic tempVal) {
    if (tempVal is num) {
      if (tempVal > 98) return 'Elevada';
      if (tempVal < 70) return 'Frío';
      return 'Óptima';
    }
    return '---';
  }

  String _getStatusTitle(ScannerState state) {
    switch (state) {
      case ScannerState.connected:
        return 'Conectado al Vehículo';
      case ScannerState.initializing:
        return 'Sincronizando Protocolo CAN';
      case ScannerState.connecting:
        return 'Enlazando Bluetooth BLE';
      case ScannerState.scanning:
        return 'Buscando Escáneres Cercanos';
      case ScannerState.error:
        return 'Fallo de Enlace OBD2';
      case ScannerState.disconnected:
      default:
        return 'Escáner Desconectado';
    }
  }

  String _getStatusSubtitle(ScannerState state) {
    switch (state) {
      case ScannerState.connected:
        return 'Transmisión de telemetría activa en tiempo real con la ECU del Chevrolet Spark.';
      case ScannerState.initializing:
        return 'Configurando velocidad de baudios (500k) y protocolo SAE J1979...';
      case ScannerState.connecting:
        return 'Negociando canales GATT y tamaño de MTU con el adaptador...';
      case ScannerState.scanning:
        return 'Rastreando ScanMate, ThinkDiag y adaptadores compatibles...';
      case ScannerState.error:
        return 'No fue posible comunicar con la computadora del motor. Verifica la ignición.';
      case ScannerState.disconnected:
      default:
        return 'Conecta el dispositivo en el puerto OBD-II y enciende el motor.';
    }
  }

  void _showDeviceListBottomSheet(BuildContext context, ScannerProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BluetoothDeviceListWidget(provider: provider),
    );
  }

  /// Diálogo de Diagnóstico IA estilo Apple Card
  void _diagnoseWithAI(BuildContext context, List<String> dtcs) async {
    showCupertinoDialog(
      context: context,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: CupertinoAlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.sparkles, color: AppAppleTheme.electricCyan, size: 20),
              const SizedBox(width: 8),
              Text(
                'Analizando con IA...',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CupertinoActivityIndicator(radius: 14),
                const SizedBox(height: 14),
                Text(
                  'Consultando los sistemas de diagnóstico para ${dtcs.join(", ")}...',
                  style: GoogleFonts.outfit(fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final prompt = "Actúa como un ingeniero mecánico automotriz experto de My Auto Guide. "
        "El vehículo es un Chevrolet Spark y el escáner OBD2 acaba de detectar estos códigos de error: ${dtcs.join(', ')}. "
        "Explica en español directo y conciso: "
        "1) Qué componente falla. "
        "2) Nivel de riesgo (¿es seguro rodar?). "
        "3) Solución recomendada y repuestos.";

    final response = await AIBotService().sendMessage(prompt);

    if (context.mounted) {
      Navigator.of(context).pop(); // Cierra loader

      showCupertinoModalPopup(
        context: context,
        builder: (_) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.72,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppAppleTheme.midnightSurface.withValues(alpha: 0.94),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(CupertinoIcons.sparkles, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Dictamen IA Mecánica',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Text(
                            response,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CupertinoButton(
                      color: AppAppleTheme.electricBlue,
                      borderRadius: BorderRadius.circular(16),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Entendido',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
  }
}
