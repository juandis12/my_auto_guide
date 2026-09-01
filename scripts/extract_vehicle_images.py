# scripts/extract_vehicle_images.py
import urllib.request
import urllib.parse
import json
import os
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

headers = {
    'User-Agent': 'MyAutoGuideApp/2.0 (automotive mobile application; contact@myautoguide.app)'
}

def get_wikimedia_image(query):
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
    try:
        req = urllib.request.Request(url, headers=headers)
        res = urllib.request.urlopen(req, timeout=6)
        data = json.loads(res.read().decode('utf-8'))
        pages = data.get('query', {}).get('pages', {})
        for _, page in pages.items():
            thumb = page.get('thumbnail', {}).get('source')
            if thumb and any(ext in thumb.lower() for ext in ['.jpg', '.jpeg', '.png', '.webp']):
                return thumb
    except Exception:
        pass
    return None

def fetch_single(item):
    make, model, is_moto = item
    key = f"{make} {model}".strip().upper()
    query = f"{make} {model} motorcycle" if is_moto else f"{make} {model}"
    url = get_wikimedia_image(query)
    return key, url

def process_vehicle_images():
    print("Iniciando extraccion ultrarrapida de imagenes de vehiculos...")
    
    images_db_path = 'assets/data/vehicle_images.json'
    images_db = {}
    if os.path.exists(images_db_path):
        try:
            with open(images_db_path, 'r', encoding='utf-8') as f:
                images_db = json.load(f)
        except Exception:
            images_db = {}

    tasks = []

    # 1. Carros principales desde car_catalog.json
    car_catalog_path = 'assets/data/car_catalog.json'
    if os.path.exists(car_catalog_path):
        with open(car_catalog_path, 'r', encoding='utf-8') as f:
            car_data = json.load(f)
            
        for make, models in car_data.items():
            for m in models:
                model_name = m.get('modelo', '')
                key = f"{make} {model_name}".strip().upper()
                if key not in images_db or not images_db[key]:
                    tasks.append((make, model_name, False))

    # 2. Motos desde motorcycle_manuals.json
    moto_catalog_path = 'assets/data/motorcycle_manuals.json'
    if os.path.exists(moto_catalog_path):
        with open(moto_catalog_path, 'r', encoding='utf-8') as f:
            moto_data = json.load(f)
            
        seen = set()
        for item in moto_data:
            make = (item.get('make') or '').strip()
            model = (item.get('model') or '').strip()
            key = f"{make} {model}".strip().upper()
            if key and key not in seen:
                seen.add(key)
                if key not in images_db or not images_db[key]:
                    tasks.append((make, model, True))

    print(f"Total consultas en cola: {len(tasks)}")
    
    # Procesar con 8 hilos en paralelo
    completed = 0
    with ThreadPoolExecutor(max_workers=8) as executor:
        futures = {executor.submit(fetch_single, t): t for t in tasks}
        for future in as_completed(futures):
            key, url = future.result()
            if url:
                images_db[key] = url
            completed += 1
            if completed % 25 == 0 or completed == len(tasks):
                print(f"Progreso: {completed}/{len(tasks)} procesados. Imagenes encontradas: {len([v for v in images_db.values() if v])}")
                with open(images_db_path, 'w', encoding='utf-8') as f:
                    json.dump(images_db, f, indent=2, ensure_ascii=False)

    print("Extraccion completada con exito!")

if __name__ == '__main__':
    process_vehicle_images()
