# Sistema de Comentarios Reutilizable

## Descripción General

El sistema de comentarios de StreetCore es un módulo genérico y reutilizable que permite agregar funcionalidad de comentarios a cualquier entidad del sistema (posts, competitions, events, clubs, products, etc.).

**Ubicación**:
- **Backend**: `backend/features/profile/comment_*.go`
- **Frontend**: `street_core/lib/features/social/comment/`

**Características**:
- ✅ Comentarios en cualquier entidad
- ✅ Respuestas anidadas (comentarios → respuestas)
- ✅ Sistema de likes en comentarios
- ✅ Soft delete
- ✅ Edición con marca "editado"
- ✅ Paginación soportada
- ✅ Compatibilidad hacia atrás con PostID

---

## Arquitectura

### Modelo Genérico (Backend)

```go
type Comment struct {
    ID primitive.ObjectID

    // Generic entity reference (NEW)
    EntityID   primitive.ObjectID  // ID de la entidad comentada
    EntityType string               // "post", "competition", "event", etc.

    // Legacy support (DEPRECATED)
    PostID primitive.ObjectID      // Mantiene compatibilidad

    // User info
    UserID     primitive.ObjectID
    UserName   string
    UserAvatar string

    // Content
    Text string  // Max 2200 caracteres

    // Reply system
    ParentCommentID *primitive.ObjectID  // null = comentario principal
    RepliesCount    int

    // Engagement
    LikesCount           int
    IsLikedByCurrentUser bool

    // Status
    IsEdited  bool
    IsDeleted bool  // Soft delete

    // Timestamps
    CreatedAt time.Time
    UpdatedAt time.Time
    DeletedAt *time.Time
}
```

### Tipos de Entidades Soportados

```go
const (
    EntityTypePost        = "post"
    EntityTypeCompetition = "competition"
    EntityTypeEvent       = "event"
    EntityTypeClub        = "club"
    EntityTypeProduct     = "product"
)
```

---

## Uso en Backend

### 1. Para Posts (Ya implementado)

```go
// Crear comentario en un post
comment := &Comment{
    EntityID:   postID,
    EntityType: EntityTypePost,
    UserID:     currentUser.ID,
    UserName:   currentUser.Name,
    UserAvatar: currentUser.Avatar,
    Text:       "Mi comentario aquí",
}

commentService.CreateComment(comment)
```

### 2. Para Competiciones (Ejemplo de implementación)

```go
// En el handler de competiciones
func (h *CompetitionHandler) CreateCompetitionComment(c *gin.Context) {
    competitionID := c.Param("id")
    userData := middlewares.GetUserContextData(c)

    var req profile.CreateCommentRequest
    c.ShouldBindJSON(&req)

    comment := &profile.Comment{
        EntityID:   primitive.ObjectIDFromHex(competitionID),
        EntityType: profile.EntityTypeCompetition,
        UserID:     userData.UserID,
        UserName:   userData.UserName,
        UserAvatar: userData.Avatar,
        Text:       req.Text,
    }

    // Usar el servicio de comentarios compartido
    err := commentService.CreateComment(comment)

    if err != nil {
        c.JSON(500, gin.H{"error": "failed_to_create_comment"})
        return
    }

    c.JSON(201, gin.H{"status": "success", "data": comment})
}
```

### 3. Endpoints API

#### Posts (Legacy - Ya implementado)
```
GET    /api/v2/posts/:id/comments         # Obtener comentarios
POST   /api/v2/posts/:id/comments         # Crear comentario (requiere auth)
```

#### Genéricos (Para implementar en otros features)
```
GET    /api/v2/competitions/:id/comments  # Obtener comentarios de competición
POST   /api/v2/competitions/:id/comments  # Crear comentario (requiere auth)

GET    /api/v2/events/:id/comments        # Obtener comentarios de evento
POST   /api/v2/events/:id/comments        # Crear comentario (requiere auth)
```

#### Operaciones sobre comentarios (independientes de la entidad)
```
GET    /api/v2/comments/:commentId        # Obtener comentario específico
PUT    /api/v2/comments/:commentId        # Actualizar comentario
DELETE /api/v2/comments/:commentId        # Eliminar comentario
GET    /api/v2/comments/:commentId/replies # Obtener respuestas

POST   /api/v2/comments/:commentId/like   # Like al comentario
DELETE /api/v2/comments/:commentId/like   # Unlike al comentario
```

---

## Uso en Frontend

### 1. Modelo (Dart)

```dart
class CommentModel extends Equatable {
  final String id;

  // Generic entity reference
  final String? entityId;
  final String? entityType;  // 'post', 'competition', 'event'

  // Legacy support
  final String? postId;

  final String userId;
  final String userName;
  final String? userAvatar;
  final String text;
  final String? parentCommentId;
  final int repliesCount;
  final int likesCount;
  final bool isLikedByCurrentUser;
  final bool isEdited;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Helper getters
  String get getEntityId => entityId ?? postId ?? '';
  String get getEntityType => entityType ?? (postId != null ? 'post' : '');
}
```

### 2. Uso en Posts (Ya implementado)

```dart
// En post_detail_page.dart
BlocProvider(
  create: (_) => getIt<CommentsCubit>()..fetchComments(postId),
  child: BlocBuilder<CommentsCubit, CommentsState>(
    builder: (context, state) {
      if (state is CommentsLoaded) {
        return ListView.builder(
          itemCount: state.comments.length,
          itemBuilder: (context, index) {
            return CommentCard(comment: state.comments[index]);
          },
        );
      }
    },
  ),
)
```

