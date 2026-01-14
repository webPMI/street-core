# Livestreaming Module

Sistema completo de livestreaming en tiempo real con chat, reacciones y estadísticas.

## 🏗️ Arquitectura

```
features/livestreams/
├── models/                 # Modelos de datos
│   ├── livestream.dart         - LiveStream, JoinStreamResponse, StreamStats
│   ├── chat_message.dart       - ChatMessage
│   ├── stream_reaction.dart    - StreamReaction, ReactionType
│   ├── stream_viewer.dart      - StreamViewer
│   └── models.dart             - Barrel file
│
├── services/               # Servicios
│   ├── livestream_service.dart         - API REST service
│   └── livestream_socket_service.dart  - WebSocket service (Socket.IO)
│
├── bloc/                   # State Management
│   ├── livestream_state.dart           - Estados del stream
│   ├── livestream_cubit.dart           - Cubit principal
│   ├── livestream_chat_cubit.dart      - Cubit de chat
│   └── livestream_reactions_cubit.dart - Cubit de reacciones
│
├── widgets/                # Widgets reutilizables
│   ├── live_badge.dart                 - Badge "EN VIVO"
│   ├── live_stream_card.dart           - Tarjeta de stream
│   ├── stream_reaction_button.dart     - Botones de reacción
│   ├── floating_reactions_overlay.dart - Reacciones flotantes
│   ├── stream_chat_bubble.dart         - Burbujas de chat
│   ├── stream_chat_input.dart          - Input de chat
│   ├── stream_stats_widget.dart        - Estadísticas
│   ├── stream_control_button.dart      - Controles
│   └── widgets.dart                    - Barrel file
│
├── pages/                  # Páginas
│   ├── live_streams_list_page.dart     - Lista de streams
│   ├── livestream_viewer_page.dart     - Ver stream
│   ├── create_livestream_page.dart     - Crear stream
│   └── pages.dart                      - Barrel file
│
├── WIDGETS_GUIDE.md        # Guía de widgets
└── README.md               # Este archivo
```

## 🚀 Quick Start

### 1. Importar el módulo

```dart
import 'package:street_core/features/livestreams/pages/pages.dart';
import 'package:street_core/features/livestreams/widgets/widgets.dart';
import 'package:street_core/features/livestreams/models/models.dart';
```

### 2. Configurar rutas

```dart
GoRoute(
  path: '/livestreams',
  builder: (context, state) => const LiveStreamsListPage(),
),
GoRoute(
  path: '/livestreams/view',
  builder: (context, state) {
    final streamId = state.extra as String;
    return LiveStreamViewerPage(streamId: streamId);
  },
),
GoRoute(
  path: '/livestreams/create',
  builder: (context, state) => const CreateLiveStreamPage(),
),
```

### 3. Usar en la app

```dart
// Navegar a lista de streams
Navigator.pushNamed(context, '/livestreams');

// Ver un stream específico
Navigator.pushNamed(
  context,
  '/livestreams/view',
  arguments: streamId,
);

// Crear nuevo stream
Navigator.pushNamed(context, '/livestreams/create');
```

## 📡 Backend API

### Endpoints Implementados

#### Streams
- `GET /livestreams/live` - Streams en vivo
- `GET /livestreams/scheduled` - Streams programados
- `GET /livestreams/my-streams` - Streams del usuario
- `GET /livestreams/search?q=query` - Buscar streams
- `GET /livestreams/:id` - Obtener stream
- `POST /livestreams` - Crear stream
- `PATCH /livestreams/:id` - Actualizar stream
- `DELETE /livestreams/:id` - Eliminar stream

#### Lifecycle
- `POST /livestreams/:id/start` - Iniciar stream
- `POST /livestreams/:id/end` - Finalizar stream
- `POST /livestreams/:id/cancel` - Cancelar stream

#### Viewer
- `POST /livestreams/:id/join` - Unirse como espectador
- `POST /livestreams/:id/leave` - Salir del stream
- `GET /livestreams/:id/viewers` - Lista de espectadores

#### Chat
- `POST /livestreams/:id/chat` - Enviar mensaje
- `GET /livestreams/:id/chat` - Obtener mensajes

#### Reactions
- `POST /livestreams/:id/react` - Enviar reacción

