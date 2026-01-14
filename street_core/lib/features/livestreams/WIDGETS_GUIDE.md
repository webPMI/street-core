# Livestreaming Widgets Guide

Biblioteca completa de widgets reutilizables para livestreaming, diseñados para ser modulares, configurables y fáciles de usar.

## Instalación

```dart
import 'package:street_core/features/livestreams/widgets/widgets.dart';
```

---

## 🔴 LiveBadge

Badge "EN VIVO" animado con efecto de pulsación.

### Uso Básico

```dart
// Badge estándar (medium, animado)
LiveBadge()

// Badge compacto (small, sin animación)
LiveBadge.compact()

// Badge grande con animación
LiveBadge.large()

// Personalizado
LiveBadge(
  size: BadgeSize.large,
  animated: true,
  color: Colors.red,
  textColor: Colors.white,
)
```

### Parámetros

- `size`: `BadgeSize.small`, `medium`, `large`
- `animated`: `bool` - pulsación animada
- `color`: Color del badge
- `textColor`: Color del texto

---

## 📺 LiveStreamCard

Tarjeta para mostrar livestreams en listas o grids.

### Uso Básico

```dart
// Grid layout (default)
LiveStreamCard(
  stream: myStream,
  onTap: () => navigateToStream(),
)

// List layout
LiveStreamCard.list(
  stream: myStream,
  onTap: () => navigateToStream(),
)

// Grid layout explícito
LiveStreamCard.grid(
  stream: myStream,
  showHostInfo: true,
  showStats: true,
  onTap: () => navigateToStream(),
)
```

### Características

- ✅ Thumbnail con cache
- ✅ Badge de estado (live, programado, finalizado)
- ✅ Contador de espectadores en vivo
- ✅ Duración para streams finalizados
- ✅ Stats (views, reactions, messages)
- ✅ Layouts responsive (grid/list)

### Ejemplo en GridView

```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    childAspectRatio: 0.75,
    crossAxisSpacing: 8,
    mainAxisSpacing: 8,
  ),
  itemCount: streams.length,
  itemBuilder: (context, index) {
    return LiveStreamCard.grid(
      stream: streams[index],
      onTap: () => navigateToStream(streams[index]),
    );
  },
)
```

---

## ⭐ StreamReactionButton

Botón de reacción individual con animación.

### Uso Básico

```dart
// Botón individual
StreamReactionButton(
  type: ReactionType.heart,
  onTap: () => sendReaction(ReactionType.heart),
)

// Botón compacto (sin label)
StreamReactionButton.compact(
  type: ReactionType.fire,
  onTap: () => sendReaction(ReactionType.fire),
)

// Personalizado
StreamReactionButton(
  type: ReactionType.thumbsup,
  onTap: () => sendReaction(ReactionType.thumbsup),
  showLabel: true,
  size: 60,
  backgroundColor: Colors.white,
)
```

### StreamReactionBar

Barra con todos los botones de reacción.

```dart
// Horizontal
StreamReactionBar(
  onReaction: (type) => sendReaction(type),
)

// Vertical compacta
StreamReactionBar(
  onReaction: (type) => sendReaction(type),
  direction: Axis.vertical,
  isCompact: true,
)

// Reacciones personalizadas
StreamReactionBar(
  onReaction: (type) => sendReaction(type),
  reactions: [
    ReactionType.heart,
    ReactionType.fire,
  ],
)
```

### Tipos de Reacciones

- `ReactionType.heart` ❤️
- `ReactionType.fire` 🔥
- `ReactionType.thumbsup` 👍
- `ReactionType.clap` 👏
- `ReactionType.star` ⭐

---

## ✨ FloatingReactionsOverlay

Overlay con reacciones flotantes animadas.

### Uso Básico

```dart
Stack(
  children: [
    // Tu contenido (video, etc.)
    VideoPlayerWidget(),

    // Overlay de reacciones
    FloatingReactionsOverlay(
      reactions: reactionsList,
    ),
  ],
)
```

### Con Estado

```dart
class StreamPage extends StatefulWidget {
  @override
  State<StreamPage> createState() => _StreamPageState();
}

class _StreamPageState extends State<StreamPage> {
  final List<AnimatedReaction> _reactions = [];

  void _addReaction(ReactionType type) {
    final random = Random();
    setState(() {
      _reactions.add(
        AnimatedReaction(
          type: type,
          x: random.nextDouble() * MediaQuery.of(context).size.width,
          y: MediaQuery.of(context).size.height - 100,
          createdAt: DateTime.now(),
        ),
      );
    });

    // Limpiar reacciones expiradas
    Future.delayed(Duration(seconds: 6), () {
      setState(() {
        _reactions.removeWhere((r) => r.isExpired);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        VideoPlayerWidget(),
        FloatingReactionsOverlay(reactions: _reactions),
        Positioned(
          bottom: 100,
          right: 16,
          child: StreamReactionBar(
            direction: Axis.vertical,
            onReaction: _addReaction,
          ),
        ),
      ],
    );
  }
}
```

