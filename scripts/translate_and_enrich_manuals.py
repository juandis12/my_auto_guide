# scripts/translate_and_enrich_manuals.py
import json
import os
import sys
import re

if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

# Diccionario de traducciones técnicas automotrices para motos (Inglés -> Español)
TECHNICAL_TRANSLATIONS = [
    # Tipos de moto
    (r"\bnaked bike\b|\bnaked\b", "Naked / Urbana"),
    (r"\bsuper sport\b|\bsupersport\b", "Super Sport (Pista)"),
    (r"\bsport\b", "Deportiva"),
    (r"\btouring\b", "Turismo / Viajera"),
    (r"\badventure\b", "Aventura / Doble Propósito"),
    (r"\benduro\b|\boffroad\b|\boff-road\b", "Enduro / Todoterreno"),
    (r"\bcross\b|\bmotocross\b", "Motocross"),
    (r"\bcustom\b|\bcruiser\b", "Custom / Chopper"),
    (r"\bscooter\b", "Scooter / Automática"),
    (r"\ballround\b", "Multipropósito"),
    (r"\btrial\b", "Trial"),
    (r"\bclassic\b", "Clásica / Vintage"),
    (r"\bminibike\b", "Minibike / Recreativa"),
    
    # Motores y Cilindros
    (r"\bsingle cylinder\b", "Monocilíndrico"),
    (r"\btwo cylinder\b|\btwin\b", "Bicilíndrico"),
    (r"\bthree cylinder\b|\btriple\b", "Tricilíndrico"),
    (r"\bfour cylinder\b|\bfour-cylinder\b", "Tetracilíndrico (4 cilindros)"),
    (r"\bsix cylinder\b", "6 cilindros"),
    (r"\bv-twin\b", "Bicilíndrico en V"),
    (r"\bfour-stroke\b|\b4-stroke\b", "4 tiempos"),
    (r"\btwo-stroke\b|\b2-stroke\b", "2 tiempos"),
    (r"\bparallel twin\b", "Bicilíndrico en paralelo"),
    (r"\bv2\b", "Motor en V a 90°"),
    (r"\bv4\b", "Motor V4"),
    (r"\bboxer\b", "Bóxer bicilíndrico opuesto"),
    (r"\bin-line four\b|\binline four\b", "4 cilindros en línea"),
    
    # Refrigeración
    (r"\bliquid\b|\bliquid cooled\b|\bwater\b", "Líquida (Radiador)"),
    (r"\bair\b|\bair cooled\b", "Por aire natural"),
    (r"\boil\b|\boil cooled\b", "Por aire y radiador de aceite"),
    (r"\bair and oil\b", "Mixta (Aire y Aceite)"),
    
    # Arranque
    (r"\belectric & kick\b|\belectric and kick\b", "Eléctrico y Pedal"),
    (r"\belectric\b", "Eléctrico"),
    (r"\bkick\b", "Pedal (Patada)"),
    
    # Cajas de cambios y velocidades
    (r"(\d+)-speed", r"\1 velocidades"),
    (r"\bautomatic\b", "Automática (CVT)"),
    (r"\bmanual\b", "Manual"),
    (r"\b6-speed\b", "6 velocidades"),
    (r"\b5-speed\b", "5 velocidades"),
    (r"\b4-speed\b", "4 velocidades"),
    
    # Transmisión final
    (r"\bchain\b(?:\s*\(final drive\))?", "Cadena de transmisión"),
    (r"\bbelt\b(?:\s*\(final drive\))?", "Correa dentada"),
    (r"\bshaft\b(?:\s*\(final drive\))?", "Cardán"),
    
    # Embrague
    (r"\bwet, multi-plate\b|\bwet multi-plate\b|\bwet multiplate\b", "Multidisco en baño de aceite"),
    (r"\bwet\b", "Húmedo"),
    (r"\bdry\b", "Seco"),
    (r"\bmulti-plate\b|\bmultiplate\b", "Multidisco"),
    (r"\bslipper clutch\b", "Antirrebote (Slipper Clutch)"),
    (r"\bcentrifugal\b", "Centrífugo automático"),
    
    # Sistema de Combustible
    (r"\binjection\b|\belectronic injection\b", "Inyección Electrónica (FI)"),
    (r"\bcarburettor\b|\bcarburetor\b", "Carburador"),
    
    # Frenos
    (r"\bsingle disc\b", "Disco individual"),
    (r"\bdouble disc\b|\bdual disc\b", "Doble disco"),
    (r"\bexpanding brake\b|\bdrum brake\b|\bdrum\b", "Tambor"),
    (r"\bhydraulic\b", "hidráulico"),
    (r"\bwith abs\b|\babs\b", "con sistema ABS"),
    
    # Suspensiones
    (r"\btelescopic forks?\b", "Horquilla telescópica hidráulica"),
    (r"\bupside-down\b|\busd fork\b|\binverted fork\b", "Horquilla invertida (USD)"),
    (r"\bmonoshock\b|\bmono-shock\b", "Monoamortiguador ajustable (Monoshock)"),
    (r"\btwin shock\b|\bdual shock\b", "Doble amortiguador trasero"),
    
    # Chasis
    (r"\bsteel\b", "Acero"),
    (r"\baluminium\b|\baluminum\b", "Aluminio"),
    (r"\btrellis\b", "Multitubular tipo Trellis"),
    (r"\btwin spar\b|\bperimeter\b", "Perimetral de doble viga"),
    (r"\btubular\b", "Tubular de cuna"),
]

