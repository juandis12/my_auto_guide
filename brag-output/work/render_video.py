import os
import sys
import math
import subprocess
import time
from PIL import Image, ImageDraw, ImageFont, ImageFilter

WIDTH, HEIGHT = 1920, 1080
FPS = 30
DURATION = 22.0
TOTAL_FRAMES = int(FPS * DURATION)  # 660 frames

WORK_DIR = r"d:\Proyectos\my_auto_guide\brag-output\work"
FRAMES_DIR = os.path.join(WORK_DIR, "frames")
ASSETS_DIR = r"d:\Proyectos\my_auto_guide\brag-output\composition\assets"
SCREENS_DIR = os.path.join(ASSETS_DIR, "screens")
OUTPUT_VIDEO = r"d:\Proyectos\my_auto_guide\brag-output\brag.mp4"
OUTPUT_POSTER = r"d:\Proyectos\my_auto_guide\brag-output\brag.jpg"
AUDIO_PATH = os.path.join(ASSETS_DIR, "music", "track.mp3")

# Load fonts
FONT_BOLD_PATH = "C:/Windows/Fonts/segoeuib.ttf"
FONT_REG_PATH = "C:/Windows/Fonts/segoeui.ttf"

def get_font(path, size):
    try:
        return ImageFont.truetype(path, size)
    except:
        return ImageFont.load_default()

font_hero_title = get_font(FONT_BOLD_PATH, 54)
font_kicker = get_font(FONT_BOLD_PATH, 15)
font_desc = get_font(FONT_REG_PATH, 22)
font_pill = get_font(FONT_BOLD_PATH, 15)
font_badge_icon = get_font(FONT_BOLD_PATH, 14)
font_badge_title = get_font(FONT_BOLD_PATH, 17)
font_badge_sub = get_font(FONT_REG_PATH, 13)
font_outro_title = get_font(FONT_BOLD_PATH, 60)
font_outro_tagline = get_font(FONT_REG_PATH, 24)
font_btn = get_font(FONT_BOLD_PATH, 22)
font_nav_title = get_font(FONT_BOLD_PATH, 20)
font_nav_tag = get_font(FONT_BOLD_PATH, 12)

def draw_rounded_rect(draw, bbox, radius, fill=None, outline=None, width=1):
    draw.rounded_rectangle(bbox, radius=radius, fill=fill, outline=outline, width=width)

