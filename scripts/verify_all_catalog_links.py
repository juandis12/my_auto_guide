# scripts/verify_all_catalog_links.py
import json
import os
import sys
import urllib.request
import urllib.error
import ssl
from concurrent.futures import ThreadPoolExecutor, as_completed

if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
    'Accept': 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
    'Accept-Language': 'es-ES,es;q=0.9,en;q=0.8',
}

def check_url(item_info):
    category, brand, model_name, url = item_info
    if not url or not url.startswith('http'):
        return item_info, False, f"URL invalida: {url}"
    
    try:
        req = urllib.request.Request(url, headers=HEADERS, method='HEAD')
        with urllib.request.urlopen(req, timeout=8, context=ctx) as response:
            content_type = response.headers.get('Content-Type', '')
            status = response.getcode()
            if status == 200:
                return item_info, True, f"OK ({content_type})"
            else:
                return item_info, False, f"HTTP {status}"
    except urllib.error.HTTPError as e:
        # Algunos servidores no aceptan HEAD, intentar GET con Range bytes=0-1024
        try:
            get_headers = dict(HEADERS)
            get_headers['Range'] = 'bytes=0-1024'
            req2 = urllib.request.Request(url, headers=get_headers, method='GET')
            with urllib.request.urlopen(req2, timeout=8, context=ctx) as response2:
                content_type2 = response2.headers.get('Content-Type', '')
                status2 = response2.getcode()
                if status2 in (200, 206):
                    return item_info, True, f"OK GET ({content_type2})"
                else:
                    return item_info, False, f"HTTP {status2}"
        except Exception as e2:
            return item_info, False, f"HTTP Error: {e.code}"
    except Exception as e:
        return item_info, False, f"Error: {e}"

def main():
    catalog_path = os.path.join('assets', 'data', 'colombian_vehicle_catalog.json')
    if not os.path.exists(catalog_path):
        print(f"Error: {catalog_path} no existe.")
        return

    with open(catalog_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    tasks = []
    # Collect all URLs
    for cat in ['carros', 'motos']:
        if cat in data:
            for brand, bdata in data[cat].items():
                if 'logo_url' in bdata:
                    tasks.append((cat, brand, "[LOGO]", bdata['logo_url']))
                for m in bdata.get('modelos', []):
                    tasks.append((cat, brand, m['nombre'], m['img_url']))

    print(f"Verificando {len(tasks)} URLs de logos y vehiculos...")
    
    total = len(tasks)
    ok_count = 0
    failed = []

    with ThreadPoolExecutor(max_workers=20) as executor:
        futures = {executor.submit(check_url, t): t for t in tasks}
        for future in as_completed(futures):
            item_info, ok, msg = future.result()
            cat, brand, name, url = item_info
            if ok:
                ok_count += 1
            else:
                failed.append((cat, brand, name, url, msg))

    print(f"\n================ RESULTADOS ================")
    print(f"Total verificados: {total}")
    print(f"URLs funcionales (200 OK): {ok_count}/{total} ({(ok_count/total)*100:.1f}%)")
    print(f"URLs fallidas: {len(failed)}")

    if failed:
        print("\nLista de URLs con error:")
        for cat, brand, name, url, msg in failed:
            print(f"❌ [{cat.upper()}] {brand} - {name}: {msg}\n   URL: {url}")
    else:
        print("\n✅ TODAS LAS URLS ESTAN FUNCIONANDO CORRECTAMENTE!")

if __name__ == '__main__':
    main()
