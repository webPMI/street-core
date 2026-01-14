# Help Guide System

Sistema de ayuda contextual para StreetCore que muestra guías paso a paso basadas en la ruta actual.

## Ubicación

`street_core/lib/core/widgets/help_guide/` - Widget core (no feature-specific)

## Características

- **Route-based**: Detecta automáticamente qué guía mostrar según la ruta
- **Auto-show**: Se muestra automáticamente las primeras 2 visitas (configurable)
- **Persistent storage**: Usa Hive para recordar qué guías se han descartado
- **Multi-step**: Soporta guías con múltiples pasos
- **Translatable**: Todas las traducciones en `core/lang/translations/es/help_guide_es.dart`
- **"?" button**: Botón flotante que permite abrir la guía manualmente

## Guías Disponibles

### 1. Crear Competición (`/competitions/create`)
- Consejos sobre título y descripción atractivos
- Planificación de fechas
- Estrategia de precios
- Calidad del banner
- Reglas claras

### 2. Invitar Jueces (`/competitions/*/judges`)
- Cuántos jueces necesitas
- Tipos de jueces (registrados vs externos)
- Invitaciones profesionales
- Diversidad en el panel
- Gestión durante el evento

### 3. Configurar Categorías (`/competitions/*/categories`)
- División por niveles
- Criterios de puntuación objetivos
- Rangos de edad realistas
- Nombres memorables
- Orden estratégico

### 4. Gestionar Participantes (`/competitions/*/participants`)
- Aprobación manual vs automática
- Verificación de documentos
- Comunicación efectiva
- Listas de espera
- Check-in del día

### 5. Iniciar Competición (`/competitions/*/manage`)
- Checklist pre-inicio
- Briefing con jueces y atletas
- Monitoreo en tiempo real
- Manejo de imprevistos
- Publicación oficial de resultados

## Uso

### 1. Inicializar el Sistema

En `main.dart` o donde inicializas tu app:

```dart
import 'core/widgets/help_guide/bloc/guide_cubit.dart';

// En tu setup de providers
BlocProvider(
  create: (context) => GuideCubit(
    hiveService: getIt<HiveService>(),
  ),
),
```

### 2. Cargar Guía en una Página

En el `initState` o en el `build` de tu página:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/widgets/help_guide/bloc/guide_cubit.dart';
import 'core/widgets/help_guide/widgets/guide_overlay.dart';
import 'core/widgets/help_guide/widgets/guide_bottom_sheet.dart';

class CompetitionCreatePage extends StatefulWidget {
  @override
  State<CompetitionCreatePage> createState() => _CompetitionCreatePageState();
}

class _CompetitionCreatePageState extends State<CompetitionCreatePage> {
  @override
  void initState() {
    super.initState();
    // Cargar guía para esta ruta
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GuideCubit>().loadGuideForRoute('/competitions/create');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Crear Competición')),
      body: Stack(
        children: [
          // Tu contenido normal
          YourContent(),

          // Widget de ayuda automática (muestra bottom sheet si aplica)
          const AutoGuide(),

          // Botón flotante "?" (aparece cuando guía está disponible)
          const GuideOverlay(),
        ],
      ),
    );
  }
}
```

### 3. Mostrar Guía Manualmente

Si quieres mostrar la guía desde un botón personalizado:

```dart
IconButton(
  icon: Icon(Icons.help_outline),
  onPressed: () {
    context.read<GuideCubit>().showGuide('/competitions/create');
    GuideBottomSheet.show(context);
  },
)
```

## Estructura de Archivos

```
core/widgets/help_guide/
├── models/
│   ├── guide_step.dart          # Modelo de un paso individual
│   └── guide_config.dart        # Configuración completa de una guía
├── services/
│   └── guide_service.dart       # Servicio que provee las guías
├── bloc/
│   ├── guide_cubit.dart         # Lógica de negocio
│   └── guide_state.dart         # Estados del sistema
└── widgets/
    ├── guide_overlay.dart       # Botón flotante "?"
    └── guide_bottom_sheet.dart  # Bottom sheet con los pasos

