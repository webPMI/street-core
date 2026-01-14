# Social Module

Este módulo contiene toda la funcionalidad de interacciones sociales en StreetCore.

## Componentes

### Comments
- Comentarios en posts, competitions, events, etc.
- Respuestas anidadas (replies)
- Soft delete (eliminación suave)
- Sistema genérico con EntityID/EntityType

**Archivos:**
- `comment_model.go` - Modelo de datos de comentarios
- `comment_service.go` - Lógica de negocio de comentarios
- `comment_handler.go` - Controladores HTTP de comentarios

**Características:**
- Soporte para múltiples tipos de entidades (post, competition, event, club, product)
- Sistema de respuestas anidadas con contador automático
- Contador de likes integrado
- Soft delete para moderación
- Sanitización de HTML en contenido

### Comment Likes
- Likes en comentarios individuales
- Contadores automáticos de likes
- Prevención de likes duplicados

**Archivos:**
- `comment_like_model.go` - Modelo de datos de likes en comentarios
- `comment_like_service.go` - Lógica de negocio de likes en comentarios
- `comment_like_handler.go` - Controladores HTTP de likes en comentarios

**Características:**
- Like/Unlike de comentarios
- Verificación de estado de like
- Lista de usuarios que dieron like
- Actualización automática de contadores

### Post Likes
- Likes en posts
- Batch queries optimizadas para performance
- Contadores automáticos de likes

**Archivos:**
- `like_model.go` - Modelo de datos de likes en posts
- `like_service.go` - Lógica de negocio de likes en posts
- `like_handler.go` - Controladores HTTP de likes en posts

**Características:**
- Like/Unlike de posts
- Verificación de estado de like
- Lista de usuarios que dieron like
- **Batch query optimizada** (`GetUserLikesForPosts`) - Reduce N queries a 1 sola

## Arquitectura

### Interfaces
El módulo define interfaces claras para evitar dependencias circulares:

```go
// ICommentService - Operaciones de comentarios
// ICommentLikeService - Operaciones de likes en comentarios
// ILikeService - Operaciones de likes en posts
// IPostService - Interfaz mínima del servicio de posts
```

Ver `interfaces.go` para la lista completa de métodos.

### Module Pattern
El módulo usa el patrón de módulo con inicialización centralizada:

```go
type Module struct {
    CommentService     ICommentService
    CommentLikeService ICommentLikeService
    LikeService        ILikeService
}

func NewModule(db *mongo.Database, postService IPostService) *Module
```

## Uso desde Otros Módulos

### Importar el módulo

```go
import "backend/features/social"
```

### Inicializar el módulo

```go
// Crear adaptador para IPostService si es necesario
postServiceAdapter := &PostServiceAdapter{postService: postService}

// Inicializar módulo social
socialModule := social.NewModule(db, postServiceAdapter)
```

### Registrar rutas

```go
// Registrar todas las rutas del módulo (públicas + protegidas)
authMiddleware := middlewares.JWTAuthMiddleware(...)
social.RegisterRoutes(version, socialModule, authMiddleware)
```

### Usar servicios individuales

```go
// Inyectar servicios en handlers
postHandler := NewPostHandler(
    postService,
    userService,
    socialModule.LikeService, // Batch query optimizado
)
```

## Rutas API

### Comentarios
- `GET /posts/:id/comments` - Obtener comentarios de un post (público)
- `POST /posts/:id/comments` - Crear comentario (protegido)
- `GET /comments/:commentId/replies` - Obtener respuestas (público)
- `PUT /comments/:commentId` - Actualizar comentario (protegido)
- `DELETE /comments/:commentId` - Eliminar comentario (protegido)
- `GET /comments/me` - Mis comentarios (protegido)

### Likes en Comentarios
- `POST /comments/:commentId/like` - Dar like (protegido)
- `DELETE /comments/:commentId/like` - Quitar like (protegido)
- `GET /comments/:commentId/likes` - Lista de likes (público)
- `GET /comments/:commentId/like/status` - Estado de like (protegido)