### ReactionBurst

Efecto de explosión de reacciones.

```dart
ReactionBurst(
  type: ReactionType.heart,
  count: 5,
  centerX: tapX,
  centerY: tapY,
)
```

---

## 💬 StreamChatBubble

Burbuja de mensaje de chat.

### Uso Básico

```dart
// Burbuja estándar
StreamChatBubble(
  message: chatMessage,
  onLongPress: () => showMessageOptions(),
  onAvatarTap: () => showUserProfile(),
)

// Burbuja compacta
StreamChatBubble.compact(
  message: chatMessage,
)
```

### En ListView

```dart
ListView.builder(
  itemCount: messages.length,
  itemBuilder: (context, index) {
    return StreamChatBubble(
      message: messages[index],
      onLongPress: () => _showMessageOptions(messages[index]),
      onAvatarTap: () => _showUserProfile(messages[index].userId),
    );
  },
)
```

### PinnedMessageBanner

Banner para mensaje fijado.

```dart
Column(
  children: [
    if (pinnedMessage != null)
      PinnedMessageBanner(
        message: pinnedMessage!,
        onTap: () => scrollToMessage(pinnedMessage!),
        onUnpin: () => unpinMessage(),
      ),
    Expanded(
      child: ChatListView(),
    ),
  ],
)
```

---

## ⌨️ StreamChatInput

Input de chat con botón de envío.

### Uso Básico

```dart
// Input estándar
StreamChatInput(
  onSend: (message) => sendMessage(message),
  hintText: 'Escribe un mensaje...',
)

// Con widgets adicionales
StreamChatInput(
  onSend: (message) => sendMessage(message),
  leading: IconButton(
    icon: Icon(Icons.emoji_emotions),
    onPressed: () => showEmojiPicker(),
  ),
  trailing: IconButton(
    icon: Icon(Icons.image),
    onPressed: () => pickImage(),
  ),
)

// Controlado
final controller = TextEditingController();

StreamChatInput(
  controller: controller,
  onSend: (message) {
    sendMessage(message);
    controller.clear();
  },
)
```

### CompactChatInput

Versión minimalista para espacios reducidos.

```dart
CompactChatInput(
  onSend: (message) => sendMessage(message),
  hintText: 'Comentar...',
)
```

---

## 📊 StreamStatsWidget

Widget de estadísticas del stream.

### Uso Básico

```dart
// Desde objeto LiveStream
StreamStatsWidget.fromStream(
  stream: liveStream,
)

// Desde objeto StreamStats
StreamStatsWidget.fromStats(
  stats: streamStats,
)

// Manual
StreamStatsWidget(
  viewerCount: 1234,
  peakViewers: 2500,
  reactionCount: 5000,
  duration: Duration(minutes: 45),
)

// Compacto horizontal
StreamStatsWidget.fromStream(
  stream: liveStream,
  isCompact: true,
)

// Vertical con labels
StreamStatsWidget.fromStream(
  stream: liveStream,
  direction: Axis.vertical,
)
```

### StreamStatsOverlay

Overlay para mostrar stats sobre video.

```dart
Stack(
  children: [
    VideoPlayerWidget(),

    StreamStatsOverlay(
      viewerCount: 1234,
      duration: Duration(minutes: 45),
      position: OverlayPosition.topRight,
    ),
  ],
)
```

### Posiciones del Overlay

- `OverlayPosition.topLeft`
- `OverlayPosition.topRight`
- `OverlayPosition.bottomLeft`
- `OverlayPosition.bottomRight`

---

## 🎮 StreamControlButton

Botones de control del stream.

### Botones Predefinidos

```dart
// Botón de inicio
StreamControlButton.start(
  onPressed: () => startStream(),
  isLoading: isStarting,
)

// Botón de finalizar
StreamControlButton.end(
  onPressed: () => endStream(),
  isLoading: isEnding,
)

// Botón de cancelar
StreamControlButton.cancel(
  onPressed: () => cancelStream(),
)

// Botón de configuración
StreamControlButton.settings(
  onPressed: () => showSettings(),
)

// Botón de compartir
StreamControlButton.share(
  onPressed: () => shareStream(),
)
```

### Botón Personalizado

```dart
StreamControlButton(
  icon: Icons.mic_off,
  label: 'Silenciar',
  onPressed: () => toggleMute(),
  color: Colors.white,
  backgroundColor: Colors.orange,
)
```

### StreamControlBar

Barra con múltiples controles.

```dart
StreamControlBar(
  buttons: [
    StreamControlButton.start(
      onPressed: () => startStream(),
      isLoading: isStarting,
    ),
    StreamControlButton.settings(
      onPressed: () => showSettings(),
    ),
    StreamControlButton.share(
      onPressed: () => shareStream(),
    ),
  ],
  alignment: MainAxisAlignment.spaceEvenly,
  padding: EdgeInsets.all(16),
)
```

