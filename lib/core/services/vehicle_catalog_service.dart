import 'package:flutter/material.dart';

class VehicleCatalogService {
  static final VehicleCatalogService _instance = VehicleCatalogService._internal();
  factory VehicleCatalogService() => _instance;
  VehicleCatalogService._internal();

  // --- CAR CATALOG ---
  final Map<String, List<Map<String, String>>> _carCatalog = {
    'TOYOTA': [
      {'modelo': 'Corolla', 'img': 'assets/carros/toyota/corolla.png'},
      {'modelo': 'Hilux', 'img': 'assets/carros/toyota/hilux.png'},
      {'modelo': 'YARIS', 'img': 'assets/carros/toyota/yaris.png'},
      {'modelo': 'YARIS CROSS', 'img': 'assets/carros/toyota/yaris_cross.png'},
      {'modelo': 'TUNDRA', 'img': 'assets/carros/toyota/tundra.png'},
      {'modelo': 'LAND CRUISER 300', 'img': 'assets/carros/toyota/landcruiser300.png'},
      {'modelo': 'HILUX CARGA', 'img': 'assets/carros/toyota/hiluxcarga.png'},
      {'modelo': 'FORTUNER', 'img': 'assets/carros/toyota/fortuner.png'},
      {'modelo': 'COROLLA CROSS', 'img': 'assets/carros/toyota/corolla_cross.png'},
      {'modelo': 'COROLLA CROSS GR-S', 'img': 'assets/carros/toyota/corolla_cross_gr-s.png'},
    ],
    'MAZDA': [
      {'modelo': 'MAZDA 2 HATCHBACK', 'img': 'assets/carros/mazda/mazda2.png'},
      {'modelo': 'MAZDA 2 SEDAN', 'img': 'assets/carros/mazda/mazda2sedan.png'},
      {'modelo': 'MAZDA 3 SEDAN', 'img': 'assets/carros/mazda/mazda3.png'},
    ],
    'CHEVROLET': [
      {'modelo': 'ONIX TURBO RS', 'img': 'assets/carros/chevrolet/jelly-onix-turbo-rs.png'},
      {'modelo': 'ONIX PRIME HB', 'img': 'assets/carros/chevrolet/2022-tambien-onix-turbo-hb.png'},
      {'modelo': 'ONIX TURBO SEDAN', 'img': 'assets/carros/chevrolet/2024-versiones-onix-turbo-ltz-at.png'},
      {'modelo': 'TRACKER RS', 'img': 'assets/carros/chevrolet/tracker-RS.png'},
      {'modelo': 'BLAZER EV RS', 'img': 'assets/carros/chevrolet/BLAZEREV.png'},
      {'modelo': 'EQUINOX RS', 'img': 'assets/carros/chevrolet/equinox-rs-blazer-rs.png'},
      {'modelo': 'TRAVERSE RS', 'img': 'assets/carros/chevrolet/traverse.png'},
      {'modelo': 'BLAZER RS', 'img': 'assets/carros/chevrolet/blazerrs.png'},
      {'modelo': 'MONTANA', 'img': 'assets/carros/chevrolet/Montana.png'},
      {'modelo': 'COLORADO RS', 'img': 'assets/carros/chevrolet/colorado.png'},
      {'modelo': 'SILVERADO', 'img': 'assets/carros/chevrolet/silverado.png'},
    ],
  };

  final Map<String, String> _carLogos = {
    'TOYOTA': 'assets/logos/toyota_logo.png',
    'MAZDA': 'assets/logos/mazda_logo.png',
    'CHEVROLET': 'assets/logos/chevrolet_logo.png',
  };

