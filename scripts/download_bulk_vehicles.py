# scripts/download_bulk_vehicles.py
import urllib.request
import urllib.parse
import json
import os
import sys
import re
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

headers = {
    'User-Agent': 'MyAutoGuide-Engineering-Bot/2.2 (https://myautoguide.app; full-catalog@myautoguide.app)'
}

def clean_filename(text):
    clean = re.sub(r'[^a-zA-Z0-9_\-]', '_', text.strip().lower())
    clean = re.sub(r'_+', '_', clean).strip('_')
    return clean

def get_wikimedia_image_url(query):
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
    for attempt in range(2):
        try:
            req = urllib.request.Request(url, headers=headers)
            res = urllib.request.urlopen(req, timeout=12)
            data = json.loads(res.read().decode('utf-8'))
            pages = data.get('query', {}).get('pages', {})
            for _, page in pages.items():
                thumb = page.get('thumbnail', {}).get('source')
                if thumb:
                    return thumb
        except Exception:
            time.sleep(0.3)
    return None

def download_file(url, dest_path):
    for attempt in range(2):
        try:
            req = urllib.request.Request(url, headers=headers)
            data = urllib.request.urlopen(req, timeout=15).read()
            if len(data) > 1000:
                os.makedirs(os.path.dirname(dest_path), exist_ok=True)
                with open(dest_path, 'wb') as f:
                    f.write(data)
                return True
        except Exception:
            time.sleep(0.3)
    return False