### Likes en Posts
- `POST /posts/:id/like` - Dar like (protegido)
- `DELETE /posts/:id/like` - Quitar like (protegido)
- `GET /posts/:id/likes` - Lista de likes (público)
- `GET /posts/:id/like/status` - Estado de like (protegido)
- `GET /likes/me` - Mis likes (protegido)

Ver `routes.go` para la lista completa de endpoints y middleware.

## Optimizaciones

### Batch Query en Post Likes
Para mejorar performance al cargar feeds de posts:

```go
// ANTES (N+1 queries):
for _, post := range posts {
    isLiked, _ := likeService.GetLike(post.ID.Hex(), userID)
    post.IsLikedByCurrentUser = (isLiked != nil)
}

// DESPUÉS (1 query):
postIDs := make([]primitive.ObjectID, len(posts))
for i := range posts {
    postIDs[i] = posts[i].ID
}
likedPosts, _ := likeService.GetUserLikesForPosts(userID, postIDs)
for i := range posts {
    posts[i].IsLikedByCurrentUser = likedPosts[posts[i].ID.Hex()]
}
```

### Contadores Desnormalizados
Los contadores de likes y comentarios se mantienen desnormalizados en los documentos para evitar queries adicionales:

- `Post.LikesCount` - Incrementado/decrementado automáticamente
- `Post.CommentsCount` - Incrementado/decrementado automáticamente
- `Comment.LikesCount` - Incrementado/decrementado automáticamente
- `Comment.RepliesCount` - Incrementado/decrementado automáticamente

## Base de Datos

### Colecciones
- `comments` - Comentarios
- `comment_likes` - Likes en comentarios
- `likes` - Likes en posts

### Índices Recomendados

```javascript
// comments
db.comments.createIndex({ "entityId": 1, "entityType": 1 })
db.comments.createIndex({ "postId": 1 }) // Legacy support
db.comments.createIndex({ "parentCommentId": 1 })
db.comments.createIndex({ "userId": 1 })
db.comments.createIndex({ "isDeleted": 1 })

// comment_likes
db.comment_likes.createIndex({ "commentId": 1, "userId": 1 }, { unique: true })
db.comment_likes.createIndex({ "commentId": 1 })
db.comment_likes.createIndex({ "userId": 1 })

// likes
db.likes.createIndex({ "postId": 1, "userId": 1 }, { unique: true })
db.likes.createIndex({ "postId": 1 })
db.likes.createIndex({ "userId": 1 })
```

## Testing

TODO: Agregar tests unitarios e integración

## Migración desde `comments`

Este módulo fue renombrado de `comments` a `social` para reflejar mejor su alcance (comments + likes + futuras funcionalidades sociales).

**Cambios realizados:**
- Directorio: `backend/features/comments/` → `backend/features/social/`
- Package: `package comments` → `package social`
- Imports: `backend/features/comments` → `backend/features/social`
- Referencias de tipos: `comments.ILikeService` → `social.ILikeService`

**Rutas HTTP:** NO CAMBIARON (mantienen `/posts/:id/comments`, etc.)

## Roadmap

### Funcionalidades futuras
- [ ] Reacciones personalizadas (no solo likes)
- [ ] Menciones en comentarios con notificaciones
- [ ] Report/flag de comentarios inapropiados
- [ ] Edición de comentarios con historial
- [ ] Comentarios con media (imágenes/videos)
- [ ] Trending comments algorithm
- [ ] Comment templates/quick replies

### Mejoras de rendimiento
- [ ] Caché de comentarios populares (Redis)
- [ ] Paginación cursor-based para feeds largos
- [ ] Agregación de estadísticas en tiempo real

## Contribuir

Al modificar este módulo:
1. Mantener las interfaces estables
2. Documentar cambios en CHANGELOG.md
3. Agregar tests para nuevas funcionalidades
4. Actualizar este README si es necesario

## Contacto

Para preguntas sobre este módulo, contactar al Backend Team.
