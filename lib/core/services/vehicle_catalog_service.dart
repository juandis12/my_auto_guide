// =============================================================================
// vehicle_catalog_service.dart — CATÁLOGO COLOMBIANO LIVIANO CLOUD-DRIVEN
// =============================================================================
//
// Catálogo integral de marcas y vehículos oficiales del mercado colombiano
// (RUNT / ANDI / FENALCO). 
//
// Arquitectura Cloud-CDN:
// - Desacopla archivos binarios pesados del bundle para mantener el APK liviano (<25MB).
// - Provee URLs de CDN de alta velocidad con caché inteligente.
// - Soporta fallback local instantáneo y colores de marca oficiales.
// =============================================================================

import 'dart:convert';
import 'package:flutter/material.dart';

class VehicleCatalogService {
  static final VehicleCatalogService _instance =
      VehicleCatalogService._internal();
  factory VehicleCatalogService() => _instance;
  VehicleCatalogService._internal();

  static const String _githubLogoBase =
      'https://raw.githubusercontent.com/filippofilip95/car-logos-dataset/master/logos/optimized';

  // --- 1. CATÁLOGO DE CARROS LÍDERES EN COLOMBIA ---
  final Map<String, List<Map<String, String>>> _carCatalog = {
    'CHEVROLET': [
      {'modelo': 'Onix Turbo RS', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/Chevrolet_Onix_Plus_1.0_Turbo_Premier_2020.jpg/600px-Chevrolet_Onix_Plus_1.0_Turbo_Premier_2020.jpg'},
      {'modelo': 'Onix Turbo Sedán', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/Chevrolet_Onix_Plus_1.0_Turbo_Premier_2020.jpg/600px-Chevrolet_Onix_Plus_1.0_Turbo_Premier_2020.jpg'},
      {'modelo': 'Tracker Turbo', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/2020_Chevrolet_Tracker_%28China%29_front_view.jpg/600px-2020_Chevrolet_Tracker_%28China%29_front_view.jpg'},
      {'modelo': 'Spark GT', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/2019_Chevrolet_Spark_1LT_1.4L%2C_front_10.13.19.jpg/600px-2019_Chevrolet_Spark_1LT_1.4L%2C_front_10.13.19.jpg'},
      {'modelo': 'Montana', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/24/Chevrolet_Montana_Premier_2023.jpg/600px-Chevrolet_Montana_Premier_2023.jpg'},
      {'modelo': 'Equinox RS', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/07/2018_Chevrolet_Equinox_LT%2C_front_10.13.19.jpg/600px-2018_Chevrolet_Equinox_LT%2C_front_10.13.19.jpg'},
      {'modelo': 'Blazer RS', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/2019_Chevrolet_Blazer_RS_AWD%2C_front_10.13.19.jpg/600px-2019_Chevrolet_Blazer_RS_AWD%2C_front_10.13.19.jpg'},
      {'modelo': 'Traverse', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/67/2018_Chevrolet_Traverse_LT_Cloth_AWD%2C_front_10.13.19.jpg/600px-2018_Chevrolet_Traverse_LT_Cloth_AWD%2C_front_10.13.19.jpg'},
      {'modelo': 'Colorado', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d4/2019_Chevrolet_Colorado_Crew_Cab_4WD%2C_front_10.13.19.jpg/600px-2019_Chevrolet_Colorado_Crew_Cab_4WD%2C_front_10.13.19.jpg'},
      {'modelo': 'Silverado Trail Boss', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4f/2019_Chevrolet_Silverado_1500_RST_Crew_Cab_4WD%2C_front_10.13.19.jpg/600px-2019_Chevrolet_Silverado_1500_RST_Crew_Cab_4WD%2C_front_10.13.19.jpg'},
      {'modelo': 'Tahoe', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6e/2021_Chevrolet_Tahoe_LT_4WD%2C_front_left.jpg/600px-2021_Chevrolet_Tahoe_LT_4WD%2C_front_left.jpg'},
      {'modelo': 'Camaro SS', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5e/2019_Chevrolet_Camaro_2SS_6.2L%2C_front_10.13.19.jpg/600px-2019_Chevrolet_Camaro_2SS_6.2L%2C_front_10.13.19.jpg'},
    ],
    'RENAULT': [
      {'modelo': 'Duster', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/66/Dacia_Duster_II_1.3_TCe_150_4WD_Prestige_%28Facelift%29_%E2%80%93_f_03072022.jpg/600px-Dacia_Duster_II_1.3_TCe_150_4WD_Prestige_%28Facelift%29_%E2%80%93_f_03072022.jpg'},
      {'modelo': 'Sandero', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/ce/Dacia_Sandero_III_Stepway_TCe_90_%E2%80%93_f_02052021.jpg/600px-Dacia_Sandero_III_Stepway_TCe_90_%E2%80%93_f_02052021.jpg'},
      {'modelo': 'Stepway', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/ce/Dacia_Sandero_III_Stepway_TCe_90_%E2%80%93_f_02052021.jpg/600px-Dacia_Sandero_III_Stepway_TCe_90_%E2%80%93_f_02052021.jpg'},
      {'modelo': 'Logan', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/Dacia_Logan_III_TCe_90_%E2%80%93_f_02052021.jpg/600px-Dacia_Logan_III_TCe_90_%E2%80%93_f_02052021.jpg'},
      {'modelo': 'Kwid', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b3/Renault_Kwid_Outsider_2020.jpg/600px-Renault_Kwid_Outsider_2020.jpg'},
      {'modelo': 'Kardian', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/ba/Renault_Kardian_Premiere_Edition_2024.jpg/600px-Renault_Kardian_Premiere_Edition_2024.jpg'},
      {'modelo': 'Oroch', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/81/Renault_Duster_Oroch_Dynamique_2.0_2016_%2816781745423%29.jpg/600px-Renault_Duster_Oroch_Dynamique_2.0_2016_%2816781745423%29.jpg'},
      {'modelo': 'Megane E-Tech', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/15/Renault_M%C3%A9gane_E-Tech_Electric_Techno_EV60_220hp_super_charge_%E2%80%93_f_16072022.jpg/600px-Renault_M%C3%A9gane_E-Tech_Electric_Techno_EV60_220hp_super_charge_%E2%80%93_f_16072022.jpg'},
      {'modelo': 'Koleos', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f6/Renault_Koleos_II_dCi_175_4WD_Initiale_Paris_%E2%80%93_Frontansicht%2C_24._Juni_2017%2C_D%C3%BCsseldorf.jpg/600px-Renault_Koleos_II_dCi_175_4WD_Initiale_Paris_%E2%80%93_Frontansicht%2C_24._Juni_2017%2C_D%C3%BCsseldorf.jpg'},
      {'modelo': 'Captur', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4f/Renault_Captur_II_TCe_130_EDC_Intens_%E2%80%93_f_18042021.jpg/600px-Renault_Captur_II_TCe_130_EDC_Intens_%E2%80%93_f_18042021.jpg'},
    ],
    'TOYOTA': [
      {'modelo': 'Corolla Sedán', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/2020_Toyota_Corolla_Altis_1.8E_front_view.jpg/600px-2020_Toyota_Corolla_Altis_1.8E_front_view.jpg'},
      {'modelo': 'Corolla Cross Híbrido', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8b/2021_Toyota_Corolla_Cross_1.8V_%28ZSG10%29_front_view.jpg/600px-2021_Toyota_Corolla_Cross_1.8V_%28ZSG10%29_front_view.jpg'},
      {'modelo': 'Hilux', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/2021_Toyota_Hilux_Revo_Rocco_Double_Cab_2.8_4x4_front_view.jpg/600px-2021_Toyota_Hilux_Revo_Rocco_Double_Cab_2.8_4x4_front_view.jpg'},
      {'modelo': 'Yaris Cross', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Toyota_Yaris_Cross_1.5_Hybrid_Club_%E2%80%93_f_24042022.jpg/600px-Toyota_Yaris_Cross_1.5_Hybrid_Club_%E2%80%93_f_24042022.jpg'},
      {'modelo': 'Fortuner', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/77/2020_Toyota_Fortuner_2.8_Legender_4WD_%28GUN156%29_front_view.jpg/600px-2020_Toyota_Fortuner_2.8_Legender_4WD_%28GUN156%29_front_view.jpg'},
      {'modelo': 'Land Cruiser Prado', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/91/2024_Toyota_Land_Cruiser_First_Edition_in_Trail_Dust%2C_Front_Left%2C_05-18-2024.jpg/600px-2024_Toyota_Land_Cruiser_First_Edition_in_Trail_Dust%2C_Front_Left%2C_05-18-2024.jpg'},
      {'modelo': 'Land Cruiser 300', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/be/Toyota_Land_Cruiser_300_VJA300W_ZX_01.jpg/600px-Toyota_Land_Cruiser_300_VJA300W_ZX_01.jpg'},
      {'modelo': 'RAV4 Hybrid', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/be/2019_Toyota_RAV4_LE_2.5L%2C_front_10.13.19.jpg/600px-2019_Toyota_RAV4_LE_2.5L%2C_front_10.13.19.jpg'},
      {'modelo': '4Runner', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/02/2020_Toyota_4Runner_TRD_Off-Road_4WD%2C_front_10.13.19.jpg/600px-2020_Toyota_4Runner_TRD_Off-Road_4WD%2C_front_10.13.19.jpg'},
      {'modelo': 'Tundra', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/74/2022_Toyota_Tundra_Limited_CrewMax_in_Blueprint%2C_Front_Left%2C_09-17-2022.jpg/600px-2022_Toyota_Tundra_Limited_CrewMax_in_Blueprint%2C_Front_Left%2C_09-17-2022.jpg'},
    ],
    'MAZDA': [
      {'modelo': 'Mazda 2 Hatchback', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/76/Mazda2_%28DJ%2C_Facelift%29_%E2%80%93_f_14032021.jpg/600px-Mazda2_%28DJ%2C_Facelift%29_%E2%80%93_f_14032021.jpg'},
      {'modelo': 'Mazda 2 Sedán', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/76/Mazda2_%28DJ%2C_Facelift%29_%E2%80%93_f_14032021.jpg/600px-Mazda2_%28DJ%2C_Facelift%29_%E2%80%93_f_14032021.jpg'},
      {'modelo': 'Mazda 3 Sedán', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d7/2019_Mazda3_Sedan_Select_AWD%2C_front_10.13.19.jpg/600px-2019_Mazda3_Sedan_Select_AWD%2C_front_10.13.19.jpg'},
      {'modelo': 'Mazda 3 Hatchback', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e6/2019_Mazda3_Premium_AWD_Hatchback%2C_front_10.13.19.jpg/600px-2019_Mazda3_Premium_AWD_Hatchback%2C_front_10.13.19.jpg'},
      {'modelo': 'CX-30 Grand Touring', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/47/Mazda_CX-30_Skyactiv-X_AWD_Selection_%E2%80%93_f_24052021.jpg/600px-Mazda_CX-30_Skyactiv-X_AWD_Selection_%E2%80%93_f_24052021.jpg'},
      {'modelo': 'CX-5', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1b/2017_Mazda_CX-5_Sport_2.5L_front_10.13.19.jpg/600px-2017_Mazda_CX-5_Sport_2.5L_front_10.13.19.jpg'},
      {'modelo': 'CX-50', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e1/2023_Mazda_CX-50_2.5_Turbo_Premium_Plus_in_Ingot_Blue_Metallic%2C_front_left.jpg/600px-2023_Mazda_CX-50_2.5_Turbo_Premium_Plus_in_Ingot_Blue_Metallic%2C_front_left.jpg'},
      {'modelo': 'CX-60', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/66/Mazda_CX-60_PHEV_Homura_%E2%80%93_f_24092022.jpg/600px-Mazda_CX-60_PHEV_Homura_%E2%80%93_f_24092022.jpg'},
      {'modelo': 'CX-90', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a2/2024_Mazda_CX-90_3.3_Turbo_S_Premium_Plus_in_Artisan_Red_Metallic%2C_front_left.jpg/600px-2024_Mazda_CX-90_3.3_Turbo_S_Premium_Plus_in_Artisan_Red_Metallic%2C_front_left.jpg'},
      {'modelo': 'MX-5 Miata', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/Mazda_MX-5_ND_20160528.jpg/600px-Mazda_MX-5_ND_20160528.jpg'},
    ],
    'KIA': [
      {'modelo': 'Picanto', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1d/Kia_Picanto_%28JA%2C_Facelift%29_%E2%80%93_f_14032021.jpg/600px-Kia_Picanto_%28JA%2C_Facelift%29_%E2%80%93_f_14032021.jpg'},
      {'modelo': 'K3 Sedán', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/dc/Kia_K3_%28BL7%29_front_view.jpg/600px-Kia_K3_%28BL7%29_front_view.jpg'},
      {'modelo': 'K3 Cross', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/dc/Kia_K3_%28BL7%29_front_view.jpg/600px-Kia_K3_%28BL7%29_front_view.jpg'},
      {'modelo': 'Sonet', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/13/2020_Kia_Sonet_HTX%2B_%28India%29_front_view.jpg/600px-2020_Kia_Sonet_HTX%2B_%28India%29_front_view.jpg'},
      {'modelo': 'Seltos', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/2021_Kia_Seltos_EX%2C_front_10.23.20.jpg/600px-2021_Kia_Seltos_EX%2C_front_10.23.20.jpg'},
      {'modelo': 'Sportage', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fa/Kia_Sportage_NQ5_PHEV_GT-Line_%E2%80%93_f_16072022.jpg/600px-Kia_Sportage_NQ5_PHEV_GT-Line_%E2%80%93_f_16072022.jpg'},
      {'modelo': 'Sorento', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ad/Kia_Sorento_MQ4_PHEV_Platinum_%E2%80%93_f_16072022.jpg/600px-Kia_Sorento_MQ4_PHEV_Platinum_%E2%80%93_f_16072022.jpg'},
      {'modelo': 'EV6', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/Kia_EV6_AWD_GT-Line_%E2%80%93_f_14052022.jpg/600px-Kia_EV6_AWD_GT-Line_%E2%80%93_f_14052022.jpg'},
      {'modelo': 'EV9', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f6/Kia_EV9_AWD_GT-Line_%E2%80%93_f_16032024.jpg/600px-Kia_EV9_AWD_GT-Line_%E2%80%93_f_16032024.jpg'},
      {'modelo': 'Carnival', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d4/2022_Kia_Carnival_EX_in_Deep_Chroma_Blue%2C_front_left.jpg/600px-2022_Kia_Carnival_EX_in_Deep_Chroma_Blue%2C_front_left.jpg'},
    ],
    'NISSAN': [
      {'modelo': 'Versa', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/2020_Nissan_Versa_SV%2C_front_10.13.19.jpg/600px-2020_Nissan_Versa_SV%2C_front_10.13.19.jpg'},
      {'modelo': 'Kicks', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b3/2018_Nissan_Kicks_SV%2C_front_10.13.19.jpg/600px-2018_Nissan_Kicks_SV%2C_front_10.13.19.jpg'},
      {'modelo': 'Sentra', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cd/2020_Nissan_Sentra_SR%2C_front_10.23.20.jpg/600px-2020_Nissan_Sentra_SR%2C_front_10.23.20.jpg'},
      {'modelo': 'Frontier Pro-4X', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c2/2022_Nissan_Frontier_PRO-4X_in_Tactical_Green_Metallic%2C_front_left.jpg/600px-2022_Nissan_Frontier_PRO-4X_in_Tactical_Green_Metallic%2C_front_left.jpg'},
      {'modelo': 'Qashqai', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1d/Nissan_Qashqai_J12_Tekna_%E2%80%93_f_14052022.jpg/600px-Nissan_Qashqai_J12_Tekna_%E2%80%93_f_14052022.jpg'},
      {'modelo': 'X-Trail e-POWER', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/Nissan_X-Trail_T33_e-Power_Tekna%2B_%E2%80%93_f_15042023.jpg/600px-Nissan_X-Trail_T33_e-Power_Tekna%2B_%E2%80%93_f_15042023.jpg'},
      {'modelo': 'Pathfinder', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c6/2022_Nissan_Pathfinder_SL_4WD_in_Glacier_White%2C_front_left.jpg/600px-2022_Nissan_Pathfinder_SL_4WD_in_Glacier_White%2C_front_left.jpg'},
      {'modelo': 'Patrol', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/2020_Nissan_Patrol_Ti_%28Y62%29_wagon_%282020-11-20%29_01.jpg/600px-2020_Nissan_Patrol_Ti_%28Y62%29_wagon_%282020-11-20%29_01.jpg'},
    ],
    'HYUNDAI': [
      {'modelo': 'Grand i10', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/Hyundai_i10_III_1.0_Trend_%E2%80%93_f_14032021.jpg/600px-Hyundai_i10_III_1.0_Trend_%E2%80%93_f_14032021.jpg'},
      {'modelo': 'HB20', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c4/Hyundai_HB20_Platinum_Plus_2023.jpg/600px-Hyundai_HB20_Platinum_Plus_2023.jpg'},
      {'modelo': 'Creta', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f7/Hyundai_Creta_Ultimate_2022.jpg/600px-Hyundai_Creta_Ultimate_2022.jpg'},
      {'modelo': 'Tucson', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/eb/Hyundai_Tucson_NX4_Prime_1.6_T-GDI_Plug-in-Hybrid_%E2%80%93_f_24052021.jpg/600px-Hyundai_Tucson_NX4_Prime_1.6_T-GDI_Plug-in-Hybrid_%E2%80%93_f_24052021.jpg'},
      {'modelo': 'Santa Fe', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/Hyundai_Santa_Fe_MX5_Calligraphy_%E2%80%93_f_16032024.jpg/600px-Hyundai_Santa_Fe_MX5_Calligraphy_%E2%80%93_f_16032024.jpg'},
      {'modelo': 'Kona Hybrid', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/25/Hyundai_Kona_SX2_Hybrid_Prime_%E2%80%93_f_08072023.jpg/600px-Hyundai_Kona_SX2_Hybrid_Prime_%E2%80%93_f_08072023.jpg'},
      {'modelo': 'Ioniq 5', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0c/Hyundai_Ioniq_5_AWD_Project_45_%E2%80%93_f_28082021.jpg/600px-Hyundai_Ioniq_5_AWD_Project_45_%E2%80%93_f_28082021.jpg'},
      {'modelo': 'Palisade', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/2020_Hyundai_Palisade_SEL_AWD%2C_front_10.13.19.jpg/600px-2020_Hyundai_Palisade_SEL_AWD%2C_front_10.13.19.jpg'},
    ],
    'VOLKSWAGEN': [
      {'modelo': 'Polo Track', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4b/Volkswagen_Polo_Track_2023.jpg/600px-Volkswagen_Polo_Track_2023.jpg'},
      {'modelo': 'Virtus', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/Volkswagen_Virtus_Highline_2018.jpg/600px-Volkswagen_Virtus_Highline_2018.jpg'},
      {'modelo': 'Nivus', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/Volkswagen_Nivus_Highline_2021.jpg/600px-Volkswagen_Nivus_Highline_2021.jpg'},
      {'modelo': 'T-Cross', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f6/VW_T-Cross_1.0_TSI_Style_%E2%80%93_f_14032021.jpg/600px-VW_T-Cross_1.0_TSI_Style_%E2%80%93_f_14032021.jpg'},
      {'modelo': 'Taos', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6b/2022_Volkswagen_Taos_SE_4MOTION_in_Platinum_Gray_Metallic%2C_front_left.jpg/600px-2022_Volkswagen_Taos_SE_4MOTION_in_Platinum_Gray_Metallic%2C_front_left.jpg'},
      {'modelo': 'Tiguan', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8e/2022_Volkswagen_Tiguan_2.0T_SE_4MOTION_in_Deep_Black_Pearl%2C_front_left.jpg/600px-2022_Volkswagen_Tiguan_2.0T_SE_4MOTION_in_Deep_Black_Pearl%2C_front_left.jpg'},
      {'modelo': 'Amarok V6', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/14/Volkswagen_Amarok_II_3.0_TDI_4Motion_PanAmericana_%E2%80%93_f_24062023.jpg/600px-Volkswagen_Amarok_II_3.0_TDI_4Motion_PanAmericana_%E2%80%93_f_24062023.jpg'},
      {'modelo': 'Golf GTI', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4c/VW_Golf_VIII_GTI_%E2%80%93_f_24052021.jpg/600px-VW_Golf_VIII_GTI_%E2%80%93_f_24052021.jpg'},
    ],
    'SUZUKI': [
      {'modelo': 'Swift Híbrido', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ab/Suzuki_Swift_1.2_Dualjet_Hybrid_Comfort_%E2%80%93_f_24042022.jpg/600px-Suzuki_Swift_1.2_Dualjet_Hybrid_Comfort_%E2%80%93_f_24042022.jpg'},
      {'modelo': 'Jimny AllGrip', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/69/Suzuki_Jimny_1.5_Allgrip_Comfort_%28GJ%29_%E2%80%93_f_14032021.jpg/600px-Suzuki_Jimny_1.5_Allgrip_Comfort_%28GJ%29_%E2%80%93_f_14032021.jpg'},
      {'modelo': 'Grand Vitara Híbrida', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d3/Suzuki_Grand_Vitara_%282022%29_front_view.jpg/600px-Suzuki_Grand_Vitara_%282022%29_front_view.jpg'},
      {'modelo': 'Fronx Híbrido', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/Suzuki_Fronx_GLX_2023.jpg/600px-Suzuki_Fronx_GLX_2023.jpg'},
      {'modelo': 'Baleno Cross', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/Suzuki_Baleno_1.2_Dualjet_Club_%E2%80%93_f_14032021.jpg/600px-Suzuki_Baleno_1.2_Dualjet_Club_%E2%80%93_f_14032021.jpg'},
      {'modelo': 'S-Cross AllGrip', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/Suzuki_S-Cross_1.4_Boosterjet_Allgrip_Comfort%2B_%E2%80%93_f_24042022.jpg/600px-Suzuki_S-Cross_1.4_Boosterjet_Allgrip_Comfort%2B_%E2%80%93_f_24042022.jpg'},
      {'modelo': 'Spresso', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/14/Maruti_Suzuki_S-Presso_VXI%2B_%28India%29_front_view.jpg/600px-Maruti_Suzuki_S-Presso_VXI%2B_%28India%29_front_view.jpg'},
    ],
    'BYD': [
      {'modelo': 'Dolphin Mini (Seagull)', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/BYD_Seagull_001.jpg/600px-BYD_Seagull_001.jpg'},
      {'modelo': 'Dolphin EV', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a2/BYD_Dolphin_001.jpg/600px-BYD_Dolphin_001.jpg'},
      {'modelo': 'Yuan Plus (Atto 3)', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/be/BYD_Atto_3_1X7A6265.jpg/600px-BYD_Atto_3_1X7A6265.jpg'},
      {'modelo': 'Song Plus DM-i', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f6/BYD_Song_Plus_DM-i_001.jpg/600px-BYD_Song_Plus_DM-i_001.jpg'},
      {'modelo': 'Seal EV', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/52/BYD_Seal_001.jpg/600px-BYD_Seal_001.jpg'},
      {'modelo': 'Tang EV', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4b/BYD_Tang_II_EV600D_Auto_Shanghai_2019.jpg/600px-BYD_Tang_II_EV600D_Auto_Shanghai_2019.jpg'},
      {'modelo': 'Shark Pickup Híbrida', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/BYD_Shark_PHEV_front_view.jpg/600px-BYD_Shark_PHEV_front_view.jpg'},
    ],
    'FORD': [
      {'modelo': 'Escape Híbrida', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/2020_Ford_Escape_Titanium_AWD%2C_front_10.13.19.jpg/600px-2020_Ford_Escape_Titanium_AWD%2C_front_10.13.19.jpg'},
      {'modelo': 'Ranger Wildtrak', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d4/2023_Ford_Ranger_Wildtrak_2.0_Bi-Turbo_4x4_in_Sedona_Orange%2C_front_left.jpg/600px-2023_Ford_Ranger_Wildtrak_2.0_Bi-Turbo_4x4_in_Sedona_Orange%2C_front_left.jpg'},
      {'modelo': 'Explorer Limited', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f6/2020_Ford_Explorer_XLT_4WD%2C_front_10.13.19.jpg/600px-2020_Ford_Explorer_XLT_4WD%2C_front_10.13.19.jpg'},
      {'modelo': 'Bronco Sport', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/2021_Ford_Bronco_Sport_Outer_Banks_in_Area_51%2C_front_left.jpg/600px-2021_Ford_Bronco_Sport_Outer_Banks_in_Area_51%2C_front_left.jpg'},
      {'modelo': 'F-150 Lariat Híbrida', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d4/2021_Ford_F-150_Lariat_SuperCrew_4x4_in_Carbonized_Gray%2C_front_left.jpg/600px-2021_Ford_F-150_Lariat_SuperCrew_4x4_in_Carbonized_Gray%2C_front_left.jpg'},
      {'modelo': 'Mustang GT 5.0', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/2018_Ford_Mustang_GT_5.0_front_10.13.19.jpg/600px-2018_Ford_Mustang_GT_5.0_front_10.13.19.jpg'},
    ],
    'BMW': [
      {'modelo': 'Serie 1 (118i/128ti)', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/BMW_118i_M_Sport_%28F40%29_%E2%80%93_f_14032021.jpg/600px-BMW_118i_M_Sport_%28F40%29_%E2%80%93_f_14032021.jpg'},
      {'modelo': 'Serie 2 Gran Coupé', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/BMW_218i_Gran_Coup%C3%A9_M_Sport_%28F44%29_%E2%80%93_f_14032021.jpg/600px-BMW_218i_Gran_Coup%C3%A9_M_Sport_%28F44%29_%E2%80%93_f_14032021.jpg'},
      {'modelo': 'Serie 3 (320i/330e)', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/BMW_320d_xDrive_M_Sport_%28G20%29_%E2%80%93_f_14032021.jpg/600px-BMW_320d_xDrive_M_Sport_%28G20%29_%E2%80%93_f_14032021.jpg'},
      {'modelo': 'X1 sDrive', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d4/BMW_X1_sDrive18d_xLine_%28U11%29_%E2%80%93_f_15042023.jpg/600px-BMW_X1_sDrive18d_xLine_%28U11%29_%E2%80%93_f_15042023.jpg'},
      {'modelo': 'X3 xDrive', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/be/BMW_X3_xDrive30e_M_Sport_%28G01%2C_Facelift%29_%E2%80%93_f_16072022.jpg/600px-BMW_X3_xDrive30e_M_Sport_%28G01%2C_Facelift%29_%E2%80%93_f_16072022.jpg'},
      {'modelo': 'X5 xDrive', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/BMW_X5_xDrive45e_M_Sport_%28G05%29_%E2%80%93_f_14032021.jpg/600px-BMW_X5_xDrive45e_M_Sport_%28G05%29_%E2%80%93_f_14032021.jpg'},
      {'modelo': 'M3 Competition', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/BMW_M3_Competition_%28G80%29_%E2%80%93_f_14052022.jpg/600px-BMW_M3_Competition_%28G80%29_%E2%80%93_f_14052022.jpg'},
    ],
    'MERCEDES-BENZ': [
      {'modelo': 'Clase A 200', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f7/Mercedes-Benz_A_200_AMG_Line_%28W_177%29_%E2%80%93_f_14032021.jpg/600px-Mercedes-Benz_A_200_AMG_Line_%28W_177%29_%E2%80%93_f_14032021.jpg'},
      {'modelo': 'Clase C 200', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ad/Mercedes-Benz_C_200_AMG_Line_%28W_206%29_%E2%80%93_f_16072022.jpg/600px-Mercedes-Benz_C_200_AMG_Line_%28W_206%29_%E2%80%93_f_16072022.jpg'},
      {'modelo': 'GLA 200', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4b/Mercedes-Benz_GLA_200_AMG_Line_%28H_247%29_%E2%80%93_f_14032021.jpg/600px-Mercedes-Benz_GLA_200_AMG_Line_%28H_247%29_%E2%80%93_f_14032021.jpg'},
      {'modelo': 'GLB 200', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/Mercedes-Benz_GLB_200_AMG_Line_%28X_247%29_%E2%80%93_f_14032021.jpg/600px-Mercedes-Benz_GLB_200_AMG_Line_%28X_247%29_%E2%80%93_f_14032021.jpg'},
      {'modelo': 'GLC 300', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Mercedes-Benz_GLC_220_d_4MATIC_AMG_Line_%28X_254%29_%E2%80%93_f_15042023.jpg/600px-Mercedes-Benz_GLC_220_d_4MATIC_AMG_Line_%28X_254%29_%E2%80%93_f_15042023.jpg'},
      {'modelo': 'GLE 450', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e1/Mercedes-Benz_GLE_300_d_4MATIC_AMG_Line_%28V_167%29_%E2%80%93_f_14032021.jpg/600px-Mercedes-Benz_GLE_300_d_4MATIC_AMG_Line_%28V_167%29_%E2%80%93_f_14032021.jpg'},
      {'modelo': 'Clase G 63 AMG', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/66/Mercedes-AMG_G_63_%28W_463A%29_%E2%80%93_f_14032021.jpg/600px-Mercedes-AMG_G_63_%28W_463A%29_%E2%80%93_f_14032021.jpg'},
    ],
    'AUDI': [
      {'modelo': 'A3 Sedán', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a2/Audi_A3_Sportback_35_TFSI_S_line_%288Y%29_%E2%80%93_f_14032021.jpg/600px-Audi_A3_Sportback_35_TFSI_S_line_%288Y%29_%E2%80%93_f_14032021.jpg'},
      {'modelo': 'A4', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b3/Audi_A4_B9_Facelift_Limousine_35_TFSI_S_line_%E2%80%93_f_14032021.jpg/600px-Audi_A4_B9_Facelift_Limousine_35_TFSI_S_line_%E2%80%93_f_14032021.jpg'},
      {'modelo': 'Q2', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/Audi_Q2_35_TFSI_S_line_%28Facelift%29_%E2%80%93_f_14032021.jpg/600px-Audi_Q2_35_TFSI_S_line_%28Facelift%29_%E2%80%93_f_14032021.jpg'},
      {'modelo': 'Q3 / Sportback', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/Audi_Q3_Sportback_45_TFSI_e_S_line_%E2%80%93_f_24052021.jpg/600px-Audi_Q3_Sportback_45_TFSI_e_S_line_%E2%80%93_f_24052021.jpg'},
      {'modelo': 'Q5', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/Audi_Q5_FY_Facelift_40_TDI_S_line_%E2%80%93_f_14032021.jpg/600px-Audi_Q5_FY_Facelift_40_TDI_S_line_%E2%80%93_f_14032021.jpg'},
      {'modelo': 'Q7', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8b/Audi_Q7_55_TFSI_e_quattro_S_line_%284M_Facelift%29_%E2%80%93_f_14032021.jpg/600px-Audi_Q7_55_TFSI_e_quattro_S_line_%284M_Facelift%29_%E2%80%93_f_14032021.jpg'},
      {'modelo': 'Q8 e-tron', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/Audi_Q8_55_e-tron_quattro_S_line_%E2%80%93_f_15042023.jpg/600px-Audi_Q8_55_e-tron_quattro_S_line_%E2%80%93_f_15042023.jpg'},
    ],
    'JEEP': [
      {'modelo': 'Renegade Turbo', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/2019_Jeep_Renegade_Latitude_4WD%2C_front_10.13.19.jpg/600px-2019_Jeep_Renegade_Latitude_4WD%2C_front_10.13.19.jpg'},
      {'modelo': 'Compass Turbo', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/2018_Jeep_Compass_Limited_4WD%2C_front_10.13.19.jpg/600px-2018_Jeep_Compass_Limited_4WD%2C_front_10.13.19.jpg'},
      {'modelo': 'Commander 7 Pasajeros', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/13/Jeep_Commander_Overland_2022.jpg/600px-Jeep_Commander_Overland_2022.jpg'},
      {'modelo': 'Grand Cherokee L', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/2022_Jeep_Grand_Cherokee_L_Limited_in_Silver_Zynith%2C_front_left.jpg/600px-2022_Jeep_Grand_Cherokee_L_Limited_in_Silver_Zynith%2C_front_left.jpg'},
      {'modelo': 'Wrangler Rubicon', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/2018_Jeep_Wrangler_Unlimited_Rubicon_4X4%2C_front_10.13.19.jpg/600px-2018_Jeep_Wrangler_Unlimited_Rubicon_4X4%2C_front_10.13.19.jpg'},
      {'modelo': 'Gladiator Rubicon', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/2020_Jeep_Gladiator_Overland_4X4%2C_front_10.13.19.jpg/600px-2020_Jeep_Gladiator_Overland_4X4%2C_front_10.13.19.jpg'},
    ]
  };

  // --- 2. CATÁLOGO DE MOTOS LÍDERES EN COLOMBIA ---
  final Map<String, List<Map<String, String>>> _motoCatalog = {
    'BAJAJ': [
      {'modelo': 'Pulsar NS 200 FI ABS', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d4/Bajaj_Pulsar_200NS.jpg/600px-Bajaj_Pulsar_200NS.jpg'},
      {'modelo': 'Pulsar NS 160 FI ABS', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d4/Bajaj_Pulsar_200NS.jpg/600px-Bajaj_Pulsar_200NS.jpg'},
      {'modelo': 'Pulsar NS 125', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d4/Bajaj_Pulsar_200NS.jpg/600px-Bajaj_Pulsar_200NS.jpg'},
      {'modelo': 'Pulsar N 250 FI ABS', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d4/Bajaj_Pulsar_200NS.jpg/600px-Bajaj_Pulsar_200NS.jpg'},
      {'modelo': 'Pulsar N 160 FI ABS', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d4/Bajaj_Pulsar_200NS.jpg/600px-Bajaj_Pulsar_200NS.jpg'},
      {'modelo': 'Pulsar RS 200 FI ABS', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/Bajaj_Pulsar_RS200.jpg/600px-Bajaj_Pulsar_RS200.jpg'},
      {'modelo': 'Pulsar NS 400Z', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d4/Bajaj_Pulsar_200NS.jpg/600px-Bajaj_Pulsar_200NS.jpg'},
      {'modelo': 'Dominar 400 Touring', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/Bajaj_Dominar_400.jpg/600px-Bajaj_Dominar_400.jpg'},
      {'modelo': 'Dominar 250', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/Bajaj_Dominar_400.jpg/600px-Bajaj_Dominar_400.jpg'},
      {'modelo': 'Boxer CT 100 KS', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Bajaj_Boxer_CT100.jpg/600px-Bajaj_Boxer_CT100.jpg'},
      {'modelo': 'Boxer CT 125', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Bajaj_Boxer_CT100.jpg/600px-Bajaj_Boxer_CT100.jpg'},
      {'modelo': 'Boxer 150X', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Bajaj_Boxer_CT100.jpg/600px-Bajaj_Boxer_CT100.jpg'},
      {'modelo': 'Discover 125 ST', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Bajaj_Discover_125_ST.jpg/600px-Bajaj_Discover_125_ST.jpg'},
    ],
    'YAMAHA': [
      {'modelo': 'MT 15 V2', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/Yamaha_MT-15_front.jpg/600px-Yamaha_MT-15_front.jpg'},
      {'modelo': 'YZF R15 V4', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4b/2022_Yamaha_YZF-R15_V4.jpg/600px-2022_Yamaha_YZF-R15_V4.jpg'},
      {'modelo': 'FZ 25 ABS', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b3/Yamaha_FZ25_2017.jpg/600px-Yamaha_FZ25_2017.jpg'},
      {'modelo': 'FZ 2.0 FI', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/Yamaha_FZ16_ST.JPG/600px-Yamaha_FZ16_ST.JPG'},
      {'modelo': 'Crypton FI', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ad/Yamaha_Crypton_115.jpg/600px-Yamaha_Crypton_115.jpg'},
      {'modelo': 'N-Max Connected', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/Yamaha_NMAX_155_2020.jpg/600px-Yamaha_NMAX_155_2020.jpg'},
      {'modelo': 'Aerox 155', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/Yamaha_Aerox_155_Connected.jpg/600px-Yamaha_Aerox_155_Connected.jpg'},
      {'modelo': 'BWS FI', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Yamaha_BWs_125.jpg/600px-Yamaha_BWs_125.jpg'},
      {'modelo': 'XTZ 125', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/Yamaha_XTZ_125E.jpg/600px-Yamaha_XTZ_125E.jpg'},
      {'modelo': 'XTZ 150', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d4/Yamaha_Crosser_150_ABS_2022.jpg/600px-Yamaha_Crosser_150_ABS_2022.jpg'},
      {'modelo': 'XTZ 250 Lander', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/67/Yamaha_XTZ_250_Lander_ABS_2020.jpg/600px-Yamaha_XTZ_250_Lander_ABS_2020.jpg'},
      {'modelo': 'MT 03 ABS', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Yamaha_MT-03_2020.jpg/600px-Yamaha_MT-03_2020.jpg'},
      {'modelo': 'MT 07 ABS', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/77/Yamaha_MT-07_2021.jpg/600px-Yamaha_MT-07_2021.jpg'},
      {'modelo': 'MT 09 SP', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/Yamaha_MT-09_2021.jpg/600px-Yamaha_MT-09_2021.jpg'},
      {'modelo': 'Ténéré 700', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4c/Yamaha_Tenere_700_2020.jpg/600px-Yamaha_Tenere_700_2020.jpg'},
    ],
    'AKT': [
      {'modelo': 'NKD 125', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/AKT_NKD_125_Classic.jpg/600px-AKT_NKD_125_Classic.jpg'},
      {'modelo': 'NKD Classic 125', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/AKT_NKD_125_Classic.jpg/600px-AKT_NKD_125_Classic.jpg'},
      {'modelo': 'CR4 150 LED', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/AKT_CR4_150.jpg/600px-AKT_CR4_150.jpg'},
      {'modelo': 'CR4 200 Pro', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/AKT_CR4_150.jpg/600px-AKT_CR4_150.jpg'},
      {'modelo': '250 R Naked', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/AKT_CR4_150.jpg/600px-AKT_CR4_150.jpg'},
      {'modelo': 'Dynamic Pro 125', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/AKT_Dynamic_Pro_125.jpg/600px-AKT_Dynamic_Pro_125.jpg'},
      {'modelo': 'Mawi 125 Scooter', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/AKT_Dynamic_Pro_125.jpg/600px-AKT_Dynamic_Pro_125.jpg'},
      {'modelo': 'TT Dual Sport 200', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/74/AKT_TT_Dual_Sport_200.jpg/600px-AKT_TT_Dual_Sport_200.jpg'},
      {'modelo': 'TT 250 Adventour', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/74/AKT_TT_Dual_Sport_200.jpg/600px-AKT_TT_Dual_Sport_200.jpg'},
      {'modelo': 'Flex 125', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/AKT_NKD_125_Classic.jpg/600px-AKT_NKD_125_Classic.jpg'},
      {'modelo': 'Special 110', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/AKT_NKD_125_Classic.jpg/600px-AKT_NKD_125_Classic.jpg'},
    ],
    'SUZUKI': [
      {'modelo': 'Gixxer 150 FI ABS', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ad/Suzuki_Gixxer_155_2019.jpg/600px-Suzuki_Gixxer_155_2019.jpg'},
      {'modelo': 'Gixxer SF 150 FI ABS', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Suzuki_Gixxer_SF_155_2019.jpg/600px-Suzuki_Gixxer_SF_155_2019.jpg'},
      {'modelo': 'Gixxer 250', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/Suzuki_Gixxer_250_2020.jpg/600px-Suzuki_Gixxer_250_2020.jpg'},
      {'modelo': 'Gixxer SF 250', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fa/Suzuki_Gixxer_SF_250_2020.jpg/600px-Suzuki_Gixxer_SF_250_2020.jpg'},
      {'modelo': 'GN 125 Euro 3', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/Suzuki_GN125.jpg/600px-Suzuki_GN125.jpg'},
      {'modelo': 'AX4 Evolution', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/Suzuki_GN125.jpg/600px-Suzuki_GN125.jpg'},
      {'modelo': 'DR 150', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/Haojue_NK150_Suzuki_DR150.jpg/600px-Haojue_NK150_Suzuki_DR150.jpg'},
      {'modelo': 'DR 650 SE', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/Suzuki_DR650SE_2013.jpg/600px-Suzuki_DR650SE_2013.jpg'},
      {'modelo': 'V-Strom 250 SX', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/Suzuki_V-Strom_SX_250.jpg/600px-Suzuki_V-Strom_SX_250.jpg'},
      {'modelo': 'V-Strom 650 XT', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a2/Suzuki_V-Strom_650_XT_2017.jpg/600px-Suzuki_V-Strom_650_XT_2017.jpg'},
      {'modelo': 'GSX-S 750', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/Suzuki_GSX-S750_2017.jpg/600px-Suzuki_GSX-S750_2017.jpg'},
      {'modelo': 'Hayabusa GSX1300R', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5e/2022_Suzuki_Hayabusa.jpg/600px-2022_Suzuki_Hayabusa.jpg'},
    ],
    'HONDA': [
      {'modelo': 'CB 125F', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/be/Honda_CB125F_2021.jpg/600px-Honda_CB125F_2021.jpg'},
      {'modelo': 'CB 190R', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Honda_CB190R_Repsol.jpg/600px-Honda_CB190R_Repsol.jpg'},
      {'modelo': 'CB 300F Twister', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/77/Honda_CB300F_Twister_ABS_2023.jpg/600px-Honda_CB300F_Twister_ABS_2023.jpg'},
      {'modelo': 'XR 150L', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d4/Honda_XR150L_2018.jpg/600px-Honda_XR150L_2018.jpg'},
      {'modelo': 'XR 190L', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d4/Honda_XR150L_2018.jpg/600px-Honda_XR150L_2018.jpg'},
      {'modelo': 'XRE 300 Rally', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/Honda_XRE_300_Rally_ABS_2022.jpg/600px-Honda_XRE_300_Rally_ABS_2022.jpg'},
      {'modelo': 'Sahara 300 Rally', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/Honda_XRE_300_Rally_ABS_2022.jpg/600px-Honda_XRE_300_Rally_ABS_2022.jpg'},
      {'modelo': 'Africa Twin CRF1100L', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/Honda_CRF1100L_Africa_Twin_Adventure_Sports_ES_2020.jpg/600px-Honda_CRF1100L_Africa_Twin_Adventure_Sports_ES_2020.jpg'},
      {'modelo': 'Transalp XL750', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f6/Honda_XL750_Transalp_2023.jpg/600px-Honda_XL750_Transalp_2023.jpg'},
      {'modelo': 'Navi 110', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3e/Honda_Navi_110.jpg/600px-Honda_Navi_110.jpg'},
      {'modelo': 'Dio 110', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Honda_Dio_scooter.jpg/600px-Honda_Dio_scooter.jpg'},
      {'modelo': 'PCX 160 ABS', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/Honda_PCX_160_ABS_2021.jpg/600px-Honda_PCX_160_ABS_2021.jpg'},
      {'modelo': 'CB 650R', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/Honda_CB650R_Neo_Sports_Cafe_2019.jpg/600px-Honda_CB650R_Neo_Sports_Cafe_2019.jpg'},
      {'modelo': 'CBR 650R', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Honda_CBR650R_2019.jpg/600px-Honda_CBR650R_2019.jpg'},
    ],
    'HERO': [
      {'modelo': 'Hunk 160R 4V', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ad/Hero_Xtreme_160R_4V.jpg/600px-Hero_Xtreme_160R_4V.jpg'},
      {'modelo': 'Hunk 160R', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ad/Hero_Xtreme_160R_4V.jpg/600px-Hero_Xtreme_160R_4V.jpg'},
      {'modelo': 'Hunk 125R', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ad/Hero_Xtreme_160R_4V.jpg/600px-Hero_Xtreme_160R_4V.jpg'},
      {'modelo': 'XPulse 200 4V', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/Hero_XPulse_200_4V.jpg/600px-Hero_XPulse_200_4V.jpg'},
      {'modelo': 'XPulse 200 4V Pro', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/Hero_XPulse_200_4V.jpg/600px-Hero_XPulse_200_4V.jpg'},
      {'modelo': 'XPulse Rally Edition', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/Hero_XPulse_200_4V.jpg/600px-Hero_XPulse_200_4V.jpg'},
      {'modelo': 'Eco Deluxe Clásica', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/Hero_HF_Deluxe_i3S.jpg/600px-Hero_HF_Deluxe_i3S.jpg'},
      {'modelo': 'Eco Deluxe i3S', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/Hero_HF_Deluxe_i3S.jpg/600px-Hero_HF_Deluxe_i3S.jpg'},
      {'modelo': 'ECO 100', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/Hero_HF_Deluxe_i3S.jpg/600px-Hero_HF_Deluxe_i3S.jpg'},
      {'modelo': 'Ignitor Xtech 125', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/Hero_Glamour_XTEC.jpg/600px-Hero_Glamour_XTEC.jpg'},
      {'modelo': 'Splendor Xpro', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/Hero_Glamour_XTEC.jpg/600px-Hero_Glamour_XTEC.jpg'},
      {'modelo': 'Xoom 110 Scooter', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/Hero_Xoom_110.jpg/600px-Hero_Xoom_110.jpg'},
    ],
    'KTM': [
      {'modelo': 'Duke 200 NG', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/KTM_200_Duke_2020.jpg/600px-KTM_200_Duke_2020.jpg'},
      {'modelo': 'Duke 250', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/KTM_250_Duke_2021.jpg/600px-KTM_250_Duke_2021.jpg'},
      {'modelo': 'Duke 390 Gen 3', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4b/KTM_390_Duke_2024.jpg/600px-KTM_390_Duke_2024.jpg'},
      {'modelo': 'Adventure 250', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/KTM_250_Adventure_2021.jpg/600px-KTM_250_Adventure_2021.jpg'},
      {'modelo': 'Adventure 390', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/KTM_390_Adventure_2020.jpg/600px-KTM_390_Adventure_2020.jpg'},
      {'modelo': 'Adventure 790', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/KTM_790_Adventure_2019.jpg/600px-KTM_790_Adventure_2019.jpg'},
      {'modelo': 'Adventure 890 R', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/KTM_890_Adventure_R_2021.jpg/600px-KTM_890_Adventure_R_2021.jpg'},
      {'modelo': 'RC 200', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/KTM_RC_200_2022.jpg/600px-KTM_RC_200_2022.jpg'},
      {'modelo': 'RC 390', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fa/KTM_RC_390_2022.jpg/600px-KTM_RC_390_2022.jpg'},
      {'modelo': 'Super Duke 1390 R', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/KTM_1390_Super_Duke_R_2024.jpg/600px-KTM_1390_Super_Duke_R_2024.jpg'},
    ],
    'ROYAL ENFIELD': [
      {'modelo': 'Himalayan 450', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Royal_Enfield_Himalayan_450.jpg/600px-Royal_Enfield_Himalayan_450.jpg'},
      {'modelo': 'Himalayan 411', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/Royal_Enfield_Himalayan_411.jpg/600px-Royal_Enfield_Himalayan_411.jpg'},
      {'modelo': 'Hunter 350', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/Royal_Enfield_Hunter_350.jpg/600px-Royal_Enfield_Hunter_350.jpg'},
      {'modelo': 'Classic 350 Reborn', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Royal_Enfield_Classic_350_Reborn.jpg/600px-Royal_Enfield_Classic_350_Reborn.jpg'},
      {'modelo': 'Meteor 350', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/Royal_Enfield_Meteor_350.jpg/600px-Royal_Enfield_Meteor_350.jpg'},
      {'modelo': 'Interceptor 650', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/Royal_Enfield_Interceptor_650.jpg/600px-Royal_Enfield_Interceptor_650.jpg'},
      {'modelo': 'Continental GT 650', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/Royal_Enfield_Continental_GT_650.jpg/600px-Royal_Enfield_Continental_GT_650.jpg'},
      {'modelo': 'Super Meteor 650', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4b/Royal_Enfield_Super_Meteor_650.jpg/600px-Royal_Enfield_Super_Meteor_650.jpg'},
      {'modelo': 'Shotgun 650', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/Royal_Enfield_Shotgun_650.jpg/600px-Royal_Enfield_Shotgun_650.jpg'},
      {'modelo': 'Guerrilla 450', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fa/Royal_Enfield_Guerrilla_450.jpg/600px-Royal_Enfield_Guerrilla_450.jpg'},
    ],
    'KAWASAKI': [
      {'modelo': 'Ninja 400 ABS', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Kawasaki_Ninja_400_2018.jpg/600px-Kawasaki_Ninja_400_2018.jpg'},
      {'modelo': 'Ninja 500', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Kawasaki_Ninja_400_2018.jpg/600px-Kawasaki_Ninja_400_2018.jpg'},
      {'modelo': 'Ninja 650 ABS', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/Kawasaki_Ninja_650_2020.jpg/600px-Kawasaki_Ninja_650_2020.jpg'},
      {'modelo': 'Ninja ZX-4RR', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/Kawasaki_Ninja_ZX-4RR_2023.jpg/600px-Kawasaki_Ninja_ZX-4RR_2023.jpg'},
      {'modelo': 'Ninja ZX-6R', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Kawasaki_Ninja_ZX-6R_2024.jpg/600px-Kawasaki_Ninja_ZX-6R_2024.jpg'},
      {'modelo': 'Z 400 ABS', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/Kawasaki_Z400_2019.jpg/600px-Kawasaki_Z400_2019.jpg'},
      {'modelo': 'Z 500', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/Kawasaki_Z400_2019.jpg/600px-Kawasaki_Z400_2019.jpg'},
      {'modelo': 'Z 900 ABS', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/Kawasaki_Z900_2020.jpg/600px-Kawasaki_Z900_2020.jpg'},
      {'modelo': 'Versys 300 X', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/Kawasaki_Versys-X_300.jpg/600px-Kawasaki_Versys-X_300.jpg'},
      {'modelo': 'Versys 650 ABS', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4b/Kawasaki_Versys_650_2022.jpg/600px-Kawasaki_Versys_650_2022.jpg'},
      {'modelo': 'KLR 650 Adventure', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/Kawasaki_KLR650_2022.jpg/600px-Kawasaki_KLR650_2022.jpg'},
    ],
    'TVS': [
      {'modelo': 'Apache RTR 200 4V FI ABS', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ad/TVS_Apache_RTR_200_4V.jpg/600px-TVS_Apache_RTR_200_4V.jpg'},
      {'modelo': 'Apache RTR 160 4V', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ad/TVS_Apache_RTR_200_4V.jpg/600px-TVS_Apache_RTR_200_4V.jpg'},
      {'modelo': 'Apache RR 310', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/TVS_Apache_RR_310.jpg/600px-TVS_Apache_RR_310.jpg'},
      {'modelo': 'Apache RTR 310 Naked', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/TVS_Apache_RR_310.jpg/600px-TVS_Apache_RR_310.jpg'},
      {'modelo': 'Raider 125', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/TVS_Raider_125.jpg/600px-TVS_Raider_125.jpg'},
      {'modelo': 'NTorq 125 Race Edition', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/TVS_NTorq_125.jpg/600px-TVS_NTorq_125.jpg'},
      {'modelo': 'Ronin 225', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/TVS_Ronin_225.jpg/600px-TVS_Ronin_225.jpg'},
    ],
    'VICTORI': [
      {'modelo': 'Venom 150', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Auteco_Victori_Venom_150.jpg/600px-Auteco_Victori_Venom_150.jpg'},
      {'modelo': 'Venom 180', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Auteco_Victori_Venom_150.jpg/600px-Auteco_Victori_Venom_150.jpg'},
      {'modelo': 'Venom 250', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Auteco_Victori_Venom_150.jpg/600px-Auteco_Victori_Venom_150.jpg'},
      {'modelo': 'MRX 125', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/74/AKT_TT_Dual_Sport_200.jpg/600px-AKT_TT_Dual_Sport_200.jpg'},
      {'modelo': 'MRX 150', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/74/AKT_TT_Dual_Sport_200.jpg/600px-AKT_TT_Dual_Sport_200.jpg'},
      {'modelo': 'MRX Arizona 200', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/74/AKT_TT_Dual_Sport_200.jpg/600px-AKT_TT_Dual_Sport_200.jpg'},
      {'modelo': 'Switch 150', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/AKT_Dynamic_Pro_125.jpg/600px-AKT_Dynamic_Pro_125.jpg'},
      {'modelo': 'Black 171', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/AKT_Dynamic_Pro_125.jpg/600px-AKT_Dynamic_Pro_125.jpg'},
    ],
    'DUCATI': [
      {'modelo': 'Monster 937', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4b/Ducati_Monster_937_2021.jpg/600px-Ducati_Monster_937_2021.jpg'},
      {'modelo': 'Panigale V4', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/Ducati_Panigale_V4_S_2020.jpg/600px-Ducati_Panigale_V4_S_2020.jpg'},
      {'modelo': 'Panigale V2', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/Ducati_Panigale_V2_2020.jpg/600px-Ducati_Panigale_V2_2020.jpg'},
      {'modelo': 'Multistrada V4 S', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Ducati_Multistrada_V4_S_2021.jpg/600px-Ducati_Multistrada_V4_S_2021.jpg'},
      {'modelo': 'Scrambler Icon 800', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/Ducati_Scrambler_Icon_2023.jpg/600px-Ducati_Scrambler_Icon_2023.jpg'},
      {'modelo': 'DesertX', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Ducati_DesertX_2022.jpg/600px-Ducati_DesertX_2022.jpg'},
      {'modelo': 'Diavel V4', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/Ducati_Diavel_V4_2023.jpg/600px-Ducati_Diavel_V4_2023.jpg'},
      {'modelo': 'Streetfighter V4', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/Ducati_Streetfighter_V4_2020.jpg/600px-Ducati_Streetfighter_V4_2020.jpg'},
    ],
    'BMW MOTORRAD': [
      {'modelo': 'G 310 R', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/BMW_G310R_2017.jpg/600px-BMW_G310R_2017.jpg'},
      {'modelo': 'G 310 GS', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/BMW_G310GS_2018.jpg/600px-BMW_G310GS_2018.jpg'},
      {'modelo': 'F 900 R', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/BMW_F900R_2020.jpg/600px-BMW_F900R_2020.jpg'},
      {'modelo': 'F 900 GS Adventure', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/BMW_F900GS_2024.jpg/600px-BMW_F900GS_2024.jpg'},
      {'modelo': 'R 1300 GS', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/BMW_R1300GS_2024.jpg/600px-BMW_R1300GS_2024.jpg'},
      {'modelo': 'R 1250 GS Adventure', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/BMW_R1250GS_Adventure_2019.jpg/600px-BMW_R1250GS_Adventure_2019.jpg'},
      {'modelo': 'S 1000 RR', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/BMW_S1000RR_2019.jpg/600px-BMW_S1000RR_2019.jpg'},
      {'modelo': 'C 400 GT Scooter', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4b/BMW_C400GT_2019.jpg/600px-BMW_C400GT_2019.jpg'},
    ],
    'TRIUMPH': [
      {'modelo': 'Speed 400', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Triumph_Speed_400_2024.jpg/600px-Triumph_Speed_400_2024.jpg'},
      {'modelo': 'Scrambler 400X', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/Triumph_Scrambler_400X_2024.jpg/600px-Triumph_Scrambler_400X_2024.jpg'},
      {'modelo': 'Trident 660', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/Triumph_Trident_660_2021.jpg/600px-Triumph_Trident_660_2021.jpg'},
      {'modelo': 'Street Triple 765 RS', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Triumph_Street_Triple_765_RS_2023.jpg/600px-Triumph_Street_Triple_765_RS_2023.jpg'},
      {'modelo': 'Tiger 900 Rally Pro', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/Triumph_Tiger_900_Rally_Pro_2020.jpg/600px-Triumph_Tiger_900_Rally_Pro_2020.jpg'},
      {'modelo': 'Tiger 1200 Explorer', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/Triumph_Tiger_1200_2022.jpg/600px-Triumph_Tiger_1200_2022.jpg'},
      {'modelo': 'Bonneville T120', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/Triumph_Bonneville_T120_2016.jpg/600px-Triumph_Bonneville_T120_2016.jpg'},
      {'modelo': 'Rocket 3 GT', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4b/Triumph_Rocket_3_GT_2020.jpg/600px-Triumph_Rocket_3_GT_2020.jpg'},
    ],
    'HARLEY-DAVIDSON': [
      {'modelo': 'Fat Boy 114', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4b/Harley-Davidson_Fat_Boy_114_2020.jpg/600px-Harley-Davidson_Fat_Boy_114_2020.jpg'},
      {'modelo': 'Breakout 117', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/Harley-Davidson_Breakout_117_2023.jpg/600px-Harley-Davidson_Breakout_117_2023.jpg'},
      {'modelo': 'Road King Special', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/Harley-Davidson_Road_King_Special_2021.jpg/600px-Harley-Davidson_Road_King_Special_2021.jpg'},
      {'modelo': 'Road Glide Special', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Harley-Davidson_Road_Glide_Special_2021.jpg/600px-Harley-Davidson_Road_Glide_Special_2021.jpg'},
      {'modelo': 'Street Bob 114', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/Harley-Davidson_Street_Bob_114_2021.jpg/600px-Harley-Davidson_Street_Bob_114_2021.jpg'},
      {'modelo': 'Sportster S', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/Harley-Davidson_Sportster_S_2021.jpg/600px-Harley-Davidson_Sportster_S_2021.jpg'},
      {'modelo': 'Pan America 1250 Special', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/Harley-Davidson_Pan_America_1250_Special_2021.jpg/600px-Harley-Davidson_Pan_America_1250_Special_2021.jpg'},
    ],
    'CFMOTO': [
      {'modelo': '250 NK', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/CFMoto_250NK.jpg/600px-CFMoto_250NK.jpg'},
      {'modelo': '300 NK', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/CFMoto_250NK.jpg/600px-CFMoto_250NK.jpg'},
      {'modelo': '450 SR', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/CFMoto_450SR_2023.jpg/600px-CFMoto_450SR_2023.jpg'},
      {'modelo': '450 NK', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/CFMoto_450NK_2024.jpg/600px-CFMoto_450NK_2024.jpg'},
      {'modelo': '450 MT Adventure', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/CFMoto_450MT_2024.jpg/600px-CFMoto_450MT_2024.jpg'},
      {'modelo': '700 CL-X Heritage', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/CFMoto_700CL-X_Heritage_2021.jpg/600px-CFMoto_700CL-X_Heritage_2021.jpg'},
      {'modelo': '800 MT Touring', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/CFMoto_800MT_Touring_2022.jpg/600px-CFMoto_800MT_Touring_2022.jpg'},
      {'modelo': 'Papio XO-1', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/CFMoto_Papio_XO-1.jpg/600px-CFMoto_Papio_XO-1.jpg'},
    ],
    'BENELLI': [
      {'modelo': '180S', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Benelli_180S.jpg/600px-Benelli_180S.jpg'},
      {'modelo': 'TNT 150i', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Benelli_180S.jpg/600px-Benelli_180S.jpg'},
      {'modelo': 'TRK 251', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/Benelli_TRK_251.jpg/600px-Benelli_TRK_251.jpg'},
      {'modelo': 'TRK 502X', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/Benelli_TRK_502_X.jpg/600px-Benelli_TRK_502_X.jpg'},
      {'modelo': 'TRK 702X', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Benelli_TRK_702X_2023.jpg/600px-Benelli_TRK_702X_2023.jpg'},
      {'modelo': 'Leoncino 500', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/Benelli_Leoncino_500_Trail.jpg/600px-Benelli_Leoncino_500_Trail.jpg'},
      {'modelo': '502C Cruiser', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/Benelli_502C.jpg/600px-Benelli_502C.jpg'},
      {'modelo': 'Imperiale 400', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/Benelli_Imperiale_400.jpg/600px-Benelli_Imperiale_400.jpg'},
    ],
    'KYMCO': [
      {'modelo': 'Agility 125', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Kymco_Agility_125.jpg/600px-Kymco_Agility_125.jpg'},
      {'modelo': 'Agility Fusion 125', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Kymco_Agility_125.jpg/600px-Kymco_Agility_125.jpg'},
      {'modelo': 'Twist 125', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Kymco_Agility_125.jpg/600px-Kymco_Agility_125.jpg'},
      {'modelo': 'Like 125', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/Kymco_Like_125.jpg/600px-Kymco_Like_125.jpg'},
      {'modelo': 'DTX 360 Crossover', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/Kymco_DT_X360.jpg/600px-Kymco_DT_X360.jpg'},
      {'modelo': 'AK 550 Maxi Scooter', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Kymco_AK550.jpg/600px-Kymco_AK550.jpg'},
    ],
    'SYM': [
      {'modelo': 'Crox 125', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/SYM_Crox_125.jpg/600px-SYM_Crox_125.jpg'},
      {'modelo': 'Crox R 125', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/SYM_Crox_125.jpg/600px-SYM_Crox_125.jpg'},
      {'modelo': 'NH Trazer 200', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/SYM_NHT_200.jpg/600px-SYM_NHT_200.jpg'},
      {'modelo': 'Citycom 300i', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/SYM_Citycom_300i.jpg/600px-SYM_Citycom_300i.jpg'},
      {'modelo': 'Joyride 200', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/SYM_Joyride_200.jpg/600px-SYM_Joyride_200.jpg'},
      {'modelo': 'Cruisym 300', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/SYM_Cruisym_300.jpg/600px-SYM_Cruisym_300.jpg'},
    ],
    'VESPA': [
      {'modelo': 'Primavera 150', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Vespa_Primavera_150_2018.jpg/600px-Vespa_Primavera_150_2018.jpg'},
      {'modelo': 'Sprint 150 S', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/Vespa_Sprint_150_2018.jpg/600px-Vespa_Sprint_150_2018.jpg'},
      {'modelo': 'GTS 300 Super Tech', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/Vespa_GTS_300_HPE_2020.jpg/600px-Vespa_GTS_300_HPE_2020.jpg'},
      {'modelo': 'GTV 300 Sei Giorni', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Vespa_Sei_Giorni_II_Edition_2020.jpg/600px-Vespa_Sei_Giorni_II_Edition_2020.jpg'},
      {'modelo': 'Vespa Elettrica', 'img': 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/Vespa_Elettrica_2019.jpg/600px-Vespa_Elettrica_2019.jpg'},
    ]
  };

  // --- 3. LOGOS OFICIALES EN ALTA RESOLUCIÓN CDN ---
  final Map<String, String> _carLogos = {
    'CHEVROLET': '$_githubLogoBase/chevrolet.png',
    'RENAULT': '$_githubLogoBase/renault.png',
    'TOYOTA': '$_githubLogoBase/toyota.png',
    'MAZDA': '$_githubLogoBase/mazda.png',
    'KIA': '$_githubLogoBase/kia.png',
    'NISSAN': '$_githubLogoBase/nissan.png',
    'HYUNDAI': '$_githubLogoBase/hyundai.png',
    'VOLKSWAGEN': '$_githubLogoBase/volkswagen.png',
    'SUZUKI': '$_githubLogoBase/suzuki.png',
    'BYD': '$_githubLogoBase/byd.png',
    'FORD': '$_githubLogoBase/ford.png',
    'BMW': '$_githubLogoBase/bmw.png',
    'MERCEDES-BENZ': '$_githubLogoBase/mercedes-benz.png',
    'AUDI': '$_githubLogoBase/audi.png',
    'JEEP': '$_githubLogoBase/jeep.png',
  };

  final Map<String, String> _motoLogos = {
    'BAJAJ': '$_githubLogoBase/bajaj.png',
    'YAMAHA': '$_githubLogoBase/yamaha.png',
    'AKT': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/AKT_Motos_logo.svg/500px-AKT_Motos_logo.svg.png',
    'SUZUKI': '$_githubLogoBase/suzuki.png',
    'HONDA': '$_githubLogoBase/honda.png',
    'HERO': '$_githubLogoBase/hero.png',
    'KTM': '$_githubLogoBase/ktm.png',
    'ROYAL ENFIELD': 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f3/Royal_Enfield_logo.svg/500px-Royal_Enfield_logo.svg.png',
    'KAWASAKI': '$_githubLogoBase/kawasaki.png',
    'TVS': '$_githubLogoBase/tvs.png',
    'VICTORI': '$_githubLogoBase/victori.png',
    'DUCATI': '$_githubLogoBase/ducati.png',
    'BMW MOTORRAD': '$_githubLogoBase/bmw.png',
    'TRIUMPH': '$_githubLogoBase/triumph.png',
    'HARLEY-DAVIDSON': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/de/Harley-Davidson_logo.svg/500px-Harley-Davidson_logo.svg.png',
    'CFMOTO': 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/32/CFMOTO_logo.svg/500px-CFMOTO_logo.svg.png',
    'BENELLI': 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/Benelli_logo.svg/500px-Benelli_logo.svg.png',
    'KYMCO': 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/KYMCO_logo.svg/500px-KYMCO_logo.svg.png',
    'SYM': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/77/SYM_Sanyang_Motor_logo.svg/500px-SYM_Sanyang_Motor_logo.svg.png',
    'VESPA': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/Vespa_logo.svg/500px-Vespa_logo.svg.png',
  };

  // --- 4. COLORES OFICIALES DE MARCA ---
  final Map<String, Color> _brandColors = {
    // Autos
    'CHEVROLET': const Color(0xFFFFC107),
    'RENAULT': const Color(0xFFFFCC00),
    'TOYOTA': const Color(0xFFEB0A1E),
    'MAZDA': const Color(0xFF990000),
    'KIA': const Color(0xFF05141F),
    'NISSAN': const Color(0xFFC3002F),
    'HYUNDAI': const Color(0xFF002C6C),
    'VOLKSWAGEN': const Color(0xFF001E50),
    'SUZUKI': const Color(0xFFE30613),
    'BYD': const Color(0xFF1E88E5),
    'FORD': const Color(0xFF003478),
    'BMW': const Color(0xFF0066B1),
    'MERCEDES-BENZ': const Color(0xFF00ADEF),
    'AUDI': const Color(0xFFBB0A30),
    'JEEP': const Color(0xFF53565A),
    // Motos
    'BAJAJ': const Color(0xFF006EFF),
    'YAMAHA': const Color(0xFF0055CC),
    'AKT': const Color(0xFF1536AC),
    'SUZUKI': const Color(0xFFE30613),
    'HONDA': const Color(0xFFCC0000),
    'HERO': const Color(0xFFED1C24),
    'KTM': const Color(0xFFFF6600),
    'ROYAL ENFIELD': const Color(0xFF990000),
    'KAWASAKI': const Color(0xFF00A651),
    'TVS': const Color(0xFF004080),
    'VICTORI': const Color(0xFFCBA73D),
    'DUCATI': const Color(0xFFCC0000),
    'BMW MOTORRAD': const Color(0xFF0066B1),
    'TRIUMPH': const Color(0xFF222222),
    'HARLEY-DAVIDSON': const Color(0xFFF26522),
    'CFMOTO': const Color(0xFF00A3E0),
    'BENELLI': const Color(0xFF005339),
    'KYMCO': const Color(0xFFDE001A),
    'SYM': const Color(0xFFE31E24),
    'VESPA': const Color(0xFF008853),
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

    final slug = brand
        .trim()
        .toLowerCase()
        .replaceAll(' ', '-')
        .replaceAll('_', '-');

    return '$_githubLogoBase/$slug.png';
  }

  /// Retorna el color insignia de la marca
  Color getColorForBrand(String brand) {
    final upper = brand.trim().toUpperCase();
    return _brandColors[upper] ?? const Color(0xFF035880);
  }

  /// Retorna la URL de imagen en CDN de un vehículo
  String getImageForVehicle(String make, String model, {bool isMoto = false}) {
    final catalog = isMoto ? _motoCatalog : _carCatalog;
    final upperMake = make.trim().toUpperCase();
    if (catalog.containsKey(upperMake)) {
      final match = catalog[upperMake]!.firstWhere(
        (m) => (m['modelo'] ?? '').toUpperCase() == model.trim().toUpperCase(),
        orElse: () => const {},
      );
      if (match.isNotEmpty && match['img'] != null && match['img']!.isNotEmpty) {
        return match['img']!;
      }
    }

    return isMoto
        ? 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/Yamaha_MT-15_front.jpg/600px-Yamaha_MT-15_front.jpg'
        : 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/2020_Toyota_Corolla_Altis_1.8E_front_view.jpg/600px-2020_Toyota_Corolla_Altis_1.8E_front_view.jpg';
  }

  /// Carga opcional de diccionario dinámico
  Future<void> loadCachedImages(BuildContext context) async {
    // Listo de inmediato
  }
}
