// =============================================================================
// vehicle_catalog_service.dart — CATÁLOGO COMPLETO DE VEHÍCULOS (AUTOS Y MOTOS)
// =============================================================================
//
// Catálogo integral de marcas, modelos, logos y paletas de color para el
// registro y selección de vehículos en My Auto Guide.
//
// Incluye:
//   - Marcas principales de automóviles organizadas por carpeta de marca.
//   - Marcas principales de motocicletas organizadas por carpeta de marca.
//   - Mapeo de logos locales en alta resolución y resolución dinámica CDN.
// =============================================================================

import 'dart:convert';
import 'package:flutter/material.dart';

class VehicleCatalogService {
  static final VehicleCatalogService _instance =
      VehicleCatalogService._internal();
  factory VehicleCatalogService() => _instance;
  VehicleCatalogService._internal();

  // --- CAR CATALOG (Organizado por carpeta de marca) ---
  final Map<String, List<Map<String, String>>> _carCatalog = {
    'TOYOTA': [
      {'modelo': 'Corolla', 'img': 'assets/carros/toyota/corolla.png'},
      {'modelo': 'Hilux', 'img': 'assets/carros/toyota/hilux.png'},
      {'modelo': 'Yaris', 'img': 'assets/carros/toyota/yaris.png'},
      {'modelo': 'Yaris Cross', 'img': 'assets/carros/toyota/yaris_cross.png'},
      {'modelo': 'Tundra', 'img': 'assets/carros/toyota/tundra.png'},
      {'modelo': 'Land Cruiser 300', 'img': 'assets/carros/toyota/landcruiser300.png'},
      {'modelo': 'Hilux Carga', 'img': 'assets/carros/toyota/hiluxcarga.png'},
      {'modelo': 'Fortuner', 'img': 'assets/carros/toyota/fortuner.png'},
      {'modelo': 'Corolla Cross', 'img': 'assets/carros/toyota/corolla_cross.png'},
      {'modelo': 'Corolla Cross GR-S', 'img': 'assets/carros/toyota/corolla_cross_gr-s.png'},
    ],
    'CHEVROLET': [
      {'modelo': 'Onix Turbo RS', 'img': 'assets/carros/chevrolet/jelly-onix-turbo-rs.png'},
      {'modelo': 'Onix Prime HB', 'img': 'assets/carros/chevrolet/2022-tambien-onix-turbo-hb.png'},
      {'modelo': 'Onix Turbo Sedan', 'img': 'assets/carros/chevrolet/2024-versiones-onix-turbo-ltz-at.png'},
      {'modelo': 'Tracker RS', 'img': 'assets/carros/chevrolet/tracker-RS.png'},
      {'modelo': 'Spark EUV', 'img': 'assets/carros/chevrolet/SparkEUV.png'},
      {'modelo': 'Blazer EV RS', 'img': 'assets/carros/chevrolet/BLAZEREV.png'},
      {'modelo': 'Equinox RS', 'img': 'assets/carros/chevrolet/equinox-rs-blazer-rs.png'},
      {'modelo': 'Traverse RS', 'img': 'assets/carros/chevrolet/traverse.png'},
      {'modelo': 'Blazer RS', 'img': 'assets/carros/chevrolet/blazerrs.png'},
      {'modelo': 'Montana', 'img': 'assets/carros/chevrolet/Montana.png'},
      {'modelo': 'Colorado RS', 'img': 'assets/carros/chevrolet/colorado.png'},
      {'modelo': 'Silverado', 'img': 'assets/carros/chevrolet/silverado.png'},
    ],
    'RENAULT': [
      {'modelo': 'Duster', 'img': 'assets/carros/renault/duster.png'},
      {'modelo': 'Sandero', 'img': 'assets/carros/renault/sandero.png'},
      {'modelo': 'Stepway', 'img': 'assets/carros/renault/stepway.png'},
      {'modelo': 'Logan', 'img': 'assets/carros/renault/logan.png'},
      {'modelo': 'Kwid', 'img': 'assets/carros/renault/kwid.png'},
      {'modelo': 'Kardian', 'img': 'assets/carros/renault/kardian.png'},
      {'modelo': 'Oroch', 'img': 'assets/carros/renault/oroch.png'},
    ],
    'MAZDA': [
      {'modelo': 'Mazda 2 Hatchback', 'img': 'assets/carros/mazda/mazda2.png'},
      {'modelo': 'Mazda 2 Sedan', 'img': 'assets/carros/mazda/mazda2sedan.png'},
      {'modelo': 'Mazda 3 Sedan', 'img': 'assets/carros/mazda/mazda3.png'},
      {'modelo': 'CX-30 Grand Touring', 'img': 'assets/carros/mazda/mazda2.png'},
      {'modelo': 'CX-50 Grand Touring', 'img': 'assets/carros/mazda/mazda3.png'},
    ],
    'NISSAN': [
      {'modelo': 'Versa', 'img': 'assets/carros/nissan/versa.png'},
      {'modelo': 'Kicks', 'img': 'assets/carros/nissan/kicks.png'},
      {'modelo': 'Sentra', 'img': 'assets/carros/nissan/sentra.png'},
      {'modelo': 'Frontier', 'img': 'assets/carros/nissan/frontier.png'},
      {'modelo': 'Qashqai', 'img': 'assets/carros/nissan/qashqai.png'},
      {'modelo': 'X-Trail', 'img': 'assets/carros/nissan/x-trail.png'},
    ],
    'KIA': [
      {'modelo': 'Picanto', 'img': 'assets/carros/kia/picanto.png'},
      {'modelo': 'Rio', 'img': 'assets/carros/kia/rio.png'},
      {'modelo': 'Sonet', 'img': 'assets/carros/kia/sonet.png'},
      {'modelo': 'Seltos', 'img': 'assets/carros/kia/seltos.png'},
      {'modelo': 'Sportage', 'img': 'assets/carros/kia/sportage.png'},
    ],
    'HYUNDAI': [
      {'modelo': 'HB20', 'img': 'assets/carros/hyundai/hb20.png'},
      {'modelo': 'Creta', 'img': 'assets/carros/hyundai/creta.png'},
      {'modelo': 'Tucson', 'img': 'assets/carros/hyundai/tucson.png'},
      {'modelo': 'Santa Fe', 'img': 'assets/carros/hyundai/santa_fe.png'},
      {'modelo': 'Kona', 'img': 'assets/carros/hyundai/kona.png'},
    ],
    'VOLKSWAGEN': [
      {'modelo': 'Polo', 'img': 'assets/carros/volkswagen/polo.png'},
      {'modelo': 'Virtus', 'img': 'assets/carros/volkswagen/virtus.png'},
      {'modelo': 'Nivus', 'img': 'assets/carros/volkswagen/nivus.png'},
      {'modelo': 'T-Cross', 'img': 'assets/carros/volkswagen/t-cross.png'},
      {'modelo': 'Taos', 'img': 'assets/carros/volkswagen/taos.png'},
      {'modelo': 'Amarok', 'img': 'assets/carros/volkswagen/amarok.png'},
      {'modelo': 'Golf', 'img': 'assets/carros/volkswagen/golf.png'},
    ],
    'FORD': [
      {'modelo': 'Ranger', 'img': 'assets/carros/ford/ranger.png'},
      {'modelo': 'F-150', 'img': 'assets/carros/ford/f-150.png'},
      {'modelo': 'Escape', 'img': 'assets/carros/ford/escape.png'},
      {'modelo': 'Explorer', 'img': 'assets/carros/ford/explorer.png'},
      {'modelo': 'Bronco Sport', 'img': 'assets/carros/ford/bronco_sport.png'},
      {'modelo': 'Mustang', 'img': 'assets/carros/ford/mustang.png'},
    ],
    'SUZUKI': [
      {'modelo': 'Swift', 'img': 'assets/carros/suzuki/swift.png'},
      {'modelo': 'Jimny', 'img': 'assets/carros/suzuki/jimny.png'},
      {'modelo': 'Grand Vitara', 'img': 'assets/carros/suzuki/grand_vitara.png'},
      {'modelo': 'Fronx', 'img': 'assets/carros/suzuki/fronx.png'},
    ],
    'HONDA': [
      {'modelo': 'Civic', 'img': 'assets/carros/honda/civic.png'},
      {'modelo': 'CR-V', 'img': 'assets/carros/honda/cr-v.png'},
      {'modelo': 'HR-V', 'img': 'assets/carros/honda/hr-v.png'},
      {'modelo': 'City', 'img': 'assets/carros/honda/city.png'},
    ],
    'BMW': [
      {'modelo': 'Serie 3', 'img': 'assets/carros/bmw/serie_3.png'},
      {'modelo': 'X1', 'img': 'assets/carros/bmw/x1.png'},
      {'modelo': 'X3', 'img': 'assets/carros/bmw/x3.png'},
      {'modelo': 'X5', 'img': 'assets/carros/bmw/x5.png'},
    ],
    'MERCEDES-BENZ': [
      {'modelo': 'Clase A', 'img': 'assets/carros/mercedes-benz/clase_a.png'},
      {'modelo': 'GLA', 'img': 'assets/carros/mercedes-benz/gla.png'},
      {'modelo': 'GLC', 'img': 'assets/carros/mercedes-benz/glc.png'},
    ],
    'AUDI': [
      {'modelo': 'A3', 'img': 'assets/carros/audi/a3.png'},
      {'modelo': 'A4', 'img': 'assets/carros/audi/a4.png'},
      {'modelo': 'Q3', 'img': 'assets/carros/audi/q3.png'},
      {'modelo': 'Q5', 'img': 'assets/carros/audi/q5.png'},
    ],
    'JEEP': [
      {'modelo': 'Renegade', 'img': 'assets/carros/jeep/renegade.png'},
      {'modelo': 'Compass', 'img': 'assets/carros/jeep/compass.png'},
      {'modelo': 'Wrangler', 'img': 'assets/carros/jeep/wrangler.png'},
      {'modelo': 'Grand Cherokee', 'img': 'assets/carros/jeep/grand_cherokee.png'},
    ],
    'BYD': [
      {'modelo': 'Dolphin', 'img': 'assets/carros/byd/dolphin.png'},
      {'modelo': 'Song Plus', 'img': 'assets/carros/byd/song_plus.png'},
      {'modelo': 'Yuan Plus', 'img': 'assets/carros/byd/yuan_plus.png'},
      {'modelo': 'Seal', 'img': 'assets/carros/byd/seal.png'},
    ],
  };

