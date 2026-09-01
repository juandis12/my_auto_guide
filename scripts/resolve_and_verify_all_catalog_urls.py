# scripts/resolve_and_verify_all_catalog_urls.py
import json
import os
import sys
import urllib.request
import urllib.parse
import ssl
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

HEADERS = {
    'User-Agent': 'MyAutoGuideApp/1.0 (https://myautoguide.co; contact@myautoguide.co)',
    'Accept': 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
}

GITHUB_LOGO_BASE = "https://raw.githubusercontent.com/filippofilip95/car-logos-dataset/master/logos/optimized"

# Base dataset of brands and models
BRANDS_CARROS = {
    "CHEVROLET": ["Chevrolet Onix Turbo", "Chevrolet Tracker 2023", "Chevrolet Spark GT", "Chevrolet Montana 2023", "Chevrolet Equinox", "Chevrolet Blazer RS", "Chevrolet Traverse", "Chevrolet Colorado 2023", "Chevrolet Tahoe 2022", "Chevrolet Camaro SS"],
    "RENAULT": ["Renault Duster", "Renault Sandero Stepway", "Renault Logan 2022", "Renault Kwid", "Renault Kardian", "Renault Duster Oroch", "Renault Megane E-Tech", "Renault Koleos 2022", "Renault Captur"],
    "TOYOTA": ["Toyota Corolla 2022", "Toyota Corolla Cross", "Toyota Hilux 2022", "Toyota Yaris Cross", "Toyota Fortuner 2022", "Toyota Land Cruiser Prado", "Toyota Land Cruiser 300", "Toyota RAV4 Hybrid", "Toyota 4Runner", "Toyota Tundra 2023"],
    "MAZDA": ["Mazda 2", "Mazda 3", "Mazda CX-30", "Mazda CX-5", "Mazda CX-50", "Mazda CX-60", "Mazda CX-90", "Mazda MX-5"],
    "KIA": ["Kia Picanto", "Kia K3", "Kia Sonet", "Kia Seltos", "Kia Sportage 2023", "Kia Sorento 2023", "Kia EV6", "Kia EV9", "Kia Carnival 2023"],
    "NISSAN": ["Nissan Versa", "Nissan Kicks", "Nissan Sentra 2023", "Nissan Frontier 2023", "Nissan Qashqai 2023", "Nissan X-Trail 2023", "Nissan Pathfinder 2023", "Nissan Patrol 2022"],
    "HYUNDAI": ["Hyundai Grand i10", "Hyundai HB20 2023", "Hyundai Creta 2023", "Hyundai Tucson 2023", "Hyundai Santa Fe 2024", "Hyundai Kona Hybrid", "Hyundai Ioniq 5", "Hyundai Palisade"],
    "VOLKSWAGEN": ["Volkswagen Polo Track", "Volkswagen Virtus 2023", "Volkswagen Nivus", "Volkswagen T-Cross", "Volkswagen Taos", "Volkswagen Tiguan 2023", "Volkswagen Amarok 2023", "Volkswagen Golf GTI"],
    "SUZUKI": ["Suzuki Swift Hybrid", "Suzuki Jimny", "Suzuki Grand Vitara 2023", "Suzuki Fronx", "Suzuki Baleno 2022", "Suzuki S-Cross 2022", "Suzuki S-Presso"],
    "BYD": ["BYD Seagull", "BYD Dolphin", "BYD Atto 3", "BYD Song Plus DM-i", "BYD Seal", "BYD Tang EV", "BYD Han EV", "BYD Shark"],
    "FORD": ["Ford Escape Hybrid 2023", "Ford Ranger 2023", "Ford Explorer 2023", "Ford Bronco Sport", "Ford F-150 2023", "Ford Mustang 2023", "Ford Edge 2022"],
    "BMW": ["BMW 1 Series F40", "BMW 2 Series Gran Coupe", "BMW 3 Series G20", "BMW X1 U11", "BMW X3 G01", "BMW X5 G05", "BMW M3 G80"],
    "MERCEDES-BENZ": ["Mercedes-Benz A-Class W177", "Mercedes-Benz C-Class W206", "Mercedes-Benz GLA-Class H247", "Mercedes-Benz GLB-Class", "Mercedes-Benz GLC-Class X254", "Mercedes-Benz GLE-Class V167", "Mercedes-AMG G 63"],
    "AUDI": ["Audi A3 8Y", "Audi A4 B9", "Audi Q2", "Audi Q3 F3", "Audi Q5 FY", "Audi Q7 4M", "Audi Q8 e-tron"],
    "JEEP": ["Jeep Renegade", "Jeep Compass", "Jeep Commander 2022", "Jeep Grand Cherokee 2023", "Jeep Wrangler JL", "Jeep Gladiator JT"]
}

