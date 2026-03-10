# 🚗 My Auto Guide

**My Auto Guide** es una aplicación móvil desarrollada en **Flutter** diseñada para la gestión integral de vehículos (carros y motos). Permite a los usuarios llevar un registro detallado de sus vehículos, gestionar mantenimientos, consultar manuales, de recibir recordatorios importantes y acceder a plataformas externas como el RUNT de manera directa.

## ✨ Características Principales

- 🔐 **Autenticación Segura**: Sistema de inicio de sesión y registro impulsado por **Supabase**.
- 🚙 **Gestión de Vehículos**: Agregar, visualizar y organizar información de carros y motocicletas.
- ⚙️ **Control de Mantenimientos**: Parametrización, control y registro de próximos mantenimientos.
- 🔔 **Notificaciones y Recordatorios**: Alertas programadas para evitar el olvido del vencimiento de documentos y mantenimientos usando `flutter_local_notifications`.
- 📖 **Guías y Manuales**: Visualizador integrado de documentos PDF (`syncfusion_flutter_pdfviewer`) y reproducción de videos tutoriales (`youtube_player_iframe`).
- 🌐 **Consulta Externa**: Integración mediante vistas web (`webview_flutter`) para consultar multas e información oficial en el **RUNT** (Registro Único Nacional de Tránsito).
- 📸 **Gestión de Multimedia**: Captura de fotografías o subida de imágenes desde la galería para registrar documentos y guardar fotos del vehículo.

## 🛠️ Tecnologías y Dependencias

El proyecto se enriquece de las siguientes librerías principales:

- **Framework**: `Flutter` (SDK >=3.3.0 <4.0.0)
- **Backend as a Service**: `supabase_flutter` para la base de datos y autenticación de los usuarios.
- **UI & UX**: `dotted_border`, `photo_view`, y uso de Material Design en Flutter.
- **Gestión de Archivos y Permisos**: `file_picker`, `image_picker`, `permission_handler`, `path_provider`.
- **Integración Web y Media**: `webview_flutter`, `youtube_player_iframe`, `url_launcher`.
- **Notificaciones**: `flutter_local_notifications`, `timezone`.

## 📂 Estructura del Código

A continuación se detalla el listado de los archivos más importantes dentro del directorio `/lib` y la función que cumplen en el proyecto:

- `main.dart`: Punto de entrada de la aplicación y configuraciones base (Supabase init, temas).
- `inicio_app.dart`: Pantalla inicial (`Dashboard` / Home), donde se despliegan las métricas y los vehículos agregados.
- `login_screen.dart` / `registro_screen.dart`: Módulo y pantallas del flujo de autenticación e incorporación (Onboarding).
- `Agregar_vehiculo.dart` / `Agregar_carro.dart`: Pantallas con los formularios y la lógica necesaria para registrar nuevas motocicletas o automóviles.
- `guia.dart`: Pantalla de consulta interactiva donde los usuarios ven documentos, manuales PDF o videos explicativos vehiculares.
- `parametrizacion_mantenimientos.dart`: Sistema principal donde se configuran los intervalos de kilometraje, fechas de chequeos y ajustes del taller.
- `runt_webview.dart`: Vista de navegador embebida para realizar las consultas dentro de la página oficial del RUNT sin salir de la app.

## 🚀 Instalación y Configuración

Para poner en marcha esta aplicación en tu propia máquina:

1. **Asegúrate de tener Flutter instalado**.
2. **Clona el repositorio** localmente:
   ```bash
   git clone <URL_DEL_REPOSITORIO>
   cd my_auto_guide
   ```
3. **Obtén las dependencias**:
   ```bash
   flutter pub get
   ```
4. **Conecta Supabase**:
   Debes verificar o configurar las variables de conexión de Supabase (la `URL` y la `Anon Key`) en el archivo principal correspondiente para que el ingreso, registro y extracción de base de datos funcionen correctamente.
5. **Corre la aplicación**:
   Puedes probar el proyecto simulando en un emulador o un dispositivo físico conectado usando el comando:
   ```bash
   flutter run
   ```

## 📝 Contribuciones y Notas

Este repositorio contiene todo lo necesario para escalar una infraestructura de administración mecánica y vehicular orientada al usuario final. La arquitectura del proyecto está pensada para ser fácil de extender mediante componentes como `webview`, servicios locales (notificaciones) o validadores del lado de la nube (Supabase).