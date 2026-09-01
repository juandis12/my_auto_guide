# scripts/translate_and_enrich_manuals.py
import json
import os
import sys
import re

if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

def clean_text(text):
    if not text or not isinstance(text, str):
        return text
    
    res = text.strip()
    res = re.sub(r'(\bcon sistema\s+)+', 'con sistema ', res, flags=re.IGNORECASE)
    res = re.sub(r'(\bAutomática \(CVT\)\s*/\s*)+', 'Automática (CVT)', res, flags=re.IGNORECASE)
    res = re.sub(r'(\bScooter / Automática\s*/\s*)+', 'Scooter / Automática', res, flags=re.IGNORECASE)
    res = re.sub(r'(\bNaked / Urbana\s*/\s*)+', 'Naked / Urbana', res, flags=re.IGNORECASE)
    res = re.sub(r'(\bMonocilíndrico,\s*4 tiempos\s*,?\s*)+', 'Monocilíndrico, 4 tiempos', res, flags=re.IGNORECASE)
    res = re.sub(r'\s*\(final drive\)', '', res, flags=re.IGNORECASE)
    res = re.sub(r'\s*\(drum brake\)', '', res, flags=re.IGNORECASE)
    res = re.sub(r'\s*\(tambor brake\)', '', res, flags=re.IGNORECASE)
    res = re.sub(r'\s*\(disc brake\)', '', res, flags=re.IGNORECASE)
    res = res.replace(" ,", ",").replace(" / / ", " / ").strip()
    return res

def main():
    manuals_path = os.path.join('assets', 'data', 'motorcycle_manuals.json')
    if not os.path.exists(manuals_path):
        print(f"Error: {manuals_path} no existe.")
        return
        
    with open(manuals_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    for item in data:
        for k, v in item.items():
            if isinstance(v, str):
                item[k] = clean_text(v)

    with open(manuals_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print(f"✅ Se limpiaron y perfeccionaron los {len(data)} manuales.")

if __name__ == '__main__':
    main()