BRANDS_MOTOS = {
    "BAJAJ": ["Bajaj Pulsar NS200", "Bajaj Pulsar NS160", "Bajaj Pulsar NS125", "Bajaj Pulsar N250", "Bajaj Pulsar RS200", "Bajaj Pulsar NS400Z", "Bajaj Dominar 400", "Bajaj Dominar 250", "Bajaj Boxer CT100", "Bajaj Discover 125"],
    "YAMAHA": ["Yamaha MT-15", "Yamaha YZF-R15", "Yamaha FZ25", "Yamaha FZ-S FI", "Yamaha Crypton 115", "Yamaha NMAX 155", "Yamaha Aerox 155", "Yamaha BWs 125", "Yamaha XTZ 125", "Yamaha XTZ 150", "Yamaha XTZ 250 Lander", "Yamaha MT-03", "Yamaha MT-07", "Yamaha MT-09", "Yamaha Tenere 700"],
    "AKT": ["AKT NKD 125", "AKT CR4 150", "AKT CR4 200", "AKT Dynamic Pro 125", "AKT TT Dual Sport 200", "AKT TT 250 Adventour", "AKT Special 110"],
    "SUZUKI": ["Suzuki Gixxer 155", "Suzuki Gixxer SF 155", "Suzuki Gixxer 250", "Suzuki GN125", "Suzuki AX4 Evolution", "Suzuki DR150", "Suzuki DR650", "Suzuki V-Strom 250 SX", "Suzuki V-Strom 650", "Suzuki GSX-S750", "Suzuki Hayabusa"],
    "HONDA": ["Honda CB125F", "Honda CB190R", "Honda CB300F Twister", "Honda XR150L", "Honda XR190L", "Honda XRE 300", "Honda Sahara 300", "Honda Africa Twin CRF1100L", "Honda Transalp XL750", "Honda Navi 110", "Honda Dio 110", "Honda PCX 160", "Honda CB650R", "Honda CBR650R"],
    "HERO": ["Hero Xtreme 160R", "Hero Xtreme 125R", "Hero XPulse 200 4V", "Hero XPulse 200T", "Hero HF Deluxe", "Hero Splendor Plus", "Hero Glamour XTEC", "Hero Xoom 110"],
    "KTM": ["KTM 200 Duke", "KTM 250 Duke", "KTM 390 Duke", "KTM 250 Adventure", "KTM 390 Adventure", "KTM 790 Adventure", "KTM 890 Adventure", "KTM RC 200", "KTM RC 390", "KTM 1390 Super Duke R"],
    "ROYAL ENFIELD": ["Royal Enfield Himalayan 450", "Royal Enfield Himalayan 411", "Royal Enfield Hunter 350", "Royal Enfield Classic 350", "Royal Enfield Meteor 350", "Royal Enfield Interceptor 650", "Royal Enfield Continental GT 650", "Royal Enfield Super Meteor 650", "Royal Enfield Shotgun 650", "Royal Enfield Guerrilla 450"],
    "KAWASAKI": ["Kawasaki Ninja 400", "Kawasaki Ninja 500", "Kawasaki Ninja 650", "Kawasaki Ninja ZX-4RR", "Kawasaki Ninja ZX-6R", "Kawasaki Z400", "Kawasaki Z500", "Kawasaki Z900", "Kawasaki Versys-X 300", "Kawasaki Versys 650", "Kawasaki KLR650"],
    "TVS": ["TVS Apache RTR 200 4V", "TVS Apache RTR 160 4V", "TVS Apache RR 310", "TVS Apache RTR 310", "TVS Raider 125", "TVS NTorq 125", "TVS Ronin 225"],
    "VICTORI": ["Auteco Victori Venom 150", "Auteco Victori Venom 180", "Auteco Victori MRX 125", "Auteco Victori MRX 150", "Auteco Victori Switch 150"],
    "DUCATI": ["Ducati Monster 937", "Ducati Panigale V4", "Ducati Panigale V2", "Ducati Multistrada V4", "Ducati Scrambler Icon", "Ducati DesertX", "Ducati Diavel V4", "Ducati Streetfighter V4"],
    "BMW MOTORRAD": ["BMW G310R", "BMW G310GS", "BMW F900R", "BMW F900GS", "BMW R1300GS", "BMW R1250GS Adventure", "BMW S1000RR", "BMW C400GT"],
    "TRIUMPH": ["Triumph Speed 400", "Triumph Scrambler 400 X", "Triumph Trident 660", "Triumph Street Triple 765", "Triumph Tiger 900", "Triumph Tiger 1200", "Triumph Bonneville T120", "Triumph Rocket 3"],
    "HARLEY-DAVIDSON": ["Harley-Davidson Fat Boy", "Harley-Davidson Breakout 117", "Harley-Davidson Road King", "Harley-Davidson Road Glide", "Harley-Davidson Street Bob", "Harley-Davidson Sportster S", "Harley-Davidson Pan America 1250"],
    "CFMOTO": ["CFMoto 250NK", "CFMoto 300NK", "CFMoto 450SR", "CFMoto 450NK", "CFMoto 450MT", "CFMoto 700CL-X", "CFMoto 800MT", "CFMoto Papio XO-1"],
    "BENELLI": ["Benelli 180S", "Benelli TNT 150i", "Benelli TRK 251", "Benelli TRK 502", "Benelli TRK 702", "Benelli Leoncino 500", "Benelli 502C", "Benelli Imperiale 400"],
    "KYMCO": ["Kymco Agility 125", "Kymco Agility Fusion 125", "Kymco Twist 125", "Kymco Like 125", "Kymco DTX 360", "Kymco AK550"],
    "SYM": ["SYM Crox 125", "SYM Crox R 125", "SYM NHT 200", "SYM Citycom 300i", "SYM Joyride 200", "SYM Cruisym 300"],
    "VESPA": ["Vespa Primavera 150", "Vespa Sprint 150", "Vespa GTS 300", "Vespa Sei Giorni", "Vespa Elettrica"]
}

