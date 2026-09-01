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
      {'modelo': 'DR 150', 'img': 'assets/motos/suzuki/DR.png'},
      {'modelo': 'FLEX 125', 'img': 'assets/motos/suzuki/FLEX.png'},
      {'modelo': 'GSX-R 150', 'img': 'assets/motos/suzuki/gsxr150.png'},
      {'modelo': 'VIVA R STYLE 115', 'img': 'assets/motos/suzuki/vivarstyle115.png'},
      {'modelo': 'GSX-S 150', 'img': 'assets/motos/suzuki/GSX-S150.png'},
      {'modelo': 'GSX-S 1000', 'img': 'assets/motos/suzuki/GSXS1000.png'},
      {'modelo': 'V-STROM 160', 'img': 'assets/motos/suzuki/VSTROM-160.png'},
      {'modelo': 'V-STROM 250 SX', 'img': 'assets/motos/suzuki/VSTROM-250-SX.png'},
      {'modelo': 'GN 125', 'img': 'assets/motos/suzuki/GN125.png'},
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
      {'modelo': 'Z 500', 'img': 'assets/motos/kawasaki/z500.png'},
      {'modelo': 'Z 900', 'img': 'assets/motos/kawasaki/z900.png'},
    ],
    'BAJAJ': [
      {'modelo': 'BOXER CT 100 KS', 'img': 'assets/motos/bajaj/boxer-ct100-ks.png'},
      {'modelo': 'BOXER CT 100 ES', 'img': 'assets/motos/bajaj/boxer-ct100.png'},
      {'modelo': 'BOXER CT 125 SPORT', 'img': 'assets/motos/bajaj/boxer-ct-125-sport.png'},
      {'modelo': 'BOXER 150 X', 'img': 'assets/motos/bajaj/boxer-150x.png'},
      {'modelo': 'BOXER S', 'img': 'assets/motos/bajaj/boxer-s.png'},
      {'modelo': 'DISCOVER 125', 'img': 'assets/motos/bajaj/discover-125.png'},
      {'modelo': 'DOMINAR 250', 'img': 'assets/motos/bajaj/Dominar-250.png'},
      {'modelo': 'DOMINAR 400 TOURING', 'img': 'assets/motos/bajaj/Dominar-400-touring.png'},
      {'modelo': 'DOMINAR 400 VOLCANO', 'img': 'assets/motos/bajaj/dominar400-volcano.png'},
      {'modelo': 'PULSAR N125', 'img': 'assets/motos/bajaj/pulsar-n125.png'},
      {'modelo': 'PULSAR N160 PRO', 'img': 'assets/motos/bajaj/pulsar-n160-pro.png'},
      {'modelo': 'PULSAR N160', 'img': 'assets/motos/bajaj/pulsar-n160.png'},
      {'modelo': 'PULSAR N250', 'img': 'assets/motos/bajaj/Pulsar-N250.png'},
      {'modelo': 'PULSAR NS 125', 'img': 'assets/motos/bajaj/pulsar-ns-125.png'},
      {'modelo': 'PULSAR NS 160 FI', 'img': 'assets/motos/bajaj/pulsar-ns160-fi.png'},
      {'modelo': 'PULSAR NS 160 FI ABS', 'img': 'assets/motos/bajaj/pulsar-ns-160-fi-abs.png'},
      {'modelo': 'PULSAR NS 200 UG', 'img': 'assets/motos/bajaj/pulsar-ns-200-ug.png'},
      {'modelo': 'PULSAR NS 200 FI ABS', 'img': 'assets/motos/bajaj/pulsar-ns200-fi-abs.png'},
      {'modelo': 'PULSAR NS 400Z', 'img': 'assets/motos/bajaj/pulsar-ns400z.png'},
      {'modelo': 'PULSARMANIA', 'img': 'assets/motos/bajaj/pulsarmania.png'},
      {'modelo': 'PULSAR P150', 'img': 'assets/motos/bajaj/Pulsar-p150.png'},
      {'modelo': 'PULSAR RS 200', 'img': 'assets/motos/bajaj/pulsar-rs200.png'},
    ],
    'HERO': [
      {'modelo': 'HUNK 125 R', 'img': 'assets/motos/hero/Hunk125r.png'},
      {'modelo': 'HUNK 150 XT', 'img': 'assets/motos/hero/Hunk150xt.png'},
      {'modelo': 'HUNK 160 R', 'img': 'assets/motos/hero/hunk160r.png'},
      {'modelo': 'HUNK 160 R 4V', 'img': 'assets/motos/hero/Hunk160R4v.png'},
      {'modelo': 'ECO DELUXE', 'img': 'assets/motos/hero/Eco_Deluxe.png'},
      {'modelo': 'ECO T', 'img': 'assets/motos/hero/ECO-T.png'},
      {'modelo': 'ECO 100', 'img': 'assets/motos/hero/Eco100.png'},
      {'modelo': 'ECO DELUXE CLÁSICA', 'img': 'assets/motos/hero/EcoDeluxeClasica.png'},
      {'modelo': 'IGNITOR XTECH', 'img': 'assets/motos/hero/IgnitorXtech.png'},
      {'modelo': 'IGNITOR', 'img': 'assets/motos/hero/Ignitor.png'},
      {'modelo': 'SPLENDOR XPRO', 'img': 'assets/motos/hero/Splendor-Xpro.png'},
      {'modelo': 'DASH 125', 'img': 'assets/motos/hero/Dash125.png'},
      {'modelo': 'XOOM 110', 'img': 'assets/motos/hero/Xoom110.png'},
      {'modelo': 'X PULSE 200 4V', 'img': 'assets/motos/hero/Xpulse2004v.png'},
      {'modelo': 'X PULSE PRO 200 4V', 'img': 'assets/motos/hero/XpulsePro2004v.png'},
      {'modelo': 'X PULSE RALLY', 'img': 'assets/motos/hero/XpulseRally.png'},
    ],
    'AKT': [
      {'modelo': 'NKD 125', 'img': 'assets/motos/akt/NKD.png'},
      {'modelo': 'CR4 150', 'img': 'assets/motos/akt/CR4_150.png'},
      {'modelo': 'CR4 200', 'img': 'assets/motos/akt/CR4_200.png'},
      {'modelo': '250 R', 'img': 'assets/motos/akt/250R.png'},
      {'modelo': 'DINAMIC PRO', 'img': 'assets/motos/akt/dinamicpro.png'},
      {'modelo': 'MAWI 125', 'img': 'assets/motos/akt/mawi.png'},
      {'modelo': 'AKT 190', 'img': 'assets/motos/akt/AKT19O.png'},
    ],
    'KTM': [
      {'modelo': 'DUKE 200', 'img': 'assets/motos/ktm/DUKE-200.png'},
      {'modelo': 'DUKE 250', 'img': 'assets/motos/ktm/KTM-250-DUKE.png'},
      {'modelo': 'DUKE 390', 'img': 'assets/motos/ktm/KTM-390-DUKE.png'},
      {'modelo': 'DUKE 990', 'img': 'assets/motos/ktm/KTM-990-DUKE.png'},
      {'modelo': '1390 SUPER DUKE R 2025', 'img': 'assets/motos/ktm/KTM1390superduke2025.png'},
      {'modelo': 'ADVENTURE 250', 'img': 'assets/motos/ktm/KTM-250-Adventure.png'},
      {'modelo': 'ADVENTURE 390', 'img': 'assets/motos/ktm/KTM-390-adv.png'},
      {'modelo': 'ADVENTURE 390 SW', 'img': 'assets/motos/ktm/KTM-390-adventure.png'},
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