def clean_and_translate(text):
    if not text or not isinstance(text, str):
        return text
    
    result = text.strip()
    for pattern, replacement in TECHNICAL_TRANSLATIONS:
        result = re.sub(pattern, replacement, result, flags=re.IGNORECASE)
    
    # Limpieza de sufijos residuales en inglés
    result = re.sub(r"\s*\(final drive\)", "", result, flags=re.IGNORECASE)
    result = re.sub(r"\s*\(drum brake\)", "", result, flags=re.IGNORECASE)
    result = re.sub(r"\s*\(tambor brake\)", "", result, flags=re.IGNORECASE)
    result = re.sub(r"\s*\(disc brake\)", "", result, flags=re.IGNORECASE)
    result = result.replace(" ,", ",").replace(" / / ", " / ").strip()
    return result

def translate_manual(item):
    """Traduce todos los atributos de un manual de moto al español técnico."""
    return {
        "id": item.get("id") or f"{item.get('make')}_{item.get('model')}_{item.get('year')}".lower().replace(" ", "_"),
        "make": str(item.get("make") or "").strip().upper(),
        "model": str(item.get("model") or "").strip(),
        "year": str(item.get("year") or "").strip(),
        "type": clean_and_translate(item.get("type")),
        "displacement": item.get("displacement"),
        "engine": clean_and_translate(item.get("engine")),
        "power": item.get("power"),
        "torque": item.get("torque"),
        "compression": item.get("compression"),
        "valves_per_cylinder": item.get("valves_per_cylinder"),
        "fuel_system": clean_and_translate(item.get("fuel_system")),
        "fuel_control": clean_and_translate(item.get("fuel_control")),
        "lubrication": clean_and_translate(item.get("lubrication")),
        "cooling": clean_and_translate(item.get("cooling")),
        "gearbox": clean_and_translate(item.get("gearbox")),
        "transmission": clean_and_translate(item.get("transmission")),
        "clutch": clean_and_translate(item.get("clutch")),
        "frame": clean_and_translate(item.get("frame")),
        "front_suspension": clean_and_translate(item.get("front_suspension")),
        "rear_suspension": clean_and_translate(item.get("rear_suspension")),
        "front_wheel_travel": item.get("front_wheel_travel"),
        "rear_wheel_travel": item.get("rear_wheel_travel"),
        "front_tire": item.get("front_tire"),
        "rear_tire": item.get("rear_tire"),
        "front_brakes": clean_and_translate(item.get("front_brakes")),
        "rear_brakes": clean_and_translate(item.get("rear_brakes")),
        "seat_height": item.get("seat_height"),
        "ground_clearance": item.get("ground_clearance"),
        "wheelbase": item.get("wheelbase"),
        "fuel_capacity": item.get("fuel_capacity"),
        "fuel_consumption": item.get("fuel_consumption"),
        "emission": clean_and_translate(item.get("emission")),
        "total_weight": item.get("total_weight"),
        "dry_weight": item.get("dry_weight"),
        "starter": clean_and_translate(item.get("starter")),
        "ignition": clean_and_translate(item.get("ignition")),
        "top_speed": item.get("top_speed"),
    }

def main():
    manuals_path = os.path.join('assets', 'data', 'motorcycle_manuals.json')
    if not os.path.exists(manuals_path):
        print(f"Error: {manuals_path} no existe.")
        return
        
    with open(manuals_path, 'r', encoding='utf-8') as f:
        existing_data = json.load(f)

    translated_manuals = [translate_manual(m) for m in existing_data]
    
    with open(manuals_path, 'w', encoding='utf-8') as f:
        json.dump(translated_manuals, f, ensure_ascii=False, indent=2)

    print(f"✅ Se tradujeron y limpiaron con éxito {len(translated_manuals)} manuales de motos en {manuals_path}")

if __name__ == '__main__':
    main()