# Render a photorealistic smartphone mockup with titanium bezel,
# dynamic island, rounded display corners, glossy glass reflection, and drop shadow.
def create_phone_mockup(screen_path, width=420, height=890, corner_radius=48, bezel=12, scroll_y_pct=0.0):
    if not os.path.exists(screen_path):
        raise FileNotFoundError(f"Screenshot missing: {screen_path}")
    
    screen_orig = Image.open(screen_path).convert('RGB')
    sw = width - bezel * 2
    sh = height - bezel * 2
    
    scale = max(sw / screen_orig.width, sh / screen_orig.height)
    tw = int(screen_orig.width * scale)
    th = int(screen_orig.height * scale)
    scaled = screen_orig.resize((tw, th), Image.Resampling.LANCZOS)
    
    max_scroll = max(0, th - sh)
    crop_top = int(max_scroll * scroll_y_pct)
    crop_left = (tw - sw) // 2
    screen_crop = scaled.crop((crop_left, crop_top, crop_left + sw, crop_top + sh))
    
    # Mask for rounded screen corners
    screen_mask = Image.new('L', (sw, sh), 0)
    draw_sm = ImageDraw.Draw(screen_mask)
    draw_sm.rounded_rectangle((0, 0, sw, sh), radius=corner_radius - bezel, fill=255)
    
    screen_rgba = screen_crop.convert('RGBA')
    screen_rgba.putalpha(screen_mask)
    
    # Build device bezel
    bezel_im = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw_b = ImageDraw.Draw(bezel_im)
    
    # Outer titanium rim
    draw_b.rounded_rectangle((0, 0, width, height), radius=corner_radius, fill=(24, 28, 38, 255), outline=(85, 102, 125, 255), width=3)
    # Inner dark frame
    draw_b.rounded_rectangle((3, 3, width - 3, height - 3), radius=corner_radius - 2, fill=(10, 12, 18, 255), outline=(32, 40, 54, 255), width=2)
    
    # Paste actual app screen
    bezel_im.paste(screen_rgba, (bezel, bezel), screen_rgba)
    
    # Dynamic Island pill
    pill_w = 95
    pill_h = 24
    pill_x = (width - pill_w) // 2
    pill_y = bezel + 10
    draw_b.rounded_rectangle((pill_x, pill_y, pill_x + pill_w, pill_y + pill_h), radius=12, fill=(0, 0, 0, 255))
    draw_b.ellipse((pill_x + pill_w - 20, pill_y + 6, pill_x + pill_w - 8, pill_y + 18), fill=(20, 28, 45, 255))
    
    # Inner stroke around screen
    draw_b.rounded_rectangle((bezel, bezel, bezel + sw, bezel + sh), radius=corner_radius - bezel, outline=(255, 255, 255, 30), width=1)
    
    # Glass glare highlight streak
    glare = Image.new('RGBA', (sw, sh), (0, 0, 0, 0))
    draw_g = ImageDraw.Draw(glare)
    for i in range(100):
        alpha = int(14 * (1.0 - i / 100))
        draw_g.line([(0, i * 2), (i * 3, 0)], fill=(255, 255, 255, alpha), width=3)
    bezel_im.paste(glare, (bezel, bezel), glare)
    
    # Assemble with multi-layer drop shadow
    pad = 50
    total_w = width + pad * 2
    total_h = height + pad * 2
    canvas = Image.new('RGBA', (total_w, total_h), (0, 0, 0, 0))
    
    shadow_mask = Image.new('L', (width, height), 0)
    ImageDraw.Draw(shadow_mask).rounded_rectangle((0, 0, width, height), radius=corner_radius, fill=255)
    shadow = Image.new('RGBA', (width, height), (0, 0, 0, 220))
    shadow.putalpha(shadow_mask)
    
    s_wide = shadow.resize((width + 40, height + 40)).filter(ImageFilter.GaussianBlur(32))
    canvas.paste(s_wide, (pad - 20, pad - 5), s_wide)
    
    s_tight = shadow.resize((width + 16, height + 16)).filter(ImageFilter.GaussianBlur(14))
    canvas.paste(s_tight, (pad - 8, pad + 10), s_tight)
    
    canvas.paste(bezel_im, (pad, pad), bezel_im)
    return canvas

print("Pre-rendering real device mockups...")
t0 = time.time()
PHONE_CACHE = {
    'home': create_phone_mockup(os.path.join(SCREENS_DIR, "screen_01_home.jpg"), 420, 890),
    'dash_ia': create_phone_mockup(os.path.join(SCREENS_DIR, "screen_02_dashboard_ia.jpg"), 420, 890),
    'gps': create_phone_mockup(os.path.join(SCREENS_DIR, "screen_05_gps_nav.jpg"), 420, 890),
    'trips': create_phone_mockup(os.path.join(SCREENS_DIR, "screen_06_trips_ia.jpg"), 420, 890),
    'maint1': create_phone_mockup(os.path.join(SCREENS_DIR, "screen_07_maint_preventive.jpg"), 420, 890),
    'maint2': create_phone_mockup(os.path.join(SCREENS_DIR, "screen_08_maint_oil_soat.jpg"), 420, 890),
    'expenses': create_phone_mockup(os.path.join(SCREENS_DIR, "screen_10_expenses.jpg"), 420, 890),
    'docs': create_phone_mockup(os.path.join(SCREENS_DIR, "screen_09_docs_legal.jpg"), 420, 890),
    'safety': create_phone_mockup(os.path.join(SCREENS_DIR, "screen_11_road_safety_videos.jpg"), 420, 890),
    'specs': create_phone_mockup(os.path.join(SCREENS_DIR, "screen_13_manuals_specs.jpg"), 420, 890),
}
print(f"Pre-rendered 10 device screens in {time.time() - t0:.2f}s")

# Load logo
logo_path = os.path.join(ASSETS_DIR, "logo.png")
logo_im = Image.open(logo_path).convert('RGBA') if os.path.exists(logo_path) else None
if logo_im:
    logo_im.thumbnail((120, 120), Image.Resampling.LANCZOS)