  final Map<String, String> _carLogos = {
    'TOYOTA': 'assets/logos/toyota_logo.png',
    'CHEVROLET': 'assets/logos/chevrolet_logo.png',
    'RENAULT': 'assets/logos/renault_logo.png',
    'MAZDA': 'assets/logos/mazda_logo.png',
    'NISSAN': 'assets/logos/nissan_logo.png',
    'KIA': 'assets/logos/kia_logo.png',
    'HYUNDAI': 'assets/logos/hyundai_logo.png',
    'VOLKSWAGEN': 'assets/logos/volkswagen_logo.png',
    'FORD': 'assets/logos/ford_logo.png',
    'SUZUKI': 'assets/logos/suzuki_logo.png',
    'HONDA': 'assets/logos/honda_logo.png',
    'BMW': 'assets/logos/bmw_logo.png',
    'MERCEDES-BENZ': 'assets/logos/mercedes_logo.png',
    'AUDI': 'assets/logos/audi_logo.png',
    'JEEP': 'assets/logos/jeep_logo.png',
    'BYD': 'assets/logos/byd_logo.png',
  };

  // --- MOTO CATALOG (Organizado por carpeta de marca) ---
  final Map<String, List<Map<String, String>>> _motoCatalog = {
    'YAMAHA': [
      {'modelo': 'MT 15', 'img': 'assets/motos/yamaha/mt15.png'},
      {'modelo': 'R15 V4 / V3', 'img': 'assets/motos/yamaha/r15.png'},
      {'modelo': 'FZ 25', 'img': 'assets/motos/yamaha/fz25.png'},
      {'modelo': 'FZ 2.0 FI', 'img': 'assets/motos/yamaha/fz2.0.png'},
      {'modelo': 'Crypton FI 115', 'img': 'assets/motos/yamaha/cripton.png'},
      {'modelo': 'N-MAX Connected 155', 'img': 'assets/motos/yamaha/nmax.png'},
      {'modelo': 'XTZ 150 Crosser', 'img': 'assets/motos/yamaha/XTZ150.png'},
    ],
    'BAJAJ': [
      {'modelo': 'Pulsar NS 200 FI ABS', 'img': 'assets/motos/bajaj/pulsar-ns200-fi-abs.png'},
      {'modelo': 'Pulsar NS 200 UG', 'img': 'assets/motos/bajaj/pulsar-ns-200-ug.png'},
      {'modelo': 'Pulsar NS 160 FI ABS', 'img': 'assets/motos/bajaj/pulsar-ns-160-fi-abs.png'},
      {'modelo': 'Pulsar NS 160 FI', 'img': 'assets/motos/bajaj/pulsar-ns160-fi.png'},
      {'modelo': 'Pulsar NS 125', 'img': 'assets/motos/bajaj/pulsar-ns-125.png'},
      {'modelo': 'Pulsar N 250', 'img': 'assets/motos/bajaj/Pulsar-N250.png'},
      {'modelo': 'Pulsar N 160 Pro', 'img': 'assets/motos/bajaj/pulsar-n160-pro.png'},
      {'modelo': 'Pulsar N 160', 'img': 'assets/motos/bajaj/pulsar-n160.png'},
      {'modelo': 'Pulsar N 125', 'img': 'assets/motos/bajaj/pulsar-n125.png'},
      {'modelo': 'Pulsar RS 200', 'img': 'assets/motos/bajaj/pulsar-rs200.png'},
      {'modelo': 'Pulsar NS 400Z', 'img': 'assets/motos/bajaj/pulsar-ns400z.png'},
      {'modelo': 'Pulsar P 150', 'img': 'assets/motos/bajaj/Pulsar-p150.png'},
      {'modelo': 'Dominar 400 Touring', 'img': 'assets/motos/bajaj/Dominar-400-touring.png'},
      {'modelo': 'Dominar 400 Volcano', 'img': 'assets/motos/bajaj/dominar400-volcano.png'},
      {'modelo': 'Dominar 250', 'img': 'assets/motos/bajaj/Dominar-250.png'},
      {'modelo': 'Boxer CT 100 KS', 'img': 'assets/motos/bajaj/boxer-ct100-ks.png'},
      {'modelo': 'Boxer CT 100 ES', 'img': 'assets/motos/bajaj/boxer-ct100.png'},
      {'modelo': 'Boxer CT 125 Sport', 'img': 'assets/motos/bajaj/boxer-ct-125-sport.png'},
      {'modelo': 'Boxer 150 X', 'img': 'assets/motos/bajaj/boxer-150x.png'},
      {'modelo': 'Boxer S', 'img': 'assets/motos/bajaj/boxer-s.png'},
      {'modelo': 'Discover 125 ST', 'img': 'assets/motos/bajaj/discover-125.png'},
    ],
    'SUZUKI': [
      {'modelo': 'Gixxer 150 FI', 'img': 'assets/motos/suzuki/gixxer150.png'},
      {'modelo': 'Gixxer SF 150 FI', 'img': 'assets/motos/suzuki/gixxersf150.png'},
    ],
    'KTM': [
      {'modelo': 'Duke 200 NG', 'img': 'assets/motos/ktm/DUKE-200.png'},
      {'modelo': 'Duke 250 ABS', 'img': 'assets/motos/ktm/KTM-250-DUKE.png'},
      {'modelo': 'Duke 390 ABS', 'img': 'assets/motos/ktm/KTM-390-DUKE.png'},
      {'modelo': 'Duke 990', 'img': 'assets/motos/ktm/KTM-990-DUKE.png'},
      {'modelo': '1390 Super Duke R', 'img': 'assets/motos/ktm/KTM1390superduke2025.png'},
      {'modelo': 'Adventure 250', 'img': 'assets/motos/ktm/KTM-250-Adventure.png'},
      {'modelo': 'Adventure 390', 'img': 'assets/motos/ktm/KTM-390-adv.png'},
      {'modelo': 'Adventure 390 SW', 'img': 'assets/motos/ktm/KTM-390-adventure.png'},
    ],
    'HERO': [
      {'modelo': 'Hunk 160 R 4V', 'img': 'assets/motos/hero/Hunk160R4v.png'},
      {'modelo': 'Hunk 160 R', 'img': 'assets/motos/hero/hunk160r.png'},
      {'modelo': 'Hunk 150 XT', 'img': 'assets/motos/hero/Hunk150xt.png'},
      {'modelo': 'Hunk 125 R', 'img': 'assets/motos/hero/Hunk125r.png'},
      {'modelo': 'XPulse 200 4V', 'img': 'assets/motos/hero/Xpulse2004v.png'},
      {'modelo': 'XPulse 200 4V Pro', 'img': 'assets/motos/hero/XpulsePro2004v.png'},
      {'modelo': 'XPulse Rally Edition', 'img': 'assets/motos/hero/XpulseRally.png'},
      {'modelo': 'Eco Deluxe Clásica', 'img': 'assets/motos/hero/EcoDeluxeClasica.png'},
      {'modelo': 'Eco Deluxe i3S', 'img': 'assets/motos/hero/Eco_Deluxe.png'},
      {'modelo': 'ECO 100', 'img': 'assets/motos/hero/Eco100.png'},
      {'modelo': 'ECO-T', 'img': 'assets/motos/hero/ECO-T.png'},
      {'modelo': 'Ignitor Xtech 125', 'img': 'assets/motos/hero/IgnitorXtech.png'},
      {'modelo': 'Splendor Xpro', 'img': 'assets/motos/hero/Splendor-Xpro.png'},
      {'modelo': 'Xoom 110 Scooter', 'img': 'assets/motos/hero/Xoom110.png'},
    ],
    'AKT': [
      {'modelo': 'NKD 125', 'img': 'assets/motos/akt/NKD.png'},
      {'modelo': 'CR4 150', 'img': 'assets/motos/akt/CR4_150.png'},
      {'modelo': 'CR4 200 Pro', 'img': 'assets/motos/akt/CR4_200.png'},
      {'modelo': '250 R Naked', 'img': 'assets/motos/akt/250R.png'},
      {'modelo': 'Dynamic Pro 125', 'img': 'assets/motos/akt/dinamicpro.png'},
      {'modelo': 'Mawi 125 Scooter', 'img': 'assets/motos/akt/mawi.png'},
    ],
    'KAWASAKI': [
      {'modelo': 'Ninja 400 ABS', 'img': 'assets/motos/kawasaki/ninja400.png'},
      {'modelo': 'Ninja 650 ABS', 'img': 'assets/motos/kawasaki/ninja650.png'},
      {'modelo': 'Z 400 ABS', 'img': 'assets/motos/kawasaki/z400.png'},
      {'modelo': 'Versys 650 ABS', 'img': 'assets/motos/kawasaki/versys650.png'},
    ],
    'BMW': [
      {'modelo': 'G 310 R', 'img': 'assets/motos/bmw/g310r.png'},
      {'modelo': 'G 310 GS', 'img': 'assets/motos/bmw/g310gs.png'},
      {'modelo': 'F 900 R', 'img': 'assets/motos/bmw/f900r.png'},
    ],
    'HONDA': [
      {'modelo': 'Africa Twin CRF1100L', 'img': 'assets/motos/honda/africa_twin_crf1100l.png'},
      {'modelo': 'CB 125F', 'img': 'assets/motos/honda/cb_125f.png'},
      {'modelo': 'CB 300F Twister', 'img': 'assets/motos/honda/cb_300f_twister.png'},
      {'modelo': 'XR 150L', 'img': 'assets/motos/honda/xr_150l.png'},
      {'modelo': 'XRE 300 Rally', 'img': 'assets/motos/honda/xre_300_rally.png'},
      {'modelo': 'Transalp XL750', 'img': 'assets/motos/honda/transalp_xl750.png'},
      {'modelo': 'Navi 110', 'img': 'assets/motos/honda/navi_110.png'},
      {'modelo': 'PCX 160', 'img': 'assets/motos/honda/pcx_160.png'},
      {'modelo': 'CB 650R', 'img': 'assets/motos/honda/cb_650r.png'},
      {'modelo': 'CBR 650R', 'img': 'assets/motos/honda/cbr_650r.png'},
    ],
    'DUCATI': [
      {'modelo': 'Monster 937', 'img': 'assets/motos/ducati/monster_937.png'},
      {'modelo': 'Panigale V4', 'img': 'assets/motos/ducati/panigale_v4.png'},
      {'modelo': 'Panigale V2', 'img': 'assets/motos/ducati/panigale_v2.png'},
      {'modelo': 'Multistrada V4', 'img': 'assets/motos/ducati/multistrada_v4.png'},
      {'modelo': 'Scrambler Icon', 'img': 'assets/motos/ducati/scrambler_icon.png'},
      {'modelo': 'DesertX', 'img': 'assets/motos/ducati/desertx.png'},
      {'modelo': 'Diavel V4', 'img': 'assets/motos/ducati/diavel_v4.png'},
      {'modelo': 'Streetfighter V4', 'img': 'assets/motos/ducati/streetfighter_v4.png'},
    ],
    'TRIUMPH': [
      {'modelo': 'Speed 400', 'img': 'assets/motos/triumph/speed_400.png'},
      {'modelo': 'Trident 660', 'img': 'assets/motos/triumph/trident_660.png'},
      {'modelo': 'Street Triple 765', 'img': 'assets/motos/triumph/street_triple_765.png'},
      {'modelo': 'Tiger 900 Rally', 'img': 'assets/motos/triumph/tiger_900_rally.png'},
      {'modelo': 'Tiger 1200', 'img': 'assets/motos/triumph/tiger_1200.png'},
      {'modelo': 'Bonneville T120', 'img': 'assets/motos/triumph/bonneville_t120.png'},
      {'modelo': 'Rocket 3', 'img': 'assets/motos/triumph/rocket_3.png'},
    ],
    'ROYAL ENFIELD': [
      {'modelo': 'Himalayan 450', 'img': 'assets/motos/royal_enfield/himalayan_450.png'},
      {'modelo': 'Classic 350', 'img': 'assets/motos/royal_enfield/classic_350.png'},
      {'modelo': 'Meteor 350', 'img': 'assets/motos/royal_enfield/meteor_350.png'},
      {'modelo': 'Interceptor 650', 'img': 'assets/motos/royal_enfield/interceptor_650.png'},
      {'modelo': 'Continental GT 650', 'img': 'assets/motos/royal_enfield/continental_gt_650.png'},
      {'modelo': 'Super Meteor 650', 'img': 'assets/motos/royal_enfield/super_meteor_650.png'},
      {'modelo': 'Hunter 350', 'img': 'assets/motos/royal_enfield/hunter_350.png'},
    ],
    'HARLEY-DAVIDSON': [
      {'modelo': 'Fat Boy', 'img': 'assets/motos/harley_davidson/fat_boy.png'},
      {'modelo': 'Road Glide Special', 'img': 'assets/motos/harley_davidson/road_glide_special.png'},
      {'modelo': 'Breakout 117', 'img': 'assets/motos/harley_davidson/breakout_117.png'},
    ],
    'SYM': [
      {'modelo': 'Crox 125', 'img': 'assets/motos/sym/crox_125.png'},
      {'modelo': 'NH Trazer 200', 'img': 'assets/motos/sym/nh_trazer_200.png'},
      {'modelo': 'Citycom 300i', 'img': 'assets/motos/sym/citycom_300i.png'},
    ],
    'KYMCO': [
      {'modelo': 'Agility 125', 'img': 'assets/motos/kymco/agility_125.png'},
      {'modelo': 'AK 550 Maxi Scooter', 'img': 'assets/motos/kymco/ak_550_maxi_scooter.png'},
    ],
    'VESPA': [
      {'modelo': 'Sprint 150', 'img': 'assets/motos/vespa/sprint_150.png'},
    ],
    'VICTORI': [
      {'modelo': 'Venom 150', 'img': 'assets/motos/victori/victori_venom_150.png'},
    ],
  };

