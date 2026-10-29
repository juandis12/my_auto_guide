#!/usr/bin/env python3
"""
High-Production 16:9 (1920x1080) Video Renderer for MY AUTO GUIDE (v2.5)
Uses 100% REAL APPLICATION SCREENSHOTS from the actual Flutter phone build.
Features:
- Real authentic screens in precision-scaled titanium phone mockup with Dynamic Island
- Smooth kinetic easing curves & floating glassmorphic callout cards
- 41.0-second broadcast commercial synchronized with Colombian Spanish neural voiceover & SFX
"""

import os
import sys
import math
import subprocess
import time
from multiprocessing import Pool
from PIL import Image, ImageDraw, ImageFont, ImageFilter

if sys.stdout.encoding and sys.stdout.encoding.lower() != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    except Exception:
        pass

WIDTH, HEIGHT = 1920, 1080
FPS = 30
DURATION = 41.0
TOTAL_FRAMES = int(FPS * DURATION)  # 1230 frames

WORK_DIR = r"d:\Proyectos\my_auto_guide\brag-output\work"
FRAMES_DIR = os.path.join(WORK_DIR, "frames_16x9")
SCREENS_DIR = r"d:\Proyectos\my_auto_guide\brag-output\composition\assets\screens"
OUTPUT_VIDEO = r"d:\Proyectos\my_auto_guide\brag-output\brag.mp4"
OUTPUT_POSTER = r"d:\Proyectos\my_auto_guide\brag-output\brag.jpg"
AUDIO_PATH = os.path.join(WORK_DIR, "final_soundtrack.mp3")

FONT_BOLD = "C:/Windows/Fonts/segoeuib.ttf"
FONT_REG = "C:/Windows/Fonts/segoeui.ttf"
FONT_MONO = "C:/Windows/Fonts/consola.ttf"

def get_font(path, size):
    try:
        return ImageFont.truetype(path, size)
    except:
        return ImageFont.load_default()

# Pre-load REAL app screenshots into memory
scr_home = Image.open(os.path.join(SCREENS_DIR, "screen_01_home.jpg")).convert('RGB')
scr_garage = Image.open(os.path.join(SCREENS_DIR, "screen_02_dashboard_ia.jpg")).convert('RGB')
scr_gps = Image.open(os.path.join(SCREENS_DIR, "screen_05_gps_nav.jpg")).convert('RGB')
scr_maint1 = Image.open(os.path.join(SCREENS_DIR, "screen_07_maint_preventive.jpg")).convert('RGB')
scr_maint2 = Image.open(os.path.join(SCREENS_DIR, "screen_08_maint_oil_soat.jpg")).convert('RGB')
scr_expenses = Image.open(os.path.join(SCREENS_DIR, "screen_10_expenses.jpg")).convert('RGB')
scr_specs = Image.open(os.path.join(SCREENS_DIR, "screen_13_manuals_specs.jpg")).convert('RGB')

# Pre-load logo
LOGO_PATH = r"d:\Proyectos\my_auto_guide\brag-output\composition\assets\logo.png"
logo_im = Image.open(LOGO_PATH).convert('RGBA') if os.path.exists(LOGO_PATH) else None

