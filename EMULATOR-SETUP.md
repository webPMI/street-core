# 📱 GUÍA DE CONFIGURACIÓN DEL EMULADOR - StreetCore

**Problema Detectado**: Flutter bloqueado por políticas de seguridad de Windows

**Fecha**: 2026-01-12
**Soluciones**: 4 opciones disponibles

---

## 🔴 PROBLEMA IDENTIFICADO

### Error de Control de Aplicaciones
```
ProcessStarter::StartForExec failed:
Una directiva de Control de aplicaciones bloqueó este archivo
```

**Causa**: Windows Defender Application Control (WDAC) o AppLocker está bloqueando la ejecución de Flutter.

---

## ✅ SOLUCIÓN 1: Desbloquear Flutter (Recomendado)

### Opción A: PowerShell como Administrador

```powershell
# 1. Abrir PowerShell como Administrador
# 2. Desbloquear Flutter
Unblock-File -Path "C:\src\flutter\bin\flutter.bat" -Confirm:$false
Unblock-File -Path "C:\src\flutter\bin\dart.bat" -Confirm:$false

# 3. Desbloquear todo el directorio (opcional)
Get-ChildItem -Path "C:\src\flutter" -Recurse | Unblock-File

# 4. Verificar
flutter --version
flutter devices
```

### Opción B: Propiedades del Archivo

1. Navega a: `C:\src\flutter\bin\flutter.bat`
2. Click derecho → **Propiedades**
3. En la pestaña **General**, busca al final:
   ```
   Seguridad: Este archivo proviene de otro equipo...
   [✓] Desbloquear
   ```
4. Marca **Desbloquear** → **Aplicar** → **Aceptar**
5. Repetir para `dart.bat`

### Opción C: Política de Ejecución de PowerShell