def draw_header(draw, im):
    # Top brand bar
    draw_rounded_rect(draw, (80, 40, 390, 88), radius=24, fill=(15, 23, 42), outline=(255, 255, 255), width=1)
    if logo_im:
        small_logo = logo_im.resize((32, 32), Image.Resampling.LANCZOS)
        im.paste(small_logo, (96, 48), small_logo)
    draw.text((140, 52), "MY AUTO GUIDE", font=font_nav_title, fill=(255, 255, 255))
    
    # Live status badge
    draw_rounded_rect(draw, (1510, 40, 1840, 86), radius=23, fill=(8, 28, 48), outline=(56, 189, 248), width=1)
    draw.ellipse((1532, 58, 1542, 68), fill=(56, 189, 248))
    draw.text((1555, 54), "DEMOSTRACIÓN REAL EN VIVO", font=font_nav_tag, fill=(56, 189, 248))

def draw_floating_badge(im, x, y, symbol, title, subtitle=None, accent_color=(56, 189, 248)):
    w = 290
    h = 66 if subtitle else 48
    badge = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    db = ImageDraw.Draw(badge)
    
    # Glass card background
    draw_rounded_rect(db, (0, 0, w, h), radius=16, fill=(12, 18, 30, 240), outline=(accent_color[0], accent_color[1], accent_color[2], 180), width=1)
    # Symbol badge circle
    icon_box = (12, 11, 48, 55 if subtitle else 37)
    draw_rounded_rect(db, icon_box, radius=10, fill=(accent_color[0]//4, accent_color[1]//4, accent_color[2]//4, 255), outline=(accent_color[0], accent_color[1], accent_color[2], 140))
    db.text((19, 17 if subtitle else 14), symbol, font=font_badge_icon, fill=(accent_color[0], accent_color[1], accent_color[2]))
    
    db.text((58, 12 if subtitle else 14), title, font=font_badge_title, fill=(255, 255, 255))
    if subtitle:
        db.text((58, 36), subtitle, font=font_badge_sub, fill=(160, 174, 192))
    
    # Drop shadow
    pad = 14
    bw_total = w + pad * 2
    bh_total = h + pad * 2
    b_canvas = Image.new('RGBA', (bw_total, bh_total), (0, 0, 0, 0))
    s_mask = Image.new('L', (w, h), 0)
    ImageDraw.Draw(s_mask).rounded_rectangle((0, 0, w, h), radius=16, fill=255)
    s_badge = Image.new('RGBA', (w, h), (0, 0, 0, 180))
    s_badge.putalpha(s_mask)
    s_blur = s_badge.filter(ImageFilter.GaussianBlur(10))
    b_canvas.paste(s_blur, (pad, pad + 4), s_blur)
    b_canvas.paste(badge, (pad, pad), badge)
    
    im.paste(b_canvas, (x - pad, y - pad), b_canvas)

def render_frame(frame_idx):
    t = frame_idx / FPS
    im = Image.new('RGB', (WIDTH, HEIGHT), (6, 9, 16))
    draw = ImageDraw.Draw(im)

    # 1. Dynamic Ambient Background Glows
    if t < 4.5:
        draw.ellipse((-150, -100, 650, 700), fill=(0, 45, 95))
        draw.ellipse((1200, 350, 2050, 1150), fill=(15, 30, 75))
    elif t < 9.0:
        draw.ellipse((-100, 300, 650, 1050), fill=(5, 55, 40))
        draw.ellipse((1150, -50, 1950, 700), fill=(10, 50, 80))
    elif t < 13.5:
        draw.ellipse((-100, -100, 700, 700), fill=(60, 30, 10))
        draw.ellipse((1250, 300, 2050, 1100), fill=(10, 45, 65))
    elif t < 17.5:
        draw.ellipse((-100, 200, 650, 950), fill=(45, 15, 70))
        draw.ellipse((1150, 100, 1950, 900), fill=(10, 50, 45))
    else:
        draw.ellipse((500, 150, 1420, 950), fill=(15, 45, 95))

    # Tech grid texture
    for gx in range(0, WIDTH, 90):
        for gy in range(0, HEIGHT, 90):
            draw.point((gx, gy), fill=(255, 255, 255, 20))

    draw_header(draw, im)

    # ==================== SCENE 1 (0.0s - 4.5s): GARAJE & ESTADO ====================
    if t < 4.5:
        float_y = int(math.sin(t * 2.5) * 8)
        
        # Left Copy
        draw_rounded_rect(draw, (100, 200, 380, 236), radius=8, fill=(8, 30, 48), outline=(0, 229, 255), width=1)
        draw.text((115, 208), "01 // GARAJE INTELIGENTE", font=font_kicker, fill=(0, 229, 255))

        draw.text((100, 260), "¿Aún adivinas qué le pasa\na tu vehículo?", font=font_hero_title, fill=(255, 255, 255))
        draw.text((100, 400), "Olvida notas perdidas y alertas ignoradas.\nCentraliza el estado real, odómetro y salud técnica\nde tu moto o carro con visualización 360°.", font=font_desc, fill=(203, 213, 225))

        pills = [("•", "Pulsar, Yamaha & Honda"), ("•", "Mazda, Chevrolet & Más"), ("•", "Índice ISH en Vivo"), ("•", "Medallas & Logros")]
        px, py = 100, 530
        for bullet, txt in pills:
            w_txt = len(txt) * 10 + 50
            draw_rounded_rect(draw, (px, py, px + w_txt, py + 44), radius=14, fill=(15, 23, 38), outline=(45, 58, 78), width=1)
            draw.text((px + 14, py + 12), f"{bullet}  {txt}", font=font_pill, fill=(241, 245, 249))
            px += w_txt + 14
            if px > 780:
                px = 100
                py += 56

        # Secondary phone behind (Dashboard IA)
        p_sec = PHONE_CACHE['dash_ia']
        im.paste(p_sec, (1080, 170 + float_y), p_sec)

        # Hero phone (Garaje Principal)
        p_hero = PHONE_CACHE['home']
        im.paste(p_hero, (1260, 120 - float_y), p_hero)

        # Floating interactive badges
        draw_floating_badge(im, 1010, 290 - float_y, "NS", "Pulsar NS 200 FI", "59.433 KM Registrados", (56, 189, 248))
        draw_floating_badge(im, 1030, 520 + float_y, "!", "Alerta Preventiva SOAT", "26 días para renovación", (245, 158, 11))
        draw_floating_badge(im, 1270, 880 - float_y, "AI", "IA Experto Conectado", "Diagnóstico 100% activo", (147, 51, 234))

    # ==================== SCENE 2 (4.5s - 9.0s): NAVEGACIÓN GPS ====================
    elif t < 9.0:
        float_y = int(math.sin(t * 2.5) * 8)
        
        # Left Copy
        draw_rounded_rect(draw, (100, 200, 390, 236), radius=8, fill=(8, 36, 24), outline=(34, 197, 94), width=1)
        draw.text((115, 208), "02 // TELEMETRÍA & RUTAS", font=font_kicker, fill=(34, 197, 94))

        draw.text((100, 260), "Navegación GPS en vivo\ny control de recorridos", font=font_hero_title, fill=(255, 255, 255))
        draw.text((100, 400), "Mapas vectoriales nocturnos optimizados para conducción.\nMonitorea cada kilómetro, registra trayectos automáticamente\ny consulta métricas de consumo en tiempo real.", font=font_desc, fill=(203, 213, 225))

        pills = [("•", "Mapas Vectoriales Nocturnos"), ("•", "Cero Consumo Excesivo"), ("•", "Cursor Moto en Vivo"), ("•", "IA Insights Semanales")]
        px, py = 100, 530
        for bullet, txt in pills:
            w_txt = len(txt) * 10 + 50
            draw_rounded_rect(draw, (px, py, px + w_txt, py + 44), radius=14, fill=(15, 23, 38), outline=(45, 58, 78), width=1)
            draw.text((px + 14, py + 12), f"{bullet}  {txt}", font=font_pill, fill=(241, 245, 249))
            px += w_txt + 14
            if px > 780:
                px = 100
                py += 56

        # Secondary phone behind (Historial de Viajes)
        p_sec = PHONE_CACHE['trips']
        im.paste(p_sec, (1080, 170 + float_y), p_sec)

        # Hero phone (GPS Navigation Map)
        p_hero = PHONE_CACHE['gps']
        im.paste(p_hero, (1260, 120 - float_y), p_hero)

        # Floating badges
        draw_floating_badge(im, 1010, 280 - float_y, "GPS", "Rutas Vectoriales", "Girardot • Carrera 22", (34, 197, 94))
        draw_floating_badge(im, 1030, 530 + float_y, "LIVE", "Recorrido Libre", "Odómetro suma en vivo", (56, 189, 248))
        draw_floating_badge(im, 1270, 870 - float_y, "AI", "IA Insights: 100%", "Salud del Activo Excelente", (34, 197, 94))

    # ==================== SCENE 3 (9.0s - 13.5s): MANTENIMIENTO PREDICTIVO ====================
    elif t < 13.5:
        float_y = int(math.sin(t * 2.5) * 8)
        
        # Left Copy
        draw_rounded_rect(draw, (100, 200, 420, 236), radius=8, fill=(40, 24, 8), outline=(245, 158, 11), width=1)
        draw.text((115, 208), "03 // SALUD PREVENTIVA & TALLER", font=font_kicker, fill=(245, 158, 11))

        draw.text((100, 260), "Mantenimiento predictivo\nque ahorra millones", font=font_hero_title, fill=(255, 255, 255))
        draw.text((100, 400), "Semáforo visual de vida útil para cadena, aceite y filtros.\nCalcula desgastes exactos según tus hábitos reales\ny programa tus revisiones antes de que sea costoso.", font=font_desc, fill=(203, 213, 225))

        pills = [("•", "Lubricación de Cadena"), ("•", "Cambio Aceite Motor"), ("•", "Filtro de Aire"), ("•", "Alertas Proactivas")]
        px, py = 100, 530
        for bullet, txt in pills:
            w_txt = len(txt) * 10 + 50
            draw_rounded_rect(draw, (px, py, px + w_txt, py + 44), radius=14, fill=(15, 23, 38), outline=(45, 58, 78), width=1)
            draw.text((px + 14, py + 12), f"{bullet}  {txt}", font=font_pill, fill=(241, 245, 249))
            px += w_txt + 14
            if px > 780:
                px = 100
                py += 56

        # Secondary phone behind (Mantenimiento Aceite y SOAT)
        p_sec = PHONE_CACHE['maint2']
        im.paste(p_sec, (1080, 170 + float_y), p_sec)

        # Hero phone (Mantenimientos Mecánicos)
        p_hero = PHONE_CACHE['maint1']
        im.paste(p_hero, (1260, 120 - float_y), p_hero)

        # Floating badges
        draw_floating_badge(im, 1010, 290 - float_y, "46%", "Salud Preventiva 46%", "Odómetro: 59.433 km", (245, 158, 11))
        draw_floating_badge(im, 1030, 520 + float_y, "OIL", "Aceite de Motor (73%)", "Ciclo recomendado 90 días", (34, 197, 94))
        draw_floating_badge(im, 1270, 880 - float_y, "OK", "Guardar y Calcular", "Métricas actualizadas", (56, 189, 248))

    # ==================== SCENE 4 (13.5s - 17.5s): GASTOS & DOCUMENTOS ====================
    elif t < 17.5:
        float_y = int(math.sin(t * 2.5) * 8)
        
        # Left Copy
        draw_rounded_rect(draw, (100, 200, 420, 236), radius=8, fill=(30, 12, 44), outline=(168, 85, 247), width=1)
        draw.text((115, 208), "04 // GASTOS & DOCUMENTACIÓN", font=font_kicker, fill=(168, 85, 247))

        draw.text((100, 260), "Gestión de gastos real\ny trámites al alcance", font=font_hero_title, fill=(255, 255, 255))
        draw.text((100, 400), "Dona interactiva de gastos: combustible, repuestos y taller.\nEscanea tu SOAT y Tecnomecánica con un solo toque\ny genera tu Hoja de Vida Vehicular oficial en PDF.", font=font_desc, fill=(203, 213, 225))

        pills = [("•", "Gráficas de Gastos"), ("•", "Bitácora de Tanqueo"), ("•", "Exportar Hoja de Vida PDF"), ("•", "Escáner SOAT & RTM")]
        px, py = 100, 530
        for bullet, txt in pills:
            w_txt = len(txt) * 10 + 50
            draw_rounded_rect(draw, (px, py, px + w_txt, py + 44), radius=14, fill=(15, 23, 38), outline=(45, 58, 78), width=1)
            draw.text((px + 14, py + 12), f"{bullet}  {txt}", font=font_pill, fill=(241, 245, 249))
            px += w_txt + 14
            if px > 780:
                px = 100
                py += 56

        # Secondary phone behind (Trámites Legales SOAT / RTM)
        p_sec = PHONE_CACHE['docs']
        im.paste(p_sec, (1080, 170 + float_y), p_sec)

        # Hero phone (Gestión de Gastos Donut)
        p_hero = PHONE_CACHE['expenses']
        im.paste(p_hero, (1260, 120 - float_y), p_hero)

        # Floating badges
        draw_floating_badge(im, 1010, 290 - float_y, "$", "Gastos: $218.000 COP", "Combustible $85k • Otros $133k", (168, 85, 247))
        draw_floating_badge(im, 1030, 520 + float_y, "SCAN", "Escáner Inteligente", "SOAT & RTM integrados", (56, 189, 248))
        draw_floating_badge(im, 1270, 880 - float_y, "PDF", "Hoja de Vida PDF", "Exportación en 1 click", (34, 197, 94))

    # ==================== SCENE 5 (17.5s - 22.0s): ECOSISTEMA & CTA FINAL ====================
    else:
        float_y = int(math.sin(t * 2.5) * 8)

        # Triple phone presentation (Ecosistema total)
        # Left phone: Seguridad Vial & Protocolos
        p_left = PHONE_CACHE['safety']
        im.paste(p_left, (80, 160 + float_y), p_left)

        # Right phone: Manuales y Fichas Técnicas
        p_right = PHONE_CACHE['specs']
        im.paste(p_right, (1380, 160 + float_y), p_right)

        # Center hero phone: Home / Garaje
        p_center = PHONE_CACHE['home']
        im.paste(p_center, (730, 100 - float_y), p_center)

        # Central Outro Card & CTA Banner
        cta_y = 790
        draw_rounded_rect(draw, (440, cta_y, 1480, cta_y + 240), radius=32, fill=(10, 16, 28), outline=(56, 189, 248), width=2)
        
        draw.text((960, cta_y + 35), "MY AUTO GUIDE", font=font_hero_title, fill=(255, 255, 255), anchor="mm")
        draw.text((960, cta_y + 85), "El copiloto digital definitivo para tu moto o vehículo", font=font_desc, fill=(148, 163, 184), anchor="mm")
        
        # Download button
        btn_w, btn_h = 440, 58
        btn_x = (WIDTH - btn_w) // 2
        btn_y = cta_y + 125
        draw_rounded_rect(draw, (btn_x, btn_y, btn_x + btn_w, btn_y + btn_h), radius=29, fill=(0, 112, 243), outline=(56, 189, 248), width=2)
        draw.text((960, btn_y + btn_h // 2), "¡DESCARGA LA APP HOY!", font=font_btn, fill=(255, 255, 255), anchor="mm")

        # Feature pills at bottom
        tags_txt = "Impulsado por IA   •   GPS & Telemetría   •   Android & iOS   •   RUNT Integrado"
        draw.text((960, cta_y + 210), tags_txt, font=font_badge_sub, fill=(56, 189, 248), anchor="mm")

    return im

def main():
    os.makedirs(FRAMES_DIR, exist_ok=True)
    print(f"Rendering {TOTAL_FRAMES} frames ({DURATION}s @ {FPS} FPS)...")
    start_time = time.time()

    for idx in range(TOTAL_FRAMES):
        frame = render_frame(idx)
        frame_path = os.path.join(FRAMES_DIR, f"frame_{idx:05d}.jpg")
        frame.save(frame_path, "JPEG", quality=92)
        
        if idx % 60 == 0 or idx == TOTAL_FRAMES - 1:
            elapsed = time.time() - start_time
            fps_render = (idx + 1) / max(0.001, elapsed)
            print(f"  Frame {idx:04d}/{TOTAL_FRAMES} ({idx/TOTAL_FRAMES*100:.1f}%) - {fps_render:.1f} fps")

    # Save representative poster at 3.0s (Frame 90)
    poster_frame = render_frame(90)
    poster_frame.save(OUTPUT_POSTER, "JPEG", quality=95)
    print(f"Poster image saved to: {OUTPUT_POSTER}")

    # Compile with ffmpeg
    print("Compiling video with ffmpeg...")
    input_pattern = os.path.join(FRAMES_DIR, "frame_%05d.jpg")
    
    cmd = [
        "ffmpeg", "-y",
        "-framerate", str(FPS),
        "-i", input_pattern,
        "-i", AUDIO_PATH,
        "-c:v", "libx264",
        "-pix_fmt", "yuv420p",
        "-preset", "medium",
        "-crf", "18",
        "-c:a", "aac",
        "-b:a", "192k",
        "-shortest",
        OUTPUT_VIDEO
    ]
    
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0:
        print("FFmpeg error:", res.stderr)
        sys.exit(1)
        
    print(f"SUCCESS: Video rendered to {OUTPUT_VIDEO} ({os.path.getsize(OUTPUT_VIDEO)} bytes)")

if __name__ == "__main__":
    main()