  // --- MOTO CATALOG ---
  final Map<String, List<Map<String, String>>> _motoCatalog = {
    'YAMAHA': [
      {'modelo': 'MT 15', 'img': 'assets/motos/yamaha/mt15.png'},
      {'modelo': 'R15', 'img': 'assets/motos/yamaha/r15.png'},
      {'modelo': 'FZ 25', 'img': 'assets/motos/yamaha/fz25.png'},
      {'modelo': 'CRYPTON FI', 'img': 'assets/motos/yamaha/cripton.png'},
      {'modelo': 'FZ 2.0', 'img': 'assets/motos/yamaha/fz2.0.png'},
      {'modelo': 'N-MAX', 'img': 'assets/motos/yamaha/nmax.png'},
      {'modelo': 'XTZ 150', 'img': 'assets/motos/yamaha/XTZ150.png'},
    ],
    'SUZUKI': [
      {'modelo': 'Gixxer 150 FI', 'img': 'assets/motos/suzuki/gixxer150.png'},
      {'modelo': 'Gixxer SF 150 FI', 'img': 'assets/motos/suzuki/gixxersf150.png'},
    ],
    'BMW': [
      {'modelo': 'G 310 R', 'img': 'assets/motos/bmw/g310r.png'},
      {'modelo': 'G 310 GS', 'img': 'assets/motos/bmw/g310gs.png'},
      {'modelo': 'F 900 R', 'img': 'assets/motos/bmw/f900r.png'},
    ],
    'KAWASAKI': [
      {'modelo': 'VERSYS 650', 'img': 'assets/motos/kawasaki/versys650.png'},
      {'modelo': 'Ninja 650', 'img': 'assets/motos/kawasaki/ninja650.png'},
      {'modelo': 'Ninja 400', 'img': 'assets/motos/kawasaki/ninja400.png'},
      {'modelo': 'Z 400', 'img': 'assets/motos/kawasaki/z400.png'},
    ],
    'BAJAJ': [
      {'modelo': 'BOXER CT 100 KS', 'img': 'assets/motos/bajaj/boxer-ct100-ks.png'},
      {'modelo': 'BOXER CT 100 ES', 'img': 'assets/motos/bajaj/boxer-ct100.png'},
      {'modelo': 'BOXER CT 125 SPORT', 'img': 'assets/motos/bajaj/boxer-ct-125-sport.png'},
      {'modelo': 'BOXER 150 X', 'img': 'assets/motos/bajaj/boxer-150x.png'},
      {'modelo': 'DOMINAR 400', 'img': 'assets/motos/bajaj/Dominar-400-touring.png'},
      {'modelo': 'PULSAR NS 200 FI ABS', 'img': 'assets/motos/bajaj/pulsar-ns200-fi-abs.png'},
    ],
    'HERO': [
      {'modelo': 'HUNK 160 R', 'img': 'assets/motos/hero/hunk160r.png'},
      {'modelo': 'IGNITOR XTECH', 'img': 'assets/motos/hero/IgnitorXtech.png'},
      {'modelo': 'X PULSE 200 4V', 'img': 'assets/motos/hero/Xpulse2004v.png'},
    ],
    'AKT': [
      {'modelo': 'NKD', 'img': 'assets/motos/akt/NKD.png'},
      {'modelo': 'CR4 150', 'img': 'assets/motos/akt/CR4_150.png'},
    ],
    'KTM': [
      {'modelo': 'DUKE 200', 'img': 'assets/motos/ktm/DUKE-200.png'},
      {'modelo': 'DUKE 390', 'img': 'assets/motos/ktm/KTM-390-DUKE.png'},
      {'modelo': 'ADVENTUR 390', 'img': 'assets/motos/ktm/KTM-390-adv.png'},
    ],
    'VICTORI': [
      {'modelo': 'VENOM 150', 'img': 'assets/motos/victori/victori_venom_150.png'},
    ],
  };

  final Map<String, String> _motoLogos = {
    'YAMAHA': 'assets/logos/yamaha_logo.png',
    'SUZUKI': 'assets/logos/suzuki_logo.png',
    'BMW': 'assets/logos/bmw_logo.png',
    'KAWASAKI': 'assets/logos/kawa_logo.png',
    'KTM': 'assets/logos/ktm_logo.png',
    'BAJAJ': 'assets/logos/bajaj_logo.png',
    'HERO': 'assets/logos/hero_logo.png',
    'AKT': 'assets/logos/akt_logo.png',
    'VICTORI': 'assets/logos/victori_logo.png',
  };

  // --- BRAND COLORS (Shared) ---
  final Map<String, Color> _brandColors = {
    'TOYOTA': const Color(0xFFEB0A1E),
    'MAZDA': const Color(0xFF1B1B1B),
    'CHEVROLET': const Color(0xFFFFC107),
    'YAMAHA': const Color(0xFF0055CC),
    'SUZUKI': const Color(0xFFE30613),
    'BMW': const Color(0xFF2A2A2A),
    'KAWASAKI': const Color(0xFF00A651),
    'KTM': const Color(0xFFFF7B00),
    'BAJAJ': const Color(0xFF006EFF),
    'HERO': Colors.black,
    'AKT': const Color.fromARGB(255, 21, 54, 172),
    'VICTORI': const Color.fromARGB(255, 203, 167, 61),
  };

  // Getters
  Map<String, List<Map<String, String>>> getCarCatalog() => _carCatalog;
  Map<String, String> getCarLogos() => _carLogos;

  Map<String, List<Map<String, String>>> getMotoCatalog() => _motoCatalog;
  Map<String, String> getMotoLogos() => _motoLogos;

  Map<String, Color> getBrandColors() => _brandColors;
}
