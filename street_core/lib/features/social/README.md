# Social Module

Módulo de interacciones sociales en StreetCore.

## Estructura

```
social/
├── comment/              # Sistema de comentarios
│   ├── comment_model.dart
│   ├── comment_repository.dart
│   ├── comment_service.dart
│   ├── comment_uris.dart
│   ├── comments_cubit.dart
│   ├── comments_state.dart
│   ├── comment_card.dart
│   └── comment_input_field.dart
│
├── like/                 # Sistema de likes
│   ├── like_model.dart
│   ├── like_repository.dart
│   ├── like_service.dart
│   ├── like_uris.dart       # ✅ NEW: URIs independientes
│   ├── like_cubit.dart
│   ├── like_state.dart
│   └── widgets/             # ✅ NEW: Widgets reutilizables
│       ├── like_button.dart
│       └── widgets.dart
│
└── di/                   # Dependency Injection
    └── social_injection.dart
```

## Uso desde Otros Módulos

### Comentarios

```dart
import 'package:get_it/get_it.dart';
import '../../social/comment/comments_cubit.dart';
import '../../social/comment/comment_card.dart';
import '../../social/comment/comment_input_field.dart';

// En tu página
BlocProvider(
  create: (_) => getIt<CommentsCubit>()..fetchComments(postId),
  child: CommentCard(...),
)
```

### Likes

#### Opción 1: Usar el widget LikeButton (Recomendado)

```dart
import '../../social/like/widgets/like_button.dart';

// Uso simple
LikeButton(
  postId: post.id,
  isLiked: post.isLikedByCurrentUser,
  likesCount: post.likesCount,
)

// Con animación
AnimatedLikeButton(
  postId: post.id,
  isLiked: post.isLikedByCurrentUser,
  likesCount: post.likesCount,
  size: 28.0,
)

// Personalizado
LikeButton(
  postId: post.id,
  isLiked: post.isLiked,
  likesCount: post.count,
  size: 32.0,
  showCount: false,
  likedColor: Colors.pink,
  unlikedColor: Colors.grey.shade400,
  onLikeChanged: (isLiked) {
    print('Like status changed: $isLiked');
  },
)
```

#### Opción 2: Usar LikeCubit directamente

```dart
import '../../social/like/like_cubit.dart';

// En tu widget
BlocProvider(
  create: (_) => getIt<LikeCubit>(),
  child: // ... tu widget
)

// Ejemplo de uso
context.read<LikeCubit>().toggleLike(
  postId,
  isCurrentlyLiked: post.isLikedByCurrentUser,
  currentCount: post.likesCount,
);
```

## Arquitectura

Este módulo sigue el patrón **Monolith-by-Features** de StreetCore:

- **Models**: Representan los datos (Comment, Like)
- **Repositories**: Llamadas API usando BaseRepository
- **Services**: Lógica de negocio
- **Cubits**: Gestión de estado con flutter_bloc
- **Widgets**: Componentes UI reutilizables (solo en comment/)

## Estados

### CommentsState

- `CommentsInitial`: Estado inicial
- `CommentsLoading`: Cargando comentarios
- `CommentsLoaded`: Comentarios cargados
- `CommentsError`: Error al cargar/crear comentarios
- `CommentsActionSuccess`: Acción exitosa (crear, editar, eliminar)

### LikeState

- `LikeInitial`: Estado inicial
- `LikeLoading`: Verificando estado de like
- `LikeSuccess`: Estado actualizado (con `isLiked` y `likesCount`)
- `LikeError`: Error al realizar operación

## Actualización Optimista

El `LikeCubit` implementa **actualización optimista** para mejor experiencia de usuario:

1. Actualiza la UI inmediatamente
2. Ejecuta la llamada al backend
3. Verifica que el resultado coincida
4. Revierte si hay error

## Dependencias

Este módulo depende de:
- `core/services/api_service.dart` - Cliente HTTP
- `core/crud/base_repository.dart` - Base para repositorios
- `core/helpers/logger.dart` - Logging

NO depende de:
- `features/profile/` (arquitectónicamente independiente)

NOTA: Ya NO depende de `profile/profile_uris.dart` - ahora usa `like/like_uris.dart`

## Integración con Profile Module

El módulo `profile` importa `social` a través de:

```dart
import '../../social/di/social_injection.dart';

void setupProfileModule(GetIt getIt) {
  // Setup social module first
  setupSocialModule(getIt);

  // ... resto del setup
}
```

## TODO

- [x] Mover URIs de likes a `social/like/like_uris.dart` (COMPLETADO)
- [x] Implementar obtención de userId desde AuthContext (COMPLETADO - se usa JWT token)
- [x] Crear widget LikeButton reutilizable (COMPLETADO)
- [ ] Agregar tests unitarios para Cubits
- [ ] Agregar tests de integración para Repositories