### 3. Uso en Competitions (Ejemplo)

```dart
// En competition_detail_page.dart
class CompetitionDetailPage extends StatelessWidget {
  final String competitionId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CommentsCubit>()
        ..fetchCommentsForEntity('competition', competitionId),
      child: Column(
        children: [
          // Información de la competición...

          // Sistema de comentarios reutilizable
          BlocBuilder<CommentsCubit, CommentsState>(
            builder: (context, state) {
              if (state is CommentsLoaded) {
                return ListView.builder(
                  itemCount: state.comments.length,
                  itemBuilder: (context, index) {
                    return CommentCard(comment: state.comments[index]);
                  },
                );
              }
            },
          ),

          CommentInputField(
            onSubmit: (text) {
              context.read<CommentsCubit>().addComment(
                entityType: 'competition',
                entityId: competitionId,
                text: text,
              );
            },
          ),
        ],
      ),
    );
  }
}
```

---

## Migración de Datos Existentes

Si ya tienes comentarios en la base de datos con el formato antiguo (`postId`), ejecuta el script de migración:

```bash
# Desde la raíz del proyecto
mongosh mongodb://localhost:27017/streetcore < scripts/migrations/migrate_comments_to_generic.js
```

Este script:
1. Copia `postId` → `entityId`
2. Establece `entityType = "post"`
3. Mantiene `postId` para compatibilidad hacia atrás
4. Crea índices optimizados para las nuevas consultas

---

## Índices MongoDB Recomendados

```javascript
// Comentarios por entidad (principal)
db.comments.createIndex({
  entityType: 1,
  entityId: 1,
  createdAt: -1
});

// Comentarios por usuario
db.comments.createIndex({
  userId: 1,
  createdAt: -1
});

// Respuestas anidadas
db.comments.createIndex({
  parentCommentId: 1,
  createdAt: 1
});

// Comentarios no eliminados
db.comments.createIndex({
  isDeleted: 1
});
```

---

## Compatibilidad Hacia Atrás

El sistema mantiene compatibilidad total con el código existente:

### Backend
- ✅ `PostID` todavía funciona
- ✅ Endpoints `/posts/:id/comments` sin cambios
- ✅ Método `Validate()` acepta ambos formatos
- ✅ Helper `NormalizeEntityReference()` convierte automáticamente

### Frontend
- ✅ `postId` todavía existe en el modelo
- ✅ Getter `getEntityId` retorna `entityId` o `postId`
- ✅ Getter `getEntityType` infiere tipo si solo existe `postId`
- ✅ Componentes existentes funcionan sin cambios

---

## Próximos Pasos para Implementar en Otros Features

### 1. Competitions

1. En `competition_handler.go`:
```go
func (h *CompetitionHandler) CreateCompetitionComment(c *gin.Context) {
    // Implementación similar a PostHandler.CreateComment
    // Pero usar EntityType = EntityTypeCompetition
}
```

2. En `competition_routes.go`:
```go
version.GET("/competitions/:id/comments", commentHandler.GetEntityComments)
protected.POST("/competitions/:id/comments", commentHandler.CreateEntityComment)
```

3. En Flutter `competition_detail_page.dart`:
```dart
BlocProvider(
  create: (_) => CommentsCubit(getIt<CommentService>())
    ..fetchCommentsForEntity('competition', competitionId),
  child: // ... UI de comentarios
)
```

### 2. Events, Clubs, Market

Seguir el mismo patrón que Competitions.

---

## Limitaciones Conocidas

1. **Respuestas anidadas**: Solo 2 niveles (comentario → respuesta). No hay respuestas a respuestas.
2. **Paginación**: Implementada en backend, falta en UI de frontend
3. **Real-time**: No hay actualizaciones en tiempo real (requeriría WebSocket/SSE)
4. **Menciones**: No se procesan menciones @usuario
5. **Notificaciones**: No hay sistema de notificaciones cuando alguien comenta

---

## Archivos Relacionados

### Backend
- `backend/features/profile/comment_model.go` - Modelo y DTOs
- `backend/features/profile/comment_service.go` - Lógica de negocio
- `backend/features/profile/comment_handler.go` - Handlers HTTP
- `backend/features/profile/comment_like_*.go` - Sistema de likes
- `backend/routes/profile_routes.go` - Definición de rutas

### Frontend
- `street_core/lib/features/social/comment/comment_model.dart` - Modelo
- `street_core/lib/features/social/comment/comment_repository.dart` - API calls
- `street_core/lib/features/social/comment/comments_cubit.dart` - State management
- `street_core/lib/features/social/comment/comment_card.dart` - Widget de comentario
- `street_core/lib/features/social/comment/comment_input_field.dart` - Input de comentarios
- `street_core/lib/features/profile/services/comment_service.dart` - Servicio de negocio

### Migración
- `scripts/migrations/migrate_comments_to_generic.js` - Script de migración MongoDB

---

## Soporte

Para preguntas o problemas con el sistema de comentarios, consulta:
- CLAUDE.md - Principios generales del proyecto
- docs/TODO.md - Estado del proyecto y roadmap
- docs/architecture/adr/ - Decisiones arquitectónicas

---

**Última actualización**: 2026-01-06
**Versión del sistema**: 0.1
**Estado**: ✅ Funcional y reutilizable