def create_phone_mockup(screen_img, width=440, height=920, corner_radius=50, bezel=14, glare_shift=0.0):
    sw = width - bezel * 2  # 412
    sh = height - bezel * 2 # 892
    
    # Scale real screenshot perfectly (739x1600 -> 412x892)
    screen_crop = screen_img.resize((sw, sh), Image.Resampling.LANCZOS).convert('RGBA')
    
    # Rounded corner mask for the phone screen
    screen_mask = Image.new('L', (sw, sh), 0)
    draw_sm = ImageDraw.Draw(screen_mask)
    draw_sm.rounded_rectangle((0, 0, sw, sh), radius=corner_radius - bezel, fill=255)
    screen_crop.putalpha(screen_mask)
    
    device = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw_d = ImageDraw.Draw(device)
    
    # Outer titanium rim & chamfered border
    draw_d.rounded_rectangle((0, 0, width, height), radius=corner_radius, fill=(28, 36, 48, 255), outline=(85, 110, 145, 255), width=3)
    draw_d.rounded_rectangle((3, 3, width - 3, height - 3), radius=corner_radius - 2, fill=(10, 14, 22, 255), outline=(35, 45, 65, 255), width=2)
    
    # Paste actual real application screen
    device.paste(screen_crop, (bezel, bezel), screen_crop)
    
    # Dynamic Island pill
    pill_w = 96
    pill_h = 24
    pill_x = (width - pill_w) // 2
    pill_y = bezel + 8
    draw_d.rounded_rectangle((pill_x, pill_y, pill_x + pill_w, pill_y + pill_h), radius=12, fill=(0, 0, 0, 255))
    draw_d.ellipse((pill_x + pill_w - 20, pill_y + 6, pill_x + pill_w - 8, pill_y + 18), fill=(16, 24, 40, 255))
    
    # Moving glass glare streak
    glare = Image.new('RGBA', (sw, sh), (0, 0, 0, 0))
    draw_g = ImageDraw.Draw(glare)
    glare_x = int((sw + 400) * glare_shift) - 200
    draw_g.polygon([
        (glare_x, 0),
        (glare_x + 85, 0),
        (glare_x - 120, sh),
        (glare_x - 205, sh)
    ], fill=(255, 255, 255, 20))
    device.paste(glare, (bezel, bezel), glare)
    
    # Inner subtle stroke
    draw_d.rounded_rectangle((bezel, bezel, bezel + sw, bezel + sh), radius=corner_radius - bezel, outline=(255, 255, 255, 30), width=1)
    return device

