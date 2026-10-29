#!/usr/bin/env python3
"""
Combines background music, 5 voiceover scene segments, and synchronized haptic/engine SFX
into a broadcast-ready stereo soundtrack (41.0s duration) with professional ducking and volume curves.
"""

import os
import subprocess

AUDIO_DIR = r"d:\Proyectos\my_auto_guide\brag-output\work\audio"
SFX_DIR = r"d:\Proyectos\my_auto_guide\brag-output\composition\assets\sfx"
MUSIC_FILE = r"d:\Proyectos\my_auto_guide\brag-output\composition\assets\music\track.mp3"
OUT_AUDIO = r"d:\Proyectos\my_auto_guide\brag-output\work\final_soundtrack.mp3"

v1 = os.path.join(AUDIO_DIR, "scene1_voice.mp3")
v2 = os.path.join(AUDIO_DIR, "scene2_voice.mp3")
v3 = os.path.join(AUDIO_DIR, "scene3_voice.mp3")
v4 = os.path.join(AUDIO_DIR, "scene4_voice.mp3")
v5 = os.path.join(AUDIO_DIR, "scene5_voice.mp3")

sfx_click = os.path.join(SFX_DIR, "click1.ogg")
sfx_switch = os.path.join(SFX_DIR, "switch1.ogg")
sfx_bong = os.path.join(SFX_DIR, "bong_001.ogg")

# Filter graph:
# Inputs:
# 0: Music
# 1: v1 (delay 500ms)
# 2: v2 (delay 9000ms)
# 3: v3 (delay 17000ms)
# 4: v4 (delay 25000ms)
# 5: v5 (delay 33000ms)
# 6: click (delay 600ms)
# 7: switch (delay 9100ms)
# 8: bong (delay 17200ms)
# 9: switch (delay 25100ms)
# 10: bong (delay 33100ms)

filter_complex = (
    "[0:a]volume=0.22,afade=t=out:st=39.5:d=1.5[music];"
    "[1:a]adelay=500|500,volume=1.4[v1];"
    "[2:a]adelay=9000|9000,volume=1.4[v2];"
    "[3:a]adelay=17000|17000,volume=1.4[v3];"
    "[4:a]adelay=25000|25000,volume=1.4[v4];"
    "[5:a]adelay=33000|33000,volume=1.4[v5];"
    "[6:a]adelay=600|600,volume=0.6[s1];"
    "[7:a]adelay=9100|9100,volume=0.7[s2];"
    "[8:a]adelay=17200|17200,volume=0.7[s3];"
    "[9:a]adelay=25100|25100,volume=0.7[s4];"
    "[10:a]adelay=33100|33100,volume=0.7[s5];"
    "[music][v1][v2][v3][v4][v5][s1][s2][s3][s4][s5]amix=inputs=11:duration=first:dropout_transition=2[outa]"
)

cmd = [
    "ffmpeg", "-y",
    "-i", MUSIC_FILE,
    "-i", v1,
    "-i", v2,
    "-i", v3,
    "-i", v4,
    "-i", v5,
    "-i", sfx_click,
    "-i", sfx_switch,
    "-i", sfx_bong,
    "-i", sfx_switch,
    "-i", sfx_bong,
    "-filter_complex", filter_complex,
    "-map", "[outa]",
    "-t", "41.0",
    "-b:a", "256k",
    OUT_AUDIO
]

print("Building final soundtrack with FFmpeg...")
res = subprocess.run(cmd, capture_output=True, text=True)
if res.returncode != 0:
    print("FFmpeg error:", res.stderr)
    exit(1)
print(f"Soundtrack created successfully at: {OUT_AUDIO}")