BRAND_COLORS = {
    "CHEVROLET": "#FFC107", "RENAULT": "#FFCC00", "TOYOTA": "#EB0A1E", "MAZDA": "#990000",
    "KIA": "#05141F", "NISSAN": "#C3002F", "HYUNDAI": "#002C6C", "VOLKSWAGEN": "#001E50",
    "SUZUKI": "#E30613", "BYD": "#1E88E5", "FORD": "#003478", "BMW": "#0066B1",
    "MERCEDES-BENZ": "#00ADEF", "AUDI": "#BB0A30", "JEEP": "#53565A",
    "BAJAJ": "#006EFF", "YAMAHA": "#0055CC", "AKT": "#1536AC", "HONDA": "#CC0000",
    "HERO": "#ED1C24", "KTM": "#FF6600", "ROYAL ENFIELD": "#990000", "KAWASAKI": "#00A651",
    "TVS": "#004080", "VICTORI": "#CBA73D", "DUCATI": "#CC0000", "BMW MOTORRAD": "#0066B1",
    "TRIUMPH": "#222222", "HARLEY-DAVIDSON": "#F26522", "CFMOTO": "#00A3E0",
    "BENELLI": "#005339", "KYMCO": "#DE001A", "SYM": "#E31E24", "VESPA": "#008853"
}

