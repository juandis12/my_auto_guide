# scripts/download_and_organize_vehicle_images.py
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
    'User-Agent': 'MyAutoGuide-Engineering-Bot/2.1 (https://myautoguide.app; info@myautoguide.app)'
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
            time.sleep(0.5)
    return None

def download_image(url, dest_path):
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
            time.sleep(0.5)
    return False

def process_vehicle(item):
    kind, brand, model = item
    brand_folder = clean_filename(brand)
    model_file = clean_filename(model) + '.png'
    
    dest_dir = os.path.join('assets', 'motos' if kind == 'moto' else 'carros', brand_folder)
    dest_path = os.path.join(dest_dir, model_file)
    
    if os.path.exists(dest_path) and os.path.getsize(dest_path) > 1000:
        return f"[EXISTE] {dest_path}"
        
    query = f"{brand} {model} motorcycle" if kind == 'moto' else f"{brand} {model}"
    img_url = get_wikimedia_image_url(query)
    
    if img_url:
        ok = download_image(img_url, dest_path)
        if ok:
            return f"[GUARDADO] {dest_path}"
            
    return f"[NO ENCONTRADO] {brand} {model}"

def main():
    print("Iniciando descarga y organizacion en carpetas de marcas...")
    
    vehicles_to_fetch = [
        # CARROS - RENAULT
        ('carro', 'renault', 'Duster'),
        ('carro', 'renault', 'Sandero'),
        ('carro', 'renault', 'Stepway'),
        ('carro', 'renault', 'Logan'),
        ('carro', 'renault', 'Kwid'),
        ('carro', 'renault', 'Kardian'),
        ('carro', 'renault', 'Oroch'),
        # CARROS - NISSAN
        ('carro', 'nissan', 'Versa'),
        ('carro', 'nissan', 'Kicks'),
        ('carro', 'nissan', 'Sentra'),
        ('carro', 'nissan', 'Frontier'),
        ('carro', 'nissan', 'Qashqai'),
        ('carro', 'nissan', 'X-Trail'),
        # CARROS - KIA
        ('carro', 'kia', 'Picanto'),
        ('carro', 'kia', 'Rio'),
        ('carro', 'kia', 'K3'),
        ('carro', 'kia', 'Sonet'),
        ('carro', 'kia', 'Seltos'),
        ('carro', 'kia', 'Sportage'),
        # CARROS - HYUNDAI
        ('carro', 'hyundai', 'HB20'),
        ('carro', 'hyundai', 'Creta'),
        ('carro', 'hyundai', 'Tucson'),
        ('carro', 'hyundai', 'Santa Fe'),
        ('carro', 'hyundai', 'Kona'),
        # CARROS - VOLKSWAGEN
        ('carro', 'volkswagen', 'Polo'),
        ('carro', 'volkswagen', 'Virtus'),
        ('carro', 'volkswagen', 'Nivus'),
        ('carro', 'volkswagen', 'T-Cross'),
        ('carro', 'volkswagen', 'Taos'),
        ('carro', 'volkswagen', 'Amarok'),
        ('carro', 'volkswagen', 'Golf'),
        # CARROS - FORD
        ('carro', 'ford', 'Ranger'),
        ('carro', 'ford', 'F-150'),
        ('carro', 'ford', 'Escape'),
        ('carro', 'ford', 'Explorer'),
        ('carro', 'ford', 'Bronco Sport'),
        ('carro', 'ford', 'Mustang'),
        # CARROS - SUZUKI
        ('carro', 'suzuki', 'Swift'),
        ('carro', 'suzuki', 'Jimny'),
        ('carro', 'suzuki', 'Grand Vitara'),
        ('carro', 'suzuki', 'Fronx'),
        # CARROS - HONDA
        ('carro', 'honda', 'Civic'),
        ('carro', 'honda', 'CR-V'),
        ('carro', 'honda', 'HR-V'),
        ('carro', 'honda', 'City'),
        # CARROS - BMW
        ('carro', 'bmw', 'Serie 3'),
        ('carro', 'bmw', 'X1'),
        ('carro', 'bmw', 'X3'),
        ('carro', 'bmw', 'X5'),
        # CARROS - MERCEDES-BENZ
        ('carro', 'mercedes-benz', 'Clase A'),
        ('carro', 'mercedes-benz', 'Clase C'),
        ('carro', 'mercedes-benz', 'GLA'),
        ('carro', 'mercedes-benz', 'GLC'),
        # CARROS - AUDI
        ('carro', 'audi', 'A3'),
        ('carro', 'audi', 'A4'),
        ('carro', 'audi', 'Q3'),
        ('carro', 'audi', 'Q5'),
        # CARROS - JEEP
        ('carro', 'jeep', 'Renegade'),
        ('carro', 'jeep', 'Compass'),
        ('carro', 'jeep', 'Wrangler'),
        ('carro', 'jeep', 'Grand Cherokee'),
        # CARROS - BYD
        ('carro', 'byd', 'Dolphin'),
        ('carro', 'byd', 'Song Plus'),
        ('carro', 'byd', 'Yuan Plus'),
        ('carro', 'byd', 'Seal'),
        # MOTOS - HONDA
        ('moto', 'honda', 'CB 125F'),
        ('moto', 'honda', 'CB 190R'),
        ('moto', 'honda', 'CB 300F Twister'),
        ('moto', 'honda', 'XR 150L'),
        ('moto', 'honda', 'XRE 300'),
        ('moto', 'honda', 'Africa Twin CRF1100L'),
        # MOTOS - DUCATI
        ('moto', 'ducati', 'Monster 937'),
        ('moto', 'ducati', 'Panigale V4'),
        ('moto', 'ducati', 'Multistrada V4'),
        ('moto', 'ducati', 'Scrambler Icon'),
        ('moto', 'ducati', 'DesertX'),
        # MOTOS - TRIUMPH
        ('moto', 'triumph', 'Speed 400'),
        ('moto', 'triumph', 'Scrambler 400X'),
        ('moto', 'triumph', 'Trident 660'),
        ('moto', 'triumph', 'Tiger 900 Rally'),
        ('moto', 'triumph', 'Bonneville T120'),
        # MOTOS - ROYAL ENFIELD
        ('moto', 'royal_enfield', 'Himalayan 450'),
        ('moto', 'royal_enfield', 'Hunter 350'),
        ('moto', 'royal_enfield', 'Classic 350'),
        ('moto', 'royal_enfield', 'Meteor 350'),
        ('moto', 'royal_enfield', 'Interceptor 650'),
    ]

    print(f"Total vehículos a procesar: {len(vehicles_to_fetch)}")
    
    with ThreadPoolExecutor(max_workers=3) as executor:
        futures = [executor.submit(process_vehicle, v) for v in vehicles_to_fetch]
        for f in as_completed(futures):
            res = f.result()
            print(f"  {res}")
            time.sleep(0.2)

    print("Organización por carpetas completada con éxito!")

if __name__ == '__main__':
    main()