  final Map<String, String> _motoLogos = {
    'YAMAHA': 'assets/logos/yamaha_logo.png',
    'SUZUKI': 'assets/logos/suzuki_logo.png',
    'BAJAJ': 'assets/logos/bajaj_logo.png',
    'KTM': 'assets/logos/ktm_logo.png',
    'HERO': 'assets/logos/hero_logo.png',
    'AKT': 'assets/logos/akt_logo.png',
    'KAWASAKI': 'assets/logos/kawa_logo.png',
    'BMW': 'assets/logos/bmw_logo.png',
    'HONDA': 'assets/logos/honda_logo.png',
    'DUCATI': 'assets/logos/ducati_logo.png',
    'VICTORI': 'assets/logos/victori_logo.png',
    'TRIUMPH': 'assets/logos/triumph_logo.png',
    'ROYAL ENFIELD': 'assets/logos/royal-enfield.png',
    'HARLEY-DAVIDSON': 'assets/logos/harley_davidson_logo.png',
    'SYM': 'assets/logos/sym.png',
    'KYMCO': 'assets/logos/kymco.png',
    'VESPA': 'assets/logos/vespa.png',
  };

  // --- BRAND COLORS (Shared) ---
  final Map<String, Color> _brandColors = {
    // Autos
    'TOYOTA': const Color(0xFFEB0A1E),
    'CHEVROLET': const Color(0xFFFFC107),
    'RENAULT': const Color(0xFFFFCC00),
    'MAZDA': const Color(0xFF990000),
    'NISSAN': const Color(0xFFC3002F),
    'KIA': const Color(0xFF05141F),
    'HYUNDAI': const Color(0xFF002C6C),
    'VOLKSWAGEN': const Color(0xFF001E50),
    'FORD': const Color(0xFF003478),
    'AUDI': const Color(0xFFBB0A30),
    'MERCEDES-BENZ': const Color(0xFF00ADEF),
    'JEEP': const Color(0xFF53565A),
    'BYD': const Color(0xFF1E88E5),
    'MITSUBISHI': const Color(0xFFE60012),
    'PEUGEOT': const Color(0xFF003865),
    'FIAT': const Color(0xFF900028),
    // Motos
    'YAMAHA': const Color(0xFF0055CC),
    'SUZUKI': const Color(0xFFE30613),
    'BAJAJ': const Color(0xFF006EFF),
    'KTM': const Color(0xFFFF6600),
    'HERO': const Color(0xFFED1C24),
    'AKT': const Color(0xFF1536AC),
    'KAWASAKI': const Color(0xFF00A651),
    'BMW': const Color(0xFF0066B1),
    'HONDA': const Color(0xFFCC0000),
    'DUCATI': const Color(0xFFCC0000),
    'VICTORI': const Color(0xFFCBA73D),
    'TRIUMPH': const Color(0xFF222222),
    'ROYAL ENFIELD': const Color(0xFF990000),
  };