def render_frame_16x9(frame_idx):
    t = frame_idx / FPS  # Current second
    
    im = Image.new("RGBA", (WIDTH, HEIGHT), (6, 9, 16, 255))
    draw = ImageDraw.Draw(im)
    
    # Ambient glowing orbs
    pulse1 = 0.5 + 0.5 * math.sin(t * 1.5)
    pulse2 = 0.5 + 0.5 * math.cos(t * 1.2)
    draw.ellipse((-120, -120, int(650 + pulse1 * 100), int(650 + pulse1 * 100)), fill=(0, 229, 255, int(18 + pulse1 * 12)))
    draw.ellipse((WIDTH - 650, HEIGHT - 650, int(WIDTH + 200 + pulse2 * 100), int(HEIGHT + 200 + pulse2 * 100)), fill=(147, 51, 234, int(18 + pulse2 * 12)))
    
    # High-tech background grid
    for x in range(0, WIDTH, 80):
        draw.line((x, 0, x, HEIGHT), fill=(255, 255, 255, 5), width=1)
    for y in range(0, HEIGHT, 80):
        draw.line((0, y, WIDTH, y), fill=(255, 255, 255, 5), width=1)
        
    # Top Brand Pill
    draw.rounded_rectangle((70, 40, 450, 95), radius=20, fill=(16, 24, 38, 220), outline=(40, 56, 85, 255), width=1)
    draw.ellipse((85, 52, 115, 82), fill=(0, 229, 255, 255))
    draw.text((100, 67), "A", fill=(8, 12, 20, 255), font=get_font(FONT_BOLD, 20), anchor="mm")
    draw.text((130, 55), "MY AUTO GUIDE", fill=(255, 255, 255, 255), font=get_font(FONT_BOLD, 19))
    draw.text((130, 75), "APP OFICIAL EN PRODUCCIÓN 2026", fill=(0, 229, 255, 255), font=get_font(FONT_BOLD, 11))
    
    # Live Proof Badge Top Right
    draw.rounded_rectangle((WIDTH - 440, 40, WIDTH - 70, 92), radius=20, fill=(10, 24, 40, 220), outline=(0, 229, 255, 180), width=1)
    draw.ellipse((WIDTH - 415, 58, WIDTH - 403, 70), fill=(0, 229, 255, 255))
    draw.text((WIDTH - 390, 56), "CAPTURAS REALES EN VIVO", fill=(0, 229, 255, 255), font=get_font(FONT_BOLD, 13))
    
    glare = (t * 0.25) % 1.0
    phone_w, phone_h = 440, 920
    px = 480
    py = 540
    
    # -------------------------------------------------------------
    # SCENE 1: GARAJE 360° & SALUD VEHICULAR (0.0s - 9.0s)
    # -------------------------------------------------------------
    if t < 9.0:
        # Crossfade between home and garage screen
        if t < 3.0:
            current_screen = scr_home
        else:
            current_screen = scr_garage
            
        phone_im = create_phone_mockup(current_screen, width=phone_w, height=phone_h, glare_shift=glare)
        
        # Soft shadow behind phone
        draw.rounded_rectangle((px - phone_w//2 + 15, py - phone_h//2 + 25, px + phone_w//2 + 15, py + phone_h//2 + 25), radius=55, fill=(0, 0, 0, 110))
        im.paste(phone_im, (px - phone_w//2, py - phone_h//2), phone_im)
        
        rx = 980
        draw.rounded_rectangle((rx, 140, rx + 320, 185), radius=14, fill=(0, 229, 255, 30), outline=(0, 229, 255, 180), width=1)
        draw.text((rx + 160, 162), "SUITE VEHICULAR INTELIGENTE", fill=(0, 229, 255, 255), font=get_font(FONT_BOLD, 15), anchor="mm")
        
        draw.text((rx, 210), "GARAJE 360° & SALUD", fill=(255, 255, 255, 255), font=get_font(FONT_BOLD, 50))
        draw.text((rx, 268), "VEHICULAR EN TIEMPO REAL", fill=(0, 229, 255, 255), font=get_font(FONT_BOLD, 50))
        
        draw.text((rx, 340), "Monitoreo integral con odómetro activo acumulativo,", fill=(180, 195, 220, 255), font=get_font(FONT_REG, 24))
        draw.text((rx, 375), "evaluación continua de fluidos y telemetría OBD-II.", fill=(180, 195, 220, 255), font=get_font(FONT_REG, 24))
        
        # Bento Floating Card 1: ISH Counter
        ish_val = int(min(92, (t / 4.0) * 92)) if t < 4.0 else 92
        draw.rounded_rectangle((rx, 445, rx + 410, 585), radius=22, fill=(14, 20, 34, 240), outline=(0, 229, 255, 140), width=2)
        draw.text((rx + 30, 475), "ÍNDICE DE SALUD (ISH)", fill=(140, 160, 190, 255), font=get_font(FONT_BOLD, 17))
        draw.text((rx + 30, 530), f"{ish_val}%", fill=(16, 185, 129, 255), font=get_font(FONT_BOLD, 48))
        draw.text((rx + 160, 538), "• Estado Óptimo", fill=(255, 255, 255, 255), font=get_font(FONT_BOLD, 22))
        
        # Bento Floating Card 2: Odómetro Sincronizado
        draw.rounded_rectangle((rx + 430, 445, rx + 840, 585), radius=22, fill=(14, 20, 34, 240), outline=(35, 48, 75, 255), width=2)
        draw.text((rx + 460, 475), "ODÓMETRO TOTAL VIVO", fill=(140, 160, 190, 255), font=get_font(FONT_BOLD, 17))
        draw.text((rx + 460, 530), "59.433", fill=(255, 255, 255, 255), font=get_font(FONT_BOLD, 46))
        draw.text((rx + 640, 540), "KM", fill=(0, 229, 255, 255), font=get_font(FONT_BOLD, 22))
        
        # Subtitle Pill Bottom
        draw.rounded_rectangle((rx, 640, rx + 840, 745), radius=20, fill=(20, 28, 46, 255), outline=(50, 70, 105, 255), width=2)
        draw.text((rx + 30, 670), "🎙️ Tu centro de mando con vista 360°, odómetro vivo e Índice de Salud", fill=(255, 255, 255, 255), font=get_font(FONT_BOLD, 20))
        draw.text((rx + 30, 702), "    vehicular en tiempo real.", fill=(0, 229, 255, 255), font=get_font(FONT_BOLD, 20))
        
    # -------------------------------------------------------------
    # SCENE 2: NAVEGACIÓN GPS LIBRE CON HUD & VOZ (9.0s - 17.0s)
    # -------------------------------------------------------------
    elif t < 17.0:
        rel_t = t - 9.0
        phone_im = create_phone_mockup(scr_gps, width=phone_w, height=phone_h, glare_shift=glare)
        
        draw.rounded_rectangle((px - phone_w//2 + 15, py - phone_h//2 + 25, px + phone_w//2 + 15, py + phone_h//2 + 25), radius=55, fill=(0, 0, 0, 110))
        im.paste(phone_im, (px - phone_w//2, py - phone_h//2), phone_im)
        
        rx = 980
        draw.rounded_rectangle((rx, 140, rx + 300, 185), radius=14, fill=(16, 185, 129, 30), outline=(16, 185, 129, 180), width=1)
        draw.text((rx + 150, 162), "TELEMETRÍA & SEGURIDAD VIAL", fill=(16, 185, 129, 255), font=get_font(FONT_BOLD, 15), anchor="mm")
        
        draw.text((rx, 210), "GPS LIBRE CON HUD", fill=(255, 255, 255, 255), font=get_font(FONT_BOLD, 50))
        draw.text((rx, 268), "Y VELOCÍMETRO INTELIGENTE", fill=(16, 185, 129, 255), font=get_font(FONT_BOLD, 50))
        
        draw.text((rx, 340), "Velocímetro digital con Head-Up Display integrado,", fill=(180, 195, 220, 255), font=get_font(FONT_REG, 24))
        draw.text((rx, 375), "cálculo de combustible en COP y alertas por voz sin distracción.", fill=(180, 195, 220, 255), font=get_font(FONT_REG, 24))
        
        spd = int(45 + min(31, rel_t * 6.5)) if rel_t < 5.0 else 76
        draw.rounded_rectangle((rx, 445, rx + 410, 585), radius=22, fill=(14, 20, 34, 240), outline=(16, 185, 129, 160), width=2)
        draw.text((rx + 30, 475), "VELOCIDAD EN RUTA", fill=(140, 160, 190, 255), font=get_font(FONT_BOLD, 17))
        draw.text((rx + 30, 530), f"{spd}", fill=(255, 255, 255, 255), font=get_font(FONT_BOLD, 48))
        draw.text((rx + 115, 540), "KM/H", fill=(0, 229, 255, 255), font=get_font(FONT_BOLD, 22))
        draw.text((rx + 220, 540), "• Límite: 80", fill=(239, 68, 68, 255), font=get_font(FONT_BOLD, 20))
        
        # Speed Alert Card
        draw.rounded_rectangle((rx + 430, 445, rx + 840, 585), radius=22, fill=(35, 22, 10, 240), outline=(245, 158, 11, 200), width=2)
        draw.text((rx + 460, 475), "ALERTA POR VOZ ACTIVA", fill=(245, 158, 11, 255), font=get_font(FONT_BOLD, 17))
        draw.text((rx + 460, 525), "🔊 Anti-Fotomultas", fill=(255, 255, 255, 255), font=get_font(FONT_BOLD, 26))
        draw.text((rx + 460, 555), "Aviso sonoro automático al superar 80 km/h", fill=(200, 215, 235, 255), font=get_font(FONT_REG, 16))
        
        draw.rounded_rectangle((rx, 640, rx + 840, 745), radius=20, fill=(20, 28, 46, 255), outline=(50, 70, 105, 255), width=2)
        draw.text((rx + 30, 670), "🎙️ Navegación GPS con telemetría en vivo, velocímetro digital inteligente", fill=(255, 255, 255, 255), font=get_font(FONT_BOLD, 20))
        draw.text((rx + 30, 702), "    y alertas sonoras automáticas para evitar fotomultas en carretera.", fill=(16, 185, 129, 255), font=get_font(FONT_BOLD, 20))
        
    # -------------------------------------------------------------
    # SCENE 3: MANTENIMIENTO, RUNT OFFLINE & SELLO QR (17.0s - 25.0s)
    # -------------------------------------------------------------
    elif t < 25.0:
        rel_t = t - 17.0
        # Show real maintenance screen 1, then screen 2
        active_scr = scr_maint1 if rel_t < 4.0 else scr_maint2
        phone_im = create_phone_mockup(active_scr, width=phone_w, height=phone_h, glare_shift=glare)
        
        draw.rounded_rectangle((px - phone_w//2 + 15, py - phone_h//2 + 25, px + phone_w//2 + 15, py + phone_h//2 + 25), radius=55, fill=(0, 0, 0, 110))
        im.paste(phone_im, (px - phone_w//2, py - phone_h//2), phone_im)
        
        rx = 980
        draw.rounded_rectangle((rx, 140, rx + 300, 185), radius=14, fill=(234, 179, 8, 30), outline=(234, 179, 8, 180), width=1)
        draw.text((rx + 150, 162), "MANTENIMIENTO & LEGALIDAD", fill=(234, 179, 8, 255), font=get_font(FONT_BOLD, 15), anchor="mm")
        
        draw.text((rx, 210), "RUNT OFFLINE & SELLO", fill=(255, 255, 255, 255), font=get_font(FONT_BOLD, 50))
        draw.text((rx, 268), "DIGITAL QR CERTIFICADO", fill=(234, 179, 8, 255), font=get_font(FONT_BOLD, 50))
        
        draw.text((rx, 340), "Semáforo predictivo de piezas críticas y consulta de SOAT", fill=(180, 195, 220, 255), font=get_font(FONT_REG, 24))
        draw.text((rx, 375), "sin internet con respaldo criptográfico para peritajes oficiales.", fill=(180, 195, 220, 255), font=get_font(FONT_REG, 24))
        
        # Bento Card 1: RUNT Offline
        draw.rounded_rectangle((rx, 445, rx + 410, 585), radius=22, fill=(16, 24, 40, 240), outline=(16, 185, 129, 180), width=2)
        draw.text((rx + 30, 475), "CONSULTA LEGAL RUNT", fill=(140, 160, 190, 255), font=get_font(FONT_BOLD, 17))
        draw.text((rx + 30, 520), "🟢 100% OFFLINE", fill=(16, 185, 129, 255), font=get_font(FONT_BOLD, 30))
        draw.text((rx + 30, 555), "SOAT y Tecno guardados en caché local", fill=(200, 215, 235, 255), font=get_font(FONT_REG, 16))
        
        # Bento Card 2: QR Taller
        draw.rounded_rectangle((rx + 430, 445, rx + 840, 585), radius=22, fill=(20, 26, 42, 240), outline=(234, 179, 8, 180), width=2)
        draw.text((rx + 460, 475), "CERTIFICACIÓN DE TALLER", fill=(234, 179, 8, 255), font=get_font(FONT_BOLD, 17))
        draw.text((rx + 460, 520), "🔐 SELLO QR SHA-256", fill=(255, 255, 255, 255), font=get_font(FONT_BOLD, 28))
        draw.text((rx + 460, 555), "Evita fraudes en kilometraje y repuestos", fill=(200, 215, 235, 255), font=get_font(FONT_REG, 16))
        
        draw.rounded_rectangle((rx, 640, rx + 840, 745), radius=20, fill=(20, 28, 46, 255), outline=(50, 70, 105, 255), width=2)
        draw.text((rx + 30, 670), "🎙️ Control de mantenimientos preventivos, consulta oficial de SOAT y", fill=(255, 255, 255, 255), font=get_font(FONT_BOLD, 20))
        draw.text((rx + 30, 702), "    Tecnomecánica sin internet, y certificación digital con código QR de taller.", fill=(234, 179, 8, 255), font=get_font(FONT_BOLD, 20))
        
    # -------------------------------------------------------------
    # SCENE 4: GASTOS REALES & COPILOTO IA (25.0s - 33.0s)
    # -------------------------------------------------------------
    elif t < 33.0:
        rel_t = t - 25.0
        active_scr = scr_expenses if rel_t < 4.5 else scr_specs
        phone_im = create_phone_mockup(active_scr, width=phone_w, height=phone_h, glare_shift=glare)
        
        draw.rounded_rectangle((px - phone_w//2 + 15, py - phone_h//2 + 25, px + phone_w//2 + 15, py + phone_h//2 + 25), radius=55, fill=(0, 0, 0, 110))
        im.paste(phone_im, (px - phone_w//2, py - phone_h//2), phone_im)
        
        rx = 980
        draw.rounded_rectangle((rx, 140, rx + 300, 185), radius=14, fill=(147, 51, 234, 30), outline=(147, 51, 234, 180), width=1)
        draw.text((rx + 150, 162), "INTELIGENCIA ARTIFICIAL & DATOS", fill=(216, 180, 254, 255), font=get_font(FONT_BOLD, 15), anchor="mm")
        
        draw.text((rx, 210), "COPILOTO MECÁNICO IA", fill=(255, 255, 255, 255), font=get_font(FONT_BOLD, 50))
        draw.text((rx, 268), "Y CONTROL FINANCIERO", fill=(216, 180, 254, 255), font=get_font(FONT_BOLD, 50))
        
        draw.text((rx, 340), "Diagnóstico vehicular asistido por Google Gemini y", fill=(180, 195, 220, 255), font=get_font(FONT_REG, 24))
        draw.text((rx, 375), "balance detallado con exportación inmediata a Excel y Sheets.", fill=(180, 195, 220, 255), font=get_font(FONT_REG, 24))
        
        # Bento Card 1: Gemini AI
        draw.rounded_rectangle((rx, 445, rx + 410, 585), radius=22, fill=(24, 18, 42, 240), outline=(147, 51, 234, 180), width=2)
        draw.text((rx + 30, 475), "ASISTENTE MECÁNICO", fill=(216, 180, 254, 255), font=get_font(FONT_BOLD, 17))
        draw.text((rx + 30, 520), "✨ GEMINI 24 / 7", fill=(255, 255, 255, 255), font=get_font(FONT_BOLD, 30))
        draw.text((rx + 30, 555), "Fichas técnicas y torques oficiales", fill=(200, 215, 235, 255), font=get_font(FONT_REG, 16))
        
        # Bento Card 2: Export CSV
        draw.rounded_rectangle((rx + 430, 445, rx + 840, 585), radius=22, fill=(16, 26, 36, 240), outline=(16, 185, 129, 180), width=2)
        draw.text((rx + 460, 475), "EXPORTACIÓN CONTABLE", fill=(16, 185, 129, 255), font=get_font(FONT_BOLD, 17))
        draw.text((rx + 460, 520), "📥 CSV & EXCEL", fill=(255, 255, 255, 255), font=get_font(FONT_BOLD, 30))
        draw.text((rx + 460, 555), "Gráfica de gastos discriminada por mes", fill=(200, 215, 235, 255), font=get_font(FONT_REG, 16))
        
        draw.rounded_rectangle((rx, 640, rx + 840, 745), radius=20, fill=(20, 28, 46, 255), outline=(50, 70, 105, 255), width=2)
        draw.text((rx + 30, 670), "🎙️ Asistente mecánico con Inteligencia Artificial disponible las 24 horas", fill=(255, 255, 255, 255), font=get_font(FONT_BOLD, 20))
        draw.text((rx + 30, 702), "    y gestión inteligente de gastos con exportación contable a Excel.", fill=(216, 180, 254, 255), font=get_font(FONT_BOLD, 20))
        
    # -------------------------------------------------------------
    # SCENE 5: SHOWCASE BENTO 3D & OUTRO CINEMÁTICO (33.0s - 41.0s)
    # -------------------------------------------------------------
    else:
        # Dual-phone showcase: Real Home + Real GPS
        p1_w, p1_h = 360, 760
        phone1 = create_phone_mockup(scr_garage, width=p1_w, height=p1_h, glare_shift=0.3)
        phone2 = create_phone_mockup(scr_gps, width=p1_w, height=p1_h, glare_shift=0.6)
        
        # Phone 1 Left tilted
        im.paste(phone1, (160, 200), phone1)
        # Phone 2 Overlapping
        im.paste(phone2, (380, 260), phone2)
        
        # Right Grand Launch Hero
        rx = 820
        cx = rx + 480
        
        if logo_im:
            l_scaled = logo_im.copy()
            l_scaled.thumbnail((260, 260))
            im.paste(l_scaled, (cx - l_scaled.width // 2, 140), l_scaled)
            
        draw.text((cx, 430), "MY AUTO GUIDE", fill=(255, 255, 255, 255), font=get_font(FONT_BOLD, 68), anchor="mm")
        draw.text((cx, 500), "Tu copiloto. Tu mecánico. Tu garaje inteligente.", fill=(0, 229, 255, 255), font=get_font(FONT_BOLD, 30), anchor="mm")
        
        # Tech Pillars Pills
        pillars = [
            "⚡ Flutter Élite 3.3",
            "🛡️ 100% Offline-First",
            "📡 Telemetría OBD-II",
            "✨ Google Gemini AI"
        ]
        pw_start = cx - 410
        for i, pil in enumerate(pillars):
            pix = pw_start + i * 210
            draw.rounded_rectangle((pix, 570, pix + 200, 620), radius=14, fill=(16, 24, 40, 255), outline=(40, 60, 95, 255), width=1)
            draw.text((pix + 100, 595), pil, fill=(200, 215, 240, 255), font=get_font(FONT_BOLD, 15), anchor="mm")
            
        # Download CTA Buttons
        draw.rounded_rectangle((cx - 280, 670, cx - 30, 750), radius=22, fill=(255, 255, 255, 255))
        draw.text((cx - 155, 710), "📱 Google Play", fill=(10, 15, 25, 255), font=get_font(FONT_BOLD, 24), anchor="mm")
        
        draw.rounded_rectangle((cx + 30, 670, cx + 280, 750), radius=22, fill=(20, 28, 48, 255), outline=(0, 229, 255, 255), width=2)
        draw.text((cx + 155, 710), "🍎 App Store", fill=(255, 255, 255, 255), font=get_font(FONT_BOLD, 24), anchor="mm")
        
        draw.text((cx, 810), "Toma el control absoluto de tu vehículo hoy mismo.", fill=(160, 175, 205, 255), font=get_font(FONT_REG, 22), anchor="mm")
        
    out_file = os.path.join(FRAMES_DIR, f"frame_{frame_idx:05d}.jpg")
    im.convert("RGB").save(out_file, "JPEG", quality=92)
    return frame_idx

def main():
    print("=" * 80)
    print("🎬 RENDERING 16:9 PRO BROADCAST VIDEO WITH 100% REAL APP SCREENS")
    print("=" * 80)
    os.makedirs(FRAMES_DIR, exist_ok=True)
    
    start_time = time.time()
    num_workers = min(7, os.cpu_count() or 4)
    print(f"[*] Rendering {TOTAL_FRAMES} frames across {num_workers} parallel workers...")
    
    with Pool(num_workers) as pool:
        for i, _ in enumerate(pool.imap_unordered(render_frame_16x9, range(TOTAL_FRAMES), chunksize=15)):
            if (i + 1) % 150 == 0 or (i + 1) == TOTAL_FRAMES:
                pct = ((i + 1) / TOTAL_FRAMES) * 100
                print(f"    Progress: {i + 1}/{TOTAL_FRAMES} frames ({pct:.1f}%)")
                
    elapsed = time.time() - start_time
    print(f"✅ Rendered {TOTAL_FRAMES} frames in {elapsed:.1f} seconds ({TOTAL_FRAMES/elapsed:.1f} fps)")
    
    poster_src = os.path.join(FRAMES_DIR, f"frame_{int(36.0 * FPS):05d}.jpg")
    if os.path.exists(poster_src):
        import shutil
        shutil.copyfile(poster_src, OUTPUT_POSTER)
        print(f"📸 Saved poster frame: {OUTPUT_POSTER}")
        
    print("\n[*] Encoding MP4 with FFmpeg and synchronizing audio...")
    cmd = [
        "ffmpeg", "-y",
        "-framerate", str(FPS),
        "-i", os.path.join(FRAMES_DIR, "frame_%05d.jpg"),
        "-i", AUDIO_PATH,
        "-c:v", "libx264",
        "-preset", "fast",
        "-crf", "18",
        "-pix_fmt", "yuv420p",
        "-c:a", "aac",
        "-b:a", "256k",
        "-shortest",
        OUTPUT_VIDEO
    ]
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0:
        print("FFmpeg encode error:", res.stderr)
        exit(1)
        
    print(f"🎉 16:9 PRO VIDEO SUCCESSFULLY GENERATED: {OUTPUT_VIDEO}")
    print("=" * 80)

if __name__ == "__main__":
    main()
