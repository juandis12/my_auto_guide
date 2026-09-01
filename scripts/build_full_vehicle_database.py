# scripts/build_full_vehicle_database.py
import urllib.request
import json
import os
import sys

if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

headers = {'User-Agent': 'Mozilla/5.0'}

# Lista de las marcas más populares del mundo
POPULAR_CAR_MAKES = [
    "TOYOTA", "CHEVROLET", "RENAULT", "MAZDA", "NISSAN", "KIA", "HYUNDAI",
    "VOLKSWAGEN", "FORD", "SUZUKI", "HONDA", "BMW", "MERCEDES-BENZ", "AUDI",
    "JEEP", "BYD", "MITSUBISHI", "PEUGEOT", "FIAT", "SEAT", "CITROEN",
    "SUBARU", "VOLVO", "PORSCHE", "LAND ROVER", "LEXUS", "MINI", "DODGE",
    "RAM", "JAC", "CHANGAN", "CHERY", "GEELY", "GREAT WALL", "HAVAL",
    "MG", "CUPRA", "TESLA", "ALFA ROMEO", "JAGUAR", "FERRARI", "LAMBORGHINI"
]

def fetch_car_models_from_nhtsa():
    print("Iniciando extraccion de modelos de carros desde NHTSA API...")
    full_catalog = {}
    total_models = 0
    
    for make in POPULAR_CAR_MAKES:
        try:
            url = f"https://vpic.nhtsa.dot.gov/api/vehicles/GetModelsForMake/{make.lower()}?format=json"
            req = urllib.request.Request(url, headers=headers)
            res = urllib.request.urlopen(req, timeout=10)
            data = json.loads(res.read().decode('utf-8'))
            results = data.get('Results', [])
            
            unique_models = set()
            models_list = []
            
            for item in results:
                m_name = (item.get('Model_Name') or '').strip()
                if m_name and m_name not in unique_models:
                    unique_models.add(m_name)
                    models_list.append({
                        "modelo": m_name,
                        "tipo": "Automovil",
                        "img": "assets/car.png"
                    })
            
            if models_list:
                # Ordenar alfabeticamente
                models_list.sort(key=lambda x: x['modelo'])
                full_catalog[make] = models_list
                total_models += len(models_list)
                print(f"  -> {make}: {len(models_list)} modelos extraidos.")
        except Exception as e:
            print(f"  -> {make}: Error ({e})")
            
    os.makedirs('assets/data', exist_ok=True)
    out_file = 'assets/data/car_catalog.json'
    with open(out_file, 'w', encoding='utf-8') as f:
        json.dump(full_catalog, f, indent=2, ensure_ascii=False)
        
    print(f"PROCESO TERMINADO: {len(full_catalog)} marcas de carros con {total_models} modelos guardados en {out_file}")

if __name__ == '__main__':
    fetch_car_models_from_nhtsa()
