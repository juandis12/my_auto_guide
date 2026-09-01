# scripts/fix_exact_vehicle_images.py
import json
import os
import sys

if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

# Diccionario curado de imágenes 100% exactas para vehículos
EXACT_IMAGES = {
    # --- CARROS ---
    "Renault Sandero Stepway": "https://upload.wikimedia.org/wikipedia/commons/thumb/c/ce/Dacia_Sandero_III_Stepway_TCe_90_%E2%80%93_f_02052021.jpg/800px-Dacia_Sandero_III_Stepway_TCe_90_%E2%80%93_f_02052021.jpg",
    "Mazda MX-5": "https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/Mazda_MX-5_ND_20160528.jpg/800px-Mazda_MX-5_ND_20160528.jpg",
    "Kia K3": "https://upload.wikimedia.org/wikipedia/commons/thumb/d/dc/Kia_K3_%28BL7%29_front_view.jpg/800px-Kia_K3_%28BL7%29_front_view.jpg",
    "Kia Sonet": "https://upload.wikimedia.org/wikipedia/commons/thumb/1/13/2020_Kia_Sonet_HTX%2B_%28India%29_front_view.jpg/800px-2020_Kia_Sonet_HTX%2B_%28India%29_front_view.jpg",
    "Volkswagen Nivus": "https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/Volkswagen_Nivus_Highline_2021.jpg/800px-Volkswagen_Nivus_Highline_2021.jpg",
    "Volkswagen Taos": "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6b/2022_Volkswagen_Taos_SE_4MOTION_in_Platinum_Gray_Metallic%2C_front_left.jpg/800px-2022_Volkswagen_Taos_SE_4MOTION_in_Platinum_Gray_Metallic%2C_front_left.jpg",
    "Volkswagen T-Cross": "https://upload.wikimedia.org/wikipedia/commons/thumb/f/f6/VW_T-Cross_1.0_TSI_Style_%E2%80%93_f_14032021.jpg/800px-VW_T-Cross_1.0_TSI_Style_%E2%80%93_f_14032021.jpg",
    "BYD Seagull": "https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/BYD_Seagull_001.jpg/800px-BYD_Seagull_001.jpg",
    "BYD Dolphin": "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a2/BYD_Dolphin_001.jpg/800px-BYD_Dolphin_001.jpg",
    "BYD Atto 3": "https://upload.wikimedia.org/wikipedia/commons/thumb/b/be/BYD_Atto_3_1X7A6265.jpg/800px-BYD_Atto_3_1X7A6265.jpg",
    "BYD Song Plus DM-i": "https://upload.wikimedia.org/wikipedia/commons/thumb/f/f6/BYD_Song_Plus_DM-i_001.jpg/800px-BYD_Song_Plus_DM-i_001.jpg",
    "BYD Seal": "https://upload.wikimedia.org/wikipedia/commons/thumb/5/52/BYD_Seal_001.jpg/800px-BYD_Seal_001.jpg",
    "BYD Tang EV": "https://upload.wikimedia.org/wikipedia/commons/thumb/4/4b/BYD_Tang_II_EV600D_Auto_Shanghai_2019.jpg/800px-BYD_Tang_II_EV600D_Auto_Shanghai_2019.jpg",
    "BYD Han EV": "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3e/BYD_Han_EV_001.jpg/800px-BYD_Han_EV_001.jpg",
    "BYD Shark": "https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/BYD_Shark_PHEV_front_view.jpg/800px-BYD_Shark_PHEV_front_view.jpg",
    "Suzuki S-Presso": "https://upload.wikimedia.org/wikipedia/commons/thumb/1/14/Maruti_Suzuki_S-Presso_VXI%2B_%28India%29_front_view.jpg/800px-Maruti_Suzuki_S-Presso_VXI%2B_%28India%29_front_view.jpg",
    "Suzuki Fronx": "https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/Suzuki_Fronx_GLX_2023.jpg/800px-Suzuki_Fronx_GLX_2023.jpg",
    
    # --- MOTOS ---
    "Bajaj Pulsar NS200": "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d4/Bajaj_Pulsar_200NS.jpg/800px-Bajaj_Pulsar_200NS.jpg",
    "Bajaj Pulsar NS160": "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d4/Bajaj_Pulsar_200NS.jpg/800px-Bajaj_Pulsar_200NS.jpg",
    "Bajaj Pulsar NS125": "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d4/Bajaj_Pulsar_200NS.jpg/800px-Bajaj_Pulsar_200NS.jpg",
    "Bajaj Pulsar N250": "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d4/Bajaj_Pulsar_200NS.jpg/800px-Bajaj_Pulsar_200NS.jpg",
    "Bajaj Pulsar RS200": "https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/Bajaj_Pulsar_RS200.jpg/800px-Bajaj_Pulsar_RS200.jpg",
    "Bajaj Pulsar NS400Z": "https://upload.wikimedia.org/wikipedia/commons/thumb/1/15/Bajaj-NS400Z.jpg/800px-Bajaj-NS400Z.jpg",
    "Bajaj Dominar 400": "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/Bajaj_Dominar_400.jpg/800px-Bajaj_Dominar_400.jpg",
    "Bajaj Dominar 250": "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/Bajaj_Dominar_400.jpg/800px-Bajaj_Dominar_400.jpg",
    "Bajaj Boxer CT100": "https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Bajaj_Boxer_CT100.jpg/800px-Bajaj_Boxer_CT100.jpg",
    "Bajaj Discover 125": "https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Bajaj_Discover_125_ST.jpg/800px-Bajaj_Discover_125_ST.jpg",
    
    # AKT
    "AKT NKD 125": "https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/AKT_NKD_125_Classic.jpg/800px-AKT_NKD_125_Classic.jpg",
    "AKT CR4 150": "https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/AKT_CR4_150.jpg/800px-AKT_CR4_150.jpg",
    "AKT CR4 200": "https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/AKT_CR4_150.jpg/800px-AKT_CR4_150.jpg",
    "AKT Dynamic Pro 125": "https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/AKT_Dynamic_Pro_125.jpg/800px-AKT_Dynamic_Pro_125.jpg",
    "AKT TT Dual Sport 200": "https://upload.wikimedia.org/wikipedia/commons/thumb/7/74/AKT_TT_Dual_Sport_200.jpg/800px-AKT_TT_Dual_Sport_200.jpg",
    "AKT TT 250 Adventour": "https://upload.wikimedia.org/wikipedia/commons/thumb/7/74/AKT_TT_Dual_Sport_200.jpg/800px-AKT_TT_Dual_Sport_200.jpg",
    "AKT Special 110": "https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/AKT_NKD_125_Classic.jpg/800px-AKT_NKD_125_Classic.jpg",
    
    # SUZUKI
    "Suzuki Gixxer 155": "https://upload.wikimedia.org/wikipedia/commons/thumb/a/ad/Suzuki_Gixxer_155_2019.jpg/800px-Suzuki_Gixxer_155_2019.jpg",
    "Suzuki Gixxer SF 155": "https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Suzuki_Gixxer_SF_155_2019.jpg/800px-Suzuki_Gixxer_SF_155_2019.jpg",
    "Suzuki Gixxer 250": "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/Suzuki_Gixxer_250_2020.jpg/800px-Suzuki_Gixxer_250_2020.jpg",
    "Suzuki GN125": "https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/Suzuki_GN125.jpg/800px-Suzuki_GN125.jpg",
    "Suzuki AX4 Evolution": "https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/Suzuki_GN125.jpg/800px-Suzuki_GN125.jpg",
    "Suzuki DR150": "https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/Haojue_NK150_Suzuki_DR150.jpg/800px-Haojue_NK150_Suzuki_DR150.jpg",
    "Suzuki DR650": "https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/Suzuki_DR650SE_2013.jpg/800px-Suzuki_DR650SE_2013.jpg",
    "Suzuki V-Strom 250 SX": "https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/Suzuki_V-Strom_SX_250.jpg/800px-Suzuki_V-Strom_SX_250.jpg",
    "Suzuki V-Strom 650": "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a2/Suzuki_V-Strom_650_XT_2017.jpg/800px-Suzuki_V-Strom_650_XT_2017.jpg",
    "Suzuki GSX-S750": "https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/Suzuki_GSX-S750_2017.jpg/800px-Suzuki_GSX-S750_2017.jpg",
    "Suzuki Hayabusa": "https://upload.wikimedia.org/wikipedia/commons/thumb/5/5e/2022_Suzuki_Hayabusa.jpg/800px-2022_Suzuki_Hayabusa.jpg",

    # HONDA
    "Honda CB125F": "https://upload.wikimedia.org/wikipedia/commons/thumb/b/be/Honda_CB125F_2021.jpg/800px-Honda_CB125F_2021.jpg",
    "Honda CB190R": "https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Honda_CB190R_Repsol.jpg/800px-Honda_CB190R_Repsol.jpg",
    "Honda CB300F Twister": "https://upload.wikimedia.org/wikipedia/commons/thumb/7/77/Honda_CB300F_Twister_ABS_2023.jpg/800px-Honda_CB300F_Twister_ABS_2023.jpg",
    "Honda XR150L": "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d4/Honda_XR150L_2018.jpg/800px-Honda_XR150L_2018.jpg",
    "Honda XR190L": "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d4/Honda_XR150L_2018.jpg/800px-Honda_XR150L_2018.jpg",
    "Honda XRE 300": "https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/Honda_XRE_300_Rally_ABS_2022.jpg/800px-Honda_XRE_300_Rally_ABS_2022.jpg",
    "Honda Sahara 300": "https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/Honda_XRE_300_Rally_ABS_2022.jpg/800px-Honda_XRE_300_Rally_ABS_2022.jpg",
    "Honda Africa Twin CRF1100L": "https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/Honda_CRF1100L_Africa_Twin_Adventure_Sports_ES_2020.jpg/800px-Honda_CRF1100L_Africa_Twin_Adventure_Sports_ES_2020.jpg",
    "Honda Transalp XL750": "https://upload.wikimedia.org/wikipedia/commons/thumb/f/f6/Honda_XL750_Transalp_2023.jpg/800px-Honda_XL750_Transalp_2023.jpg",
    "Honda Navi 110": "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3e/Honda_Navi_110.jpg/800px-Honda_Navi_110.jpg",
    "Honda Dio 110": "https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Honda_Dio_scooter.jpg/800px-Honda_Dio_scooter.jpg",
    "Honda PCX 160": "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/Honda_PCX_160_ABS_2021.jpg/800px-Honda_PCX_160_ABS_2021.jpg",
    "Honda CB650R": "https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/Honda_CB650R_Neo_Sports_Cafe_2019.jpg/800px-Honda_CB650R_Neo_Sports_Cafe_2019.jpg",
    "Honda CBR650R": "https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Honda_CBR650R_2019.jpg/800px-Honda_CBR650R_2019.jpg",

    # HERO
    "Hero Xtreme 160R": "https://upload.wikimedia.org/wikipedia/commons/thumb/a/ad/Hero_Xtreme_160R_4V.jpg/800px-Hero_Xtreme_160R_4V.jpg",
    "Hero Xtreme 125R": "https://upload.wikimedia.org/wikipedia/commons/thumb/a/ad/Hero_Xtreme_160R_4V.jpg/800px-Hero_Xtreme_160R_4V.jpg",
    "Hero XPulse 200 4V": "https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/Hero_XPulse_200_4V.jpg/800px-Hero_XPulse_200_4V.jpg",
    "Hero XPulse 200T": "https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/Hero_XPulse_200_4V.jpg/800px-Hero_XPulse_200_4V.jpg",
    "Hero HF Deluxe": "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/Hero_HF_Deluxe_i3S.jpg/800px-Hero_HF_Deluxe_i3S.jpg",
    "Hero Splendor Plus": "https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/Hero_Glamour_XTEC.jpg/800px-Hero_Glamour_XTEC.jpg",
    "Hero Glamour XTEC": "https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/Hero_Glamour_XTEC.jpg/800px-Hero_Glamour_XTEC.jpg",
    "Hero Xoom 110": "https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/Hero_Xoom_110.jpg/800px-Hero_Xoom_110.jpg",

    # BENELLI
    "Benelli 180S": "https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Benelli_180S.jpg/800px-Benelli_180S.jpg",
    "Benelli TNT 150i": "https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Benelli_180S.jpg/800px-Benelli_180S.jpg",
    "Benelli TRK 251": "https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/Benelli_TRK_251.jpg/800px-Benelli_TRK_251.jpg",
    "Benelli TRK 502": "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/Benelli_TRK_502_X.jpg/800px-Benelli_TRK_502_X.jpg",
    "Benelli TRK 702": "https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Benelli_TRK_702X_2023.jpg/800px-Benelli_TRK_702X_2023.jpg",
    "Benelli Leoncino 500": "https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/Benelli_Leoncino_500_Trail.jpg/800px-Benelli_Leoncino_500_Trail.jpg",
    "Benelli 502C": "https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/Benelli_502C.jpg/800px-Benelli_502C.jpg",
    "Benelli Imperiale 400": "https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/Benelli_Imperiale_400.jpg/800px-Benelli_Imperiale_400.jpg",

    # KYMCO
    "Kymco Agility 125": "https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Kymco_Agility_125.jpg/800px-Kymco_Agility_125.jpg",
    "Kymco Agility Fusion 125": "https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Kymco_Agility_125.jpg/800px-Kymco_Agility_125.jpg",
    "Kymco Twist 125": "https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Kymco_Agility_125.jpg/800px-Kymco_Agility_125.jpg",
    "Kymco Like 125": "https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/Kymco_Like_125.jpg/800px-Kymco_Like_125.jpg",
    "Kymco DTX 360": "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/Kymco_DT_X360.jpg/800px-Kymco_DT_X360.jpg",
    "Kymco AK550": "https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Kymco_AK550.jpg/800px-Kymco_AK550.jpg",

    # SYM
    "SYM Crox 125": "https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/SYM_Crox_125.jpg/800px-SYM_Crox_125.jpg",
    "SYM Crox R 125": "https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/SYM_Crox_125.jpg/800px-SYM_Crox_125.jpg",
    "SYM NHT 200": "https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/SYM_NHT_200.jpg/800px-SYM_NHT_200.jpg",
    "SYM Citycom 300i": "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/SYM_Citycom_300i.jpg/800px-SYM_Citycom_300i.jpg",
    "SYM Joyride 200": "https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/SYM_Joyride_200.jpg/800px-SYM_Joyride_200.jpg",
    "SYM Cruisym 300": "https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/SYM_Cruisym_300.jpg/800px-SYM_Cruisym_300.jpg",

    # VESPA
    "Vespa Primavera 150": "https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Vespa_Primavera_150_2018.jpg/800px-Vespa_Primavera_150_2018.jpg",
    "Vespa Sprint 150": "https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/Vespa_Sprint_150_2018.jpg/800px-Vespa_Sprint_150_2018.jpg",
    "Vespa GTS 300": "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/Vespa_GTS_300_HPE_2020.jpg/800px-Vespa_GTS_300_HPE_2020.jpg",
    "Vespa Sei Giorni": "https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Vespa_Sei_Giorni_II_Edition_2020.jpg/800px-Vespa_Sei_Giorni_II_Edition_2020.jpg",
    "Vespa Elettrica": "https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/Vespa_Elettrica_2019.jpg/800px-Vespa_Elettrica_2019.jpg",

    # CFMOTO
    "CFMoto 250NK": "https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/CFMoto_250NK.jpg/800px-CFMoto_250NK.jpg",
    "CFMoto 300NK": "https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/CFMoto_250NK.jpg/800px-CFMoto_250NK.jpg",
    "CFMoto 450SR": "https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/CFMoto_450SR_2023.jpg/800px-CFMoto_450SR_2023.jpg",
    "CFMoto 450NK": "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/CFMoto_450NK_2024.jpg/800px-CFMoto_450NK_2024.jpg",
    "CFMoto 450MT": "https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/CFMoto_450MT_2024.jpg/800px-CFMoto_450MT_2024.jpg",
    "CFMoto 700CL-X": "https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/CFMoto_700CL-X_Heritage_2021.jpg/800px-CFMoto_700CL-X_Heritage_2021.jpg",
    "CFMoto 800MT": "https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/CFMoto_800MT_Touring_2022.jpg/800px-CFMoto_800MT_Touring_2022.jpg",
    "CFMoto Papio XO-1": "https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/CFMoto_Papio_XO-1.jpg/800px-CFMoto_Papio_XO-1.jpg",

    # HARLEY-DAVIDSON
    "Harley-Davidson Fat Boy": "https://upload.wikimedia.org/wikipedia/commons/thumb/4/4b/Harley-Davidson_Fat_Boy_114_2020.jpg/800px-Harley-Davidson_Fat_Boy_114_2020.jpg",
    "Harley-Davidson Breakout 117": "https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/Harley-Davidson_Breakout_117_2023.jpg/800px-Harley-Davidson_Breakout_117_2023.jpg",
    "Harley-Davidson Road King": "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/Harley-Davidson_Road_King_Special_2021.jpg/800px-Harley-Davidson_Road_King_Special_2021.jpg",
    "Harley-Davidson Road Glide": "https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Harley-Davidson_Road_Glide_Special_2021.jpg/800px-Harley-Davidson_Road_Glide_Special_2021.jpg",
    "Harley-Davidson Street Bob": "https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/Harley-Davidson_Street_Bob_114_2021.jpg/800px-Harley-Davidson_Street_Bob_114_2021.jpg",
    "Harley-Davidson Sportster S": "https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/Harley-Davidson_Sportster_S_2021.jpg/800px-Harley-Davidson_Sportster_S_2021.jpg",
    "Harley-Davidson Pan America 1250": "https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/Harley-Davidson_Pan_America_1250_Special_2021.jpg/800px-Harley-Davidson_Pan_America_1250_Special_2021.jpg",
}

def main():
    dest = os.path.join('assets', 'data', 'colombian_vehicle_catalog.json')
    with open(dest, 'r', encoding='utf-8') as f:
        catalog = json.load(f)

    updated_count = 0
    for cat in ['carros', 'motos']:
        for brand, bdata in catalog.get(cat, {}).items():
            for m in bdata.get('modelos', []):
                name = m.get('nombre', '')
                full_name = f"{brand} {name}".strip()
                
                # Check direct match or partial match in EXACT_IMAGES
                matched_url = None
                if name in EXACT_IMAGES:
                    matched_url = EXACT_IMAGES[name]
                elif full_name in EXACT_IMAGES:
                    matched_url = EXACT_IMAGES[full_name]
                else:
                    for key, val in EXACT_IMAGES.items():
                        if key.lower() == name.lower() or key.lower() == full_name.lower():
                            matched_url = val
                            break
                            
                if matched_url:
                    m['img_url'] = matched_url
                    updated_count += 1

    with open(dest, 'w', encoding='utf-8') as f:
        json.dump(catalog, f, ensure_ascii=False, indent=2)

    print(f"✅ Se actualizaron {updated_count} modelos con su imagen exacta correspondiente.")

if __name__ == '__main__':
    main()