#### Stats
- `GET /livestreams/:id/stats` - Estadísticas

### Socket.IO Events

#### Client → Server
- `join_stream` - Unirse a stream
- `leave_stream` - Salir de stream
- `chat_message` - Enviar mensaje
- `reaction` - Enviar reacción

#### Server → Client
- `chat_message` - Nuevo mensaje
- `reaction` - Nueva reacción
- `viewer_count` - Actualización de espectadores
- `stream_status` - Cambio de estado
- `user_joined` - Usuario se unió
- `user_left` - Usuario salió

## 🎨 Widgets

### LiveBadge
```dart
LiveBadge()              // Estándar animado
LiveBadge.compact()      // Compacto
LiveBadge.large()        // Grande
```

### LiveStreamCard
```dart
LiveStreamCard.grid(
  stream: stream,
  onTap: () => navigate(),
)

LiveStreamCard.list(
  stream: stream,
  onTap: () => navigate(),
)
```

### StreamReactionButton & Bar
```dart
StreamReactionButton(
  type: ReactionType.heart,
  onTap: () => send(),
)

StreamReactionBar(
  onReaction: (type) => send(type),
  direction: Axis.vertical,
)
```

### FloatingReactionsOverlay
```dart
FloatingReactionsOverlay(
  reactions: reactionsList,
)
```

### StreamChatBubble
```dart
StreamChatBubble(
  message: message,
  onLongPress: () => showOptions(),
)
```

### StreamChatInput
```dart
StreamChatInput(
  onSend: (msg) => send(msg),
)
```

### StreamStatsWidget
```dart
StreamStatsWidget.fromStream(stream: stream)
StreamStatsWidget.fromStats(stats: stats)
```

Ver `WIDGETS_GUIDE.md` para más ejemplos.

## 🔄 State Management (BLoC)

### LiveStreamCubit

Maneja el estado general del stream.

```dart
// Unirse como espectador
context.read<LiveStreamCubit>().joinStream(streamId);

// Cargar como host
context.read<LiveStreamCubit>().loadStreamAsHost(streamId);

// Iniciar stream
context.read<LiveStreamCubit>().startStream(streamId);

// Finalizar stream
context.read<LiveStreamCubit>().endStream(saveRecording: true);

// Salir del stream
context.read<LiveStreamCubit>().leaveStream();
```

### LiveStreamChatCubit

Maneja el chat en tiempo real.

```dart
// Inicializar
context.read<LiveStreamChatCubit>().initialize();

// Enviar mensaje
context.read<LiveStreamChatCubit>().sendMessage(message);

// Cargar más mensajes
context.read<LiveStreamChatCubit>().loadMore();
```

### LiveStreamReactionsCubit

Maneja reacciones animadas.

```dart
// Enviar reacción
context.read<LiveStreamReactionsCubit>().sendReaction(ReactionType.heart);

// Limpiar reacciones
context.read<LiveStreamReactionsCubit>().clearReactions();
```

## 🎯 Ejemplo Completo

```dart
class MyStreamPage extends StatelessWidget {
  final String streamId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => LiveStreamCubit(
            service: getIt<LiveStreamService>(),
            socketService: getIt<LiveStreamSocketService>(),
          )..joinStream(streamId),
        ),
        BlocProvider(
          create: (context) => LiveStreamChatCubit(
            service: getIt<LiveStreamService>(),
            socketService: getIt<LiveStreamSocketService>(),
            streamId: streamId,
          )..initialize(),
        ),
        BlocProvider(
          create: (context) => LiveStreamReactionsCubit(
            service: getIt<LiveStreamService>(),
            socketService: getIt<LiveStreamSocketService>(),
            streamId: streamId,
            screenWidth: MediaQuery.of(context).size.width,
            screenHeight: MediaQuery.of(context).size.height,
          ),
        ),
      ],
      child: Scaffold(
        body: Stack(
          children: [
            // Video
            AgoraVideoPlayer(),

            // Reacciones
            BlocBuilder<LiveStreamReactionsCubit, LiveStreamReactionsState>(
              builder: (context, state) {
                return FloatingReactionsOverlay(
                  reactions: state.reactions,
                );
              },
            ),

            // Chat
            BlocBuilder<LiveStreamChatCubit, LiveStreamChatState>(
              builder: (context, state) {
                if (state is LiveStreamChatLoaded) {
                  return ListView.builder(
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      return StreamChatBubble.compact(
                        message: state.messages[index],
                      );
                    },
                  );
                }
                return SizedBox.shrink();
              },
            ),

            // Botones de reacción
            StreamReactionBar(
              onReaction: (type) {
                context.read<LiveStreamReactionsCubit>().sendReaction(type);
              },
            ),
          ],
        ),
        bottomNavigationBar: StreamChatInput(
          onSend: (msg) {
            context.read<LiveStreamChatCubit>().sendMessage(msg);
          },
        ),
      ),
    );
  }
}
```

