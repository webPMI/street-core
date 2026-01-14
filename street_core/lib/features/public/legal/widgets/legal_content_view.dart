import '../../../../../core/helpers/responsive/responsive_builder.dart';
import '../../../../../core/lang/context_tr.dart';
import '../../../../../core/lang/locale_keys.dart';
import '../../../../../core/widgets/my_text.dart';
import '../../../../../core/helpers/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget reutilizable para mostrar contenido legal
///
/// Features:
/// - Renderizado de texto con formato básico
/// - Header con titulo e icono
/// - Botón para copiar enlace
/// - Responsive design
/// - Estado de carga y error
class LegalContentView extends StatelessWidget {

  const LegalContentView({
    super.key,
    required this.titleKey,
    required this.icon,
    this.content,
    this.shareRoute,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.showHeader = true,
  });
  /// Título de la sección (clave de traducción)
  final String titleKey;

  /// Icono de la sección
  final IconData icon;

  /// Contenido texto a mostrar
  final String? content;

  /// Ruta para compartir (deep link)
  final String? shareRoute;

  /// Estado de carga
  final bool isLoading;

  /// Mensaje de error (si hay)
  final String? errorMessage;

  /// Callback para reintentar carga
  final VoidCallback? onRetry;

  /// Mostrar header con acciones
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ResponsiveBuilder(
      builder: (context, device) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            if (showHeader) _buildHeader(context, theme, device),

            // Content
            Expanded(
              child: _buildContent(context, theme, device),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    ResponsiveDevice device,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: device.value(mobile: 16, tablet: 24, desktop: 32),
        vertical: device.value(mobile: 12, tablet: 16, desktop: 20),
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: device.value(mobile: 20, tablet: 24, desktop: 28),
            ),
          ),
          SizedBox(width: device.spacing),

          // Title
          Expanded(
            child: MyText(
              titleKey,
              istitle: true,
            ),
          ),

          // Share button
          if (shareRoute != null)
            IconButton(
              onPressed: () => _copyShareLink(context),
              icon: const Icon(Icons.share_outlined),
              tooltip: context.tr(LocaleKeys.copyLink),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    ResponsiveDevice device,
  ) {
    // Loading state
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Error state
    if (errorMessage != null) {
      return _buildErrorState(context, theme, device);
    }

    // Empty state
    if (content == null || content!.isEmpty) {
      return _buildEmptyState(context, theme, device);
    }

    // Content
    return SingleChildScrollView(
      padding: EdgeInsets.all(
        device.value(mobile: 16, tablet: 24, desktop: 32),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: _buildFormattedContent(context, theme),
        ),
      ),
    );
  }

  Widget _buildFormattedContent(BuildContext context, ThemeData theme) {
    // Procesar el contenido para renderizado básico
    final processedContent = _processContent(content!);

    return SelectableText.rich(
      TextSpan(
        children: _buildTextSpans(processedContent, theme),
      ),
      style: theme.textTheme.bodyLarge?.copyWith(
        height: 1.7,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  /// Procesa el contenido HTML/texto para extraer formato básico
  String _processContent(String text) {
    // Remover tags HTML comunes y convertir a texto
    final processed = text
        // Convertir headers a texto con saltos de línea
        .replaceAllMapped(
          RegExp('<h[1-6][^>]*>(.*?)</h[1-6]>', caseSensitive: false),
          (match) => '\n\n${match.group(1)?.toUpperCase() ?? ""}\n\n',
        )
        // Convertir párrafos
        .replaceAllMapped(
          RegExp('<p[^>]*>(.*?)</p>', caseSensitive: false, dotAll: true),
          (match) => '${match.group(1) ?? ""}\n\n',
        )
        // Convertir saltos de línea
        .replaceAll(RegExp(r'<br\s*/?>'), '\n')
        // Convertir listas
        .replaceAllMapped(
          RegExp('<li[^>]*>(.*?)</li>', caseSensitive: false),
          (match) => '\u2022 ${match.group(1) ?? ""}\n',
        )
        // Remover otros tags HTML
        .replaceAll(RegExp('<[^>]+>'), '')
        // Decodificar entidades HTML comunes
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        // Limpiar espacios múltiples
        .replaceAll(RegExp(' +'), ' ')
        // Limpiar saltos de línea múltiples
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    return processed;
  }

  /// Construye TextSpans con formato básico
  List<TextSpan> _buildTextSpans(String text, ThemeData theme) {
    final spans = <TextSpan>[];
    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Detectar si es un título (todo mayúsculas y corto)
      final isTitle = line.length < 100 &&
          line.trim().isNotEmpty &&
          line == line.toUpperCase() &&
          !line.startsWith('\u2022');

      // Detectar si es un bullet point
      final isBullet = line.trim().startsWith('\u2022');

      if (isTitle) {
        spans.add(TextSpan(
          text: '$line\n',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: theme.colorScheme.onSurface,
            height: 2,
          ),
        ));
      } else if (isBullet) {
        spans.add(TextSpan(
          text: '$line\n',
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ));
      } else {
        spans.add(TextSpan(
          text: i < lines.length - 1 ? '$line\n' : line,
        ));
      }
    }

    return spans;
  }

  Widget _buildEmptyState(
    BuildContext context,
    ThemeData theme,
    ResponsiveDevice device,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(
            device.value(mobile: 24, tablet: 32, desktop: 48)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            MyText(
              LocaleKeys.noContentAvailable,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    ThemeData theme,
    ResponsiveDevice device,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(
            device.value(mobile: 24, tablet: 32, desktop: 48)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            MyText(
              errorMessage!,
              color: theme.colorScheme.error,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const MyText(LocaleKeys.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _copyShareLink(BuildContext context) {
    if (shareRoute == null) return;

    // Construir URL completa (en producción sería el dominio real)
    final url = 'https://fitriders.app$shareRoute';

    Clipboard.setData(ClipboardData(text: url));

    SnackBarHelper.showInfo(context, LocaleKeys.linkCopied);
  }
}
