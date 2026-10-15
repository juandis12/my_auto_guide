import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:my_auto_guide/core/theme/app_apple_theme.dart';
import 'package:my_auto_guide/core/services/ai_bot_service.dart';
import '../providers/scanner_provider.dart';
import 'widgets/bluetooth_device_list.dart';

class ScannerDashboardScreen extends StatefulWidget {
  final String? initialVehicleName;
  const ScannerDashboardScreen({super.key, this.initialVehicleName});

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
      create: (_) => ScannerProvider(initialVehicleName: widget.initialVehicleName),
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
                  'Telemetría en Vivo • ${provider.vehicleDisplayName}',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                          _getStatusSubtitle(provider.state, provider.vehicleDisplayName),
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
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _showProtocolSelectorSheet(context, provider);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(CupertinoIcons.slider_horizontal_3, size: 14, color: AppAppleTheme.electricCyan),
                        const SizedBox(width: 8),
                        Text(
                          provider.protocolOverride == null
                              ? 'Protocolo: Automático (Recomendado)'
                              : 'Protocolo Forzado: ${provider.protocolOverride}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppAppleTheme.electricCyan,
                          ),
                        ),
                      ],
                    ),
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
                            ? 'Conectando con escáner OBD2...'
                            : 'Sincronizando bus con ${provider.vehicleDisplayName}...',
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
    final loadVal = provider.liveMetrics['EngineLoad']?['value'];
    final voltVal = provider.batteryVoltage;

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
                provider.detectedProtocol,
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
                            ),
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

        const SizedBox(height: 14),

        // 3. Grilla de Tarjetas de Voltaje de Batería + Carga de Motor (Universal)
        Row(
          children: [
            // Voltaje de Batería 12V (Leído directo del pin 16 vía ATRV)
            Expanded(
              child: _buildMetricTile(
                title: 'Batería 12V',
                value: voltVal != null ? '$voltVal' : '---',
                unit: 'V',
                icon: CupertinoIcons.bolt_fill,
                accentColor: (voltVal != null && voltVal >= 13.2)
                    ? const Color(0xFF10B981)
                    : (voltVal != null && voltVal < 11.9
                        ? Colors.redAccent
                        : const Color(0xFFF59E0B)),
                statusTag: voltVal != null
                    ? (voltVal >= 13.2
                        ? 'Alternador OK'
                        : (voltVal < 11.9 ? 'Baja' : 'En reposo'))
                    : '---',
              ),
            ),
            const SizedBox(width: 14),

            // Carga de Motor (Calculated Engine Load)
            Expanded(
              child: _buildMetricTile(
                title: 'Carga Motor',
                value: loadVal != null ? '$loadVal' : '---',
                unit: '%',
                icon: CupertinoIcons.flame,
                accentColor: (loadVal is num && loadVal > 80)
                    ? Colors.redAccent
                    : AppAppleTheme.electricCyan,
                statusTag: (loadVal is num && loadVal > 80) ? 'Exigido' : 'Normal',
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
                                  : 'No se encontraron códigos de error en ${provider.vehicleDisplayName}.',
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
                          _diagnoseWithAI(context, provider.vehicleDisplayName, provider.currentDtcs);
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

                    // Botón Borrar Códigos (Modo 04)
                    const SizedBox(height: 10),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      color: Colors.redAccent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                      onPressed: () => _confirmClearDtcs(context, provider),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(CupertinoIcons.trash, color: Colors.redAccent, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Borrar Códigos (Apagar Check Engine)',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (provider.pendingDtcs.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'Pendientes (Modo 07): ${provider.pendingDtcs.join(", ")}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.amberAccent,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Aviso Especial de Testigos de Seguridad (Airbag SRS / ABS)
        _buildSpecialWarningLightsCard(context, provider),
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
                    description: 'Conecta tu escáner en el puerto OBD2 del vehículo (ubicado generalmente debajo del volante o tablero).',
                    icon: CupertinoIcons.bolt_horizontal_circle,
                  ),
                  const Divider(color: Colors.white12, height: 26),
                  _buildGuideStep(
                    stepNumber: '2',
                    title: 'Enciende el Motor',
                    description: 'Para leer RPM, Velocidad y Temperatura en tiempo real, el switch debe estar en ON o el motor en marcha.',
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
        return 'Sincronizando Protocolo Vehicular';
      case ScannerState.connecting:
        return 'Enlazando Bluetooth BLE';
      case ScannerState.scanning:
        return 'Buscando Escáneres Cercanos';
      case ScannerState.error:
        return 'Fallo de Enlace OBD2';
      case ScannerState.disconnected:
        return 'Escáner Desconectado';
    }
  }

  String _getStatusSubtitle(ScannerState state, [String? vehicleName]) {
    final vName = (vehicleName != null && vehicleName.isNotEmpty) ? vehicleName : 'el vehículo';
    switch (state) {
      case ScannerState.connected:
        return 'Transmisión de telemetría activa en tiempo real con la ECU de $vName.';
      case ScannerState.initializing:
        return 'Configurando baudios y sincronizando protocolos (KWP2000 / CAN / ISO)...';
      case ScannerState.connecting:
        return 'Negociando canales GATT y tamaño de MTU con el adaptador...';
      case ScannerState.scanning:
        return 'Rastreando escáneres OBD2 y adaptadores compatibles...';
      case ScannerState.error:
        return 'No fue posible comunicar con la computadora del motor. Verifica la ignición.';
      case ScannerState.disconnected:
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
  void _diagnoseWithAI(
    BuildContext context,
    String vehicleName,
    List<String> dtcs, {
    String? customQuestion,
  }) async {
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
                  customQuestion != null
                      ? 'Consultando al especialista automotriz...'
                      : (dtcs.isEmpty
                          ? 'Consultando los sistemas de diagnóstico para $vehicleName...'
                          : 'Consultando los sistemas de diagnóstico para ${dtcs.join(", ")}...'),
                  style: GoogleFonts.outfit(fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final prompt = customQuestion ?? (
      "Actúa como un ingeniero mecánico automotriz experto de My Auto Guide. "
      "El vehículo es un $vehicleName y el escáner OBD2 acaba de detectar estos códigos de error: ${dtcs.join(', ')}. "
      "Explica en español directo y conciso: "
      "1) Qué componente falla. "
      "2) Nivel de riesgo (¿es seguro rodar?). "
      "3) Solución recomendada y repuestos."
    );

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

  /// Tarjeta de advertencia y diagnóstico para testigos especiales (Airbag SRS, ABS, ESP)
  Widget _buildSpecialWarningLightsCard(BuildContext context, ScannerProvider provider) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
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
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.exclamationmark_shield_fill,
                      color: Color(0xFFF59E0B),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¿Testigo de Airbag (SRS) o ABS encendido?',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Módulo de Carrocería / Seguridad',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFFCD34D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'El estándar OBD-II genérico solo consulta la computadora de Motor (ECM/PCM - Códigos Pxxxx). '
                'El sistema de Airbag (SRS) y frenos ABS residen en módulos independientes con protocolos propietarios (Códigos Bxxxx / Cxxxx).\n\n'
                'En camionetas Nissan (Navara / Frontier) y la mayoría de vehículos, la causa #1 de testigo de Airbag encendido es la cinta flexible del volante (Clock Spring / Spiral Cable, código B1049) o conectores amarillos bajo los asientos.',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
                color: const Color(0xFFF59E0B).withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(14),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _showAirbagDiagnosisGuide(context, provider.vehicleDisplayName);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(CupertinoIcons.wrench_fill, color: Color(0xFFFCD34D), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Guía y Autodiagnóstico de Airbag',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFCD34D),
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

  /// Modal interactiva con guía paso a paso para diagnosticar Airbag y truco de llave Nissan
  void _showAirbagDiagnosisGuide(BuildContext context, String vehicleName) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.82,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppAppleTheme.midnightSurface.withValues(alpha: 0.95),
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
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(CupertinoIcons.shield_slash_fill, color: Color(0xFFF59E0B), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Diagnóstico Airbag (SRS) • $vehicleName',
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAirbagInfoCard(
                            title: '1. ¿Por qué el escáner OBD2 no detectó el Airbag?',
                            content:
                                'El estándar universal OBD-II (SAE J1979) fue creado por ley para regular emisiones del motor (Powertrain - Códigos Pxxxx). '
                                'El módulo de Airbag (SRS) es una computadora de seguridad separada (Body - Códigos Bxxxx) y no responde al comando estándar "03". Requiere un escáner con protocolo OEM o el método manual de destellos.',
                          ),
                          const SizedBox(height: 12),
                          _buildAirbagInfoCard(
                            title: '2. Falla Típica en Nissan Navara / Pickups',
                            content:
                                '• Cinta Espiral del Volante (Clock Spring / Spiral Cable):\n'
                                'Es el flex eléctrico dentro del timón. Por el giro constante se quiebra y la ECU de Airbag pierde contacto con la bolsa del conductor (DTC B1049). Si tampoco funciona la bocina (pito) o mandos del timón, el Clock Spring está 100% roto.\n\n'
                                '• Conectores Amarillos bajo los Asientos:\n'
                                'Al mover los asientos, los conectores de los pretensores o airbags laterales se aflojan.',
                          ),
                          const SizedBox(height: 12),
                          _buildAirbagInfoCard(
                            title: '3. Procedimiento Secreto de Autodiagnóstico Nissan (Sin Escáner)',
                            content:
                                'Puedes leer y resetear el testigo de Airbag con la llave de encendido:\n\n'
                                '1. Gira la llave a ON (sin encender motor).\n'
                                '2. El testigo de Airbag se encenderá fijo por ~7 segundos.\n'
                                '3. Justo en el segundo que se APAGUE, gira la llave a OFF de inmediato.\n'
                                '4. Espera más de 3 segundos con la llave en OFF.\n'
                                '5. Repite los pasos 1 al 4 EXACTAMENTE 3 VECES seguidas.\n'
                                '6. En la 4ª vez, gira a ON: El sistema entrará en "Modo Diagnóstico" y parpadeará el código exacto.\n'
                                '7. Si la falla era un falso contacto, este ciclo borra el testigo.',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: CupertinoButton(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(16),
                          onPressed: () {
                            Navigator.of(context).pop();
                            final question =
                                "Actúa como un ingeniero mecánico especialista en Nissan y vehículos multimarca. "
                                "En mi vehículo ($vehicleName) tengo el testigo de AIRBAG encendido pero el escáner de motor no muestra códigos. "
                                "Explícame detalladamente cómo diagnosticar la cinta del volante (Clock Spring / Spiral Cable), cómo probar los conectores de asiento y cómo solucionarlo.";
                            _diagnoseWithAI(context, vehicleName, [], customQuestion: question);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(CupertinoIcons.sparkles, color: Color(0xFFC084FC), size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Preguntar a IA',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFC084FC),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      CupertinoButton(
                        color: AppAppleTheme.electricBlue,
                        borderRadius: BorderRadius.circular(16),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Cerrar',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAirbagInfoCard({required String title, required String content}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFFCD34D),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  /// Modal interactiva para seleccionar o forzar cualquiera de los 10 protocolos OBD universales
  void _showProtocolSelectorSheet(BuildContext context, ScannerProvider provider) {
    final protocols = [
      {'name': 'Automático (Recomendado)', 'cmd': null, 'desc': 'Escaneo inteligente multi-bus de 10 protocolos'},
      {'name': 'ISO 14230-4 KWP (Fast Init)', 'cmd': 'ATSP5', 'desc': 'Nissan Navara, Renault Duster, Hyundai, Pickups Diésel'},
      {'name': 'ISO 15765-4 CAN (11-bit, 500k)', 'cmd': 'ATSP6', 'desc': 'Toyota, Chevrolet, Ford, Mazda, VW modernos'},
      {'name': 'ISO 15765-4 CAN (11-bit, 250k)', 'cmd': 'ATSP8', 'desc': 'Pickups diésel pesadas y Ford Transit'},
      {'name': 'ISO 14230-4 KWP (5-baud init)', 'cmd': 'ATSP4', 'desc': 'Vehículos asiáticos y europeos KWP lento'},
      {'name': 'ISO 9141-2', 'cmd': 'ATSP3', 'desc': 'Asiáticos y europeos clásicos pre-2005'},
      {'name': 'ISO 15765-4 CAN (29-bit, 500k)', 'cmd': 'ATSP7', 'desc': 'Comerciales europeos y Honda CAN 29-bit'},
      {'name': 'SAE J1850 PWM', 'cmd': 'ATSP1', 'desc': 'Ford clásico pre-2008 (41.6k)'},
      {'name': 'SAE J1850 VPW', 'cmd': 'ATSP2', 'desc': 'General Motors y Chrysler clásico pre-2008 (10.4k)'},
    ];

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
              color: AppAppleTheme.midnightSurface.withValues(alpha: 0.95),
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
                  const SizedBox(height: 16),
                  Text(
                    'Protocolo de Comunicación OBD2',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fuerza un protocolo específico si tu vehículo no conecta en automático.',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.white60,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: protocols.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final p = protocols[i];
                        final isSelected = provider.protocolOverride == p['cmd'];
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            provider.setProtocolOverride(p['cmd']);
                            Navigator.pop(ctx);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppAppleTheme.electricBlue.withValues(alpha: 0.20)
                                  : Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? AppAppleTheme.electricCyan
                                    : Colors.white.withValues(alpha: 0.08),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p['name']!,
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        p['desc']!,
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          color: Colors.white54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(CupertinoIcons.checkmark_circle_fill,
                                      color: AppAppleTheme.electricCyan, size: 20),
                              ],
                            ),
                          ),
                        );
                      },
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

  /// Diálogo de confirmación para borrar códigos de falla (Modo 04)
  void _confirmClearDtcs(BuildContext context, ScannerProvider provider) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('¿Borrar Códigos de Falla?'),
        content: const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text(
            'Esto enviará el comando Modo 04 a la ECU del vehículo para borrar los códigos almacenados y apagar el testigo Check Engine.\n\n'
            'Asegúrate de haber corregido la falla mecánica y tener el switch en ON con motor apagado.',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Borrar Códigos'),
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.clearAllDtcs();
              if (context.mounted) {
                showCupertinoDialog(
                  context: context,
                  builder: (ctx) => CupertinoAlertDialog(
                    title: Text(success ? 'Códigos Borrados' : 'No se pudo borrar'),
                    content: Text(
                      success
                          ? 'Los códigos fueron borrados exitosamente de la ECU. El testigo Check Engine debería apagarse.'
                          : 'La ECU no respondió al comando de borrado. Asegúrate de tener la ignición en ON con motor apagado.',
                    ),
                    actions: [
                      CupertinoDialogAction(
                        child: const Text('OK'),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
