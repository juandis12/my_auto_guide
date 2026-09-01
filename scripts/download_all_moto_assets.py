# scripts/download_all_moto_assets.py
import urllib.request
import urllib.parse
import json
import os
import sys
import re
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

headers = {
    'User-Agent': 'MyAutoGuide-Engineering-Bot/2.1 (https://myautoguide.app; moto-division@myautoguide.app)'
}

def clean_filename(text):
    clean = re.sub(r'[^a-zA-Z0-9_\-]', '_', text.strip().lower())
    clean = re.sub(r'_+', '_', clean).strip('_')
    return clean

def get_wikimedia_image_url(query):
    endpoint = 'https://en.wikipedia.org/w/api.php'
    params = {
        'action': 'query',
        'generator': 'search',
        'gsrsearch': query,
        'gsrlimit': 1,
        'prop': 'pageimages',
        'piprop': 'thumbnail',
        'pithumbsize': 600,
        'format': 'json'
    }
    url = f"{endpoint}?{urllib.parse.urlencode(params)}"
    for attempt in range(2):
        try:
            req = urllib.request.Request(url, headers=headers)
            res = urllib.request.urlopen(req, timeout=12)
            data = json.loads(res.read().decode('utf-8'))
            pages = data.get('query', {}).get('pages', {})
            for _, page in pages.items():
                thumb = page.get('thumbnail', {}).get('source')
                if thumb:
                    return thumb
        except Exception:
            time.sleep(0.3)
    return None

def download_file(url, dest_path):
    for attempt in range(2):
        try:
            req = urllib.request.Request(url, headers=headers)
            data = urllib.request.urlopen(req, timeout=15).read()
            if len(data) > 1000:
                os.makedirs(os.path.dirname(dest_path), exist_ok=True)
                with open(dest_path, 'wb') as f:
                    f.write(data)
                return True
        except Exception:
            time.sleep(0.3)
    return False

# 1. LOGOS DE TODAS LAS MARCAS DE MOTOS
MOTO_LOGOS = {
    'yamaha': 'https://raw.githubusercontent.com/filippofilip95/car-logos-dataset/master/logos/optimized/yamaha.png',
    'honda': 'https://raw.githubusercontent.com/filippofilip95/car-logos-dataset/master/logos/optimized/honda.png',
    'suzuki': 'https://raw.githubusercontent.com/filippofilip95/car-logos-dataset/master/logos/optimized/suzuki.png',
    'kawasaki': 'https://raw.githubusercontent.com/filippofilip95/car-logos-dataset/master/logos/optimized/kawasaki.png',
    'ktm': 'https://raw.githubusercontent.com/filippofilip95/car-logos-dataset/master/logos/optimized/ktm.png',
    'bmw': 'https://raw.githubusercontent.com/filippofilip95/car-logos-dataset/master/logos/optimized/bmw.png',
    'ducati': 'https://raw.githubusercontent.com/filippofilip95/car-logos-dataset/master/logos/optimized/ducati.png',
    'triumph': 'https://raw.githubusercontent.com/filippofilip95/car-logos-dataset/master/logos/optimized/triumph.png',
    'harley_davidson': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/de/Harley-Davidson_logo.svg/500px-Harley-Davidson_logo.svg.png',
    'royal_enfield': 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f3/Royal_Enfield_logo.svg/500px-Royal_Enfield_logo.svg.png',
    'aprilia': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/Aprilia-logo.svg/500px-Aprilia-logo.svg.png',
    'benelli': 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/Benelli_logo.svg/500px-Benelli_logo.svg.png',
    'husqvarna': 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/94/Husqvarna_Motorcycles_logo.svg/500px-Husqvarna_Motorcycles_logo.svg.png',
    'vespa': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/Vespa_logo.svg/500px-Vespa_logo.svg.png',
    'cfmoto': 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/32/CFMOTO_logo.svg/500px-CFMOTO_logo.svg.png',
    'kymco': 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/KYMCO_logo.svg/500px-KYMCO_logo.svg.png',
    'sym': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/77/SYM_Sanyang_Motor_logo.svg/500px-SYM_Sanyang_Motor_logo.svg.png',
}

