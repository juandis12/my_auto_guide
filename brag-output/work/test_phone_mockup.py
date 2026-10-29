#!/usr/bin/env python3
"""
Test script for phone mockup and sample frame generation.
"""

import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

WORK_DIR = r"d:\Proyectos\my_auto_guide\brag-output\work"
SCREENS_DIR = os.path.join(WORK_DIR, "clean_screens")

FONT_BOLD = "C:/Windows/Fonts/segoeuib.ttf"
FONT_REG = "C:/Windows/Fonts/segoeui.ttf"

def get_font(path, size):
    try:
        return ImageFont.truetype(path, size)
    except:
        return ImageFont.load_default()

def create_phone_mockup(screen_img, width=440, height=920, corner_radius=50, bezel=14, scroll_y_pct=0.0, glare_shift=0.0):
    sw = width - bezel * 2
    sh = height - bezel * 2
    
    # Scale screen image
    scale = max(sw / screen_img.width, sh / screen_img.height)
    tw = int(screen_img.width * scale)
    th = int(screen_img.height * scale)
    scaled = screen_img.resize((tw, th), Image.Resampling.LANCZOS)
    
    max_scroll = max(0, th - sh)
    crop_top = int(max_scroll * scroll_y_pct)
    crop_left = (tw - sw) // 2
    screen_crop = scaled.crop((crop_left, crop_top, crop_left + sw, crop_top + sh))
    
    # Screen rounded corner mask
    screen_mask = Image.new('L', (sw, sh), 0)
    draw_sm = ImageDraw.Draw(screen_mask)
    draw_sm.rounded_rectangle((0, 0, sw, sh), radius=corner_radius - bezel, fill=255)
    
    screen_crop.putalpha(screen_mask)
    
    # Outer device bezel
    device = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw_d = ImageDraw.Draw(device)
    
    # Outer titanium rim
    draw_d.rounded_rectangle((0, 0, width, height), radius=corner_radius, fill=(26, 32, 44, 255), outline=(75, 95, 125, 255), width=3)
    # Inner dark frame
    draw_d.rounded_rectangle((3, 3, width - 3, height - 3), radius=corner_radius - 2, fill=(10, 14, 22, 255), outline=(35, 45, 62, 255), width=2)
    
    # Paste actual app screen
    device.paste(screen_crop, (bezel, bezel), screen_crop)
    
    # Dynamic Island pill
    pill_w = 100
    pill_h = 26
    pill_x = (width - pill_w) // 2
    pill_y = bezel + 10
    draw_d.rounded_rectangle((pill_x, pill_y, pill_x + pill_w, pill_y + pill_h), radius=13, fill=(0, 0, 0, 255))
    draw_d.ellipse((pill_x + pill_w - 22, pill_y + 7, pill_x + pill_w - 10, pill_y + 19), fill=(16, 24, 40, 255))
    
    # Glass glare streak
    glare = Image.new('RGBA', (sw, sh), (0, 0, 0, 0))
    draw_g = ImageDraw.Draw(glare)
    glare_x = int((sw + 400) * glare_shift) - 200
    draw_g.polygon([
        (glare_x, 0),
        (glare_x + 90, 0),
        (glare_x - 120, sh),
        (glare_x - 210, sh)
    ], fill=(255, 255, 255, 18))
    device.paste(glare, (bezel, bezel), glare)
    
    # Subtle inner border on glass
    draw_d.rounded_rectangle((bezel, bezel, bezel + sw, bezel + sh), radius=corner_radius - bezel, outline=(255, 255, 255, 35), width=1)
    
    return device

if __name__ == "__main__":
    scr1 = Image.open(os.path.join(SCREENS_DIR, "screen1_garage.png")).convert('RGBA')
    phone = create_phone_mockup(scr1, width=440, height=920, scroll_y_pct=0.1, glare_shift=0.4)
    phone.save(os.path.join(WORK_DIR, "test_phone_clean.png"))
    print("Test phone mockup saved successfully!")
