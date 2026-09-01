// =============================================================================
// vehicle_catalog_service.dart — CATÁLOGO COMPLETO DE VEHÍCULOS (AUTOS Y MOTOS)
// =============================================================================
//
// Catálogo integral de marcas, modelos, logos y paletas de color para el
// registro y selección de vehículos en My Auto Guide.
//
// Incluye:
//   - Marcas principales de automóviles (Toyota, Chevrolet, Renault, Mazda, Nissan,
//     Kia, Hyundai, Volkswagen, Ford, Audi, Mercedes, Jeep, BYD, etc.)
//   - Marcas principales de motocicletas (Yamaha, Suzuki, Bajaj, KTM, Kawasaki,
//     BMW, Hero, AKT, Honda, Ducati, Victori, Triumph, etc.)
//   - Mapeo de logos locales en alta resolución y resolución dinámica CDN.
// =============================================================================

import 'package:flutter/material.dart';

class VehicleCatalogService {
  static final VehicleCatalogService _instance =
      VehicleCatalogService._internal();
  factory VehicleCatalogService() => _instance;
  VehicleCatalogService._internal();

  // --- CAR CATALOG ---
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
      {'modelo': 'RAV4 Hybrid', 'img': 'assets/carros/toyota/corolla_cross.png'},
      {'modelo': 'Prado TXL', 'img': 'assets/carros/toyota/landcruiser300.png'},
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
      {'modelo': 'Captiva Turbo', 'img': 'assets/carros/chevrolet/tracker-RS.png'},
    ],
    'RENAULT': [
      {'modelo': 'Duster Turbo', 'img': 'assets/car.png'},
      {'modelo': 'Sandero Life/Zen', 'img': 'assets/car.png'},
      {'modelo': 'Stepway Intens', 'img': 'assets/car.png'},
      {'modelo': 'Logan Intens', 'img': 'assets/car.png'},
      {'modelo': 'Kwid Outsider', 'img': 'assets/car.png'},
      {'modelo': 'Kwid E-Tech 100% Eléctrico', 'img': 'assets/car.png'},
      {'modelo': 'Kardian Premiere Edition', 'img': 'assets/car.png'},
      {'modelo': 'Oroch Pick-up', 'img': 'assets/car.png'},
      {'modelo': 'Megane E-Tech', 'img': 'assets/car.png'},
      {'modelo': 'Master Furgón', 'img': 'assets/furgon.png'},
    ],
    'MAZDA': [
      {'modelo': 'Mazda 2 Hatchback', 'img': 'assets/carros/mazda/mazda2.png'},
      {'modelo': 'Mazda 2 Sedan', 'img': 'assets/carros/mazda/mazda2sedan.png'},
      {'modelo': 'Mazda 3 Sedan', 'img': 'assets/carros/mazda/mazda3.png'},
      {'modelo': 'Mazda 3 Hatchback', 'img': 'assets/carros/mazda/mazda3.png'},
      {'modelo': 'CX-30 Grand Touring', 'img': 'assets/carros/mazda/mazda2.png'},
      {'modelo': 'CX-50 Grand Touring', 'img': 'assets/carros/mazda/mazda3.png'},
      {'modelo': 'CX-60 Mild Hybrid', 'img': 'assets/carros/mazda/mazda2sedan.png'},
      {'modelo': 'CX-90 Signature', 'img': 'assets/carros/mazda/mazda3.png'},
    ],
    'NISSAN': [
      {'modelo': 'Versa Sense / Advance', 'img': 'assets/car.png'},
      {'modelo': 'Kicks Advance / Exclusive', 'img': 'assets/car.png'},
      {'modelo': 'Sentra SR', 'img': 'assets/car.png'},
      {'modelo': 'Frontier Pro-4X', 'img': 'assets/car.png'},
      {'modelo': 'Qashqai Exclusive AWD', 'img': 'assets/car.png'},
      {'modelo': 'X-Trail e-POWER', 'img': 'assets/car.png'},
      {'modelo': 'Patrol King Off-Road', 'img': 'assets/car.png'},
      {'modelo': 'Urvan Microbus', 'img': 'assets/bus.png'},
    ],
    'KIA': [
      {'modelo': 'Picanto Vibrant / Zenith', 'img': 'assets/car.png'},
      {'modelo': 'Rio Sedan / Hatchback', 'img': 'assets/car.png'},
      {'modelo': 'K3 Sedan / Cross', 'img': 'assets/car.png'},
      {'modelo': 'Sonet Zenith', 'img': 'assets/car.png'},
      {'modelo': 'Seltos Emotion / Zenith', 'img': 'assets/car.png'},
      {'modelo': 'Sportage GT-Line', 'img': 'assets/car.png'},
      {'modelo': 'Sorento Híbrida', 'img': 'assets/car.png'},
      {'modelo': 'EV6 GT-Line Eléctrico', 'img': 'assets/car.png'},
      {'modelo': 'EV9 GT Eléctrico', 'img': 'assets/car.png'},
    ],
    'HYUNDAI': [
      {'modelo': 'Grand i10 HB / Sedan', 'img': 'assets/car.png'},
      {'modelo': 'HB20 Getz / Accent', 'img': 'assets/car.png'},
      {'modelo': 'Creta Premium', 'img': 'assets/car.png'},
      {'modelo': 'Tucson Limited AWD', 'img': 'assets/car.png'},
      {'modelo': 'Santa Fe Limited', 'img': 'assets/car.png'},
      {'modelo': 'Kona Híbrida / Eléctrica', 'img': 'assets/car.png'},
      {'modelo': 'Ioniq 5 EV', 'img': 'assets/car.png'},
      {'modelo': 'Palisade 4WD', 'img': 'assets/car.png'},
    ],
    'VOLKSWAGEN': [
      {'modelo': 'Polo Track / Highline', 'img': 'assets/car.png'},
      {'modelo': 'Virtus Comfortline', 'img': 'assets/car.png'},
      {'modelo': 'Nivus Highline', 'img': 'assets/car.png'},
      {'modelo': 'T-Cross Trendline / Highline', 'img': 'assets/car.png'},
      {'modelo': 'Taos Highline', 'img': 'assets/car.png'},
      {'modelo': 'Tiguan Elegance', 'img': 'assets/car.png'},
      {'modelo': 'Amarok V6 Extreme', 'img': 'assets/car.png'},
      {'modelo': 'Golf GTI', 'img': 'assets/car.png'},
      {'modelo': 'Crafter Furgón', 'img': 'assets/furgon.png'},
    ],
    'FORD': [
      {'modelo': 'Ranger XLT / Limited / Raptor', 'img': 'assets/car.png'},
      {'modelo': 'F-150 Lariat / Raptor', 'img': 'assets/car.png'},
      {'modelo': 'Escape Titanium Híbrida', 'img': 'assets/car.png'},
      {'modelo': 'Explorer Limited / ST', 'img': 'assets/car.png'},
      {'modelo': 'Bronco Sport / Badlands', 'img': 'assets/car.png'},
      {'modelo': 'Mustang GT / Dark Horse', 'img': 'assets/car.png'},
      {'modelo': 'Transit Furgón', 'img': 'assets/furgon.png'},
    ],
    'SUZUKI': [
      {'modelo': 'Swift Híbrido Sedan / HB', 'img': 'assets/car.png'},
      {'modelo': 'Jimny GLX / 5 Puertas', 'img': 'assets/car.png'},
      {'modelo': 'Grand Vitara Boostergreen', 'img': 'assets/car.png'},
      {'modelo': 'Fronx Boostergreen', 'img': 'assets/car.png'},
      {'modelo': 'S-Presso', 'img': 'assets/car.png'},
      {'modelo': 'Ertiga Híbrida 7 Pasajeros', 'img': 'assets/bus.png'},
    ],
    'HONDA': [
      {'modelo': 'Civic e:HEV Híbrido', 'img': 'assets/car.png'},
      {'modelo': 'CR-V Advance / Touring', 'img': 'assets/car.png'},
      {'modelo': 'HR-V Uniq / Prestige', 'img': 'assets/car.png'},
      {'modelo': 'ZR-V Touring', 'img': 'assets/car.png'},
      {'modelo': 'Pilot Touring 4WD', 'img': 'assets/car.png'},
      {'modelo': 'City Sedan / Hatchback', 'img': 'assets/car.png'},
    ],
    'BMW': [
      {'modelo': 'Serie 1 (118i / 128ti)', 'img': 'assets/car.png'},
      {'modelo': 'Serie 2 Gran Coupé', 'img': 'assets/car.png'},
      {'modelo': 'Serie 3 (320i / 330e Híbrido)', 'img': 'assets/car.png'},
      {'modelo': 'Serie 4 Gran Coupé / M4', 'img': 'assets/car.png'},
      {'modelo': 'X1 sDrive18i / xLine', 'img': 'assets/car.png'},
      {'modelo': 'X3 xDrive30e Híbrido', 'img': 'assets/car.png'},
      {'modelo': 'X5 xDrive50e Híbrido', 'img': 'assets/car.png'},
      {'modelo': 'M3 Competition / M5', 'img': 'assets/car.png'},
      {'modelo': 'i4 / iX3 100% Eléctrico', 'img': 'assets/car.png'},
    ],
    'MERCEDES-BENZ': [
      {'modelo': 'Clase A 200 Sedan / Hatchback', 'img': 'assets/car.png'},
      {'modelo': 'Clase C 200 Mild-Hybrid', 'img': 'assets/car.png'},
      {'modelo': 'Clase E 300 e Híbrido', 'img': 'assets/car.png'},
      {'modelo': 'GLA 200 Progressive', 'img': 'assets/car.png'},
      {'modelo': 'GLB 200 7 Puestos', 'img': 'assets/car.png'},
      {'modelo': 'GLC 300 4MATIC Coupe', 'img': 'assets/car.png'},
      {'modelo': 'GLE 450 4MATIC', 'img': 'assets/car.png'},
      {'modelo': 'Mercedes-AMG A 45 S 4MATIC+', 'img': 'assets/car.png'},
    ],
    'AUDI': [
      {'modelo': 'A3 Sedan / Sportback 35 TFSI', 'img': 'assets/car.png'},
      {'modelo': 'A4 40 TFSI S line', 'img': 'assets/car.png'},
      {'modelo': 'Q2 35 TFSI', 'img': 'assets/car.png'},
      {'modelo': 'Q3 Sportback 35 TFSI', 'img': 'assets/car.png'},
      {'modelo': 'Q5 45 TFSI quattro', 'img': 'assets/car.png'},
      {'modelo': 'Q7 55 TFSI quattro 7 Plazas', 'img': 'assets/car.png'},
      {'modelo': 'Q8 e-tron Eléctrico', 'img': 'assets/car.png'},
      {'modelo': 'RS3 / RS5 Coupe', 'img': 'assets/car.png'},
    ],
    'JEEP': [
      {'modelo': 'Renegade Longitude Turbo', 'img': 'assets/car.png'},
      {'modelo': 'Compass Limited 4x2 / 4x4', 'img': 'assets/car.png'},
      {'modelo': 'Commander Overland 7 Puestos', 'img': 'assets/car.png'},
      {'modelo': 'Wrangler Rubicon 4x4', 'img': 'assets/car.png'},
      {'modelo': 'Gladiator Rubicon Pick-up', 'img': 'assets/car.png'},
      {'modelo': 'Grand Cherokee 4xe Híbrida', 'img': 'assets/car.png'},
    ],
    'BYD': [
      {'modelo': 'Dolphin EV 100% Eléctrico', 'img': 'assets/car.png'},
      {'modelo': 'Dolphin Mini (Seagull)', 'img': 'assets/car.png'},
      {'modelo': 'Yuan Plus EV (Atto 3)', 'img': 'assets/car.png'},
      {'modelo': 'Song Plus DM-i Híbrido Enchufable', 'img': 'assets/car.png'},
      {'modelo': 'Seal Sedan EV', 'img': 'assets/car.png'},
      {'modelo': 'Han EV Luxury', 'img': 'assets/car.png'},
      {'modelo': 'Tang EV SUV 7 Pasajeros', 'img': 'assets/car.png'},
      {'modelo': 'Shark Pick-up DM-i', 'img': 'assets/car.png'},
    ],
    'MITSUBISHI': [
      {'modelo': 'L200 Sportero 4x4', 'img': 'assets/car.png'},
      {'modelo': 'Montero Sport Takai 4WD', 'img': 'assets/car.png'},
      {'modelo': 'Outlander Diamond PHEV', 'img': 'assets/car.png'},
      {'modelo': 'Xpander Cross 7 Puestos', 'img': 'assets/bus.png'},
      {'modelo': 'Eclipse Cross Turbo', 'img': 'assets/car.png'},
    ],
    'PEUGEOT': [
      {'modelo': '208 GT / Allure', 'img': 'assets/car.png'},
      {'modelo': '2008 Turbo Allure / GT', 'img': 'assets/car.png'},
      {'modelo': '3008 GT Line', 'img': 'assets/car.png'},
      {'modelo': '5008 7 Puestos', 'img': 'assets/car.png'},
      {'modelo': 'Partner Furgón', 'img': 'assets/furgon.png'},
    ],
    'FIAT': [
      {'modelo': 'Mobi Trekking', 'img': 'assets/car.png'},
      {'modelo': 'Argo Trekking / Drive', 'img': 'assets/car.png'},
      {'modelo': 'Pulse Drive / Audace / Impetus', 'img': 'assets/car.png'},
      {'modelo': 'Fastback Audace / Limited Turbo', 'img': 'assets/car.png'},
      {'modelo': 'Strada Volcano Doble Cabina', 'img': 'assets/car.png'},
      {'modelo': 'Fiorino Furgón', 'img': 'assets/furgon.png'},
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
    'MITSUBISHI': 'assets/logos/mitsubishi_logo.png',
    'PEUGEOT': 'assets/logos/peugeot_logo.png',
    'FIAT': 'assets/logos/fiat_logo.png',
  };

  // --- MOTO CATALOG ---
  final Map<String, List<Map<String, String>>> _motoCatalog = {
    'YAMAHA': [
      {'modelo': 'MT 15', 'img': 'assets/motos/yamaha/mt15.png'},
      {'modelo': 'R15 V4 / V3', 'img': 'assets/motos/yamaha/r15.png'},
      {'modelo': 'FZ 25', 'img': 'assets/motos/yamaha/fz25.png'},
      {'modelo': 'FZ 2.0 FI', 'img': 'assets/motos/yamaha/fz2.0.png'},
      {'modelo': 'Crypton FI 115', 'img': 'assets/motos/yamaha/cripton.png'},
      {'modelo': 'N-MAX Connected 155', 'img': 'assets/motos/yamaha/nmax.png'},
      {'modelo': 'XTZ 150 Crosser', 'img': 'assets/motos/yamaha/XTZ150.png'},
      {'modelo': 'XTZ 250 Lander', 'img': 'assets/motos/yamaha/XTZ150.png'},
      {'modelo': 'MT 03', 'img': 'assets/motos/yamaha/mt15.png'},
      {'modelo': 'MT 07', 'img': 'assets/motos/yamaha/mt15.png'},
      {'modelo': 'MT 09 SP', 'img': 'assets/motos/yamaha/mt15.png'},
      {'modelo': 'Ténéré 700 Rally', 'img': 'assets/motos/yamaha/XTZ150.png'},
      {'modelo': 'Aerox 155', 'img': 'assets/motos/yamaha/nmax.png'},
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
      {'modelo': 'Gixxer 250 FI ABS', 'img': 'assets/motos/suzuki/gixxer150.png'},
      {'modelo': 'Gixxer SF 250 FI ABS', 'img': 'assets/motos/suzuki/gixxersf150.png'},
      {'modelo': 'GN 125', 'img': 'assets/motos/suzuki/gixxer150.png'},
      {'modelo': 'DR 150', 'img': 'assets/motos/suzuki/gixxer150.png'},
      {'modelo': 'DR 650 SE', 'img': 'assets/motos/suzuki/gixxer150.png'},
      {'modelo': 'V-Strom 250 SX', 'img': 'assets/motos/suzuki/gixxer150.png'},
      {'modelo': 'V-Strom 650 XT / 800 DE', 'img': 'assets/motos/suzuki/gixxer150.png'},
      {'modelo': 'GSX-S 750 / GSX-8S', 'img': 'assets/motos/suzuki/gixxer150.png'},
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
      {'modelo': 'Adventure 790 / 890 R', 'img': 'assets/motos/ktm/KTM-390-adv.png'},
      {'modelo': 'RC 200 / RC 390', 'img': 'assets/motos/ktm/DUKE-200.png'},
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
      {'modelo': 'NKD Classic 125', 'img': 'assets/motos/akt/NKD.png'},
      {'modelo': 'CR4 150', 'img': 'assets/motos/akt/CR4_150.png'},
      {'modelo': 'CR4 200 Pro', 'img': 'assets/motos/akt/CR4_200.png'},
      {'modelo': '250 R Naked', 'img': 'assets/motos/akt/250R.png'},
      {'modelo': 'Dynamic Pro 125', 'img': 'assets/motos/akt/dinamicpro.png'},
      {'modelo': 'Mawi 125 Scooter', 'img': 'assets/motos/akt/mawi.png'},
      {'modelo': 'TT Dual Sport 200', 'img': 'assets/motos/akt/CR4_200.png'},
      {'modelo': 'TT Dual Sport 250', 'img': 'assets/motos/akt/250R.png'},
      {'modelo': 'Flex 125 LED', 'img': 'assets/motos/akt/NKD.png'},
    ],
    'KAWASAKI': [
      {'modelo': 'Ninja 400 ABS', 'img': 'assets/motos/kawasaki/ninja400.png'},
      {'modelo': 'Ninja 650 ABS', 'img': 'assets/motos/kawasaki/ninja650.png'},
      {'modelo': 'Ninja ZX-4RR / ZX-6R', 'img': 'assets/motos/kawasaki/ninja400.png'},
      {'modelo': 'Ninja ZX-10R', 'img': 'assets/motos/kawasaki/ninja650.png'},
      {'modelo': 'Z 400 ABS', 'img': 'assets/motos/kawasaki/z400.png'},
      {'modelo': 'Z 650 / Z 900', 'img': 'assets/motos/kawasaki/z400.png'},
      {'modelo': 'Versys 650 ABS', 'img': 'assets/motos/kawasaki/versys650.png'},
      {'modelo': 'Versys 300X', 'img': 'assets/motos/kawasaki/versys650.png'},
      {'modelo': 'KLX 150 / 300R', 'img': 'assets/motos/kawasaki/versys650.png'},
      {'modelo': 'KLR 650 Adventure', 'img': 'assets/motos/kawasaki/versys650.png'},
    ],
    'BMW': [
      {'modelo': 'G 310 R', 'img': 'assets/motos/bmw/g310r.png'},
      {'modelo': 'G 310 GS', 'img': 'assets/motos/bmw/g310gs.png'},
      {'modelo': 'F 900 R', 'img': 'assets/motos/bmw/f900r.png'},
      {'modelo': 'F 900 XR', 'img': 'assets/motos/bmw/f900r.png'},
      {'modelo': 'F 850 GS / F 900 GS', 'img': 'assets/motos/bmw/g310gs.png'},
      {'modelo': 'R 1250 GS / R 1300 GS', 'img': 'assets/motos/bmw/g310gs.png'},
      {'modelo': 'R 1250 GS Adventure', 'img': 'assets/motos/bmw/g310gs.png'},
      {'modelo': 'S 1000 RR Sport', 'img': 'assets/motos/bmw/f900r.png'},
      {'modelo': 'S 1000 XR', 'img': 'assets/motos/bmw/f900r.png'},
      {'modelo': 'C 400 GT Scooter', 'img': 'assets/motos/bmw/g310r.png'},
    ],
    'HONDA': [
      {'modelo': 'CB 125F Twister', 'img': 'assets/motos/hero/Hunk125r.png'},
      {'modelo': 'CB 160F / CB 190R', 'img': 'assets/motos/hero/hunk160r.png'},
      {'modelo': 'CB 300F Twister ABS', 'img': 'assets/motos/hero/Hunk160R4v.png'},
      {'modelo': 'XR 150L / XR 190L', 'img': 'assets/motos/hero/Xpulse2004v.png'},
      {'modelo': 'XRE 300 Rally / Sahara 300', 'img': 'assets/motos/hero/XpulsePro2004v.png'},
      {'modelo': 'Navi 110 Automatic', 'img': 'assets/motos/akt/mawi.png'},
      {'modelo': 'Dio 110 / PCX 160 ABS', 'img': 'assets/motos/yamaha/nmax.png'},
      {'modelo': 'CB 650R / CBR 650R', 'img': 'assets/motos/kawasaki/ninja650.png'},
      {'modelo': 'CRF 1100L Africa Twin', 'img': 'assets/motos/bmw/g310gs.png'},
      {'modelo': 'Transalp XL750', 'img': 'assets/motos/kawasaki/versys650.png'},
    ],
    'DUCATI': [
      {'modelo': 'Monster 937 / Plus', 'img': 'assets/motos/ktm/DUKE-200.png'},
      {'modelo': 'Panigale V2 / V4', 'img': 'assets/motos/kawasaki/ninja650.png'},
      {'modelo': 'Streetfighter V2 / V4', 'img': 'assets/motos/ktm/KTM-990-DUKE.png'},
      {'modelo': 'Multistrada V4 S / Rally', 'img': 'assets/motos/bmw/g310gs.png'},
      {'modelo': 'DesertX 937 Rally', 'img': 'assets/motos/bmw/g310gs.png'},
      {'modelo': 'Scrambler Icon / Full Throttle', 'img': 'assets/motos/ktm/DUKE-200.png'},
      {'modelo': 'Diavel V4', 'img': 'assets/motos/ktm/KTM1390superduke2025.png'},
      {'modelo': 'Hypermotard 698 Mono / 950', 'img': 'assets/motos/ktm/DUKE-200.png'},
    ],
    'VICTORI': [
      {'modelo': 'Venom 150', 'img': 'assets/motos/victori/victori_venom_150.png'},
      {'modelo': 'Venom 180', 'img': 'assets/motos/victori/victori_venom_150.png'},
      {'modelo': 'Venom 250 FI', 'img': 'assets/motos/victori/victori_venom_150.png'},
      {'modelo': 'MRX 125 / MRX 150', 'img': 'assets/motos/yamaha/XTZ150.png'},
      {'modelo': 'MRX Arizona 200', 'img': 'assets/motos/yamaha/XTZ150.png'},
      {'modelo': 'Switch 150 Scooter', 'img': 'assets/motos/akt/mawi.png'},
      {'modelo': 'Black 171', 'img': 'assets/motos/victori/victori_venom_150.png'},
    ],
    'TRIUMPH': [
      {'modelo': 'Speed 400', 'img': 'assets/motos/bmw/g310r.png'},
      {'modelo': 'Scrambler 400 X', 'img': 'assets/motos/bmw/g310gs.png'},
      {'modelo': 'Trident 660', 'img': 'assets/motos/bmw/f900r.png'},
      {'modelo': 'Street Triple 765 RS', 'img': 'assets/motos/bmw/f900r.png'},
      {'modelo': 'Tiger 900 GT Pro / Rally Pro', 'img': 'assets/motos/kawasaki/versys650.png'},
      {'modelo': 'Tiger 1200 Rally Explorer', 'img': 'assets/motos/bmw/g310gs.png'},
      {'modelo': 'Bonneville T120', 'img': 'assets/motos/bmw/g310r.png'},
      {'modelo': 'Rocket 3 R / GT (2500cc)', 'img': 'assets/motos/ktm/KTM1390superduke2025.png'},
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
  };

  // Getters
  Map<String, List<Map<String, String>>> getCarCatalog() => _carCatalog;
  Map<String, String> getCarLogos() => _carLogos;

  Map<String, List<Map<String, String>>> getMotoCatalog() => _motoCatalog;
  Map<String, String> getMotoLogos() => _motoLogos;

  Map<String, Color> getBrandColors() => _brandColors;

  /// Obtiene la URL o asset del logo de cualquier marca (Carro o Moto)
  String getLogoForBrand(String brand) {
    final upper = brand.trim().toUpperCase();
    if (_motoLogos.containsKey(upper)) return _motoLogos[upper]!;
    if (_carLogos.containsKey(upper)) return _carLogos[upper]!;

    // Fallback a CDN de alta calidad si no está en local
    final slug = brand
        .trim()
        .toLowerCase()
        .replaceAll(' ', '-')
        .replaceAll('_', '-');
    return 'https://raw.githubusercontent.com/filippofilip95/car-logos-dataset/master/logos/optimized/$slug.png';
  }

  /// Retorna el color insignia de la marca
  Color getColorForBrand(String brand) {
    final upper = brand.trim().toUpperCase();
    return _brandColors[upper] ?? const Color(0xFF035880);
  }
}
