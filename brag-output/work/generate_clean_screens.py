#!/usr/bin/env python3
"""
Generates ultra-high-resolution, clean, simulated native UI screens for MY AUTO GUIDE.
Recreates the app's real interface elements (ISH gauge, 360 garage, GPS HUD, RUNT cache,
QR digital certification, AI Gemini copilot, and expense donut chart) with razor-sharp vector fidelity.
"""

import os
import math
import qrcode
from PIL import Image, ImageDraw, ImageFont, ImageFilter

OUT_DIR = r"d:\Proyectos\my_auto_guide\brag-output\work\clean_screens"
os.makedirs(OUT_DIR, exist_ok=True)

WIDTH, HEIGHT = 880, 1900

FONT_BOLD = "C:/Windows/Fonts/segoeuib.ttf"
FONT_REG = "C:/Windows/Fonts/segoeui.ttf"
FONT_MONO = "C:/Windows/Fonts/consola.ttf"

def get_font(path, size):
    try:
        return ImageFont.truetype(path, size)
    except:
        return ImageFont.load_default()

def draw_status_bar(draw):
    f_time = get_font(FONT_BOLD, 28)
    f_icons = get_font(FONT_REG, 22)
    draw.text((50, 24), "7:45", fill=(255, 255, 255, 240), font=f_time)
    draw.text((WIDTH - 150, 26), "5G  100%", fill=(255, 255, 255, 230), font=f_icons)

def draw_nav_bar(draw, active_tab=0):
    nav_h = 130
    y = HEIGHT - nav_h
    # Glass bar
    draw.rectangle((0, y, WIDTH, HEIGHT), fill=(12, 16, 26, 255))
    draw.line((0, y, WIDTH, y), fill=(35, 45, 65, 255), width=2)
    
    tabs = [
        ("Garaje", 0),
        ("Navegación", 1),
        ("Mantenimiento", 2),
        ("Gastos", 3),
        ("Experto IA", 4)
    ]
    
    f_tab = get_font(FONT_BOLD, 19)
    step = WIDTH // len(tabs)
    for i, (name, idx) in enumerate(tabs):
        cx = i * step + step // 2
        is_active = (i == active_tab)
        color = (0, 229, 255, 255) if is_active else (140, 155, 180, 255)
        # Tab icon dot / indicator
        if is_active:
            draw.ellipse((cx - 5, y + 25, cx + 5, y + 35), fill=(0, 229, 255, 255))
        draw.text((cx, y + 55), name, fill=color, font=f_tab, anchor="mt")

