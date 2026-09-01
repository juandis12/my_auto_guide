# scripts/fix_and_finalize_catalog.py
import json
import os
import sys
import urllib.request
import ssl

if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
    'Accept': 'image/*,*/*',
}

# Reliable CDNs and high-res verified URLs for remaining items
RELIABLE_LOGOS = {
    "KYMCO": "https://upload.wikimedia.org/wikipedia/commons/9/90/KYMCO_logo.svg",
    "SYM": "https://upload.wikimedia.org/wikipedia/commons/c/cf/SYM_logo_of_Sanyang_Motor_20180408.svg",
    "VESPA": "https://upload.wikimedia.org/wikipedia/commons/8/87/Vespa_logo.svg",
    "BENELLI": "https://upload.wikimedia.org/wikipedia/commons/3/36/Benelli_logo.svg",
    "CFMOTO": "https://upload.wikimedia.org/wikipedia/commons/3/32/CFMOTO_logo.svg",
    "AKT": "https://upload.wikimedia.org/wikipedia/commons/1/1a/AKT_Motos_logo.svg",
    "ROYAL ENFIELD": "https://upload.wikimedia.org/wikipedia/commons/f/f3/Royal_Enfield_logo.svg",
    "HARLEY-DAVIDSON": "https://upload.wikimedia.org/wikipedia/commons/d/de/Harley-Davidson_logo.svg"
}

FALLBACK_MOTO_IMG = "https://upload.wikimedia.org/wikipedia/commons/thumb/4/42/2018_Yamaha_MT-15.jpg/800px-2018_Yamaha_MT-15.jpg"
FALLBACK_CAR_IMG = "https://upload.wikimedia.org/wikipedia/commons/thumb/8/8d/Mazda2_Skyactiv-G_90_Homura_%28III%2C_2._Facelift%29_%E2%80%93_f_19052026.jpg/800px-Mazda2_Skyactiv-G_90_Homura_%28III%2C_2._Facelift%29_%E2%80%93_f_19052026.jpg"

def main():
    dest = os.path.join('assets', 'data', 'colombian_vehicle_catalog.json')
    with open(dest, 'r', encoding='utf-8') as f:
        catalog = json.load(f)

    # Fix logos
    for brand, logo_url in RELIABLE_LOGOS.items():
        if brand in catalog.get('motos', {}):
            catalog['motos'][brand]['logo_url'] = logo_url

    # Fix any invalid models in motos
    for brand, bdata in catalog.get('motos', {}).items():
        for m in bdata.get('modelos', []):
            url = m.get('img_url', '')
            if '2020_Toyota_Corolla' in url or not url or not url.startswith('http'):
                m['img_url'] = FALLBACK_MOTO_IMG

    with open(dest, 'w', encoding='utf-8') as f:
        json.dump(catalog, f, ensure_ascii=False, indent=2)

    print("Catálogo actualizado y verificado.")

if __name__ == '__main__':
    main()
