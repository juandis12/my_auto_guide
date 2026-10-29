#!/usr/bin/env python3
"""
High-Production 9:16 (1080x1920) Video Renderer for MY AUTO GUIDE (v2.5)
Optimized for Instagram Reels, TikTok, and YouTube Shorts.
Uses 100% REAL APPLICATION SCREENSHOTS from the actual Flutter phone build.
Features:
- Large centered titanium smartphone with real screens & dynamic glass reflections
- Kinetic typography, animated progress bar, and floating feature pills
- Synchronized with Colombian Spanish voiceover & broadcast soundtrack
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

WIDTH, HEIGHT = 1080, 1920
FPS = 30
DURATION = 41.0
TOTAL_FRAMES = int(FPS * DURATION)  # 1230 frames

WORK_DIR = r"d:\Proyectos\my_auto_guide\brag-output\work"
FRAMES_DIR = os.path.join(WORK_DIR, "frames_9x16")
SCREENS_DIR = r"d:\Proyectos\my_auto_guide\brag-output\composition\assets\screens"
OUTPUT_VIDEO = r"d:\Proyectos\my_auto_guide\brag-output\my_auto_guide_reels_9x16.mp4"
OUTPUT_POSTER = r"d:\Proyectos\my_auto_guide\brag-output\my_auto_guide_reels_9x16.jpg"
AUDIO_PATH = os.path.join(WORK_DIR, "final_soundtrack.mp3")

FONT_BOLD = "C:/Windows/Fonts/segoeuib.ttf"
FONT_REG = "C:/Windows/Fonts/segoeui.ttf"
FONT_MONO = "C:/Windows/Fonts/consola.ttf"

def get_font(path, size):
    try:
        return ImageFont.truetype(path, size)
    except:
        return ImageFont.load_default()

# Pre-load real screenshots
scr_home = Image.open(os.path.join(SCREENS_DIR, "screen_01_home.jpg")).convert('RGB')
scr_garage = Image.open(os.path.join(SCREENS_DIR, "screen_02_dashboard_ia.jpg")).convert('RGB')
scr_gps = Image.open(os.path.join(SCREENS_DIR, "screen_05_gps_nav.jpg")).convert('RGB')
scr_maint1 = Image.open(os.path.join(SCREENS_DIR, "screen_07_maint_preventive.jpg")).convert('RGB')
scr_maint2 = Image.open(os.path.join(SCREENS_DIR, "screen_08_maint_oil_soat.jpg")).convert('RGB')
scr_expenses = Image.open(os.path.join(SCREENS_DIR, "screen_10_expenses.jpg")).convert('RGB')
scr_specs = Image.open(os.path.join(SCREENS_DIR, "screen_13_manuals_specs.jpg")).convert('RGB')

LOGO_PATH = r"d:\Proyectos\my_auto_guide\brag-output\composition\assets\logo.png"
logo_im = Image.open(LOGO_PATH).convert('RGBA') if os.path.exists(LOGO_PATH) else None

def create_phone_mockup_vertical(screen_img, width=580, height=1240, corner_radius=58, bezel=16, glare_shift=0.0):
    sw = width - bezel * 2  # 548
    sh = height - bezel * 2 # 1208
    
    # Scale real screenshot to fill display area
    scale = max(sw / screen_img.width, sh / screen_img.height)
    tw = int(screen_img.width * scale)
    th = int(screen_img.height * scale)
    scaled = screen_img.resize((tw, th), Image.Resampling.LANCZOS).convert('RGBA')
    
    # Exact center crop
    cx = (tw - sw) // 2
    cy = (th - sh) // 2
    screen_crop = scaled.crop((cx, cy, cx + sw, cy + sh))
    
    screen_mask = Image.new('L', (sw, sh), 0)
    draw_sm = ImageDraw.Draw(screen_mask)
    draw_sm.rounded_rectangle((0, 0, sw, sh), radius=corner_radius - bezel, fill=255)
    screen_crop.putalpha(screen_mask)
    
    device = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw_d = ImageDraw.Draw(device)
    
    # Outer frame
    draw_d.rounded_rectangle((0, 0, width, height), radius=corner_radius, fill=(26, 34, 46, 255), outline=(80, 105, 140, 255), width=4)
    draw_d.rounded_rectangle((4, 4, width - 4, height - 4), radius=corner_radius - 2, fill=(10, 14, 22, 255), outline=(35, 45, 65, 255), width=2)
    
    device.paste(screen_crop, (bezel, bezel), screen_crop)
    
    # Dynamic Island
    pill_w = 120
    pill_h = 30
    pill_x = (width - pill_w) // 2
    pill_y = bezel + 10
    draw_d.rounded_rectangle((pill_x, pill_y, pill_x + pill_w, pill_y + pill_h), radius=15, fill=(0, 0, 0, 255))
    draw_d.ellipse((pill_x + pill_w - 26, pill_y + 8, pill_x + pill_w - 10, pill_y + 24), fill=(16, 24, 40, 255))
    
    # Glare streak
    glare = Image.new('RGBA', (sw, sh), (0, 0, 0, 0))
    draw_g = ImageDraw.Draw(glare)
    glare_x = int((sw + 500) * glare_shift) - 250
    draw_g.polygon([
        (glare_x, 0),
        (glare_x + 110, 0),
        (glare_x - 160, sh),
        (glare_x - 270, sh)
    ], fill=(255, 255, 255, 22))
    device.paste(glare, (bezel, bezel), glare)
    
    draw_d.rounded_rectangle((bezel, bezel, bezel + sw, bezel + sh), radius=corner_radius - bezel, outline=(255, 255, 255, 30), width=1)
    return device

def render_frame_9x16(frame_idx):
    t = frame_idx / FPS
    im = Image.new("RGBA", (WIDTH, HEIGHT), (6, 9, 16, 255))
    draw = ImageDraw.Draw(im)
    
    # Ambient glows
    pulse1 = 0.5 + 0.5 * math.sin(t * 1.5)
    pulse2 = 0.5 + 0.5 * math.cos(t * 1.2)
    draw.ellipse((-100, 200, int(600 + pulse1 * 100), int(900 + pulse1 * 100)), fill=(0, 229, 255, int(16 + pulse1 * 12)))
    draw.ellipse((WIDTH - 500, HEIGHT - 700, int(WIDTH + 200 + pulse2 * 100), int(HEIGHT + pulse2 * 100)), fill=(147, 51, 234, int(16 + pulse2 * 12)))
    
    # Grid
    for x in range(0, WIDTH, 60):
        draw.line((x, 0, x, HEIGHT), fill=(255, 255, 255, 4), width=1)
    for y in range(0, HEIGHT, 60):
        draw.line((0, y, WIDTH, y), fill=(255, 255, 255, 4), width=1)
        
    # Story progress bar top
    progress_w = int((t / DURATION) * WIDTH)
    draw.rectangle((0, 0, WIDTH, 8), fill=(25, 35, 55, 255))
    draw.rectangle((0, 0, progress_w, 8), fill=(0, 229, 255, 255))
    
    # Top Bar Header
    draw.rounded_rectangle((40, 30, 480, 85), radius=20, fill=(16, 24, 38, 220), outline=(40, 56, 85, 255), width=1)
    draw.ellipse((55, 42, 85, 72), fill=(0, 229, 255, 255))
    draw.text((70, 57), "A", fill=(8, 12, 20, 255), font=get_font(FONT_BOLD, 20), anchor="mm")
    draw.text((100, 45), "MY AUTO GUIDE", fill=(255, 255, 255, 255), font=get_font(FONT_BOLD, 18))
    draw.text((100, 65), "COLOMBIA • OFICIAL 2026", fill=(0, 229, 255, 255), font=get_font(FONT_BOLD, 11))
    
    draw.rounded_rectangle((WIDTH - 320, 30, WIDTH - 40, 85), radius=20, fill=(10, 24, 40, 220), outline=(0, 229, 255, 180), width=1)
    draw.text((WIDTH - 180, 57), "CAPTURAS REALES", fill=(0, 229, 255, 255), font=get_font(FONT_BOLD, 14), anchor="mm")
    
    glare = (t * 0.25) % 1.0
    phone_w, phone_h = 580, 1240
    px = WIDTH // 2
    py = 830
    
    # -------------------------------------------------------------
    # SCENE 1: GARAJE 360° (0.0s - 9.0s)
    # -------------------------------------------------------------
    if t < 9.0:
        scr = scr_home if t < 3.0 else scr_garage
        phone_im = create_phone_mockup_vertical(scr, width=phone_w, height=phone_h, glare_shift=glare)
        
        # Shadow & Phone
        draw.rounded_rectangle((px - phone_w//2 + 15, py - phone_h//2 + 25, px + phone_w//2 + 15, py + phone_h//2 + 25), radius=60, fill=(0, 0, 0, 120))
        im.paste(phone_im, (px - phone_w//2, py - phone_h//2), phone_im)
        
        # Upper Header
        draw.text((WIDTH // 2, 130), "GARAJE 360° & SALUD VEHICULAR", fill=(0, 229, 255, 255), font=get_font(FONT_BOLD, 28), anchor="mm")
        draw.text((WIDTH // 2, 175), "Tu Centro de Mando en Tiempo Real", fill=(255, 255, 255, 255), font=get_font(FONT_BOLD, 42), anchor="mm")
        
        # Floating Badges Over Phone
        draw.rounded_rectangle((60, 480, 340, 560), radius=18, fill=(14, 20, 34, 245), outline=(0, 229, 255, 200), width=2)
        draw.text((80, 505), "Índice de Salud ISH", fill=(140, 160, 190, 255), font=get_font(FONT_BOLD, 15))
        draw.text((80, 535), "92% ÓPTIMO", fill=(16, 185, 129, 255), font=get_font(FONT_BOLD, 22))
        
        draw.rounded_rectangle((WIDTH - 360, 1150, WIDTH - 60, 1230), radius=18, fill=(14, 20, 34, 245), outline=(0, 229, 255, 200), width=2)
        draw.text((WIDTH - 340, 1175), "Odómetro Acumulado", fill=(140, 160, 190, 255), font=get_font(FONT_BOLD, 15))
        draw.text((WIDTH - 340, 1205), "59.433 KM VIVO", fill=(0, 229, 255, 255), font=get_font(FONT_BOLD, 22))
        
        # Bottom Subtitle Pill
        draw.rounded_rectangle((40, 1520, WIDTH - 40, 1720), radius=26, fill=(16, 24, 40, 245), outline=(0, 229, 255, 180), width=2)
        draw.text((WIDTH // 2, 1580), "🎙️ Tu centro de mando con vista 360°,", fill=(255, 255, 255, 255), font=get_font(FONT_BOLD, 30), anchor="mm")
        draw.text((WIDTH // 2, 1630), "odómetro vivo e Índice de Salud vehicular.", fill=(0, 229, 255, 255), font=get_font(FONT_BOLD, 30), anchor="mm")
        
    # -------------------------------------------------------------
    # SCENE 2: NAVEGACIÓN GPS (9.0s - 17.0s)
    # -------------------------------------------------------------
    elif t < 17.0:
        rel_t = t - 9.0
        phone_im = create_phone_mockup_vertical(scr_gps, width=phone_w, height=phone_h, glare_shift=glare)
        
        draw.rounded_rectangle((px - phone_w//2 + 15, py - phone_h//2 + 25, px + phone_w//2 + 15, py + phone_h//2 + 25), radius=60, fill=(0, 0, 0, 120))
        im.paste(phone_im, (px - phone_w//2, py - phone_h//2), phone_im)
        
        draw.text((WIDTH // 2, 130), "TELEMETRÍA EN VIVO", fill=(16, 185, 129, 255), font=get_font(FONT_BOLD, 28), anchor="mm")
        draw.text((WIDTH // 2, 175), "Navegación GPS con HUD de Velocidad", fill=(255, 255, 255, 255), font=get_font(FONT_BOLD, 42), anchor="mm")
        
        # Floating Alert Badge
        draw.rounded_rectangle((60, 480, 440, 560), radius=18, fill=(35, 22, 10, 245), outline=(245, 158, 11, 240), width=2)
        draw.text((80, 505), "🔊 Alerta por Voz Activa", fill=(245, 158, 11, 255), font=get_font(FONT_BOLD, 17))
        draw.text((80, 535), "PROTECCIÓN ANTI-FOTOMULTAS", fill=(255, 255, 255, 255), font=get_font(FONT_BOLD, 20))
        
        draw.rounded_rectangle((WIDTH - 360, 1150, WIDTH - 60, 1230), radius=18, fill=(14, 20, 34, 245), outline=(16, 185, 129, 200), width=2)
        draw.text((WIDTH - 340, 1175), "Velocímetro Digital", fill=(140, 160, 190, 255), font=get_font(FONT_BOLD, 15))
        draw.text((WIDTH - 340, 1205), "76 KM/H • LÍMITE 80", fill=(16, 185, 129, 255), font=get_font(FONT_BOLD, 22))
        
        draw.rounded_rectangle((40, 1520, WIDTH - 40, 1720), radius=26, fill=(16, 24, 40, 245), outline=(16, 185, 129, 180), width=2)
        draw.text((WIDTH // 2, 1580), "🎙️ Navegación GPS con telemetría en vivo,", fill=(255, 255, 255, 255), font=get_font(FONT_BOLD, 30), anchor="mm")
        draw.text((WIDTH // 2, 1630), "velocímetro digital y alertas anti-fotomultas.", fill=(16, 185, 129, 255), font=get_font(FONT_BOLD, 30), anchor="mm")
        
    # -------------------------------------------------------------
    # SCENE 3: RUNT OFFLINE & QR TALLER (17.0s - 25.0s)
    # -------------------------------------------------------------
    elif t < 25.0:
        rel_t = t - 17.0
        scr = scr_maint1 if rel_t < 4.0 else scr_maint2
        phone_im = create_phone_mockup_vertical(scr, width=phone_w, height=phone_h, glare_shift=glare)
        
        draw.rounded_rectangle((px - phone_w//2 + 15, py - phone_h//2 + 25, px + phone_w//2 + 15, py + phone_h//2 + 25), radius=60, fill=(0, 0, 0, 120))
        im.paste(phone_im, (px - phone_w//2, py - phone_h//2), phone_im)
        
        draw.text((WIDTH // 2, 130), "MANTENIMIENTO PREVENTIVO", fill=(234, 179, 8, 255), font=get_font(FONT_BOLD, 28), anchor="mm")
        draw.text((WIDTH // 2, 175), "SOAT Offline & Certificación QR", fill=(255, 255, 255, 255), font=get_font(FONT_BOLD, 42), anchor="mm")
        
        draw.rounded_rectangle((60, 480, 420, 560), radius=18, fill=(16, 26, 42, 245), outline=(16, 185, 129, 200), width=2)
        draw.text((80, 505), "RUNT Oficial Colombia", fill=(140, 160, 190, 255), font=get_font(FONT_BOLD, 15))
        draw.text((80, 535), "🟢 100% DISPONIBLE OFFLINE", fill=(16, 185, 129, 255), font=get_font(FONT_BOLD, 20))
        
        draw.rounded_rectangle((WIDTH - 380, 1150, WIDTH - 60, 1230), radius=18, fill=(24, 20, 12, 245), outline=(234, 179, 8, 200), width=2)
        draw.text((WIDTH - 360, 1175), "Sello de Taller Certificado", fill=(234, 179, 8, 255), font=get_font(FONT_BOLD, 15))
        draw.text((WIDTH - 360, 1205), "🔐 CÓDIGO QR SHA-256", fill=(255, 255, 255, 255), font=get_font(FONT_BOLD, 20))
        
        draw.rounded_rectangle((40, 1520, WIDTH - 40, 1720), radius=26, fill=(16, 24, 40, 245), outline=(234, 179, 8, 180), width=2)
        draw.text((WIDTH // 2, 1580), "🎙️ Consulta oficial de SOAT sin internet", fill=(255, 255, 255, 255), font=get_font(FONT_BOLD, 30), anchor="mm")
        draw.text((WIDTH // 2, 1630), "y certificación digital con código QR de taller.", fill=(234, 179, 8, 255), font=get_font(FONT_BOLD, 30), anchor="mm")
        
    # -------------------------------------------------------------
    # SCENE 4: GASTOS & COPILOTO IA (25.0s - 33.0s)
    # -------------------------------------------------------------
    elif t < 33.0:
        rel_t = t - 25.0
        scr = scr_expenses if rel_t < 4.5 else scr_specs
        phone_im = create_phone_mockup_vertical(scr, width=phone_w, height=phone_h, glare_shift=glare)
        
        draw.rounded_rectangle((px - phone_w//2 + 15, py - phone_h//2 + 25, px + phone_w//2 + 15, py + phone_h//2 + 25), radius=60, fill=(0, 0, 0, 120))
        im.paste(phone_im, (px - phone_w//2, py - phone_h//2), phone_im)
        
        draw.text((WIDTH // 2, 130), "INTELIGENCIA ARTIFICIAL & GASTOS", fill=(216, 180, 254, 255), font=get_font(FONT_BOLD, 28), anchor="mm")
        draw.text((WIDTH // 2, 175), "Mecánico Gemini IA & Balance en CSV", fill=(255, 255, 255, 255), font=get_font(FONT_BOLD, 42), anchor="mm")
        
        draw.rounded_rectangle((60, 480, 420, 560), radius=18, fill=(24, 18, 42, 245), outline=(147, 51, 234, 200), width=2)
        draw.text((80, 505), "Copiloto Asistente", fill=(216, 180, 254, 255), font=get_font(FONT_BOLD, 15))
        draw.text((80, 535), "✨ GEMINI IA 24/7", fill=(255, 255, 255, 255), font=get_font(FONT_BOLD, 22))
        
        draw.rounded_rectangle((WIDTH - 360, 1150, WIDTH - 60, 1230), radius=18, fill=(16, 26, 36, 245), outline=(16, 185, 129, 200), width=2)
        draw.text((WIDTH - 340, 1175), "Exportación Contable", fill=(16, 185, 129, 255), font=get_font(FONT_BOLD, 15))
        draw.text((WIDTH - 340, 1205), "📥 DESCARGA EN CSV", fill=(255, 255, 255, 255), font=get_font(FONT_BOLD, 22))
        
        draw.rounded_rectangle((40, 1520, WIDTH - 40, 1720), radius=26, fill=(16, 24, 40, 245), outline=(147, 51, 234, 180), width=2)
        draw.text((WIDTH // 2, 1580), "🎙️ Asistente mecánico con Inteligencia Artificial", fill=(255, 255, 255, 255), font=get_font(FONT_BOLD, 30), anchor="mm")
        draw.text((WIDTH // 2, 1630), "y gestión de gastos con exportación a Excel.", fill=(216, 180, 254, 255), font=get_font(FONT_BOLD, 30), anchor="mm")
        
    # -------------------------------------------------------------
    # SCENE 5: OUTRO CINEMÁTICO (33.0s - 41.0s)
    # -------------------------------------------------------------
    else:
        # Grand vertical outro
        phone_w, phone_h = 480, 1020
        phone_im = create_phone_mockup_vertical(scr_garage, width=phone_w, height=phone_h, glare_shift=0.5)
        im.paste(phone_im, (WIDTH // 2 - phone_w // 2, 720), phone_im)
        
        if logo_im:
            l_scaled = logo_im.copy()
            l_scaled.thumbnail((260, 260))
            im.paste(l_scaled, (WIDTH // 2 - l_scaled.width // 2, 160), l_scaled)
            
        draw.text((WIDTH // 2, 450), "MY AUTO GUIDE", fill=(255, 255, 255, 255), font=get_font(FONT_BOLD, 64), anchor="mm")
        draw.text((WIDTH // 2, 520), "Tu copiloto. Tu mecánico.", fill=(0, 229, 255, 255), font=get_font(FONT_BOLD, 34), anchor="mm")
        draw.text((WIDTH // 2, 570), "Tu garaje inteligente.", fill=(0, 229, 255, 255), font=get_font(FONT_BOLD, 34), anchor="mm")
        
        # Download CTA Bottom
        draw.rounded_rectangle((60, 1640, WIDTH - 60, 1740), radius=26, fill=(255, 255, 255, 255))
        draw.text((WIDTH // 2, 1690), "📱 DESCARGA EN GOOGLE PLAY & APP STORE", fill=(10, 15, 25, 255), font=get_font(FONT_BOLD, 26), anchor="mm")
        
        draw.text((WIDTH // 2, 1800), "¡Disponible hoy para Android e iOS!", fill=(160, 175, 205, 255), font=get_font(FONT_BOLD, 24), anchor="mm")
        
    out_file = os.path.join(FRAMES_DIR, f"frame_{frame_idx:05d}.jpg")
    im.convert("RGB").save(out_file, "JPEG", quality=92)
    return frame_idx

def main():
    print("=" * 80)
    print("🎬 RENDERING 9:16 PRO REELS/SHORTS VIDEO WITH 100% REAL APP SCREENS")
    print("=" * 80)
    os.makedirs(FRAMES_DIR, exist_ok=True)
    
    start_time = time.time()
    num_workers = min(7, os.cpu_count() or 4)
    print(f"[*] Rendering {TOTAL_FRAMES} frames across {num_workers} parallel workers...")
    
    with Pool(num_workers) as pool:
        for i, _ in enumerate(pool.imap_unordered(render_frame_9x16, range(TOTAL_FRAMES), chunksize=15)):
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
        
    print(f"🎉 9:16 PRO REELS VIDEO SUCCESSFULLY GENERATED: {OUTPUT_VIDEO}")
    print("=" * 80)

if __name__ == "__main__":
    main()
