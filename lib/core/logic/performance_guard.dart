import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

/// Clase encargada de detectar el nivel de hardware del dispositivo
/// y decidir si se deben activar efectos visuales pesados (Glassmorphism, Blurs).
class PerformanceGuard {
  static final PerformanceGuard _instance = PerformanceGuard._internal();
  factory PerformanceGuard() => _instance;
  PerformanceGuard._internal();

  bool _isLowEnd = false;
  
  /// Indica si el dispositivo es de gama de entrada (entrada/baja)
  bool get isLowEnd => _isLowEnd;

  /// Inicializa la detección de hardware. Debe llamarse en el main().
  Future<void> initialize() async {
    if (kIsWeb) {
      _isLowEnd = false;
      return;
    }

    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        
        final model = androidInfo.model.toUpperCase();
        final brand = androidInfo.brand.toUpperCase();
        final hardware = androidInfo.hardware.toLowerCase();
        final product = androidInfo.product.toLowerCase();
        
        debugPrint('PerformanceGuard: Detectando Hardware - Brand: $brand, Model: $model, Hardware: $hardware, Product: $product');

        // 1. Detección específica por modelo (Samsung Galaxy A series y M series son críticos)
        // El Galaxy A05 suele identificarse como SM-A055...
        if (brand.contains('SAMSUNG') && 
           (model.contains('A05') || model.contains('A04') || model.contains('A03') || 
            model.contains('A02') || model.contains('A01') || model.contains('A10') || 
            model.contains('A11') || model.contains('A12') || model.contains('A13') ||
            model.contains('M12') || model.contains('M13') || model.contains('A21') ||
            product.contains('a05') || product.contains('a04'))) {
          _isLowEnd = true;
          debugPrint('PerformanceGuard: MODO BAJO CONSUMO ACTIVADO (Samsung A/M Series)');
          return;
        }

        // 2. Detección por Hardware (Chipsets conocidos de gama baja / entry level)
        // Helio G35 (mt6765), P22 (mt6762), Unisoc (sc9863a/tiger), etc.
        // El MT676x y Unisoc son el cuello de botella principal en Android económico.
        if (hardware.contains('mt676') || hardware.contains('unisoc') || 
            hardware.contains('sc98') || hardware.contains('exynos850') ||
            hardware.contains('mt6739') || hardware.contains('spreadtrum')) {
          _isLowEnd = true;
          debugPrint('PerformanceGuard: MODO BAJO CONSUMO ACTIVADO (Chipset Limitado: $hardware)');
          return;
        }
        
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        final machine = iosInfo.utsname.machine.toLowerCase();
        // Dispositivos antiguos o con menos de 3GB RAM se consideran bajos para efectos pesados
        if (machine.contains('iphone7,') || machine.contains('iphone8,') || 
            machine.contains('iphone9,') || machine.contains('iphone10,1') || 
            machine.contains('iphone10,4') || machine.contains('ipad4,') || machine.contains('ipad5,')) {
          _isLowEnd = true;
        }
      }
    } catch (e) {
      debugPrint('PerformanceGuard: Error detectando nivel de hardware: $e');
      _isLowEnd = false; 
    }
  }

  /// Widget auxiliar que aplica desenfoque solo si el hardware lo soporta.
  /// Si es gama baja, muestra un fondo sólido con opacidad para ahorrar GPU.
  static Widget adaptiveBlur({
    required Widget child, 
    double sigma = 5, 
    Color? fallbackColor,
    BorderRadius? borderRadius,
  }) {
    final isLow = PerformanceGuard().isLowEnd;
    
    if (isLow) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: Container(
          // Forzar color sólido sin transparencia compleja si es posible
          color: fallbackColor ?? const Color(0xFF121212), 
          child: child,
        ),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Container(
          color: Colors.transparent,
          child: child,
        ),
      ),
    );
  }
}