# -------------------------------------------------------------
# SCREEN 1: GARAJE INTELIGENTE 360° & HERO DASHBOARD
# -------------------------------------------------------------
def create_screen_garage():
    im = Image.new("RGBA", (WIDTH, HEIGHT), (8, 12, 20, 255))
    draw = ImageDraw.Draw(im)
    
    # Ambient glows
    draw.ellipse((-100, 100, 400, 600), fill=(0, 150, 255, 40))
    draw.ellipse((WIDTH - 300, 400, WIDTH + 200, 900), fill=(16, 185, 129, 30))
    
    draw_status_bar(draw)
    
    # Top Header Pill
    f_brand = get_font(FONT_BOLD, 26)
    f_sub = get_font(FONT_REG, 18)
    draw.rounded_rectangle((40, 80, WIDTH - 40, 150), radius=20, fill=(18, 24, 38, 255), outline=(40, 54, 80, 255), width=2)
    draw.ellipse((60, 95, 100, 135), fill=(0, 229, 255, 255))
    draw.text((80, 115), "A", fill=(10, 15, 28, 255), font=get_font(FONT_BOLD, 22), anchor="mm")
    draw.text((120, 98), "Pulsar NS 200 FI ABS", fill=(255, 255, 255, 255), font=f_brand)
    draw.text((120, 125), "Garaje Activo • Bogotá D.C.", fill=(140, 160, 190, 255), font=f_sub)
    draw.polygon([(WIDTH - 85, 110), (WIDTH - 65, 110), (WIDTH - 75, 124)], fill=(0, 229, 255, 255))
    
    # 360 Hero Area
    hero_y = 175
    draw.rounded_rectangle((40, hero_y, WIDTH - 40, hero_y + 440), radius=28, fill=(14, 19, 32, 255), outline=(32, 44, 68, 255), width=2)
    
    # 360 Badge
    draw.rounded_rectangle((65, hero_y + 20, 240, hero_y + 60), radius=15, fill=(0, 229, 255, 30), outline=(0, 229, 255, 180), width=1)
    draw.text((152, hero_y + 40), "🔄 VISTA 360°", fill=(0, 229, 255, 255), font=get_font(FONT_BOLD, 17), anchor="mm")
    
    # Vehicle Image (Pulsar / MT-15)
    bike_path = r"d:\Proyectos\my_auto_guide\brag-output\composition\assets\mt15.png"
    if os.path.exists(bike_path):
        b_im = Image.open(bike_path).convert("RGBA")
        b_im.thumbnail((540, 360))
        im.paste(b_im, ((WIDTH - b_im.width) // 2, hero_y + 70), b_im)
        
    # Health Index circular gauge
    ish_y = hero_y + 465
    draw.rounded_rectangle((40, ish_y, WIDTH - 40, ish_y + 350), radius=28, fill=(14, 19, 32, 255), outline=(32, 44, 68, 255), width=2)
    
    # Circular Gauge Arc
    gauge_cx, gauge_cy = 220, ish_y + 175
    r = 110
    draw.arc((gauge_cx - r, gauge_cy - r, gauge_cx + r, gauge_cy + r), start=135, end=405, fill=(35, 45, 65, 255), width=18)
    draw.arc((gauge_cx - r, gauge_cy - r, gauge_cx + r, gauge_cy + r), start=135, end=385, fill=(16, 185, 129, 255), width=18)
    
    draw.text((gauge_cx, gauge_cy - 15), "92%", fill=(255, 255, 255, 255), font=get_font(FONT_BOLD, 54), anchor="mm")
    draw.text((gauge_cx, gauge_cy + 30), "ESTADO ÓPTIMO", fill=(16, 185, 129, 255), font=get_font(FONT_BOLD, 15), anchor="mm")
    
    # ISH Right text details
    draw.text((380, ish_y + 70), "Índice de Salud (ISH)", fill=(255, 255, 255, 255), font=get_font(FONT_BOLD, 28))
    draw.text((380, ish_y + 115), "Evaluación continua de motor,", fill=(160, 175, 200, 255), font=get_font(FONT_REG, 20))
    draw.text((380, ish_y + 145), "fluidos, frenos y transmisión.", fill=(160, 175, 200, 255), font=get_font(FONT_REG, 20))
    
    draw.rounded_rectangle((380, ish_y + 200, 780, ish_y + 270), radius=18, fill=(24, 32, 50, 255), outline=(45, 60, 90, 255), width=1)
    draw.text((400, ish_y + 235), "⚡ Telemetría Bluetooth OBD2 Activa", fill=(0, 229, 255, 255), font=get_font(FONT_BOLD, 18), anchor="lm")
    
    # 2 Big Stat Bento Cards
    bento_y = ish_y + 375
    # Card 1: Odómetro
    draw.rounded_rectangle((40, bento_y, 425, bento_y + 220), radius=24, fill=(16, 22, 36, 255), outline=(35, 48, 75, 255), width=2)
    draw.text((70, bento_y + 40), "ODÓMETRO TOTAL", fill=(130, 150, 180, 255), font=get_font(FONT_BOLD, 17))
    draw.text((70, bento_y + 95), "59.433", fill=(255, 255, 255, 255), font=get_font(FONT_BOLD, 46))
    draw.text((250, bento_y + 105), "KM", fill=(0, 229, 255, 255), font=get_font(FONT_BOLD, 24))
    draw.text((70, bento_y + 160), "✓ Sincronizado por GPS", fill=(16, 185, 129, 255), font=get_font(FONT_REG, 17))
    
    # Card 2: Batería & Combustible
    draw.rounded_rectangle((455, bento_y, WIDTH - 40, bento_y + 220), radius=24, fill=(16, 22, 36, 255), outline=(35, 48, 75, 255), width=2)
    draw.text((485, bento_y + 40), "VOLTAJE BATERÍA", fill=(130, 150, 180, 255), font=get_font(FONT_BOLD, 17))
    draw.text((485, bento_y + 95), "12.6 V", fill=(255, 255, 255, 255), font=get_font(FONT_BOLD, 46))
    draw.text((485, bento_y + 160), "✓ Carga de alternador OK", fill=(16, 185, 129, 255), font=get_font(FONT_REG, 17))
    
    # Gamification Banner
    game_y = bento_y + 245
    draw.rounded_rectangle((40, game_y, WIDTH - 40, game_y + 115), radius=22, fill=(24, 30, 48, 255), outline=(50, 68, 105, 255), width=2)
    draw.text((70, game_y + 35), "🏆 Medallas: Nivel Bronce", fill=(255, 215, 0, 255), font=get_font(FONT_BOLD, 22))
    draw.text((70, game_y + 70), "4 Insignias desbloqueadas • Conductor Responsable", fill=(160, 175, 205, 255), font=get_font(FONT_REG, 18))
    
    draw_nav_bar(draw, active_tab=0)
    
    im.save(os.path.join(OUT_DIR, "screen1_garage.png"))
    print("Saved screen1_garage.png")

# -------------------------------------------------------------
# SCREEN 2: NAVEGACIÓN GPS LIBRE, HUD DE VELOCIDAD & VOZ
# -------------------------------------------------------------
def create_screen_gps():
    im = Image.new("RGBA", (WIDTH, HEIGHT), (6, 9, 16, 255))
    draw = ImageDraw.Draw(im)
    
    # Vector Night Map Background
    for x in range(0, WIDTH, 70):
        draw.line((x, 0, x, HEIGHT), fill=(16, 22, 36, 255), width=1)
    for y in range(0, HEIGHT, 70):
        draw.line((0, y, WIDTH, y), fill=(16, 22, 36, 255), width=1)
        
    # Glowing Route Polyline
    points = [
        (150, HEIGHT - 200),
        (280, HEIGHT - 500),
        (340, HEIGHT - 750),
        (560, HEIGHT - 1100),
        (650, HEIGHT - 1450),
        (580, 280)
    ]
    # Route glow
    for w in [32, 22, 14]:
        draw.line(points, fill=(0, 229, 255, 40 if w > 14 else 120), width=w, joint="curve")
    draw.line(points, fill=(0, 255, 255, 255), width=8, joint="curve")
    
    # Pulse vehicle marker
    vx, vy = 340, HEIGHT - 750
    draw.ellipse((vx - 36, vy - 36, vx + 36, vy + 36), fill=(0, 229, 255, 60))
    draw.ellipse((vx - 20, vy - 20, vx + 20, vy + 20), fill=(255, 255, 255, 255), outline=(0, 229, 255, 255), width=4)
    
    draw_status_bar(draw)
    
    # Top Route Banner
    draw.rounded_rectangle((40, 80, WIDTH - 40, 200), radius=24, fill=(14, 20, 34, 240), outline=(40, 56, 88, 255), width=2)
    draw.text((70, 110), "Autopista Bogotá — Girardot", fill=(255, 255, 255, 255), font=get_font(FONT_BOLD, 26))
    draw.text((70, 150), "En 1.2 km gira a la derecha hacia Túnel Gualanday", fill=(0, 229, 255, 255), font=get_font(FONT_BOLD, 20))
    
    # Center Floating HUD: Giant Speedometer
    hud_y = 520
    draw.rounded_rectangle((100, hud_y, WIDTH - 100, hud_y + 380), radius=36, fill=(10, 15, 26, 235), outline=(0, 229, 255, 200), width=3)
    
    # Speed numbers
    draw.text((WIDTH // 2 - 50, hud_y + 150), "76", fill=(255, 255, 255, 255), font=get_font(FONT_BOLD, 140), anchor="mm")
    draw.text((WIDTH // 2 - 50, hud_y + 250), "KM / H", fill=(0, 229, 255, 255), font=get_font(FONT_BOLD, 28), anchor="mm")
    
    # Speed Limit Sign Circle (Col)
    sl_cx, sl_cy = WIDTH - 220, hud_y + 180
    sl_r = 65
    draw.ellipse((sl_cx - sl_r, sl_cy - sl_r, sl_cx + sl_r, sl_cy + sl_r), fill=(255, 255, 255, 255), outline=(220, 38, 38, 255), width=10)
    draw.text((sl_cx, sl_cy), "80", fill=(20, 20, 20, 255), font=get_font(FONT_BOLD, 52), anchor="mm")
    draw.text((sl_cx, sl_cy + 85), "LÍMITE MÁX", fill=(200, 210, 230, 255), font=get_font(FONT_BOLD, 15), anchor="mm")
    
    # Speed warning voice alert banner
    al_y = hud_y + 420
    draw.rounded_rectangle((40, al_y, WIDTH - 40, al_y + 120), radius=22, fill=(35, 22, 10, 245), outline=(245, 158, 11, 255), width=2)
    draw.text((70, al_y + 35), "🔊 Alerta por Voz Activa", fill=(245, 158, 11, 255), font=get_font(FONT_BOLD, 22))
    draw.text((70, al_y + 70), "Velocidad dentro del margen seguro. Monitoreando radares.", fill=(255, 255, 255, 230), font=get_font(FONT_REG, 18))
    
    # Bottom Stats Bar
    st_y = al_y + 150
    draw.rounded_rectangle((40, st_y, WIDTH - 40, st_y + 260), radius=26, fill=(14, 20, 34, 250), outline=(35, 48, 75, 255), width=2)
    
    items = [
        ("Distancia", "14.8 KM"),
        ("Tiempo", "18 MIN"),
        ("Combustible", "$14.200 COP"),
        ("Odómetro", "+14.8 KM")
    ]
    for i, (k, v) in enumerate(items):
        col = i % 2
        row = i // 2
        ix = 80 + col * 400
        iy = st_y + 35 + row * 110
        draw.text((ix, iy), k, fill=(140, 160, 190, 255), font=get_font(FONT_BOLD, 17))
        draw.text((ix, iy + 35), v, fill=(255, 255, 255, 255), font=get_font(FONT_BOLD, 30))
        
    draw_nav_bar(draw, active_tab=1)
    
    im.save(os.path.join(OUT_DIR, "screen2_gps.png"))
    print("Saved screen2_gps.png")

# -------------------------------------------------------------
# SCREEN 3: MANTENIMIENTO, RUNT OFFLINE & SELLO QR DE TALLER
# -------------------------------------------------------------
def create_screen_maintenance():
    im = Image.new("RGBA", (WIDTH, HEIGHT), (8, 12, 20, 255))
    draw = ImageDraw.Draw(im)
    
    draw_status_bar(draw)
    
    # Title
    draw.text((50, 90), "Salud Preventiva & Legal", fill=(255, 255, 255, 255), font=get_font(FONT_BOLD, 36))
    draw.text((50, 138), "Monitoreo de desgaste por kilometraje y vigencias oficiales", fill=(140, 160, 190, 255), font=get_font(FONT_REG, 18))
    
    # Semaphore wear cards
    sem_y = 185
    draw.rounded_rectangle((40, sem_y, WIDTH - 40, sem_y + 380), radius=26, fill=(14, 20, 34, 255), outline=(35, 48, 75, 255), width=2)
    
    wear_items = [
        ("Lubricación de Cadena (Cada 500 km)", 0.05, "0% • ¡REQUERIDO!", (239, 68, 68, 255)),
        ("Aceite de Motor (Yamalube 10W-40)", 0.73, "73% • Restan 2.190 km", (16, 185, 129, 255)),
        ("Filtro de Aire Original", 0.73, "73% • Vida óptima", (16, 185, 129, 255)),
        ("Pastillas de Freno Cerámicas", 0.65, "65% • Inspección en 3.500 km", (0, 229, 255, 255))
    ]
    
    for i, (name, pct, label, col) in enumerate(wear_items):
        iy = sem_y + 30 + i * 85
        draw.text((70, iy), name, fill=(255, 255, 255, 255), font=get_font(FONT_BOLD, 18))
        draw.text((WIDTH - 70, iy), label, fill=col, font=get_font(FONT_BOLD, 16), anchor="ra")
        
        # Track
        draw.rounded_rectangle((70, iy + 35, WIDTH - 70, iy + 47), radius=6, fill=(25, 34, 52, 255))
        # Fill
        fw = int((WIDTH - 140) * pct)
        if fw > 0:
            draw.rounded_rectangle((70, iy + 35, 70 + fw, iy + 47), radius=6, fill=col)
            
    # RUNT Offline Card
    runt_y = sem_y + 405
    draw.rounded_rectangle((40, runt_y, WIDTH - 40, runt_y + 300), radius=26, fill=(16, 24, 40, 255), outline=(0, 229, 255, 140), width=2)
    
    # Runt badge
    draw.rounded_rectangle((65, runt_y + 25, 360, runt_y + 68), radius=14, fill=(16, 185, 129, 30), outline=(16, 185, 129, 200), width=1)
    draw.text((80, runt_y + 46), "🟢 CACHÉ RUNT OFFLINE ACTIVO", fill=(16, 185, 129, 255), font=get_font(FONT_BOLD, 15), anchor="lm")
    
    draw.text((70, runt_y + 90), "SOAT:", fill=(140, 160, 190, 255), font=get_font(FONT_BOLD, 18))
    draw.text((150, runt_y + 90), "Vigente (Vence 24 Nov 2026 • 26 días restantes)", fill=(255, 255, 255, 255), font=get_font(FONT_BOLD, 18))
    
    draw.text((70, runt_y + 130), "Tecno:", fill=(140, 160, 190, 255), font=get_font(FONT_BOLD, 18))
    draw.text((150, runt_y + 130), "Vigente (Vence 15 Ene 2027 • CDA Girardot)", fill=(255, 255, 255, 255), font=get_font(FONT_BOLD, 18))
    
    draw.rounded_rectangle((65, runt_y + 185, WIDTH - 65, runt_y + 265), radius=16, fill=(24, 34, 56, 255))
    draw.text((85, runt_y + 225), "🛡️ Datos guardados en dispositivo. Válidos ante autoridades sin internet.", fill=(0, 229, 255, 255), font=get_font(FONT_REG, 17), anchor="lm")
    
    # Certified Workshop Digital Seal with QR
    qr_y = runt_y + 325
    draw.rounded_rectangle((40, qr_y, WIDTH - 40, qr_y + 420), radius=28, fill=(20, 26, 42, 255), outline=(234, 179, 8, 200), width=2)
    
    # Gold Seal Header
    draw.text((70, qr_y + 35), "🏅 CERTIFICACIÓN DIGITAL DE TALLER", fill=(234, 179, 8, 255), font=get_font(FONT_BOLD, 22))
    draw.text((70, qr_y + 70), "Taller Autorizado AutoGuide — Trazabilidad verificable", fill=(170, 185, 215, 255), font=get_font(FONT_REG, 17))
    
    # Generate authentic QR
    qr = qrcode.QRCode(box_size=5, border=2)
    qr.add_data("https://myautoguide.app/verify?vehicle=PULSAR_NS200&hash=e8b942f1a9")
    qr.make(fit=True)
    qr_img = qr.make_image(fill_color="black", back_color="white").convert("RGBA")
    
    im.paste(qr_img, (70, qr_y + 115))
    
    draw.text((320, qr_y + 140), "Sello Criptográfico:", fill=(140, 160, 190, 255), font=get_font(FONT_BOLD, 18))
    draw.text((320, qr_y + 175), "SHA-256: e8b942...a90f", fill=(0, 229, 255, 255), font=get_font(FONT_MONO, 18))
    draw.text((320, qr_y + 220), "✓ Odómetro auditado: 59.433 KM", fill=(16, 185, 129, 255), font=get_font(FONT_BOLD, 17))
    draw.text((320, qr_y + 255), "✓ Repuestos originales verificados", fill=(16, 185, 129, 255), font=get_font(FONT_BOLD, 17))
    
    # Export PDF Button
    draw.rounded_rectangle((70, qr_y + 340, WIDTH - 70, qr_y + 395), radius=16, fill=(234, 179, 8, 255))
    draw.text((WIDTH // 2, qr_y + 368), "📄 EXPORTAR HOJA DE VIDA EN PDF", fill=(15, 20, 30, 255), font=get_font(FONT_BOLD, 20), anchor="mm")
    
    draw_nav_bar(draw, active_tab=2)
    
    im.save(os.path.join(OUT_DIR, "screen3_maintenance.png"))
    print("Saved screen3_maintenance.png")

# -------------------------------------------------------------
# SCREEN 4: COPILOTO IA (GEMINI) & GESTIÓN DE GASTOS CON CSV
# -------------------------------------------------------------
def create_screen_ai_expenses():
    im = Image.new("RGBA", (WIDTH, HEIGHT), (8, 12, 20, 255))
    draw = ImageDraw.Draw(im)
    
    draw_status_bar(draw)
    
    draw.text((50, 90), "Copiloto IA & Finanzas", fill=(255, 255, 255, 255), font=get_font(FONT_BOLD, 36))
    draw.text((50, 138), "Diagnóstico asistido por Google Gemini y balance contable", fill=(140, 160, 190, 255), font=get_font(FONT_REG, 18))
    
    # AI Chat Area
    ai_y = 185
    draw.rounded_rectangle((40, ai_y, WIDTH - 40, ai_y + 440), radius=28, fill=(15, 20, 34, 255), outline=(147, 51, 234, 180), width=2)
    
    # AI Header
    draw.rounded_rectangle((65, ai_y + 25, 340, ai_y + 70), radius=15, fill=(147, 51, 234, 40), outline=(147, 51, 234, 220), width=1)
    draw.text((80, ai_y + 47), "✨ EXPERTO MECÁNICO IA", fill=(216, 180, 254, 255), font=get_font(FONT_BOLD, 17), anchor="lm")
    
    # User message bubble
    draw.rounded_rectangle((280, ai_y + 90, WIDTH - 65, ai_y + 160), radius=18, fill=(35, 45, 75, 255))
    draw.text((305, ai_y + 115), "¿Por qué cascabelea el motor", fill=(255, 255, 255, 255), font=get_font(FONT_REG, 18))
    draw.text((305, ai_y + 138), "al acelerar en subida fuerte?", fill=(255, 255, 255, 255), font=get_font(FONT_REG, 18))
    
    # AI response bubble
    draw.rounded_rectangle((65, ai_y + 180, WIDTH - 120, ai_y + 410), radius=20, fill=(26, 18, 45, 255), outline=(147, 51, 234, 120), width=1)
    draw.text((90, ai_y + 205), "Diagnóstico Técnico (Pulsar NS 200 FI):", fill=(0, 229, 255, 255), font=get_font(FONT_BOLD, 18))
    ai_text = [
        "1. Octanaje: El motor 199.5cc con compresión",
        "   11:1 requiere gasolina Extra para evitar detonación.",
        "2. Bujía: Verifica calibración de electrodo a 0.8 mm.",
        "3. La cadena requiere lubricación urgente (0% vida útil).",
        "✓ Índice de Salud actual: 92% (Falla Leve / No Crítica)"
    ]
    for idx, l in enumerate(ai_text):
        draw.text((90, ai_y + 245 + idx * 30), l, fill=(230, 230, 240, 255), font=get_font(FONT_REG, 17))
        
    # Expense Donut Section
    exp_y = ai_y + 465
    draw.rounded_rectangle((40, exp_y, WIDTH - 40, exp_y + 570), radius=28, fill=(14, 20, 34, 255), outline=(35, 48, 75, 255), width=2)
    
    # Title & Export button in header
    draw.text((70, exp_y + 35), "Gestión de Gastos", fill=(255, 255, 255, 255), font=get_font(FONT_BOLD, 26))
    
    # CSV Button
    draw.rounded_rectangle((WIDTH - 250, exp_y + 25, WIDTH - 70, exp_y + 70), radius=14, fill=(16, 185, 129, 255))
    draw.text((WIDTH - 160, exp_y + 47), "📥 CSV / Excel", fill=(10, 20, 15, 255), font=get_font(FONT_BOLD, 17), anchor="mm")
    
    # Filter Chips
    chips = ["Todos", "Mes Actual", "Combustible", "Mantenimiento"]
    cx = 70
    for c in chips:
        active = (c == "Mes Actual")
        cw = 140 if len(c) > 7 else 100
        bg = (0, 229, 255, 255) if active else (24, 32, 50, 255)
        tc = (10, 15, 28, 255) if active else (160, 175, 200, 255)
        draw.rounded_rectangle((cx, exp_y + 85, cx + cw, exp_y + 125), radius=12, fill=bg)
        draw.text((cx + cw // 2, exp_y + 105), c, fill=tc, font=get_font(FONT_BOLD, 16), anchor="mm")
        cx += cw + 14
        
    # Donut Chart
    dc_x, dc_y = 220, exp_y + 280
    d_r = 110
    draw.arc((dc_x - d_r, dc_y - d_r, dc_x + d_r, dc_y + d_r), start=0, end=240, fill=(0, 229, 255, 255), width=26)
    draw.arc((dc_x - d_r, dc_y - d_r, dc_x + d_r, dc_y + d_r), start=240, end=310, fill=(234, 179, 8, 255), width=26)
    draw.arc((dc_x - d_r, dc_y - d_r, dc_x + d_r, dc_y + d_r), start=310, end=360, fill=(147, 51, 234, 255), width=26)
    
    draw.text((dc_x, dc_y - 12), "$218K", fill=(255, 255, 255, 255), font=get_font(FONT_BOLD, 36), anchor="mm")
    draw.text((dc_x, dc_y + 24), "COP Total", fill=(140, 160, 190, 255), font=get_font(FONT_REG, 16), anchor="mm")
    
    # Legend right
    lx = 420
    draw.text((lx, exp_y + 210), "• Combustible: $145.000 (66%)", fill=(0, 229, 255, 255), font=get_font(FONT_BOLD, 20))
    draw.text((lx, exp_y + 260), "• Mantenimiento: $45.000 (21%)", fill=(234, 179, 8, 255), font=get_font(FONT_BOLD, 20))
    draw.text((lx, exp_y + 310), "• Otros / Seguro: $28.000 (13%)", fill=(216, 180, 254, 255), font=get_font(FONT_BOLD, 20))
    
    # Recent expense row
    draw.rounded_rectangle((70, exp_y + 440, WIDTH - 70, exp_y + 535), radius=18, fill=(20, 28, 46, 255))
    draw.text((95, exp_y + 465), "⛽ Tanqueo Completo Estación Terpel", fill=(255, 255, 255, 255), font=get_font(FONT_BOLD, 18))
    draw.text((95, exp_y + 500), "Ayer • Odómetro: 59.400 KM • 3.2 Galones", fill=(140, 160, 190, 255), font=get_font(FONT_REG, 16))
    draw.text((WIDTH - 95, exp_y + 482), "-$45.000 COP", fill=(239, 68, 68, 255), font=get_font(FONT_BOLD, 20), anchor="rm")
    
    draw_nav_bar(draw, active_tab=3)
    
    im.save(os.path.join(OUT_DIR, "screen4_ai_expenses.png"))
    print("Saved screen4_ai_expenses.png")

if __name__ == "__main__":
    create_screen_garage()
    create_screen_gps()
    create_screen_maintenance()
    create_screen_ai_expenses()
    print("ALL CLEAN HIGH-RESOLUTION SCREENS GENERATED SUCCESSFULLY!")