  // Getters
  Map<String, List<Map<String, String>>> getCarCatalog() => _carCatalog;
  Map<String, String> getCarLogos() => _carLogos;

  Map<String, List<Map<String, String>>> getMotoCatalog() => _motoCatalog;
  Map<String, String> getMotoLogos() => _motoLogos;

  Map<String, Color> getBrandColors() => _brandColors;

  Map<String, String> _cachedImages = {};
  bool _hasLoadedImages = false;

  /// Carga en memoria el diccionario de imágenes reales de vehículos
  Future<void> loadCachedImages(BuildContext context) async {
    if (_hasLoadedImages) return;
    try {
      final jsonStr = await DefaultAssetBundle.of(context)
          .loadString('assets/data/vehicle_images.json');
      final Map<String, dynamic> decoded = json.decode(jsonStr);
      _cachedImages = decoded.map((k, v) => MapEntry(k, v.toString()));
      _hasLoadedImages = true;
    } catch (_) {
      // Continua silenciosamente
    }
  }

  /// Obtiene la URL o asset del logo de cualquier marca (Carro o Moto)
  String getLogoForBrand(String brand) {
    final upper = brand.trim().toUpperCase();
    if (_motoLogos.containsKey(upper)) return _motoLogos[upper]!;
    if (_carLogos.containsKey(upper)) return _carLogos[upper]!;

    final slug = brand
        .trim()
        .toLowerCase()
        .replaceAll(' ', '-')
        .replaceAll('_', '-');

    return 'assets/logos/$slug.png';
  }

  /// Retorna el color insignia de la marca
  Color getColorForBrand(String brand) {
    final upper = brand.trim().toUpperCase();
    return _brandColors[upper] ?? const Color(0xFF035880);
  }

  /// Retorna la URL o ruta local de imagen de un vehículo
  String getImageForVehicle(String make, String model, {bool isMoto = false}) {
    // 1. Buscar en catálogo local organizado por carpetas
    final catalog = isMoto ? _motoCatalog : _carCatalog;
    final upperMake = make.trim().toUpperCase();
    if (catalog.containsKey(upperMake)) {
      final match = catalog[upperMake]!.firstWhere(
        (m) => (m['modelo'] ?? '').toUpperCase() == model.trim().toUpperCase(),
        orElse: () => const {},
      );
      if (match.isNotEmpty && match['img'] != null && match['img'] != 'assets/car.png') {
        return match['img']!;
      }
    }

    // 2. Buscar en caché dinámica descargada
    final key = '${make.trim()} ${model.trim()}'.toUpperCase();
    if (_cachedImages.containsKey(key) && _cachedImages[key]!.isNotEmpty) {
      return _cachedImages[key]!;
    }

    return isMoto ? 'assets/motos/yamaha/mt15.png' : 'assets/car.png';
  }
}