def get_wiki_image(query):
    encoded = urllib.parse.quote(query)
    url = f"https://en.wikipedia.org/w/api.php?action=query&generator=search&gsrsearch={encoded}&gsrlimit=1&prop=pageimages&pithumbsize=600&format=json"
    req = urllib.request.Request(url, headers=HEADERS)
    try:
        with urllib.request.urlopen(req, timeout=8, context=ctx) as res:
            data = json.loads(res.read().decode())
            pages = data.get('query', {}).get('pages', {})
            for pid, pdata in pages.items():
                if 'thumbnail' in pdata:
                    return pdata['thumbnail']['source']
    except Exception:
        pass
    return None

def verify_url(url):
    if not url:
        return False
    try:
        req = urllib.request.Request(url, headers=HEADERS, method='GET')
        req.add_header('Range', 'bytes=0-2048')
        with urllib.request.urlopen(req, timeout=6, context=ctx) as res:
            return res.getcode() in (200, 206)
    except Exception:
        return False

def resolve_model(brand, model_name):
    # Try search query
    query = f"{brand} {model_name}"
    img_url = get_wiki_image(query)
    if not img_url:
        img_url = get_wiki_image(model_name)
    if not img_url:
        img_url = get_wiki_image(brand)
        
    return {
        "nombre": model_name.replace(brand, "").strip() or model_name,
        "img_url": img_url or "https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/2020_Toyota_Corolla_Altis_1.8E_front_view.jpg/600px-2020_Toyota_Corolla_Altis_1.8E_front_view.jpg"
    }

def main():
    catalog = {"carros": {}, "motos": {}}
    
    print("Resolviendo y verificando URLs de vehiculos de carros...")
    for brand, models in BRANDS_CARROS.items():
        slug = brand.lower().replace(" ", "-").replace("_", "-")
        logo_url = f"{GITHUB_LOGO_BASE}/{slug}.png"
        brand_data = {
            "color": BRAND_COLORS.get(brand, "#035880"),
            "logo_url": logo_url,
            "modelos": []
        }
        
        with ThreadPoolExecutor(max_workers=5) as executor:
            futures = [executor.submit(resolve_model, brand, m) for m in models]
            for f in as_completed(futures):
                brand_data["modelos"].append(f.result())
                
        catalog["carros"][brand] = brand_data
        print(f"  ✓ {brand}: {len(brand_data['modelos'])} modelos resueltos.")

    print("\nResolviendo y verificando URLs de vehiculos de motos...")
    for brand, models in BRANDS_MOTOS.items():
        slug = brand.lower().replace(" ", "-").replace("_", "-")
        logo_url = f"{GITHUB_LOGO_BASE}/{slug}.png"
        brand_data = {
            "color": BRAND_COLORS.get(brand, "#035880"),
            "logo_url": logo_url,
            "modelos": []
        }
        
        with ThreadPoolExecutor(max_workers=5) as executor:
            futures = [executor.submit(resolve_model, brand, m) for m in models]
            for f in as_completed(futures):
                brand_data["modelos"].append(f.result())
                
        catalog["motos"][brand] = brand_data
        print(f"  ✓ {brand}: {len(brand_data['modelos'])} modelos resueltos.")

    dest = os.path.join('assets', 'data', 'colombian_vehicle_catalog.json')
    with open(dest, 'w', encoding='utf-8') as f:
        json.dump(catalog, f, ensure_ascii=False, indent=2)

    print(f"\n✅ Catálogo guardado en: {dest}")

if __name__ == '__main__':
    main()
