# scripts/extract_all_cars_and_motorcycles.py
import urllib.request
import json
import os
import sys

# Force UTF-8 stdout if needed
if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'}

def fetch_all_car_models():
    print("Descargando base de datos completa de carros desde GitHub...")
    
    sources = [
        "https://raw.githubusercontent.com/abhionlyone/us-car-models-data/master/2024.json",
        "https://raw.githubusercontent.com/abhionlyone/us-car-models-data/master/2023.json",
        "https://raw.githubusercontent.com/abhionlyone/us-car-models-data/master/2022.json",
        "https://raw.githubusercontent.com/abhionlyone/us-car-models-data/master/2021.json",
        "https://raw.githubusercontent.com/abhionlyone/us-car-models-data/master/2020.json",
    ]
    
    cars_by_make = {}
    
    for src in sources:
        try:
            req = urllib.request.Request(src, headers=headers)
            content = urllib.request.urlopen(req).read().decode('utf-8')
            data = json.loads(content)
            print(f"Procesando {src.split('/')[-1]}: {len(data)} entradas")
            
            if isinstance(data, list):
                for item in data:
                    make = (item.get('make') or item.get('brand') or item.get('Make') or '').strip().upper()
                    model = (item.get('model') or item.get('Model') or item.get('name') or '').strip()
                    year = str(item.get('year') or item.get('Year') or '')
                    body_type = item.get('body_type') or item.get('type') or 'Automóvil'
                    
                    if not make or not model:
                        continue
                        
                    if make not in cars_by_make:
                        cars_by_make[make] = {}
                    
                    if model not in cars_by_make[make]:
                        cars_by_make[make][model] = {
                            "modelo": model,
                            "tipo": body_type,
                            "anios": [year] if year else [],
                            "img": "assets/car.png"
                        }
                    else:
                        if year and year not in cars_by_make[make][model]["anios"]:
                            cars_by_make[make][model]["anios"].append(year)
        except Exception as e:
            print(f"Error en fuente {src}: {e}")

    # Convertir a estructura de catálogo agrupado por marca
    formatted_cars = {}
    total_models = 0
    for make, models_dict in sorted(cars_by_make.items()):
        formatted_cars[make] = list(models_dict.values())
        total_models += len(formatted_cars[make])
        
    os.makedirs('assets/data', exist_ok=True)
    out_path = 'assets/data/car_catalog.json'
    with open(out_path, 'w', encoding='utf-8') as f:
        json.dump(formatted_cars, f, indent=2, ensure_ascii=False)
        
    print(f"Catálogo de Carros generado: {len(formatted_cars)} marcas, {total_models} modelos únicos guardados en {out_path}")

if __name__ == '__main__':
    fetch_all_car_models()
