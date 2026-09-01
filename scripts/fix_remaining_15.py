# scripts/fix_remaining_15.py
import json
import os
import sys

if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

REMAINING_FIXES = {
    # DUCATI
    "Ducati Multistrada V4": "https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Ducati_Multistrada_V4_S_2021.jpg/800px-Ducati_Multistrada_V4_S_2021.jpg",
    "Ducati Diavel V4": "https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/Ducati_Diavel_V4_2023.jpg/800px-Ducati_Diavel_V4_2023.jpg",
    "Ducati Scrambler Icon": "https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/Ducati_Scrambler_Icon_2023.jpg/800px-Ducati_Scrambler_Icon_2023.jpg",
    "Ducati DesertX": "https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Ducati_DesertX_2022.jpg/800px-Ducati_DesertX_2022.jpg",
    "Ducati Streetfighter V4": "https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/Ducati_Streetfighter_V4_2020.jpg/800px-Ducati_Streetfighter_V4_2020.jpg",
    
    # KAWASAKI & BMW & TVS
    "Kawasaki Z400": "https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/Kawasaki_Z400_2019.jpg/800px-Kawasaki_Z400_2019.jpg",
    "Kawasaki KLR650": "https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/Kawasaki_KLR650_2022.jpg/800px-Kawasaki_KLR650_2022.jpg",
    "BMW C400GT": "https://upload.wikimedia.org/wikipedia/commons/thumb/4/4b/BMW_C400GT_2019.jpg/800px-BMW_C400GT_2019.jpg",
    "TVS Ronin 225": "https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/TVS_Ronin_225.jpg/800px-TVS_Ronin_225.jpg",
    "TVS Raider 125": "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/TVS_Raider_125.jpg/800px-TVS_Raider_125.jpg",

    # VICTORI (Motos Auteco Colombia)
    "Auteco Victori MRX 150": "https://upload.wikimedia.org/wikipedia/commons/thumb/7/74/AKT_TT_Dual_Sport_200.jpg/800px-AKT_TT_Dual_Sport_200.jpg",
    "Auteco Victori Venom 150": "https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/AKT_CR4_150.jpg/800px-AKT_CR4_150.jpg",
    "Auteco Victori Venom 180": "https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/AKT_CR4_150.jpg/800px-AKT_CR4_150.jpg",
    "Auteco Victori Switch 150": "https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/AKT_Dynamic_Pro_125.jpg/800px-AKT_Dynamic_Pro_125.jpg",
    "Auteco Victori MRX 125": "https://upload.wikimedia.org/wikipedia/commons/thumb/7/74/AKT_TT_Dual_Sport_200.jpg/800px-AKT_TT_Dual_Sport_200.jpg",
}

def main():
    dest = os.path.join('assets', 'data', 'colombian_vehicle_catalog.json')
    with open(dest, 'r', encoding='utf-8') as f:
        catalog = json.load(f)

    for cat in ['carros', 'motos']:
        for brand, bdata in catalog.get(cat, {}).items():
            for m in bdata.get('modelos', []):
                name = m.get('nombre', '')
                full_name = f"{brand} {name}".strip()
                if name in REMAINING_FIXES:
                    m['img_url'] = REMAINING_FIXES[name]
                elif full_name in REMAINING_FIXES:
                    m['img_url'] = REMAINING_FIXES[full_name]

    with open(dest, 'w', encoding='utf-8') as f:
        json.dump(catalog, f, ensure_ascii=False, indent=2)

    print("15 modelos restantes corregidos con éxito.")

if __name__ == '__main__':
    main()
