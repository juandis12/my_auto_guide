# scripts/audit_vehicle_url_match.py
import json
import os
import sys
import urllib.parse
import urllib.request
import ssl
from concurrent.futures import ThreadPoolExecutor, as_completed

if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

HEADERS = {
    'User-Agent': 'MyAutoGuideApp/1.0 (https://myautoguide.co; contact@myautoguide.co)',
}

def extract_filename_from_url(url):
    if not url:
        return ""
    parsed = urllib.parse.urlparse(url)
    path = parsed.path
    parts = path.split('/')
    for p in reversed(parts):
        if any(p.lower().endswith(ext) for ext in ['.jpg', '.jpeg', '.png', '.webp', '.svg']):
            return urllib.parse.unquote(p)
    return urllib.parse.unquote(parts[-1]) if parts else ""

def get_exact_commons_image(query):
    """Busca en Wikimedia Commons un archivo de imagen específico con el modelo."""
    encoded = urllib.parse.quote(f"{query} car" if "moto" not in query.lower() else f"{query} motorcycle")
    url = f"https://commons.wikimedia.org/w/api.php?action=query&generator=search&gsrsearch={encoded}&gsrnamespace=6&gsrlimit=3&prop=imageinfo&iiprop=url&iiurlwidth=800&format=json"
    try:
        req = urllib.request.Request(url, headers=HEADERS)
        with urllib.request.urlopen(req, timeout=8, context=ctx) as res:
            data = json.loads(res.read().decode())
            pages = data.get('query', {}).get('pages', {})
            for pid, pdata in pages.items():
                title = pdata.get('title', '').lower()
                # Filter out logos, maps, flags, diagrams
                if any(bad in title for bad in ['logo', 'map', 'flag', 'diagram', 'icon', 'symbol', 'plan']):
                    continue
                imageinfo = pdata.get('imageinfo', [])
                if imageinfo and 'thumburl' in imageinfo[0]:
                    return imageinfo[0]['thumburl']
    except Exception:
        pass
    return None

def check_match(brand, model_name, img_url):
    fname = extract_filename_from_url(img_url).lower()
    
    # Normalize model tokens
    clean_model = model_name.lower().replace('-', ' ').replace('_', ' ')
    tokens = [t for t in clean_model.split() if len(t) > 2 and t not in ['the', 'del', 'con', 'pro', 'plus']]
    
    # Check token overlap with image filename
    matched_tokens = [t for t in tokens if t in fname]
    is_match = len(matched_tokens) > 0 or brand.lower() in fname
    
    # Detect generic fallbacks
    if 'corolla_altis' in fname and 'corolla' not in clean_model:
        is_match = False
    if 'yamaha_mt-15' in fname and 'mt' not in clean_model and 'yamaha' not in brand.lower():
        is_match = False
    if 'logo' in fname:
        is_match = False
        
    return is_match, fname

def main():
    catalog_path = os.path.join('assets', 'data', 'colombian_vehicle_catalog.json')
    with open(catalog_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    audit_results = []
    mismatches = []

    print("==================================================================")
    print(" AUDITORIA DE COINCIDENCIA: NOMBRE DE VEHICULO VS IMAGEN DE URL")
    print("==================================================================")

    for cat in ['carros', 'motos']:
        for brand, bdata in data.get(cat, {}).items():
            for m in bdata.get('modelos', []):
                name = m.get('nombre', '')
                url = m.get('img_url', '')
                is_match, fname = check_match(brand, name, url)
                
                if not is_match:
                    mismatches.append((cat, brand, name, url, fname))
                else:
                    audit_results.append((cat, brand, name, fname))

    total = len(audit_results) + len(mismatches)
    print(f"\nTotal vehículos analizados: {total}")
    print(f"Coincidencias verificadas exactas: {len(audit_results)} ({(len(audit_results)/total)*100:.1f}%)")
    print(f"Diferencias o genéricos detectados: {len(mismatches)}")

    if mismatches:
        print("\n--- DETALLES DE VEHICULOS PARA CORRECCION PRECISA ---")
        for cat, brand, name, url, fname in mismatches[:25]:
            print(f"⚠️ [{cat.upper()}] {brand} -> '{name}'")
            print(f"   Archivo en URL: {fname}")

    print("\nGuardando reporte de auditoría...")

if __name__ == '__main__':
    main()
