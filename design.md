# MY AUTO GUIDE — Design System & UI Architecture Specification (Reverse Engineering)

> **Document Version:** 1.0.0  
> **Target Platform:** Google Stitch (Model Context Protocol)  
> **Source Codebase:** `my_auto_guide` (Flutter Clean Architecture)  
> **Aesthetic Paradigm:** Apple HIG + Dynamic Midnight Glassmorphism (High-End Automotive)

---

## 1. Design Tokens & Color Palette

### 1.1 Core Brand Colors (Dynamic Midnight)
- **Scaffold Background (`midnightBackground`):** `#080C14` (Deep obsidian black with subtle radial gradient)
- **Card & Sheet Surface (`midnightSurface`):** `#0F172A` (Slate dark 900)
- **Elevated Surfaces (`midnightSurfaceElevated`):** `#1E293B` (Slate dark 800)
- **Primary Brand Accent (`electricBlue`):** `#2563EB` (Vibrant cobalt blue)
- **Secondary Accent Glow (`electricBlueLight`):** `#3B82F6` (Electric sky blue)
- **Telemetry & Cyber Accent (`electricCyan`):** `#38BDF8` (Cyan neon for GPS/telemetry indicators)
- **Success / Eco Accent (`accentGreen`):** `#22C55E` (Vibrant emerald green)
- **Warning / Alert Accent (`accentAmber`):** `#F59E0B` (Amber gold for speed traps & maintenance alerts)
- **Danger / Critical Accent (`accentRed`):** `#EF4444` (Racing crimson for mechanical alerts / SOS)

### 1.2 Glassmorphism & Materials
- **Dark Glass Fill:** `rgba(15, 23, 42, 0.75)`
- **Light Glass Fill:** `rgba(255, 255, 255, 0.85)`
- **Glass Border Stroke:** `1.2px solid rgba(56, 189, 248, 0.18)`
- **Backdrop Blur:** `20px` (`sigma: 20.0`)
- **Corner Radius:**
  - Standard Cards: `20px` (`BorderRadius.circular(20)`)
  - Modals & Sheets: `24px` (`BorderRadius.circular(24)`)
  - Badges / Action Chips: `999px` (Full Pill)

### 1.3 OEM Vehicle Manufacturer Theme Accents
- **Yamaha:** `#003087` / `#0056D2`
- **Suzuki:** `#CF122D` / `#EC1C24`
- **BMW:** `#0066B2` / `#009CDE`
- **Kawasaki:** `#66FF00` / `#4CBB17`
- **Honda:** `#E4002B` / `#B00020`
- **Ducati:** `#CC0000` / `#8B0000`
- **KTM:** `#FF6600` / `#E65C00`
- **Bajaj:** `#0055A5` / `#003D7A`

### 1.4 Typography (`Outfit` Font Family)
- **Display 1 (Speedometer / Big Gauges):** `48px` | Weight: 900 ExtraBold | Tracking: -1px
- **Title 1 (Screen Headers):** `26px` | Weight: 800 Bold | Gradient Fill: `#FFFFFF` -> `#94A3B8`
- **Title 2 (Card Section Titles):** `18px` | Weight: 700 SemiBold
- **Body Regular:** `14px` | Weight: 400 Regular | Color: `#F8FAFC` (92% opacity)
- **Caption / Meta:** `12px` | Weight: 600 SemiBold | Color: `#94A3B8`

---

## 2. Supported Screen Formats & Form Factors

1. **Mobile Vertical (Primary - Android & iOS):**
   - Resolution: `390 x 844 px` / `412 x 915 px`
   - Safe Area: Dynamic Island / Status Bar top (44px), Navigation Bar bottom (34px)
2. **Tablet & Dashboard Car View (Landscape - CarPlay & Android Auto):**
   - Resolution: `1024 x 600 px` & `1280 x 800 px`
   - Split-screen HUD: Left map navigation / Right telemetry & vehicle health widgets

---

## 3. Reverse-Engineered Screen Specifications

### Screen 01: Onboarding & Auth (`features/auth`)
- **Visual Structure:**
  - Dark obsidian background with animated cyber road lines (`assets/lineasfondo.png`).
  - Central dynamic 3D vehicle avatar / logo.
  - Social Auth Buttons (Apple HIG Glass, Google, Facebook).
  - Biometric Face ID / Fingerprint prompt with glowing cyan ring.

### Screen 02: Garaje & Vehicle Health Dashboard (`features/vehicles/presentation/inicio_app.dart`)
- **Visual Structure:**
  - Vehicle Selector Carousel (Switch between Carro / Moto).
  - Main Hero Card: Rendered vehicle with dynamic manufacturer theme gradient.
  - Odómetro Digital HUD (Kilometraje actual + barras de desgaste de aceite y llantas).
  - Status Grid: SOAT, Tecnomecánica, Batería, Próximo Mantenimiento (Badges Verde/Ámbar/Rojo).
  - Quick Actions: "Registrar Tanqueo", "Escanear Falla", "Ver Manual".

### Screen 03: Telemetría & Navegación en Vivo (`features/navigation/rutas_screen.dart`)
- **Visual Structure:**
  - Full-screen Dark Vector Map (Night mode style).
  - Floating Top Bar: Próxima maniobra (flecha curva, distancia restante, tiempo estimado).
  - Floating Live HUD: Velocidad actual en tiempo real vs. Límite de velocidad permitido.
  - Community Incident Layer: Pines de cámaras de fotomulta, retenes policiales, accidentes y zonas de tráfico.
  - Floating Bottom Action: Botón flotante para reportar incidentes con un toque (Quick Report Radial Menu).

### Screen 04: Diagnóstico Mecánico Asistido por IA (`features/ai_bot`)
- **Visual Structure:**
  - Interactive Mechanic AI Chat with animated waveform / glowing orb avatar.
  - Diagnostic Scanner OBD-II simulation (Códigos de error DTC: ej. P0300, P0420 explicados en lenguaje humano).
  - Severity Chips: "Urgente", "Preventivo", "Informativo".
  - One-tap CTA: "Buscar repuesto en Marketplace" o "Agendar taller cercano".

### Screen 05: Marketplace Automotriz & Talleres (`features/marketplace`)
- **Visual Structure:**
  - Search Bar con filtro por marca y modelo de vehículo activo.
  - Category Pills: Repuestos, Llantas, Lubricantes, Talleres Especializados, Grúas SOS.
  - Product / Service Cards: Imagen de producto, calificación por estrellas, precio en COP/USD, botón "Comprar / Cotizar".
  - Talleres Cercanos con distancia en km y badge de "Verificado".

### Screen 06: Bitácora de Gastos & Analítica de Combustible (`features/expenses`)
- **Visual Structure:**
  - Resumen mensual de gastos con gráfico circular (Combustible vs. Mantenimiento vs. Papeles).
  - Métrica clave: Rendimiento de combustible (`km / galón` o `L / 100km`).
  - Lista de transacciones recientes con iconos temáticos y botón flotante "+ Nuevo Gasto".

### Screen 07: Manuales de Taller & Guías Paso a Paso (`features/manuals`, `features/guides`)
- **Visual Structure:**
  - Buscador de manuales PDF indexados por marca y cilindraje.
  - Visualizador de guías paso a paso (ej. Cambio de pastillas de freno, revisión de fusibles) con checklist interactivo.

### Screen 08: Centro de Actualizaciones & Ajustes (`features/updater`, `core`)
- **Visual Structure:**
  - App Update Lock Screen con changelog animado y barra de descarga.
  - Panel de Ajustes: Gestión de permisos GPS en segundo plano, sincronización offline Supabase, selección de tema.