### StreamFloatingButton

Floating action button para controles rápidos.

```dart
StreamFloatingButton(
  icon: Icons.videocam,
  onPressed: () => toggleCamera(),
  backgroundColor: Colors.red,
  tooltip: 'Cambiar cámara',
)

// Mini version
StreamFloatingButton(
  icon: Icons.mic,
  onPressed: () => toggleMic(),
  mini: true,
)
```

---

## 🎨 Ejemplo Completo: Página de Livestream

```dart
class LiveStreamPage extends StatefulWidget {
  final String streamId;

  const LiveStreamPage({required this.streamId});

  @override
  State<LiveStreamPage> createState() => _LiveStreamPageState();
}

class _LiveStreamPageState extends State<LiveStreamPage> {
  final List<AnimatedReaction> _reactions = [];
  final List<ChatMessage> _messages = [];
  LiveStream? _stream;
  int _viewerCount = 0;
  Duration _duration = Duration.zero;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Video player
          VideoPlayerWidget(),

          // Floating reactions
          FloatingReactionsOverlay(reactions: _reactions),

          // Top stats overlay
          StreamStatsOverlay(
            viewerCount: _viewerCount,
            duration: _duration,
            position: OverlayPosition.topRight,
          ),

          // Live badge
          Positioned(
            top: 16,
            left: 16,
            child: LiveBadge(),
          ),

          // Chat overlay (bottom half)
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.4,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return StreamChatBubble.compact(
                    message: _messages[index],
                  );
                },
              ),
            ),
          ),

          // Reaction buttons (right side)
          Positioned(
            right: 16,
            bottom: 120,
            child: StreamReactionBar(
              direction: Axis.vertical,
              isCompact: true,
              onReaction: _handleReaction,
            ),
          ),
        ],
      ),

      // Chat input at bottom
      bottomNavigationBar: StreamChatInput(
        onSend: _handleSendMessage,
        leading: IconButton(
          icon: Icon(Icons.emoji_emotions),
          onPressed: _showEmojiPicker,
        ),
      ),
    );
  }

  void _handleReaction(ReactionType type) {
    // Enviar reacción al servidor
    _sendReaction(type);

    // Agregar a overlay
    final random = Random();
    setState(() {
      _reactions.add(
        AnimatedReaction(
          type: type,
          x: random.nextDouble() * MediaQuery.of(context).size.width * 0.7,
          y: MediaQuery.of(context).size.height - 150,
          createdAt: DateTime.now(),
        ),
      );
    });
  }

  void _handleSendMessage(String message) {
    // Enviar mensaje al servidor
    _sendChatMessage(message);
  }
}
```

---

## 🎯 Best Practices

### 1. **Usa Constructores Named**
```dart
// ✅ Bueno
LiveBadge.compact()
LiveStreamCard.list(stream: stream)
StreamControlButton.start(onPressed: start)

// ❌ Evitar constructores largos
LiveBadge(size: BadgeSize.small, animated: false)
```

### 2. **Combina Widgets**
```dart
// Los widgets están diseñados para componerse
Stack(
  children: [
    VideoPlayer(),
    FloatingReactionsOverlay(reactions: reactions),
    StreamStatsOverlay(viewerCount: count),
  ],
)
```

### 3. **Usa Callbacks para Acciones**
```dart
// Los widgets no conocen la lógica de negocio
StreamReactionButton(
  type: ReactionType.heart,
  onTap: () {
    // Tu lógica aquí
    context.read<StreamCubit>().sendReaction(ReactionType.heart);
  },
)
```

### 4. **Limpia Recursos**
```dart
// Reacciones expiran automáticamente
// Pero limpia periódicamente para evitar memory leaks
Timer.periodic(Duration(seconds: 5), (timer) {
  setState(() {
    _reactions.removeWhere((r) => r.isExpired);
  });
});
```

---

## 📦 Dependencias

Estos widgets requieren:

- `cached_network_image: ^3.4.1` ✅ Ya incluido
- `timeago: ^3.7.1` ✅ Ya incluido
- `equatable: ^2.0.7` ✅ Ya incluido

---

## 🔄 Actualización de Estado

Los widgets son **stateless** o tienen estado interno mínimo. Usa BLoC/Cubit para estado compartido:

```dart
class StreamPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StreamCubit, StreamState>(
      builder: (context, state) {
        return Stack(
          children: [
            VideoPlayer(),
            StreamStatsOverlay(
              viewerCount: state.viewerCount, // Del BLoC
              duration: state.duration,       // Del BLoC
            ),
          ],
        );
      },
    );
  }
}
```

---

¡Todos los widgets están listos para usar! 🎉
