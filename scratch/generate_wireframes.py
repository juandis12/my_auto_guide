import os
import base64
import shutil

os.makedirs('wireframes_figma/assets', exist_ok=True)
shutil.copy('assets/logos/yamaha_logo.png', 'wireframes_figma/assets/')
shutil.copy('assets/motos/yamaha/mt15.png', 'wireframes_figma/assets/')
shutil.copy('assets/carros/mazda/mazda3.png', 'wireframes_figma/assets/')
shutil.copy('assets/logos/mazda_logo.png', 'wireframes_figma/assets/')
shutil.copy('assets/logos/bmw_logo.png', 'wireframes_figma/assets/')

def b64(path):
    with open(path, 'rb') as f:
        return 'data:image/png;base64,' + base64.b64encode(f.read()).decode('utf-8')

yamaha_logo_b64 = b64('assets/logos/yamaha_logo.png')
mt15_b64 = b64('assets/motos/yamaha/mt15.png')
mazda3_b64 = b64('assets/carros/mazda/mazda3.png')
mazda_logo_b64 = b64('assets/logos/mazda_logo.png')

# 1. 01_dashboard_garaje.svg
svg_01 = f'''<svg width="390" height="1200" viewBox="0 0 390 1200" fill="none" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
  <defs>
    <linearGradient id="mainHeroBg" x1="0" y1="0" x2="350" y2="190" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#003087" stop-opacity="0.3"/>
      <stop offset="100%" stop-color="#000000" stop-opacity="0.4"/>
    </linearGradient>

    <linearGradient id="brandBtnGrad" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0%" stop-color="#003087"/>
      <stop offset="100%" stop-color="#0056D2"/>
    </linearGradient>

    <linearGradient id="specialAiGrad" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0%" stop-color="#38BDF8"/>
      <stop offset="100%" stop-color="#9333EA"/>
    </linearGradient>

    <linearGradient id="ishGrad" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0%" stop-color="#0056D2"/>
      <stop offset="100%" stop-color="#38BDF8"/>
    </linearGradient>
  </defs>

  <!-- Scaffold Background (Apple Dynamic Midnight) -->
  <rect width="390" height="1200" rx="44" fill="#080C14"/>

  <!-- Subtle Brand Ambient Glows -->
  <circle cx="40" cy="40" r="160" fill="#003087" fill-opacity="0.2"/>
  <circle cx="360" cy="520" r="180" fill="#0056D2" fill-opacity="0.1"/>

  <!-- Status Bar (iOS) -->
  <text x="36" y="34" fill="#FFFFFF" font-family="'Outfit', -apple-system, sans-serif" font-size="14" font-weight="700">9:41</text>
  <path d="M328 24C328 22.8954 328.895 22 330 22H348C349.105 22 350 22.8954 350 24V32C350 33.1046 349.105 34 348 34H330C328.895 34 328 33.1046 328 32V24Z" stroke="#FFFFFF" stroke-opacity="0.6" stroke-width="2"/>
  <rect x="331" y="25" width="13" height="6" rx="1.5" fill="#38BDF8"/>

  <!-- AppBar: Title 'Inicio' + Native Action Icons -->
  <text x="195" y="78" text-anchor="middle" fill="#FFFFFF" font-family="'Outfit', -apple-system, sans-serif" font-size="18" font-weight="700">Inicio</text>
  
  <!-- Action Icons (Share, Garaje, Logout) -->
  <g transform="translate(254, 62)">
    <circle cx="12" cy="12" r="16" fill="rgba(255,255,255,0.06)"/>
    <path d="M8 12L16 8M8 12L16 16M8 12H16" stroke="#FFFFFF" stroke-width="1.8" stroke-linecap="round"/>
    <circle cx="8" cy="12" r="2" fill="#FFFFFF"/>
    <circle cx="16" cy="8" r="2" fill="#FFFFFF"/>
    <circle cx="16" cy="16" r="2" fill="#FFFFFF"/>
  </g>

  <!-- Garage Icon -->
  <g transform="translate(294, 62)">
    <circle cx="12" cy="12" r="16" fill="rgba(255,255,255,0.06)"/>
    <text x="5" y="17" font-size="14">🚗</text>
  </g>

  <!-- Logout Icon -->
  <g transform="translate(334, 62)">
    <circle cx="12" cy="12" r="16" fill="rgba(239,68,68,0.15)"/>
    <path d="M9 7H15C16 7 17 8 17 9V15C17 16 16 17 15 17H9M5 12H13M9 9L12 12L9 15" stroke="#EF4444" stroke-width="1.8" stroke-linecap="round"/>
  </g>

  <!-- ==================== 1. _MAINHERO CARD WITH REAL ASSETS ==================== -->
  <rect x="20" y="104" width="350" height="194" rx="24" fill="url(#mainHeroBg)" stroke="rgba(56,189,248,0.2)" stroke-width="1.2"/>
  
  <!-- Left Side of Hero (Flex 3) -->
  <!-- Real Brand Logo Box -->
  <rect x="36" y="120" width="64" height="34" rx="10" fill="#FFFFFF"/>
  <image href="{yamaha_logo_b64}" x="42" y="123" width="52" height="28" preserveAspectRatio="xMidYMid meet"/>

  <!-- Model Name & KMs -->
  <text x="36" y="178" fill="#FFFFFF" font-family="'Outfit', -apple-system, sans-serif" font-size="22" font-weight="800" letter-spacing="-0.5">MT-15</text>
  <text x="36" y="200" fill="rgba(255,255,255,0.75)" font-family="'Outfit', -apple-system, sans-serif" font-size="15" font-weight="600">24.500 KM</text>

  <!-- _HealthBar (ISH 92%) -->
  <text x="36" y="220" fill="#94A3B8" font-family="'Outfit', -apple-system, sans-serif" font-size="10" font-weight="800">ISH</text>
  <text x="156" y="220" text-anchor="end" fill="#FFFFFF" font-family="'Outfit', -apple-system, sans-serif" font-size="10" font-weight="800">92%</text>
  
  <rect x="36" y="226" width="120" height="6" rx="3" fill="rgba(0,0,0,0.5)"/>
  <rect x="36" y="226" width="110" height="6" rx="3" fill="url(#ishGrad)"/>

  <text x="36" y="252" fill="#38BDF8" font-family="'Outfit', -apple-system, sans-serif" font-size="11" font-weight="700">En Óptimas Condiciones</text>

  <!-- Right Side of Hero (Flex 4: Real Motorcycle Image + 360 Camera Button) -->
  <image href="{mt15_b64}" x="180" y="116" width="180" height="150" preserveAspectRatio="xMidYMid meet"/>

  <!-- 360 Camera Button (LiquidGlassIconButton) -->
  <circle cx="344" cy="132" r="16" fill="rgba(0,0,0,0.6)" stroke="rgba(255,255,255,0.3)" stroke-width="1"/>
  <text x="337" y="137" font-size="13">📷</text>

  <!-- 360 Rotation Badge -->
  <rect x="296" y="256" width="62" height="22" rx="11" fill="rgba(0,0,0,0.7)" stroke="rgba(255,255,255,0.2)" stroke-width="1"/>
  <text x="327" y="271" text-anchor="middle" fill="#FFFFFF" font-family="'Outfit', sans-serif" font-size="10" font-weight="800">🔄 360°</text>

  <!-- ==================== 2. HORIZONTAL INDICATOR CAROUSEL ==================== -->
  <g id="indicator_carousel">
    <!-- Tile 1: Cadena -->
    <rect x="20" y="316" width="76" height="106" rx="20" fill="rgba(255,255,255,0.05)" stroke="rgba(255,255,255,0.1)" stroke-width="1"/>
    <text x="58" y="338" text-anchor="middle" fill="rgba(255,255,255,0.7)" font-family="'Outfit', sans-serif" font-size="11" font-weight="600">Cadena</text>
    <circle cx="58" cy="376" r="20" fill="none" stroke="rgba(255,255,255,0.1)" stroke-width="5"/>
    <circle cx="58" cy="376" r="20" fill="none" stroke="#22C55E" stroke-width="5" stroke-dasharray="125" stroke-dashoffset="10" stroke-linecap="round"/>
    <text x="58" y="380" text-anchor="middle" fill="#FFFFFF" font-family="'Outfit', sans-serif" font-size="11" font-weight="800">95%</text>

    <!-- Tile 2: Filtro -->
    <rect x="104" y="316" width="76" height="106" rx="20" fill="rgba(255,255,255,0.05)" stroke="rgba(255,255,255,0.1)" stroke-width="1"/>
    <text x="142" y="338" text-anchor="middle" fill="rgba(255,255,255,0.7)" font-family="'Outfit', sans-serif" font-size="11" font-weight="600">Filtro</text>
    <circle cx="142" cy="376" r="20" fill="none" stroke="rgba(255,255,255,0.1)" stroke-width="5"/>
    <circle cx="142" cy="376" r="20" fill="none" stroke="#38BDF8" stroke-width="5" stroke-dasharray="125" stroke-dashoffset="25" stroke-linecap="round"/>
    <text x="142" y="380" text-anchor="middle" fill="#FFFFFF" font-family="'Outfit', sans-serif" font-size="11" font-weight="800">80%</text>

    <!-- Tile 3: Aceite -->
    <rect x="188" y="316" width="76" height="106" rx="20" fill="rgba(255,255,255,0.05)" stroke="rgba(255,255,255,0.1)" stroke-width="1"/>
    <text x="226" y="338" text-anchor="middle" fill="rgba(255,255,255,0.7)" font-family="'Outfit', sans-serif" font-size="11" font-weight="600">Aceite</text>
    <circle cx="226" cy="376" r="20" fill="none" stroke="rgba(255,255,255,0.1)" stroke-width="5"/>
    <circle cx="226" cy="376" r="20" fill="none" stroke="#F59E0B" stroke-width="5" stroke-dasharray="125" stroke-dashoffset="35" stroke-linecap="round"/>
    <text x="226" y="380" text-anchor="middle" fill="#FFFFFF" font-family="'Outfit', sans-serif" font-size="11" font-weight="800">70%</text>

    <!-- Tile 4: SIMIT -->
    <rect x="272" y="316" width="98" height="106" rx="20" fill="rgba(255,255,255,0.05)" stroke="rgba(255,255,255,0.1)" stroke-width="1"/>
    <text x="321" y="338" text-anchor="middle" fill="rgba(255,255,255,0.7)" font-family="'Outfit', sans-serif" font-size="11" font-weight="600">SIMIT</text>
    <circle cx="321" cy="376" r="20" fill="none" stroke="rgba(255,255,255,0.1)" stroke-width="5"/>
    <circle cx="321" cy="376" r="20" fill="none" stroke="#22C55E" stroke-width="5"/>
    <text x="313" y="382" font-size="16">⚖️</text>
  </g>

  <!-- ==================== 3. DOCUMENTOS LEGALES (2x2 GRID) ==================== -->
  <text x="24" y="452" fill="rgba(255,255,255,0.54)" font-family="'Outfit', sans-serif" font-size="12" font-weight="900" letter-spacing="1.2">DOCUMENTOS LEGALES</text>

  <!-- DocTile 1: SOAT (Vigente) -->
  <rect x="20" y="466" width="168" height="104" rx="24" fill="rgba(255,255,255,0.05)" stroke="rgba(34,197,94,0.3)" stroke-width="2"/>
  <circle cx="104" cy="498" r="18" fill="rgba(34,197,94,0.1)"/>
  <path d="M96 498L102 504L112 492" stroke="#22C55E" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
  <text x="104" y="532" text-anchor="middle" fill="rgba(255,255,255,0.9)" font-family="'Outfit', sans-serif" font-size="13" font-weight="700">SOAT</text>
  <text x="104" y="548" text-anchor="middle" fill="#22C55E" font-family="'Outfit', sans-serif" font-size="10" font-weight="900">VER DOCUMENTO</text>

  <!-- DocTile 2: Tecnomecánica (Vigente) -->
  <rect x="202" y="466" width="168" height="104" rx="24" fill="rgba(255,255,255,0.05)" stroke="rgba(34,197,94,0.3)" stroke-width="2"/>
  <circle cx="286" cy="498" r="18" fill="rgba(34,197,94,0.1)"/>
  <path d="M278 498L284 504L294 492" stroke="#22C55E" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
  <text x="286" y="532" text-anchor="middle" fill="rgba(255,255,255,0.9)" font-family="'Outfit', sans-serif" font-size="13" font-weight="700">Tecno mechanical</text>
  <text x="286" y="548" text-anchor="middle" fill="#22C55E" font-family="'Outfit', sans-serif" font-size="10" font-weight="900">VER DOCUMENTO</text>

  <!-- DocTile 3: Seguro Todo Riesgo -->
  <rect x="20" y="582" width="168" height="104" rx="24" fill="rgba(255,255,255,0.05)" stroke="rgba(255,255,255,0.1)" stroke-width="2"/>
  <circle cx="104" cy="614" r="18" fill="rgba(255,255,255,0.1)"/>
  <text x="96" y="621" font-size="16">🛡️</text>
  <text x="104" y="648" text-anchor="middle" fill="rgba(255,255,255,0.9)" font-family="'Outfit', sans-serif" font-size="13" font-weight="700">Seguro Todo Riesgo</text>
  <text x="104" y="664" text-anchor="middle" fill="#38BDF8" font-family="'Outfit', sans-serif" font-size="10" font-weight="900">SUBIR ARCHIVO</text>

  <!-- DocTile 4: Tarjeta de Propiedad -->
  <rect x="202" y="582" width="168" height="104" rx="24" fill="rgba(255,255,255,0.05)" stroke="rgba(255,255,255,0.1)" stroke-width="2"/>
  <circle cx="286" cy="614" r="18" fill="rgba(255,255,255,0.1)"/>
  <text x="278" y="621" font-size="16">📄</text>
  <text x="286" y="648" text-anchor="middle" fill="rgba(255,255,255,0.9)" font-family="'Outfit', sans-serif" font-size="13" font-weight="700">Tarjeta Propiedad</text>
  <text x="286" y="664" text-anchor="middle" fill="#38BDF8" font-family="'Outfit', sans-serif" font-size="10" font-weight="900">SUBIR ARCHIVO</text>

  <!-- ==================== 4. HERRAMIENTAS Y SERVICIOS (GRADIENTBUTTONS) ==================== -->
  <text x="24" y="718" fill="rgba(255,255,255,0.54)" font-family="'Outfit', sans-serif" font-size="12" font-weight="900" letter-spacing="1.2">HERRAMIENTAS Y SERVICIOS</text>

  <!-- Button 1: Navegación GPS -->
  <rect x="20" y="732" width="350" height="58" rx="20" fill="url(#brandBtnGrad)"/>
  <rect x="32" y="741" width="40" height="40" rx="12" fill="rgba(255,255,255,0.2)"/>
  <text x="43" y="766" font-size="18">🗺️</text>
  <text x="84" y="767" fill="#FFFFFF" font-family="'Outfit', sans-serif" font-size="15" font-weight="700">Navegación GPS</text>
  <text x="346" y="767" fill="rgba(255,255,255,0.7)" font-size="16">›</text>

  <!-- Button 2: Guía y Manuales -->
  <rect x="20" y="800" width="350" height="58" rx="20" fill="url(#brandBtnGrad)"/>
  <rect x="32" y="809" width="40" height="40" rx="12" fill="rgba(255,255,255,0.2)"/>
  <text x="43" y="834" font-size="18">📖</text>
  <text x="84" y="835" fill="#FFFFFF" font-family="'Outfit', sans-serif" font-size="15" font-weight="700">Guía y Manuales</text>
  <text x="346" y="835" fill="rgba(255,255,255,0.7)" font-size="16">›</text>

  <!-- Button 3: Gestión de Gastos -->
  <rect x="20" y="868" width="350" height="58" rx="20" fill="url(#brandBtnGrad)"/>
  <rect x="32" y="877" width="40" height="40" rx="12" fill="rgba(255,255,255,0.2)"/>
  <text x="43" y="902" font-size="18">💳</text>
  <text x="84" y="903" fill="#FFFFFF" font-family="'Outfit', sans-serif" font-size="15" font-weight="700">Gestión de Gastos</text>
  <text x="346" y="903" fill="rgba(255,255,255,0.7)" font-size="16">›</text>

  <!-- Button 4: Bitácora de Tanqueo -->
  <rect x="20" y="936" width="350" height="58" rx="20" fill="url(#brandBtnGrad)"/>
  <rect x="32" y="945" width="40" height="40" rx="12" fill="rgba(255,255,255,0.2)"/>
  <text x="43" y="970" font-size="18">⛽</text>
  <text x="84" y="971" fill="#FFFFFF" font-family="'Outfit', sans-serif" font-size="15" font-weight="700">Bitácora de Tanqueo</text>
  <text x="346" y="971" fill="rgba(255,255,255,0.7)" font-size="16">›</text>

  <!-- Button 5: Marketplace de Talleres -->
  <rect x="20" y="1004" width="350" height="58" rx="20" fill="url(#brandBtnGrad)"/>
  <rect x="32" y="1013" width="40" height="40" rx="12" fill="rgba(255,255,255,0.2)"/>
  <text x="43" y="1038" font-size="18">🏬</text>
  <text x="84" y="1039" fill="#FFFFFF" font-family="'Outfit', sans-serif" font-size="15" font-weight="700">Marketplace de Talleres</text>
  <text x="346" y="1039" fill="rgba(255,255,255,0.7)" font-size="16">›</text>

  <!-- Button 6: Consultar al Experto IA (Special Glowing Gradient) -->
  <rect x="20" y="1072" width="350" height="58" rx="20" fill="url(#specialAiGrad)"/>
  <rect x="32" y="1081" width="40" height="40" rx="12" fill="rgba(255,255,255,0.2)"/>
  <text x="43" y="1106" font-size="18">✨</text>
  <text x="84" y="1107" fill="#FFFFFF" font-family="'Outfit', sans-serif" font-size="15" font-weight="800">Consultar al Experto IA</text>
  <text x="346" y="1107" fill="rgba(255,255,255,0.9)" font-size="16">›</text>

  <!-- Bottom Home Indicator -->
  <rect x="130" y="1170" width="130" height="4" rx="2" fill="#475569"/>
</svg>'''

with open('wireframes_figma/01_dashboard_garaje.svg', 'w', encoding='utf-8') as f:
    f.write(svg_01)

# Also create an alternative car version: 01_dashboard_carro.svg
svg_01_car = svg_01.replace('YAMAHA', 'MAZDA').replace('MT-15', 'Mazda 3').replace(yamaha_logo_b64, mazda_logo_b64).replace(mt15_b64, mazda3_b64).replace('Cadena', 'Pastillas')

with open('wireframes_figma/01_dashboard_carro.svg', 'w', encoding='utf-8') as f:
    f.write(svg_01_car)

print("Generated 01_dashboard_garaje.svg and 01_dashboard_carro.svg with real project assets!")