## 🔧 Configuración

### Backend (.env)

```env
# Agora RTC
AGORA_APP_ID=your_32_char_app_id
AGORA_APP_CERTIFICATE=your_32_char_certificate
AGORA_VIEWER_TOKEN_EXP_HOURS=24
AGORA_HOST_TOKEN_EXP_HOURS=48

# Cloud Recording (opcional)
AGORA_RECORDING_ENABLED=false
AGORA_RECORDING_BUCKET=
AGORA_RECORDING_REGION=
```

### Frontend (pubspec.yaml)

```yaml
dependencies:
  # Ya incluidas:
  flutter_bloc: ^9.1.1
  socket_io_client: ^2.0.3+1
  cached_network_image: ^3.4.1
  timeago: ^3.7.1
  equatable: ^2.0.7

  # Por agregar:
  agora_rtc_engine: ^6.3.2      # Video streaming
  permission_handler: ^11.3.1   # Permisos
  wakelock_plus: ^1.2.8         # Mantener pantalla encendida
```

## 📋 Próximos Pasos

### 1. Integración Agora RTC ⏳

```dart
// Placeholder actual en viewer_page.dart
_buildVideoPlaceholder(state)

// Reemplazar con:
AgoraVideoView(
  controller: VideoViewController(
    rtcEngine: _engine,
    canvas: VideoCanvas(uid: joinResponse.uid),
  ),
)
```

### 2. Dependency Injection

Configurar GetIt:

```dart
// Setup DI
getIt.registerLazySingleton(() => ApiService());
getIt.registerLazySingleton(() => LiveStreamService(getIt()));
getIt.registerLazySingleton(() => LiveStreamSocketService(getIt()));

// Usar en páginas
final service = getIt<LiveStreamService>();
```

### 3. Permisos

```dart
// Solicitar permisos antes de transmitir
await Permission.camera.request();
await Permission.microphone.request();
```

### 4. Backend Socket.IO

Implementar servidor Socket.IO en Go/Node.js:

```javascript
io.on('connection', (socket) => {
  socket.on('join_stream', ({ stream_id }) => {
    socket.join(stream_id);
    io.to(stream_id).emit('user_joined', { username: socket.username });
  });

  socket.on('chat_message', ({ stream_id, message }) => {
    io.to(stream_id).emit('chat_message', {
      id: generateId(),
      stream_id,
      user_id: socket.userId,
      username: socket.username,
      message,
      created_at: new Date(),
    });
  });
});
```

## ✅ Features Implementadas

- ✅ Modelos completos (LiveStream, Chat, Reactions, Viewers)
- ✅ API REST service
- ✅ Socket.IO service (tiempo real)
- ✅ BLoC/Cubit state management
- ✅ 8+ widgets reutilizables
- ✅ 3 páginas completas
- ✅ Documentación extensiva
- ⏳ Integración Agora RTC (placeholder)
- ⏳ Backend Socket.IO server
- ⏳ Testing

## 📚 Documentación

- `WIDGETS_GUIDE.md` - Guía completa de widgets (400+ líneas)
- `README.md` - Este archivo
- Comentarios inline en código

## 🎉 Resumen

Sistema completo de livestreaming con:
- 🎥 Video streaming (Agora RTC ready)
- 💬 Chat en tiempo real (Socket.IO)
- ⭐ Reacciones animadas
- 📊 Estadísticas en tiempo real
- 🎨 8+ widgets reutilizables
- 🏗️ Arquitectura limpia y modular
- 📱 UI responsive
- ⚡ Optimizado para performance

**Todo listo para integrar Agora y empezar a transmitir!** 🚀
