# Wallpaper App - Documentación del Proyecto

## 📋 Descripción

App Flutter de wallpapers que carga imágenes desde URLs remotas y permite establecerlas como fondo de pantalla en Android.

## 🛠 Stack Tecnológico

| Tecnología | Versión | Uso |
|-----------|---------|-----|
| Flutter | >=3.0.0 | Framework UI |
| Dart | >=3.0.0 | Lenguaje |
| Kotlin | 2.0.0 | Nativo Android |
| Gradle | 8.11.1 | Build Android |
| Material Design 3 | SDK | Diseño UI |

### Dependencias principales

| Paquete | Uso |
|---------|-----|
| `http` | Peticiones de red |
| `cached_network_image` | Cache de imágenes |
| `flutter_cache_manager` | Gestión de cache |
| `path_provider` | Directorio temporal |
| `permission_handler` | Permisos Android |
| `image_gallery_saver_plus` | Guardar en galería |
| `connectivity_plus` | Estado de conexión |
| `url_launcher` | Abrir enlaces externos |
| `share_plus` | Compartir imágenes |
| `flutter_launcher_icons` | Icono de app |
| `flutter_native_splash` | Splash screen |

## 📁 Estructura del Proyecto

```
wallpaper_app/
├── lib/
│   ├── main.dart                              # Entry point
│   ├── models/
│   │   └── wallpaper.dart                     # Modelo Wallpaper
│   ├── screens/
│   │   ├── home_screen.dart                   # Pantalla principal + Drawer
│   │   ├── preview_screen.dart                # Vista previa + acciones
│   │   └── community_screen.dart              # Comunidad (envío Telegram)
│   ├── services/
│   │   ├── wallpaper_service.dart             # Carga de JSONs remotos + categorías
│   │   ├── wallpaper_action.dart              # Permisos, descarga, guardado, wallpaper nativo
│   │   └── url_resolver.dart                  # Resuelve URLs Google Drive
│   └── widgets/
│       └── wallpaper_image.dart               # Widget imagen con fallbacks
├── assets/
│   ├── images/
│   │   ├── logo.png                           # Logo (icono + splash)
│   │   └── banner.gif                         # Banner del Drawer
│   └── community_sample.json                  # Ejemplo de formato JSON
├── android/
│   ├── app/
│   │   ├── build.gradle                       # compileSdk 36, minify, signing
│   │   ├── proguard-rules.pro                 # Reglas ProGuard
│   │   ├── key.properties.example             # Plantilla signing
│   │   └── src/main/
│   │       ├── AndroidManifest.xml            # Permisos + queries
│   │       └── kotlin/.../MainActivity.kt     # WallpaperManager nativo
├── pubspec.yaml                               # Dependencias y assets
└── analysis_options.yaml                      # Reglas de lint
```

## 🔧 Configuración

### 1. Key Store (para release)

Copia `android/key.properties.example` → `android/key.properties` y configura:
```properties
storePassword=tu_password
keyPassword=tu_key_password
keyAlias=tu_alias
storeFile=../tu-keystore.jks
```

### 2. URLs de datos

Las categorías se cargan desde GitHub RAW en `lib/services/wallpaper_service.dart`:
```dart
static const baseUrl = 'https://raw.githubusercontent.com/xgumiimegpoid-netizen/Wallpapers/DATA';
```

Los JSONs deben seguir este formato:
```json
[
  {
    "id": "string",
    "title": "string",
    "author": "string",
    "url": "string (URL de imagen)"
  }
]
```

### 3. Comunidad (Telegram)

Configurar en `lib/screens/community_screen.dart`:
```dart
static const _telegramLink = 'https://t.me/tu_canal';
```

## 🚀 Comandos Útiles

```bash
# Instalar dependencias
flutter pub get

# Análisis de código
flutter analyze

# Build release APK
flutter build apk --release

# Build debug APK
flutter build apk --debug

# Instalar en dispositivo conectado
flutter install

# Regenerar icono de app (tras cambiar assets/images/logo.png)
flutter pub run flutter_launcher_icons

# Regenerar splash screen
flutter pub run flutter_native_splash:create

# Tests
flutter test
```

## 📱 Funcionalidades

### Implementadas
- Carga de wallpapers desde 7 categorías (Anime, Paisajes, Cyberpunk, Fantasy/Sci-Fi, Pokemon, Juegos, Comunidad)
- Carga paralela de categorías con `Future.wait`
- Cache de imágenes en disco (`cached_network_image`)
- Búsqueda con debounce (300ms) por título, autor, categoría e ID
- "Cargar más" en grid (inicial: 12, incremento: +8)
- Drawer con banner GIF, categorías y donación
- Pantalla de comunidad (enviar vía Telegram)
- Vista previa con zoom (`InteractiveViewer`)
- Guardar en galería
- **Establecer como fondo nativo** (Android WallpaperManager) — Home, Lock, o Both
- Compartir imagen vía `share_plus`
- Manejo de conectividad (`connectivity_plus`)
- Pantalla de error con botón Reintentar
- Minify/ProGuard habilitado
- Splash screen con logo
- Icono personalizado

### Nativo Android (MainActivity.kt)
- `MethodChannel` para comunicación Flutter ↔ Kotlin
- `WallpaperManager.setStream()` para establecer fondo
- Soporta: HOME_SCREEN (FLAG_SYSTEM), LOCK_SCREEN (FLAG_LOCK), ambos
- Compatible con Android N+ (API 24+)

## ⚠️ Warnings de compilación conocidos

| Warning | Solución |
|---------|----------|
| `Kotlin version (2.0.0) will soon be dropped` | Actualizar Kotlin a >=2.2.20 en `android/settings.gradle` |
| `Plugins that apply KGP` | Migrar a Built-in Kotlin (documentación Flutter) |
| `plugins do not support Swift Package Manager for ios` | Ignorar (app solo Android) |

## 🎨 UI/UX

- Tema oscuro Material 3 con `colorSchemeSeed: Colors.blue`
- Snackbars flotantes con feedback visual
- Bottom sheet con opciones de descarga/fondo
- Drawer con banner animado (GIF)
- Badges con contadores de wallpapers por categoría
- Shimmer/progress en carga de imágenes