core/lang/translations/es/
└── help_guide_es.dart           # Traducciones en español

core/storage/models/
└── guide_progress.dart          # Modelo Hive para progreso
```

## Añadir una Nueva Guía

### 1. Añadir Traducciones

En `core/lang/translations/es/help_guide_es.dart`:

```dart
'help.guide.nueva.feature.title': 'Título de la Guía',
'help.guide.nueva.feature.step1.title': 'Paso 1',
'help.guide.nueva.feature.step1.description': 'Descripción del paso 1',
// ... más pasos
```

### 2. Añadir Keys en LocaleKeys

En `core/lang/locale_keys.dart`:

```dart
static const String helpGuideNuevaFeatureTitle = 'help.guide.nueva.feature.title';
// ... más keys
```

### 3. Registrar Guía en GuideService

En `core/widgets/help_guide/services/guide_service.dart`:

```dart
static final Map<String, GuideConfig> _guides = {
  // ... guías existentes
  '/ruta/nueva': GuideConfig(
    routePath: '/ruta/nueva',
    titleKey: 'help.guide.nueva.feature.title',
    steps: [
      const GuideStep(
        titleKey: 'help.guide.nueva.feature.step1.title',
        descriptionKey: 'help.guide.nueva.feature.step1.description',
      ),
      // ... más pasos
    ],
    autoShow: true,
  ),
};
```

### 4. Actualizar Normalización de Rutas (si es dinámica)

Si tu ruta tiene parámetros (ej: `/competitions/:id/nueva`):

```dart
// En GuideService.getGuideForRoute()
if (routePath.endsWith('/nueva')) {
  return _guides['/competitions/nueva'];
}
```

## Estados del Sistema

- `GuideInitial` - No inicializado
- `GuideLoading` - Cargando guía
- `GuideNotAvailable` - No hay guía para esta ruta
- `GuideAvailable` - Guía disponible, botón "?" visible
- `GuideShowing` - Guía siendo mostrada (bottom sheet abierto)
- `GuideDismissed` - Usuario descartó la guía
- `GuideCompleted` - Usuario completó todos los pasos
- `GuideError` - Error al cargar/mostrar

## Métodos del Cubit

```dart
// Cargar guía para ruta
guideCubit.loadGuideForRoute(String routePath)

// Mostrar guía manualmente
guideCubit.showGuide(String routePath)

// Navegar pasos
guideCubit.nextStep()
guideCubit.previousStep()

// Cerrar sin completar
guideCubit.skipGuide()

// Descartar permanentemente
guideCubit.dismissPermanently()

// Reset (testing/preferencias)
guideCubit.resetGuide(String routePath)
guideCubit.resetAllGuides()
```

## Storage

El progreso se guarda en Hive con la key:
```
'guide_progress_/ruta/de/la/pagina'
```

Datos guardados:
- `isDismissed`: bool
- `dismissedAt`: DateTime?
- `viewCount`: int
- `lastViewedAt`: DateTime?

## Notas Técnicas

1. **TypeId 6**: GuideProgress usa Hive TypeId 6
2. **Auto-show logic**: Solo se muestra automáticamente las primeras 2 visitas si `autoShow: true`
3. **Normalización de rutas**: Rutas dinámicas se normalizan para compartir guías
4. **Equatable**: Todos los modelos usan Equatable para comparación de estados
5. **Translations**: Usa el sistema existente con `context.tr(key)`

## Testing

Para resetear todas las guías durante desarrollo:

```dart
context.read<GuideCubit>().resetAllGuides();
```

O resetear una específica:

```dart
context.read<GuideCubit>().resetGuide('/competitions/create');
```

## Ejemplo Completo

Ver `street_core/lib/features/competitions/pages/create_competition_page.dart` para un ejemplo completo de implementación.
