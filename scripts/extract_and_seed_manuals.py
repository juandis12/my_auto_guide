#!/usr/bin/env python3
"""
Motorcycle Manuals & Technical Specs Extractor
Extrae fichas técnicas completas de API Ninjas y las inserta en Supabase y localmente en JSON.
"""

import urllib.request
import urllib.parse
import json
import time
import os
import sys

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

API_KEY = "Fl8fob3IKAjd3l4rFvIDdzUnUCjbwPvhQYI7KPtN"
SUPABASE_URL = "https://xstzerpnupubyfbhrrzu.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhzdHplcnBudXB1YnlmYmhycnp1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc3Mjg3NDYsImV4cCI6MjA3MzMwNDc0Nn0.viihWGH6wRcv3gQQ5AySAQtoCcIdGZ7kEaSWyhcz-3A"

# Lista de marcas principales y sub-búsquedas para extraer la mayor cantidad posible
BRANDS = [
    "yamaha", "honda", "suzuki", "kawasaki", "bajaj", "ktm", "bmw",
    "ducati", "harley-davidson", "triumph", "royal enfield", "tvs",
    "hero", "kymco", "benelli", "husqvarna", "aprilia", "mv agusta",
    "sym", "italika", "voge", "cf moto", "vespa", "piaggio"
]

YEARS = ["2024", "2023", "2022", "2021", "2020", "2019", "2018", "2017", "2016", "2015"]

def fetch_motorcycles(params):
    url = f"https://api.api-ninjas.com/v1/motorcycles?{urllib.parse.urlencode(params)}"
    req = urllib.request.Request(url, headers={"X-Api-Key": API_KEY, "User-Agent": "MyAutoGuide/1.0"})
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            if resp.status == 200:
                data = json.loads(resp.read().decode('utf-8'))
                return data
    except Exception as e:
        print(f"  ⚠️ Error en petición {params}: {e}")
    return []

def sanitize_item(item):
    """Mapea y limpia los campos de la API para la tabla motorcycle_manuals."""
    return {
        "make": str(item.get("make") or "").strip().title(),
        "model": str(item.get("model") or "").strip(),
        "year": str(item.get("year") or "").strip(),
        "type": item.get("type"),
        "displacement": item.get("displacement"),
        "engine": item.get("engine"),
        "power": item.get("power"),
        "torque": item.get("torque"),
        "compression": item.get("compression"),
        "valves_per_cylinder": item.get("valves_per_cylinder"),
        "fuel_system": item.get("fuel_system"),
        "fuel_control": item.get("fuel_control"),
        "lubrication": item.get("lubrication"),
        "cooling": item.get("cooling"),
        "gearbox": item.get("gearbox"),
        "transmission": item.get("transmission"),
        "clutch": item.get("clutch"),
        "frame": item.get("frame"),
        "front_suspension": item.get("front_suspension"),
        "rear_suspension": item.get("rear_suspension"),
        "front_wheel_travel": item.get("front_wheel_travel"),
        "rear_wheel_travel": item.get("rear_wheel_travel"),
        "front_tire": item.get("front_tire"),
        "rear_tire": item.get("rear_tire"),
        "front_brakes": item.get("front_brakes"),
        "rear_brakes": item.get("rear_brakes"),
        "seat_height": item.get("seat_height"),
        "ground_clearance": item.get("ground_clearance"),
        "wheelbase": item.get("wheelbase"),
        "fuel_capacity": item.get("fuel_capacity"),
        "fuel_consumption": item.get("fuel_consumption"),
        "emission": item.get("emission"),
        "total_weight": item.get("total_weight"),
        "dry_weight": item.get("dry_weight"),
        "starter": item.get("starter"),
        "ignition": item.get("ignition"),
        "top_speed": item.get("top_speed"),
        "raw_specs": item
    }

def push_to_supabase_batch(items_batch):
    """Inserta registros a Supabase usando REST con Upsert (ON CONFLICT ignore/merge)."""
    if not items_batch:
        return 0
    url = f"{SUPABASE_URL}/rest/v1/motorcycle_manuals"
    headers = {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Content-Type": "application/json",
        "Prefer": "resolution=merge-duplicates,return=minimal"
    }
    payload = json.dumps(items_batch).encode('utf-8')
    req = urllib.request.Request(url, data=payload, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            if resp.status in (200, 201):
                return len(items_batch)
            else:
                print(f"  ❌ Fallo Supabase con status {resp.status}")
    except urllib.error.HTTPError as he:
        err_msg = he.read().decode('utf-8')
        print(f"  ❌ Error HTTP Supabase: {he.code} - {err_msg[:200]}")
    except Exception as e:
        print(f"  ❌ Error enviando batch a Supabase: {e}")
    return 0

def main():
    print("==================================================")
    print("🚀 INICIANDO EXTRACCIÓN DE MANUALES DE MOTOCICLETAS")
    print("==================================================")

    all_motorcycles = {}
    total_extracted = 0

    for brand in BRANDS:
        print(f"\n🔍 Extrayendo marca: {brand.upper()}...")
        # 1. Búsqueda directa por marca
        items = fetch_motorcycles({"make": brand})
        time.sleep(0.3)
        for item in items:
            key = f"{item.get('make')}_{item.get('model')}_{item.get('year')}".lower()
            if key not in all_motorcycles and item.get("model"):
                all_motorcycles[key] = sanitize_item(item)

        # 2. Búsqueda por marca + año para maximizar cantidad
        for year in YEARS:
            items_year = fetch_motorcycles({"make": brand, "year": year})
            time.sleep(0.25)
            for item in items_year:
                key = f"{item.get('make')}_{item.get('model')}_{item.get('year')}".lower()
                if key not in all_motorcycles and item.get("model"):
                    all_motorcycles[key] = sanitize_item(item)
        
        print(f"  -> Total acumulado: {len(all_motorcycles)} motos únicas.")

    items_list = list(all_motorcycles.values())
    print(f"\n✅ Total extraído de API Ninjas: {len(items_list)} motocicletas.")

    # Guardar en archivo JSON local en assets/data/
    os.makedirs("assets/data", exist_ok=True)
    json_path = os.path.join("assets", "data", "motorcycle_manuals.json")
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(items_list, f, ensure_ascii=False, indent=2)
    print(f"💾 Guardado localmente en {json_path} ({os.path.getsize(json_path) // 1024} KB)")

    # Intentar subir a Supabase en lotes de 50
    print("\n☁️ Subiendo a Supabase (motorcycle_manuals)...")
    batch_size = 50
    inserted = 0
    for i in range(0, len(items_list), batch_size):
        batch = items_list[i:i + batch_size]
        count = push_to_supabase_batch(batch)
        inserted += count
        print(f"  📦 Lote {i // batch_size + 1}: {count} registros procesados.")
        time.sleep(0.2)

    print(f"\n🎉 PROCESO COMPLETADO: {len(items_list)} manuales listos.")

if __name__ == "__main__":
    main()