# 2. MODELOS POPULARES DE MOTOS POR MARCA
MOTO_MODELS = [
    # HONDA
    ('honda', 'CB 125F', 'Honda CB125F'),
    ('honda', 'CB 190R', 'Honda CB190R'),
    ('honda', 'CB 300F Twister', 'Honda CB300F'),
    ('honda', 'XR 150L', 'Honda XR150L'),
    ('honda', 'XRE 300 Rally', 'Honda XRE300'),
    ('honda', 'Africa Twin CRF1100L', 'Honda CRF1100L Africa Twin'),
    ('honda', 'Transalp XL750', 'Honda XL750 Transalp'),
    ('honda', 'Navi 110', 'Honda Navi'),
    ('honda', 'PCX 160', 'Honda PCX'),
    ('honda', 'CB 650R', 'Honda CB650R'),
    ('honda', 'CBR 650R', 'Honda CBR650R'),
    ('honda', 'Dio 110', 'Honda Dio scooter'),
    # DUCATI
    ('ducati', 'Monster 937', 'Ducati Monster'),
    ('ducati', 'Panigale V4', 'Ducati Panigale V4'),
    ('ducati', 'Panigale V2', 'Ducati Panigale V2'),
    ('ducati', 'Multistrada V4', 'Ducati Multistrada V4'),
    ('ducati', 'Scrambler Icon', 'Ducati Scrambler'),
    ('ducati', 'DesertX', 'Ducati DesertX'),
    ('ducati', 'Diavel V4', 'Ducati Diavel'),
    ('ducati', 'Streetfighter V4', 'Ducati Streetfighter'),
    ('ducati', 'Hypermotard 950', 'Ducati Hypermotard'),
    # TRIUMPH
    ('triumph', 'Speed 400', 'Triumph Speed 400'),
    ('triumph', 'Scrambler 400X', 'Triumph Scrambler 400 X'),
    ('triumph', 'Trident 660', 'Triumph Trident 660'),
    ('triumph', 'Street Triple 765', 'Triumph Street Triple'),
    ('triumph', 'Tiger 900 Rally', 'Triumph Tiger 900'),
    ('triumph', 'Tiger 1200', 'Triumph Tiger 1200'),
    ('triumph', 'Bonneville T120', 'Triumph Bonneville T120'),
    ('triumph', 'Rocket 3', 'Triumph Rocket III'),
    # ROYAL ENFIELD
    ('royal_enfield', 'Himalayan 450', 'Royal Enfield Himalayan'),
    ('royal_enfield', 'Hunter 350', 'Royal Enfield Hunter 350'),
    ('royal_enfield', 'Classic 350', 'Royal Enfield Classic 350'),
    ('royal_enfield', 'Meteor 350', 'Royal Enfield Meteor 350'),
    ('royal_enfield', 'Interceptor 650', 'Royal Enfield Interceptor 650'),
    ('royal_enfield', 'Continental GT 650', 'Royal Enfield Continental GT 650'),
    ('royal_enfield', 'Super Meteor 650', 'Royal Enfield Super Meteor 650'),
    ('royal_enfield', 'Guerrilla 450', 'Royal Enfield Guerrilla 450'),
    # HARLEY-DAVIDSON
    ('harley_davidson', 'Iron 883', 'Harley-Davidson Sportster Iron 883'),
    ('harley_davidson', 'Sportster S', 'Harley-Davidson Sportster S'),
    ('harley_davidson', 'Fat Boy', 'Harley-Davidson Fat Boy'),
    ('harley_davidson', 'Street Bob 114', 'Harley-Davidson Street Bob'),
    ('harley_davidson', 'Pan America 1250', 'Harley-Davidson Pan America'),
    ('harley_davidson', 'Road Glide Special', 'Harley-Davidson Road Glide'),
    ('harley_davidson', 'Breakout 117', 'Harley-Davidson Breakout'),
    # APRILIA
    ('aprilia', 'RS 457', 'Aprilia RS 457'),
    ('aprilia', 'RS 660', 'Aprilia RS 660'),
    ('aprilia', 'Tuono 660', 'Aprilia Tuono 660'),
    ('aprilia', 'Tuareg 660', 'Aprilia Tuareg 660'),
    ('aprilia', 'RSV4 1100 Factory', 'Aprilia RSV4'),
    ('aprilia', 'SR GT 200', 'Aprilia SR GT'),
    # BENELLI
    ('benelli', 'TNT 150i', 'Benelli TNT 150'),
    ('benelli', '180S', 'Benelli 180S'),
    ('benelli', 'TRK 502X', 'Benelli TRK 502'),
    ('benelli', 'TRK 702X', 'Benelli TRK 702'),
    ('benelli', 'Leoncino 500', 'Benelli Leoncino 500'),
    ('benelli', 'Imperiale 400', 'Benelli Imperiale 400'),
    ('benelli', '502C Cruiser', 'Benelli 502C'),
    # CFMOTO
    ('cfmoto', '250 NK', 'CFMoto 250NK'),
    ('cfmoto', '300 NK', 'CFMoto 300NK'),
    ('cfmoto', '450 SR', 'CFMoto 450SR'),
    ('cfmoto', '450 MT Adventure', 'CFMoto 450MT'),
    ('cfmoto', '700 CL-X Heritage', 'CFMoto 700CL-X'),
    ('cfmoto', '800 MT Touring', 'CFMoto 800MT'),
    ('cfmoto', 'Papio XO-1', 'CFMoto Papio'),
    # HUSQVARNA
    ('husqvarna', 'Svartpilen 200', 'Husqvarna Svartpilen 200'),
    ('husqvarna', 'Svartpilen 401', 'Husqvarna Svartpilen 401'),
    ('husqvarna', 'Vitpilen 401', 'Husqvarna Vitpilen 401'),
    ('husqvarna', 'Norden 901 Expedition', 'Husqvarna Norden 901'),
    ('husqvarna', '701 Enduro', 'Husqvarna 701 Enduro'),
    ('husqvarna', '701 Supermoto', 'Husqvarna 701 Supermoto'),
    # VESPA
    ('vespa', 'Primavera 150', 'Vespa Primavera'),
    ('vespa', 'Sprint 150', 'Vespa Sprint'),
    ('vespa', 'GTS 300 Super Tech', 'Vespa GTS'),
    # KYMCO
    ('kymco', 'Agility 125', 'Kymco Agility 125'),
    ('kymco', 'Agility Fusion 125', 'Kymco Agility'),
    ('kymco', 'Twist 125', 'Kymco Twist 125'),
    ('kymco', 'DTX 360 Crossover', 'Kymco DTX 360'),
    ('kymco', 'AK 550 Maxi Scooter', 'Kymco AK 550'),
    # SYM
    ('sym', 'Crox 125', 'SYM Crox 125'),
    ('sym', 'NH Trazer 200', 'SYM NHT 200'),
    ('sym', 'Citycom 300i', 'SYM Citycom 300'),
]

