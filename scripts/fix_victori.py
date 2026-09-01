# scripts/fix_victori.py
import json
import os

dest = os.path.join('assets', 'data', 'colombian_vehicle_catalog.json')
with open(dest, 'r', encoding='utf-8') as f:
    catalog = json.load(f)

if 'VICTORI' in catalog.get('motos', {}):
    catalog['motos']['VICTORI']['modelos'] = [
        {"nombre": "Venom 150", "img_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Auteco_Victori_Venom_150.jpg/800px-Auteco_Victori_Venom_150.jpg"},
        {"nombre": "Venom 180", "img_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Auteco_Victori_Venom_150.jpg/800px-Auteco_Victori_Venom_150.jpg"},
        {"nombre": "MRX 125", "img_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Auteco_Victori_Venom_150.jpg/800px-Auteco_Victori_Venom_150.jpg"},
        {"nombre": "MRX 150", "img_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Auteco_Victori_Venom_150.jpg/800px-Auteco_Victori_Venom_150.jpg"},
        {"nombre": "Switch 150", "img_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Auteco_Victori_Venom_150.jpg/800px-Auteco_Victori_Venom_150.jpg"}
    ]

with open(dest, 'w', encoding='utf-8') as f:
    json.dump(catalog, f, ensure_ascii=False, indent=2)

print("Victori actualizado.")
