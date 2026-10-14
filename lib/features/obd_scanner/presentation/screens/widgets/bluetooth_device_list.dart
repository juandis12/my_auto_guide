import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_apple_theme.dart';
import '../../providers/scanner_provider.dart';

/// Modal estilo iOS (Cupertino Sheet) para escanear y conectar adaptadores OBD-II
class BluetoothDeviceListWidget extends StatelessWidget {
  final ScannerProvider provider;

  const BluetoothDeviceListWidget({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: provider,
      child: Consumer<ScannerProvider>(
        builder: (context, scanProvider, _) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppAppleTheme.midnightSurface.withValues(alpha: 0.92),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // iOS Grabber Handle
                      Container(
                        width: 38,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Header con Título iOS y estado de radar
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppAppleTheme.electricBlue.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppAppleTheme.electricCyan.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Icon(
                              CupertinoIcons.bluetooth,
                              color: AppAppleTheme.electricCyan,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Vincular Escáner',
                                  style: GoogleFonts.outfit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Busca tu ScanMate o adaptador ELM327 BLE',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (scanProvider.state == ScannerState.scanning)
                            const CupertinoActivityIndicator(
                              radius: 11,
                              color: AppAppleTheme.electricCyan,
                            ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Lista de dispositivos encontrados estilo Grouped Inset
                      SizedBox(
                        height: 280,
                        child: scanProvider.devices.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        CupertinoIcons.dot_radiowaves_left_right,
                                        size: 42,
                                        color: Colors.white.withValues(alpha: 0.3),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        scanProvider.state == ScannerState.scanning
                                            ? "Buscando dispositivos cercanos...\nAsegúrate de que el escáner esté en el puerto OBD del auto."
                                            : "No se encontraron escáneres.\nVerifica que el carro tenga el switch en ON.",
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.outfit(
                                          color: Colors.white.withValues(alpha: 0.65),
                                          fontSize: 13,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.separated(
                                physics: const BouncingScrollPhysics(),
                                itemCount: scanProvider.devices.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final item = scanProvider.devices[index];
                                  final device = item.device;
                                  final rawName = device.platformName.isNotEmpty
                                      ? device.platformName
                                      : item.advertisementData.advName;
                                  final name = rawName.trim().isNotEmpty
                                      ? rawName.trim()
                                      : "Dispositivo OBD2";

                                  final isThinkDiag = name.toLowerCase().contains("scanmate") ||
                                      name.toLowerCase().contains("think") ||
                                      name.toLowerCase().contains("obd");

                                  return Container(
                                    decoration: BoxDecoration(
                                      color: isThinkDiag
                                          ? AppAppleTheme.electricBlue.withValues(alpha: 0.12)
                                          : Colors.white.withValues(alpha: 0.04),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: isThinkDiag
                                            ? AppAppleTheme.electricCyan.withValues(alpha: 0.4)
                                            : Colors.white.withValues(alpha: 0.08),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 4,
                                      ),
                                      leading: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: isThinkDiag
                                              ? AppAppleTheme.electricCyan.withValues(alpha: 0.2)
                                              : Colors.white.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          isThinkDiag
                                              ? CupertinoIcons.car_detailed
                                              : CupertinoIcons.radiowaves_right,
                                          color: isThinkDiag
                                              ? AppAppleTheme.electricCyan
                                              : Colors.white70,
                                          size: 20,
                                        ),
                                      ),
                                      title: Text(
                                        name,
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                      subtitle: Text(
                                        device.remoteId.str,
                                        style: GoogleFonts.outfit(
                                          color: Colors.white.withValues(alpha: 0.45),
                                          fontSize: 11,
                                        ),
                                      ),
                                      trailing: CupertinoButton(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        color: AppAppleTheme.electricBlue,
                                        borderRadius: BorderRadius.circular(20),
                                        minSize: 34,
                                        onPressed: () {
                                          HapticFeedback.mediumImpact();
                                          Navigator.pop(context);
                                          scanProvider.connectToDevice(device);
                                        },
                                        child: Text(
                                          'Conectar',
                                          style: GoogleFonts.outfit(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),

                      const SizedBox(height: 14),

                      // Botón Cancelar estilo iOS
                      SizedBox(
                        width: double.infinity,
                        child: CupertinoButton(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            scanProvider.stopScanning();
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Cerrar',
                            style: GoogleFonts.outfit(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