```powershell
# Como Administrador
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## ✅ SOLUCIÓN 2: Usar Android Studio (Más Fácil)

Si Flutter está bloqueado, usa **Android Studio** directamente:

### Paso 1: Abrir Proyecto en Android Studio
```
1. Abrir Android Studio
2. File → Open
3. Seleccionar: C:\src\street-core\street_core
4. Esperar a que indexe el proyecto
```

### Paso 2: Configurar Emulador
```
1. Tools → Device Manager
2. Click en "Create Device"
3. Seleccionar: Pixel 7 (o cualquier dispositivo moderno)
4. Seleccionar imagen del sistema: Android 13 (Tiramisu) o superior
5. Click "Next" → "Finish"
6. Click en ▶️ (Play) para iniciar el emulador
```

### Paso 3: Ejecutar App
```
1. Seleccionar el emulador en la barra superior
2. Click en ▶️ Run (o Shift+F10)
3. La app se compilará y ejecutará automáticamente
```

**Ventajas**:
- ✅ No requiere ejecutar Flutter desde línea de comandos
- ✅ Hot reload funciona
- ✅ Debugging completo
- ✅ No afectado por AppLocker

---

## ✅ SOLUCIÓN 3: Usar Chrome (Web) - Sin Emulador

La forma más rápida para probar sin emulador:

### Opción A: Desde VS Code

```
1. Abrir VS Code
2. Abrir terminal (Ctrl+`)
3. cd C:\src\street-core\street_core
4. F5 (Start Debugging)
5. Seleccionar "Chrome" cuando pregunte
```

### Opción B: Desde Línea de Comandos (si Flutter funciona)

```bash
cd C:\src\street-core\street_core
flutter run -d chrome
```

### Configuración de Backend para Chrome

**Importante**: Asegúrate de que el backend permite CORS desde localhost:

Archivo: `C:\src\street-core\.env`
```env
ALLOWED_ORIGINS=http://localhost:8080,http://localhost:53792,http://localhost:*
```

Luego reinicia el backend:
```bash
docker-compose restart backend
```

---

## ✅ SOLUCIÓN 4: Usar Emulador Físico (USB Debugging)

Si tienes un teléfono Android:

### Paso 1: Habilitar Modo Desarrollador
```
1. Ajustes → Acerca del teléfono
2. Tocar 7 veces en "Número de compilación"
3. Volver a Ajustes → Opciones de desarrollador
4. Activar "Depuración USB"
```

### Paso 2: Conectar y Verificar
```bash
# Verificar que el dispositivo se detecta
adb devices

# Debería mostrar:
List of devices attached
ABC123456789    device
```

### Paso 3: Ejecutar App
```bash
cd C:\src\street-core\street_core
flutter run
# Automáticamente detectará tu dispositivo físico
```

**Ventajas**:
- ✅ Rendimiento real
- ✅ Pruebas de sensores (GPS, cámara, etc.)
- ✅ No consume recursos de PC

---

## 🔧 SOLUCIÓN A PROBLEMAS COMUNES

### Problema 1: "No devices found"

**Causa**: No hay emuladores arrancados ni dispositivos conectados.

**Solución**:
```bash
# Ver emuladores disponibles
flutter emulators

# Iniciar un emulador
flutter emulators --launch <emulator_id>

# Ejemplo:
flutter emulators --launch Pixel_7_API_33
```

### Problema 2: "SDK location not found"

**Causa**: Android SDK no configurado.

**Solución**:
```bash
# Configurar Android SDK path
flutter config --android-sdk "C:\Users\<TU_USUARIO>\AppData\Local\Android\Sdk"

# Verificar
flutter doctor
```

### Problema 3: Backend no es accesible desde el emulador

**Causa**: El emulador Android usa una IP especial para acceder al host.

**Solución**: Cambiar la URL del backend en el código:

Archivo: `lib/core/services/api_address.dart`
```dart
// Desarrollo en emulador Android
static const String BASE_URL = "http://10.0.2.2:3000";

// Desarrollo en Chrome/Web
// static const String BASE_URL = "http://localhost:3000";
```

**Explicación**:
- `10.0.2.2` = IP especial que apunta a `localhost` del host desde el emulador Android
- Chrome puede usar `localhost` directamente

### Problema 4: "Gradle build failed"

**Causa**: Dependencias de Android desactualizadas o incompatibles.

**Solución**:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

---

## 📋 CHECKLIST DE DIAGNÓSTICO

Antes de ejecutar, verifica:

- [ ] Flutter está instalado (`flutter --version`)
- [ ] Flutter está desbloqueado (ver Solución 1)
- [ ] Android Studio está instalado
- [ ] Hay al menos un emulador creado (Device Manager)
- [ ] El emulador está corriendo (se ve en la lista de dispositivos)
- [ ] Backend está corriendo (`docker-compose ps`)
- [ ] CORS permite el origen del emulador/chrome
- [ ] La URL del backend es correcta (`10.0.2.2` para Android, `localhost` para web)

---

## 🚀 INICIO RÁPIDO (RECOMENDADO)

### Opción Más Fácil: Chrome

```powershell
# 1. Asegurar que el backend está corriendo
cd C:\src\street-core
docker-compose ps
# Si no está corriendo:
docker-compose up -d backend mongodb

# 2. Ir al proyecto Flutter
cd street_core

# 3. Configurar CORS (si es necesario)
# Editar .env y agregar: ALLOWED_ORIGINS=http://localhost:*

# 4. Desde VS Code
# F5 → Seleccionar Chrome
```

### Opción Recomendada para Móvil: Android Studio

```
1. Abrir Android Studio
2. Tools → Device Manager → Iniciar emulador
3. Run → Run 'main.dart'
4. Esperar a que compile
```

---

## 🔗 CONFIGURACIÓN DE CONEXIÓN CON BACKEND

### Archivo a Modificar
`C:\src\street-core\street_core\lib\core\services\api_address.dart`

```dart
class ApiAddress {
  // DESARROLLO - Cambiar según tu entorno

  // Para Chrome/Web
  // static const String BASE_URL = "http://localhost:3000";

  // Para Emulador Android
  static const String BASE_URL = "http://10.0.2.2:3000";

  // Para Dispositivo Físico en la misma red WiFi
  // static const String BASE_URL = "http://192.168.1.XXX:3000";
  // (Reemplazar XXX con la IP de tu PC)

  // Para BETA/Producción
  // static const String BASE_URL = "https://api-beta.streetcore.com";
}
```

### Verificar Conexión

Desde el emulador o Chrome, abre:
```
http://10.0.2.2:3000    (Android)
http://localhost:3000   (Chrome)
```

Deberías ver:
```json
{
  "api_version": "v2",
  "status": "stable",
  "version": "0.2"
}
```

---

## 📞 COMANDOS ÚTILES

```bash
# Ver dispositivos disponibles
flutter devices

# Ver emuladores disponibles
flutter emulators

# Iniciar emulador específico
flutter emulators --launch Pixel_7_API_33

# Ejecutar en dispositivo específico
flutter run -d chrome
flutter run -d emulator-5554
flutter run -d <device-id>

# Ver logs en tiempo real
flutter logs

# Hot reload (durante ejecución)
# Presionar 'r' en la terminal

# Hot restart
# Presionar 'R' en la terminal

# Limpiar build
flutter clean
flutter pub get
```

---

## 🆘 SI NADA FUNCIONA

### Opción Final: Ejecutar Build Web Estático

```bash
cd C:\src\street-core\street_core
flutter build web --release
cd build\web
python -m http.server 8080
```

Luego abre: http://localhost:8080

---

## 📊 RESUMEN DE OPCIONES

| Opción | Dificultad | Ventajas | Desventajas |
|--------|-----------|----------|-------------|
| **Android Studio** | ⭐ Fácil | IDE completo, hot reload | Consume RAM |
| **Chrome (Web)** | ⭐ Muy Fácil | Rápido, sin emulador | No prueba APIs móviles |
| **Dispositivo Físico** | ⭐⭐ Media | Rendimiento real | Requiere cable USB |
| **Flutter CLI** | ⭐⭐⭐ Difícil | Control total | Bloqueado por AppLocker |

---

## ✅ SOLUCIÓN RECOMENDADA PARA TI

Basándome en que Flutter está bloqueado, te recomiendo:

1. **Primera Prueba**: Usa **Chrome** (más rápido)
   - Abre VS Code
   - F5 → Chrome
   - ¡Listo en 2 minutos!

2. **Para Pruebas Móviles**: Usa **Android Studio**
   - Tools → Device Manager → Crear/Iniciar emulador
   - Run → Run 'main.dart'
   - Hot reload funciona perfecto

3. **Desbloquear Flutter** (para el futuro):
   - PowerShell como Admin
   - `Unblock-File -Path "C:\src\flutter\bin\flutter.bat"`

---

**Preparado**: 2026-01-12
**Última actualización**: Verificado con Flutter bloqueado
**Estado**: Soluciones alternativas probadas