def process_moto(item):
    brand, model_name, search_query = item
    brand_folder = clean_filename(brand)
    model_file = clean_filename(model_name) + '.png'
    
    dest_dir = os.path.join('assets', 'motos', brand_folder)
    dest_path = os.path.join(dest_dir, model_file)
    
    if os.path.exists(dest_path) and os.path.getsize(dest_path) > 1000:
        return f"[EXISTE] {dest_path}"
        
    img_url = get_wikimedia_image_url(search_query)
    if img_url:
        ok = download_file(img_url, dest_path)
        if ok:
            return f"[GUARDADO] {dest_path}"
            
    return f"[NO ENCONTRADO] {brand} {model_name}"

def main():
    print("=== DESCARGANDO LOGOS DE MOTOS ===")
    for brand, url in MOTO_LOGOS.items():
        dest = os.path.join('assets', 'logos', f"{brand}_logo.png")
        if not os.path.exists(dest):
            ok = download_file(url, dest)
            print(f"  Logo {brand}: {'OK' if ok else 'FAIL'}")
        else:
            print(f"  Logo {brand}: Ya existe")

    print("\n=== DESCARGANDO Y ORGANIZANDO MODELOS DE MOTOS POR CARPETA ===")
    with ThreadPoolExecutor(max_workers=3) as executor:
        futures = [executor.submit(process_moto, m) for m in MOTO_MODELS]
        for f in as_completed(futures):
            res = f.result()
            print(f"  {res}")
            time.sleep(0.2)

    print("\nPROCESO DE MOTOS COMPLETADO AL 100%!")

if __name__ == '__main__':
    main()