ALL_VEHICLES = [
    # --- CARROS (Minimo 10 por marca) ---
    # TOYOTA
    ('carro', 'toyota', 'Corolla', 'Toyota Corolla'),
    ('carro', 'toyota', 'Hilux', 'Toyota Hilux'),
    ('carro', 'toyota', 'Yaris', 'Toyota Yaris'),
    ('carro', 'toyota', 'Yaris Cross', 'Toyota Yaris Cross'),
    ('carro', 'toyota', 'Tundra', 'Toyota Tundra'),
    ('carro', 'toyota', 'Land Cruiser 300', 'Toyota Land Cruiser J300'),
    ('carro', 'toyota', 'Fortuner', 'Toyota Fortuner'),
    ('carro', 'toyota', 'Corolla Cross', 'Toyota Corolla Cross'),
    ('carro', 'toyota', 'RAV4', 'Toyota RAV4'),
    ('carro', 'toyota', 'Prado', 'Toyota Land Cruiser Prado'),
    ('carro', 'toyota', 'Camry', 'Toyota Camry'),
    ('carro', 'toyota', '4Runner', 'Toyota 4Runner'),

    # CHEVROLET
    ('carro', 'chevrolet', 'Onix', 'Chevrolet Onix'),
    ('carro', 'chevrolet', 'Tracker', 'Chevrolet Tracker'),
    ('carro', 'chevrolet', 'Spark', 'Chevrolet Spark'),
    ('carro', 'chevrolet', 'Blazer EV', 'Chevrolet Blazer EV'),
    ('carro', 'chevrolet', 'Equinox', 'Chevrolet Equinox'),
    ('carro', 'chevrolet', 'Traverse', 'Chevrolet Traverse'),
    ('carro', 'chevrolet', 'Montana', 'Chevrolet Montana'),
    ('carro', 'chevrolet', 'Colorado', 'Chevrolet Colorado'),
    ('carro', 'chevrolet', 'Silverado', 'Chevrolet Silverado'),
    ('carro', 'chevrolet', 'Captiva', 'Chevrolet Captiva'),
    ('carro', 'chevrolet', 'Camaro', 'Chevrolet Camaro'),
    ('carro', 'chevrolet', 'Tahoe', 'Chevrolet Tahoe'),

    # RENAULT
    ('carro', 'renault', 'Duster', 'Renault Duster'),
    ('carro', 'renault', 'Sandero', 'Renault Sandero'),
    ('carro', 'renault', 'Stepway', 'Renault Stepway'),
    ('carro', 'renault', 'Logan', 'Renault Logan'),
    ('carro', 'renault', 'Kwid', 'Renault Kwid'),
    ('carro', 'renault', 'Kardian', 'Renault Kardian'),
    ('carro', 'renault', 'Oroch', 'Renault Oroch'),
    ('carro', 'renault', 'Megane', 'Renault Megane'),
    ('carro', 'renault', 'Captur', 'Renault Captur'),
    ('carro', 'renault', 'Koleos', 'Renault Koleos'),
    ('carro', 'renault', 'Clio', 'Renault Clio'),
    ('carro', 'renault', 'Twingo', 'Renault Twingo'),

    # MAZDA
    ('carro', 'mazda', 'Mazda 2', 'Mazda 2'),
    ('carro', 'mazda', 'Mazda 3', 'Mazda 3'),
    ('carro', 'mazda', 'Mazda 6', 'Mazda 6'),
    ('carro', 'mazda', 'CX-3', 'Mazda CX-3'),
    ('carro', 'mazda', 'CX-30', 'Mazda CX-30'),
    ('carro', 'mazda', 'CX-5', 'Mazda CX-5'),
    ('carro', 'mazda', 'CX-50', 'Mazda CX-50'),
    ('carro', 'mazda', 'CX-60', 'Mazda CX-60'),
    ('carro', 'mazda', 'CX-9', 'Mazda CX-9'),
    ('carro', 'mazda', 'MX-5 Miata', 'Mazda MX-5'),
    ('carro', 'mazda', 'BT-50', 'Mazda BT-50'),

    # NISSAN
    ('carro', 'nissan', 'Versa', 'Nissan Versa'),
    ('carro', 'nissan', 'Kicks', 'Nissan Kicks'),
    ('carro', 'nissan', 'Sentra', 'Nissan Sentra'),
    ('carro', 'nissan', 'Frontier', 'Nissan Frontier'),
    ('carro', 'nissan', 'Qashqai', 'Nissan Qashqai'),
    ('carro', 'nissan', 'X-Trail', 'Nissan X-Trail'),
    ('carro', 'nissan', 'March', 'Nissan Micra'),
    ('carro', 'nissan', 'Tiida', 'Nissan Tiida'),
    ('carro', 'nissan', 'Pathfinder', 'Nissan Pathfinder'),
    ('carro', 'nissan', 'Patrol', 'Nissan Patrol'),
    ('carro', 'nissan', 'Leaf', 'Nissan Leaf'),
    ('carro', 'nissan', 'GT-R', 'Nissan GT-R'),

    # KIA
    ('carro', 'kia', 'Picanto', 'Kia Picanto'),
    ('carro', 'kia', 'Rio', 'Kia Rio'),
    ('carro', 'kia', 'K3', 'Kia K3'),
    ('carro', 'kia', 'Sonet', 'Kia Sonet'),
    ('carro', 'kia', 'Seltos', 'Kia Seltos'),
    ('carro', 'kia', 'Sportage', 'Kia Sportage'),
    ('carro', 'kia', 'Sorento', 'Kia Sorento'),
    ('carro', 'kia', 'Carnival', 'Kia Carnival'),
    ('carro', 'kia', 'EV6', 'Kia EV6'),
    ('carro', 'kia', 'EV9', 'Kia EV9'),
    ('carro', 'kia', 'Stinger', 'Kia Stinger'),
    ('carro', 'kia', 'Forte', 'Kia Cerato'),

    # HYUNDAI
    ('carro', 'hyundai', 'Grand i10', 'Hyundai i10'),
    ('carro', 'hyundai', 'HB20', 'Hyundai HB20'),
    ('carro', 'hyundai', 'Accent', 'Hyundai Accent'),
    ('carro', 'hyundai', 'Elantra', 'Hyundai Elantra'),
    ('carro', 'hyundai', 'Creta', 'Hyundai Creta'),
    ('carro', 'hyundai', 'Tucson', 'Hyundai Tucson'),
    ('carro', 'hyundai', 'Santa Fe', 'Hyundai Santa Fe'),
    ('carro', 'hyundai', 'Kona', 'Hyundai Kona'),
    ('carro', 'hyundai', 'Ioniq 5', 'Hyundai Ioniq 5'),
    ('carro', 'hyundai', 'Palisade', 'Hyundai Palisade'),
    ('carro', 'hyundai', 'Venue', 'Hyundai Venue'),
    ('carro', 'hyundai', 'Staria', 'Hyundai Staria'),

    # VOLKSWAGEN
    ('carro', 'volkswagen', 'Gol', 'Volkswagen Gol'),
    ('carro', 'volkswagen', 'Polo', 'Volkswagen Polo'),
    ('carro', 'volkswagen', 'Virtus', 'Volkswagen Virtus'),
    ('carro', 'volkswagen', 'Nivus', 'Volkswagen Nivus'),
    ('carro', 'volkswagen', 'T-Cross', 'Volkswagen T-Cross'),
    ('carro', 'volkswagen', 'Taos', 'Volkswagen Taos'),
    ('carro', 'volkswagen', 'Tiguan', 'Volkswagen Tiguan'),
    ('carro', 'volkswagen', 'Amarok', 'Volkswagen Amarok'),
    ('carro', 'volkswagen', 'Golf', 'Volkswagen Golf'),
    ('carro', 'volkswagen', 'Jetta', 'Volkswagen Jetta'),
    ('carro', 'volkswagen', 'Passat', 'Volkswagen Passat'),

    # FORD
    ('carro', 'ford', 'Fiesta', 'Ford Fiesta'),
    ('carro', 'ford', 'Focus', 'Ford Focus'),
    ('carro', 'ford', 'Fusion', 'Ford Fusion'),
    ('carro', 'ford', 'EcoSport', 'Ford EcoSport'),
    ('carro', 'ford', 'Escape', 'Ford Escape'),
    ('carro', 'ford', 'Explorer', 'Ford Explorer'),
    ('carro', 'ford', 'Expedition', 'Ford Expedition'),
    ('carro', 'ford', 'Edge', 'Ford Edge'),
    ('carro', 'ford', 'Ranger', 'Ford Ranger'),
    ('carro', 'ford', 'F-150', 'Ford F-150'),
    ('carro', 'ford', 'Bronco Sport', 'Ford Bronco Sport'),
    ('carro', 'ford', 'Mustang', 'Ford Mustang'),

    # SUZUKI
    ('carro', 'suzuki', 'Swift', 'Suzuki Swift'),
    ('carro', 'suzuki', 'Baleno', 'Suzuki Baleno'),
    ('carro', 'suzuki', 'Ignis', 'Suzuki Ignis'),
    ('carro', 'suzuki', 'Celerio', 'Suzuki Celerio'),
    ('carro', 'suzuki', 'Alto', 'Suzuki Alto'),
    ('carro', 'suzuki', 'Jimny', 'Suzuki Jimny'),
    ('carro', 'suzuki', 'Grand Vitara', 'Suzuki Grand Vitara'),
    ('carro', 'suzuki', 'Vitara', 'Suzuki Vitara'),
    ('carro', 'suzuki', 'Fronx', 'Suzuki Fronx'),
    ('carro', 'suzuki', 'S-Cross', 'Suzuki SX4 S-Cross'),
    ('carro', 'suzuki', 'Ertiga', 'Suzuki Ertiga'),
    ('carro', 'suzuki', 'Spresso', 'Suzuki S-Presso'),

    # HONDA
    ('carro', 'honda', 'Civic', 'Honda Civic'),
    ('carro', 'honda', 'Accord', 'Honda Accord'),
    ('carro', 'honda', 'Fit', 'Honda Fit'),
    ('carro', 'honda', 'City', 'Honda City'),
    ('carro', 'honda', 'HR-V', 'Honda HR-V'),
    ('carro', 'honda', 'CR-V', 'Honda CR-V'),
    ('carro', 'honda', 'WR-V', 'Honda WR-V'),
    ('carro', 'honda', 'ZR-V', 'Honda ZR-V'),
    ('carro', 'honda', 'Pilot', 'Honda Pilot'),
    ('carro', 'honda', 'Passport', 'Honda Passport'),
    ('carro', 'honda', 'Odyssey', 'Honda Odyssey'),
    ('carro', 'honda', 'Ridgeline', 'Honda Ridgeline'),

    # BMW
    ('carro', 'bmw', 'Serie 1', 'BMW 1 Series'),
    ('carro', 'bmw', 'Serie 2', 'BMW 2 Series'),
    ('carro', 'bmw', 'Serie 3', 'BMW 3 Series'),
    ('carro', 'bmw', 'Serie 4', 'BMW 4 Series'),
    ('carro', 'bmw', 'Serie 5', 'BMW 5 Series'),
    ('carro', 'bmw', 'Serie 7', 'BMW 7 Series'),
    ('carro', 'bmw', 'X1', 'BMW X1'),
    ('carro', 'bmw', 'X2', 'BMW X2'),
    ('carro', 'bmw', 'X3', 'BMW X3'),
    ('carro', 'bmw', 'X4', 'BMW X4'),
    ('carro', 'bmw', 'X5', 'BMW X5'),
    ('carro', 'bmw', 'X6', 'BMW X6'),
    ('carro', 'bmw', 'M3', 'BMW M3'),

    # MERCEDES-BENZ
    ('carro', 'mercedes-benz', 'Clase A', 'Mercedes-Benz A-Class'),
    ('carro', 'mercedes-benz', 'Clase B', 'Mercedes-Benz B-Class'),
    ('carro', 'mercedes-benz', 'Clase C', 'Mercedes-Benz C-Class'),
    ('carro', 'mercedes-benz', 'Clase E', 'Mercedes-Benz E-Class'),
    ('carro', 'mercedes-benz', 'Clase S', 'Mercedes-Benz S-Class'),
    ('carro', 'mercedes-benz', 'GLA', 'Mercedes-Benz GLA'),
    ('carro', 'mercedes-benz', 'GLB', 'Mercedes-Benz GLB'),
    ('carro', 'mercedes-benz', 'GLC', 'Mercedes-Benz GLC'),
    ('carro', 'mercedes-benz', 'GLE', 'Mercedes-Benz GLE'),
    ('carro', 'mercedes-benz', 'GLS', 'Mercedes-Benz GLS'),
    ('carro', 'mercedes-benz', 'CLA', 'Mercedes-Benz CLA'),
    ('carro', 'mercedes-benz', 'Clase G', 'Mercedes-Benz G-Class'),

    # AUDI
    ('carro', 'audi', 'A1', 'Audi A1'),
    ('carro', 'audi', 'A3', 'Audi A3'),
    ('carro', 'audi', 'A4', 'Audi A4'),
    ('carro', 'audi', 'A5', 'Audi A5'),
    ('carro', 'audi', 'A6', 'Audi A6'),
    ('carro', 'audi', 'A7', 'Audi A7'),
    ('carro', 'audi', 'A8', 'Audi A8'),
    ('carro', 'audi', 'Q2', 'Audi Q2'),
    ('carro', 'audi', 'Q3', 'Audi Q3'),
    ('carro', 'audi', 'Q5', 'Audi Q5'),
    ('carro', 'audi', 'Q7', 'Audi Q7'),
    ('carro', 'audi', 'Q8', 'Audi Q8'),
    ('carro', 'audi', 'TT', 'Audi TT'),
    ('carro', 'audi', 'R8', 'Audi R8'),

    # JEEP
    ('carro', 'jeep', 'Renegade', 'Jeep Renegade'),
    ('carro', 'jeep', 'Compass', 'Jeep Compass'),
    ('carro', 'jeep', 'Cherokee', 'Jeep Cherokee'),
    ('carro', 'jeep', 'Grand Cherokee', 'Jeep Grand Cherokee'),
    ('carro', 'jeep', 'Commander', 'Jeep Commander'),
    ('carro', 'jeep', 'Wrangler', 'Jeep Wrangler'),
    ('carro', 'jeep', 'Gladiator', 'Jeep Gladiator'),
    ('carro', 'jeep', 'Wagoneer', 'Jeep Wagoneer'),
    ('carro', 'jeep', 'Patriot', 'Jeep Patriot'),
    ('carro', 'jeep', 'Liberty', 'Jeep Liberty'),

    # BYD
    ('carro', 'byd', 'Dolphin', 'BYD Dolphin'),
    ('carro', 'byd', 'Dolphin Mini', 'BYD Seagull'),
    ('carro', 'byd', 'Yuan Plus', 'BYD Atto 3'),
    ('carro', 'byd', 'Song Plus', 'BYD Song Plus'),
    ('carro', 'byd', 'Tang', 'BYD Tang'),
    ('carro', 'byd', 'Han', 'BYD Han'),
    ('carro', 'byd', 'Seal', 'BYD Seal'),
    ('carro', 'byd', 'Qin Plus', 'BYD Qin Plus'),
    ('carro', 'byd', 'Shark', 'BYD Shark'),
    ('carro', 'byd', 'Destroyer 05', 'BYD Destroyer 05'),

    # --- MOTOS (Minimo 10 por marca) ---
    # YAMAHA
    ('moto', 'yamaha', 'MT 15', 'Yamaha MT-15'),
    ('moto', 'yamaha', 'R15', 'Yamaha YZF-R15'),
    ('moto', 'yamaha', 'FZ 25', 'Yamaha FZ25'),
    ('moto', 'yamaha', 'FZ 2.0', 'Yamaha FZ16'),
    ('moto', 'yamaha', 'Crypton', 'Yamaha Crypton'),
    ('moto', 'yamaha', 'N-Max', 'Yamaha NMAX'),
    ('moto', 'yamaha', 'XTZ 125', 'Yamaha XTZ 125'),
    ('moto', 'yamaha', 'XTZ 150', 'Yamaha XTZ 150'),
    ('moto', 'yamaha', 'XTZ 250', 'Yamaha XTZ 250'),
    ('moto', 'yamaha', 'MT 03', 'Yamaha MT-03'),
    ('moto', 'yamaha', 'MT 07', 'Yamaha MT-07'),
    ('moto', 'yamaha', 'MT 09', 'Yamaha MT-09'),
    ('moto', 'yamaha', 'Tenere 700', 'Yamaha Ténéré 700'),
    ('moto', 'yamaha', 'Aerox 155', 'Yamaha Aerox 155'),
    ('moto', 'yamaha', 'BWS 125', 'Yamaha BWs 125'),

    # HONDA
    ('moto', 'honda', 'CB 125F', 'Honda CB125F'),
    ('moto', 'honda', 'CB 160F', 'Honda CB Unicorn 160'),
    ('moto', 'honda', 'CB 190R', 'Honda CB190R'),
    ('moto', 'honda', 'CB 250 Twister', 'Honda CB Twister 250'),
    ('moto', 'honda', 'CB 300F', 'Honda CB300F'),
    ('moto', 'honda', 'CB 650R', 'Honda CB650R'),
    ('moto', 'honda', 'CBR 650R', 'Honda CBR650R'),
    ('moto', 'honda', 'XR 150L', 'Honda XR150L'),
    ('moto', 'honda', 'XR 190L', 'Honda XR190L'),
    ('moto', 'honda', 'XRE 300', 'Honda XRE300'),
    ('moto', 'honda', 'Sahara 300', 'Honda Sahara 300'),
    ('moto', 'honda', 'Africa Twin 1100', 'Honda CRF1100L Africa Twin'),
    ('moto', 'honda', 'Transalp 750', 'Honda XL750 Transalp'),
    ('moto', 'honda', 'Navi', 'Honda Navi'),
    ('moto', 'honda', 'Dio', 'Honda Dio'),
    ('moto', 'honda', 'PCX 160', 'Honda PCX'),

    # SUZUKI
    ('moto', 'suzuki', 'Gixxer 150', 'Suzuki Gixxer 150'),
    ('moto', 'suzuki', 'Gixxer SF 150', 'Suzuki Gixxer SF 150'),
    ('moto', 'suzuki', 'Gixxer 250', 'Suzuki Gixxer 250'),
    ('moto', 'suzuki', 'Gixxer SF 250', 'Suzuki Gixxer SF 250'),
    ('moto', 'suzuki', 'GN 125', 'Suzuki GN125'),
    ('moto', 'suzuki', 'AX4', 'Suzuki AX4'),
    ('moto', 'suzuki', 'DR 150', 'Suzuki DR150'),
    ('moto', 'suzuki', 'DR 200', 'Suzuki DR200S'),
    ('moto', 'suzuki', 'DR 650', 'Suzuki DR650'),
    ('moto', 'suzuki', 'V-Strom 250 SX', 'Suzuki V-Strom 250 SX'),
    ('moto', 'suzuki', 'V-Strom 650', 'Suzuki V-Strom 650'),
    ('moto', 'suzuki', 'GSX-S 750', 'Suzuki GSX-S750'),
    ('moto', 'suzuki', 'Hayabusa', 'Suzuki Hayabusa'),

    # KAWASAKI
    ('moto', 'kawasaki', 'Ninja 300', 'Kawasaki Ninja 300'),
    ('moto', 'kawasaki', 'Ninja 400', 'Kawasaki Ninja 400'),
    ('moto', 'kawasaki', 'Ninja 650', 'Kawasaki Ninja 650'),
    ('moto', 'kawasaki', 'Ninja ZX-4RR', 'Kawasaki Ninja ZX-4R'),
    ('moto', 'kawasaki', 'Ninja ZX-6R', 'Kawasaki Ninja ZX-6R'),
    ('moto', 'kawasaki', 'Ninja ZX-10R', 'Kawasaki Ninja ZX-10R'),
    ('moto', 'kawasaki', 'Z 400', 'Kawasaki Z400'),
    ('moto', 'kawasaki', 'Z 650', 'Kawasaki Z650'),
    ('moto', 'kawasaki', 'Z 900', 'Kawasaki Z900'),
    ('moto', 'kawasaki', 'Versys 300', 'Kawasaki Versys-X 300'),
    ('moto', 'kawasaki', 'Versys 650', 'Kawasaki Versys 650'),
    ('moto', 'kawasaki', 'KLX 150', 'Kawasaki KLX 150'),
    ('moto', 'kawasaki', 'KLR 650', 'Kawasaki KLR650'),

    # BAJAJ
    ('moto', 'bajaj', 'Pulsar NS 200', 'Bajaj Pulsar 200NS'),
    ('moto', 'bajaj', 'Pulsar NS 160', 'Bajaj Pulsar NS160'),
    ('moto', 'bajaj', 'Pulsar NS 125', 'Bajaj Pulsar 125'),
    ('moto', 'bajaj', 'Pulsar N 250', 'Bajaj Pulsar 250'),
    ('moto', 'bajaj', 'Pulsar N 160', 'Bajaj Pulsar N160'),
    ('moto', 'bajaj', 'Pulsar N 125', 'Bajaj Pulsar N125'),
    ('moto', 'bajaj', 'Pulsar RS 200', 'Bajaj Pulsar RS200'),
    ('moto', 'bajaj', 'Pulsar NS 400', 'Bajaj Pulsar NS400'),
    ('moto', 'bajaj', 'Dominar 400', 'Bajaj Dominar 400'),
    ('moto', 'bajaj', 'Dominar 250', 'Bajaj Dominar 250'),
    ('moto', 'bajaj', 'Boxer CT 100', 'Bajaj Boxer CT 100'),
    ('moto', 'bajaj', 'Boxer CT 125', 'Bajaj Boxer 125'),
    ('moto', 'bajaj', 'Boxer 150X', 'Bajaj Boxer 150'),
    ('moto', 'bajaj', 'Discover 125', 'Bajaj Discover 125'),

    # KTM
    ('moto', 'ktm', 'Duke 125', 'KTM 125 Duke'),
    ('moto', 'ktm', 'Duke 200', 'KTM 200 Duke'),
    ('moto', 'ktm', 'Duke 250', 'KTM 250 Duke'),
    ('moto', 'ktm', 'Duke 390', 'KTM 390 Duke'),
    ('moto', 'ktm', 'Duke 790', 'KTM 790 Duke'),
    ('moto', 'ktm', 'Duke 890', 'KTM 890 Duke'),
    ('moto', 'ktm', 'Duke 990', 'KTM 990 Duke'),
    ('moto', 'ktm', 'Super Duke 1290', 'KTM 1290 Super Duke R'),
    ('moto', 'ktm', 'Super Duke 1390', 'KTM 1390 Super Duke R'),
    ('moto', 'ktm', 'Adventure 250', 'KTM 250 Adventure'),
    ('moto', 'ktm', 'Adventure 390', 'KTM 390 Adventure'),
    ('moto', 'ktm', 'Adventure 790', 'KTM 790 Adventure'),
    ('moto', 'ktm', 'Adventure 890', 'KTM 890 Adventure'),
    ('moto', 'ktm', 'RC 200', 'KTM RC 200'),
    ('moto', 'ktm', 'RC 390', 'KTM RC 390'),

    # HERO
    ('moto', 'hero', 'Hunk 160R', 'Hero Xtreme 160R'),
    ('moto', 'hero', 'Hunk 160R 4V', 'Hero Xtreme 160R 4V'),
    ('moto', 'hero', 'Hunk 150', 'Hero Hunk'),
    ('moto', 'hero', 'Hunk 125R', 'Hero Xtreme 125R'),
    ('moto', 'hero', 'XPulse 200', 'Hero XPulse 200'),
    ('moto', 'hero', 'XPulse 200 Pro', 'Hero XPulse 200 4V'),
    ('moto', 'hero', 'XPulse Rally', 'Hero XPulse Rally'),
    ('moto', 'hero', 'Eco Deluxe', 'Hero HF Deluxe'),
    ('moto', 'hero', 'Eco Deluxe i3S', 'Hero HF Deluxe'),
    ('moto', 'hero', 'ECO 100', 'Hero Dawn'),
    ('moto', 'hero', 'Ignitor 125', 'Hero Glamour'),
    ('moto', 'hero', 'Splendor', 'Hero Splendor'),
    ('moto', 'hero', 'Xoom 110', 'Hero Xoom'),
    ('moto', 'hero', 'Dash 125', 'Hero Maestro'),

    # AKT
    ('moto', 'akt', 'NKD 125', 'AKT NKD 125'),
    ('moto', 'akt', 'NKD Classic', 'AKT NKD Classic'),
    ('moto', 'akt', 'CR4 150', 'AKT CR4 150'),
    ('moto', 'akt', 'CR4 200', 'AKT CR4 200'),
    ('moto', 'akt', '250 R', 'AKT 250R'),
    ('moto', 'akt', 'Dynamic Pro', 'AKT Dynamic Pro'),
    ('moto', 'akt', 'Mawi 125', 'AKT Mawi 125'),
    ('moto', 'akt', 'TT 200', 'AKT TT Dual Sport 200'),
    ('moto', 'akt', 'TT 250', 'AKT TT 250 Adventour'),
    ('moto', 'akt', 'Flex 125', 'AKT Flex 125'),
    ('moto', 'akt', 'Special 110', 'AKT Special 110'),

    # DUCATI
    ('moto', 'ducati', 'Monster 937', 'Ducati Monster 937'),
    ('moto', 'ducati', 'Monster 821', 'Ducati Monster 821'),
    ('moto', 'ducati', 'Panigale V2', 'Ducati Panigale V2'),
    ('moto', 'ducati', 'Panigale V4', 'Ducati Panigale V4'),
    ('moto', 'ducati', 'Multistrada V2', 'Ducati Multistrada V2'),
    ('moto', 'ducati', 'Multistrada V4', 'Ducati Multistrada V4'),
    ('moto', 'ducati', 'Scrambler Icon', 'Ducati Scrambler'),
    ('moto', 'ducati', 'DesertX', 'Ducati DesertX'),
    ('moto', 'ducati', 'Diavel V4', 'Ducati Diavel V4'),
    ('moto', 'ducati', 'Hypermotard 950', 'Ducati Hypermotard 950'),
    ('moto', 'ducati', 'Streetfighter V2', 'Ducati Streetfighter V2'),
    ('moto', 'ducati', 'Streetfighter V4', 'Ducati Streetfighter V4'),

    # TRIUMPH
    ('moto', 'triumph', 'Speed 400', 'Triumph Speed 400'),
    ('moto', 'triumph', 'Scrambler 400X', 'Triumph Scrambler 400 X'),
    ('moto', 'triumph', 'Trident 660', 'Triumph Trident 660'),
    ('moto', 'triumph', 'Street Triple 765', 'Triumph Street Triple 765'),
    ('moto', 'triumph', 'Speed Triple 1200', 'Triumph Speed Triple 1200'),
    ('moto', 'triumph', 'Tiger 660', 'Triumph Tiger Sport 660'),
    ('moto', 'triumph', 'Tiger 900', 'Triumph Tiger 900'),
    ('moto', 'triumph', 'Tiger 1200', 'Triumph Tiger 1200'),
    ('moto', 'triumph', 'Bonneville T100', 'Triumph Bonneville T100'),
    ('moto', 'triumph', 'Bonneville T120', 'Triumph Bonneville T120'),
    ('moto', 'triumph', 'Scrambler 900', 'Triumph Street Scrambler'),
    ('moto', 'triumph', 'Scrambler 1200', 'Triumph Scrambler 1200'),
    ('moto', 'triumph', 'Rocket 3', 'Triumph Rocket 3'),

    # ROYAL ENFIELD
    ('moto', 'royal_enfield', 'Himalayan 411', 'Royal Enfield Himalayan 411'),
    ('moto', 'royal_enfield', 'Himalayan 450', 'Royal Enfield Himalayan 450'),
    ('moto', 'royal_enfield', 'Hunter 350', 'Royal Enfield Hunter 350'),
    ('moto', 'royal_enfield', 'Classic 350', 'Royal Enfield Classic 350'),
    ('moto', 'royal_enfield', 'Classic 500', 'Royal Enfield Classic 500'),
    ('moto', 'royal_enfield', 'Meteor 350', 'Royal Enfield Meteor 350'),
    ('moto', 'royal_enfield', 'Interceptor 650', 'Royal Enfield Interceptor 650'),
    ('moto', 'royal_enfield', 'Continental GT 650', 'Royal Enfield Continental GT 650'),
    ('moto', 'royal_enfield', 'Super Meteor 650', 'Royal Enfield Super Meteor 650'),
    ('moto', 'royal_enfield', 'Shotgun 650', 'Royal Enfield Shotgun 650'),
    ('moto', 'royal_enfield', 'Bullet 350', 'Royal Enfield Bullet 350'),
    ('moto', 'royal_enfield', 'Guerrilla 450', 'Royal Enfield Guerrilla 450'),

    # HARLEY-DAVIDSON
    ('moto', 'harley_davidson', 'Iron 883', 'Harley-Davidson Iron 883'),
    ('moto', 'harley_davidson', 'Forty-Eight', 'Harley-Davidson Forty-Eight'),
    ('moto', 'harley_davidson', 'Street 750', 'Harley-Davidson Street 750'),
    ('moto', 'harley_davidson', 'Sportster S', 'Harley-Davidson Sportster S'),
    ('moto', 'harley_davidson', 'Nightster 975', 'Harley-Davidson Nightster'),
    ('moto', 'harley_davidson', 'Fat Boy', 'Harley-Davidson Fat Boy'),
    ('moto', 'harley_davidson', 'Street Bob', 'Harley-Davidson Street Bob'),
    ('moto', 'harley_davidson', 'Low Rider S', 'Harley-Davidson Low Rider S'),
    ('moto', 'harley_davidson', 'Breakout 117', 'Harley-Davidson Breakout'),
    ('moto', 'harley_davidson', 'Pan America 1250', 'Harley-Davidson Pan America'),
    ('moto', 'harley_davidson', 'Road King', 'Harley-Davidson Road King'),
    ('moto', 'harley_davidson', 'Road Glide', 'Harley-Davidson Road Glide'),
    ('moto', 'harley_davidson', 'Street Glide', 'Harley-Davidson Street Glide'),

    # BMW MOTORRAD
    ('moto', 'bmw', 'G 310 R', 'BMW G310R'),
    ('moto', 'bmw', 'G 310 GS', 'BMW G310GS'),
    ('moto', 'bmw', 'F 800 R', 'BMW F800R'),
    ('moto', 'bmw', 'F 900 R', 'BMW F900R'),
    ('moto', 'bmw', 'F 900 XR', 'BMW F900XR'),
    ('moto', 'bmw', 'F 750 GS', 'BMW F750GS'),
    ('moto', 'bmw', 'F 850 GS', 'BMW F850GS'),
    ('moto', 'bmw', 'F 900 GS', 'BMW F900GS'),
    ('moto', 'bmw', 'R 1200 GS', 'BMW R1200GS'),
    ('moto', 'bmw', 'R 1250 GS', 'BMW R1250GS'),
    ('moto', 'bmw', 'R 1300 GS', 'BMW R1300GS'),
    ('moto', 'bmw', 'S 1000 RR', 'BMW S1000RR'),
    ('moto', 'bmw', 'S 1000 XR', 'BMW S1000XR'),
    ('moto', 'bmw', 'S 1000 R', 'BMW S1000R'),
    ('moto', 'bmw', 'C 400 GT', 'BMW C400GT'),
    ('moto', 'bmw', 'R 18', 'BMW R18'),

    # APRILIA
    ('moto', 'aprilia', 'RS 125', 'Aprilia RS 125'),
    ('moto', 'aprilia', 'RS 457', 'Aprilia RS 457'),
    ('moto', 'aprilia', 'RS 660', 'Aprilia RS 660'),
    ('moto', 'aprilia', 'Tuono 660', 'Aprilia Tuono 660'),
    ('moto', 'aprilia', 'Tuareg 660', 'Aprilia Tuareg 660'),
    ('moto', 'aprilia', 'RSV4 1100', 'Aprilia RSV4 1100'),
    ('moto', 'aprilia', 'Tuono V4', 'Aprilia Tuono V4'),
    ('moto', 'aprilia', 'SR GT 125', 'Aprilia SR GT 125'),
    ('moto', 'aprilia', 'SR GT 200', 'Aprilia SR GT 200'),
    ('moto', 'aprilia', 'Shiver 900', 'Aprilia Shiver 900'),
    ('moto', 'aprilia', 'Dorsoduro 900', 'Aprilia Dorsoduro 900'),

    # BENELLI
    ('moto', 'benelli', 'TNT 150', 'Benelli TNT 150'),
    ('moto', 'benelli', 'TNT 25', 'Benelli TNT 25'),
    ('moto', 'benelli', '180S', 'Benelli 180S'),
    ('moto', 'benelli', '302S', 'Benelli 302S'),
    ('moto', 'benelli', '502C', 'Benelli 502C'),
    ('moto', 'benelli', '752S', 'Benelli 752S'),
    ('moto', 'benelli', 'Leoncino 250', 'Benelli Leoncino 250'),
    ('moto', 'benelli', 'Leoncino 500', 'Benelli Leoncino 500'),
    ('moto', 'benelli', 'Leoncino 800', 'Benelli Leoncino 800'),
    ('moto', 'benelli', 'TRK 251', 'Benelli TRK 251'),
    ('moto', 'benelli', 'TRK 502X', 'Benelli TRK 502'),
    ('moto', 'benelli', 'TRK 702X', 'Benelli TRK 702'),
    ('moto', 'benelli', 'Imperiale 400', 'Benelli Imperiale 400'),

    # CFMOTO
    ('moto', 'cfmoto', '250 NK', 'CFMoto 250NK'),
    ('moto', 'cfmoto', '300 NK', 'CFMoto 300NK'),
    ('moto', 'cfmoto', '400 NK', 'CFMoto 400NK'),
    ('moto', 'cfmoto', '650 NK', 'CFMoto 650NK'),
    ('moto', 'cfmoto', '300 SR', 'CFMoto 300SR'),
    ('moto', 'cfmoto', '450 SR', 'CFMoto 450SR'),
    ('moto', 'cfmoto', '450 NK', 'CFMoto 450NK'),
    ('moto', 'cfmoto', '450 MT', 'CFMoto 450MT'),
    ('moto', 'cfmoto', '700 CL-X', 'CFMoto 700CL-X'),
    ('moto', 'cfmoto', '800 MT', 'CFMoto 800MT'),
    ('moto', 'cfmoto', 'Papio XO-1', 'CFMoto Papio'),
    ('moto', 'cfmoto', '650 GT', 'CFMoto 650GT'),

    # KYMCO
    ('moto', 'kymco', 'Agility 125', 'Kymco Agility 125'),
    ('moto', 'kymco', 'Agility RS', 'Kymco Agility RS'),
    ('moto', 'kymco', 'Agility Fusion', 'Kymco Agility Fusion'),
    ('moto', 'kymco', 'Twist 125', 'Kymco Twist 125'),
    ('moto', 'kymco', 'Like 125', 'Kymco Like 125'),
    ('moto', 'kymco', 'Like 150', 'Kymco Like 150'),
    ('moto', 'kymco', 'People S 150', 'Kymco People S 150'),
    ('moto', 'kymco', 'DTX 360', 'Kymco DTX 360'),
    ('moto', 'kymco', 'X-Town 300', 'Kymco X-Town 300'),
    ('moto', 'kymco', 'Downtown 350', 'Kymco Downtown 350'),
    ('moto', 'kymco', 'AK 550', 'Kymco AK 550'),

    # SYM
    ('moto', 'sym', 'Crox 125', 'SYM Crox 125'),
    ('moto', 'sym', 'Crox R 125', 'SYM Crox R 125'),
    ('moto', 'sym', 'Fiddle III', 'SYM Fiddle III'),
    ('moto', 'sym', 'Jet 14', 'SYM Jet 14'),
    ('moto', 'sym', 'Symphony 125', 'SYM Symphony 125'),
    ('moto', 'sym', 'NH Trazer 200', 'SYM NHT 200'),
    ('moto', 'sym', 'NHX 190', 'SYM NHX 190'),
    ('moto', 'sym', 'Joyride 200', 'SYM Joyride 200'),
    ('moto', 'sym', 'Cruisym 300', 'SYM Cruisym 300'),
    ('moto', 'sym', 'Citycom 300', 'SYM Citycom 300'),
    ('moto', 'sym', 'Maxsym 400', 'SYM Maxsym 400'),

    # VESPA
    ('moto', 'vespa', 'Primavera 50', 'Vespa Primavera 50'),
    ('moto', 'vespa', 'Primavera 125', 'Vespa Primavera 125'),
    ('moto', 'vespa', 'Primavera 150', 'Vespa Primavera 150'),
    ('moto', 'vespa', 'Sprint 50', 'Vespa Sprint 50'),
    ('moto', 'vespa', 'Sprint 125', 'Vespa Sprint 125'),
    ('moto', 'vespa', 'Sprint 150', 'Vespa Sprint 150'),
    ('moto', 'vespa', 'GTS 125', 'Vespa GTS 125'),
    ('moto', 'vespa', 'GTS 300', 'Vespa GTS 300'),
    ('moto', 'vespa', 'GTV 300', 'Vespa GTV 300'),
    ('moto', 'vespa', 'Elettrica', 'Vespa Elettrica'),

    # VICTORI
    ('moto', 'victori', 'Venom 150', 'Victori Venom 150'),
    ('moto', 'victori', 'Venom 180', 'Victori Venom 180'),
    ('moto', 'victori', 'Venom 250', 'Victori Venom 250'),
    ('moto', 'victori', 'MRX 125', 'Victori MRX 125'),
    ('moto', 'victori', 'MRX 150', 'Victori MRX 150'),
    ('moto', 'victori', 'MRX Arizona 200', 'Victori MRX Arizona'),
    ('moto', 'victori', 'Nitro 125', 'Victori Nitro 125'),
    ('moto', 'victori', 'Switch 150', 'Victori Switch 150'),
    ('moto', 'victori', 'Black 171', 'Victori Black 171'),
    ('moto', 'victori', 'Bomber 150', 'Victori Bomber 150'),
]

def process_item(item):
    kind, brand, model_name, query = item
    brand_folder = clean_filename(brand)
    model_file = clean_filename(model_name) + '.png'
    
    dest_dir = os.path.join('assets', 'motos' if kind == 'moto' else 'carros', brand_folder)
    dest_path = os.path.join(dest_dir, model_file)
    
    if os.path.exists(dest_path) and os.path.getsize(dest_path) > 1000:
        return f"[EXISTE] {dest_path}"
        
    img_url = get_wikimedia_image_url(query)
    if img_url:
        ok = download_file(img_url, dest_path)
        if ok:
            return f"[GUARDADO] {dest_path}"
            
    return f"[NO ENCONTRADO] {brand} {model_name}"

def main():
    print(f"Iniciando descarga masiva de vehículos (+10 por marca). Total a procesar: {len(ALL_VEHICLES)}")
    
    with ThreadPoolExecutor(max_workers=4) as executor:
        futures = [executor.submit(process_item, v) for v in ALL_VEHICLES]
        for f in as_completed(futures):
            res = f.result()
            print(f"  {res}")
            time.sleep(0.15)

    print("\nDESCARGA MASIVA COMPLETADA AL 100%!")

if __name__ == '__main__':
    main()
