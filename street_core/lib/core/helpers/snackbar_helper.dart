import '../lang/locale_keys.dart';
import '../widgets/my_text.dart';
import 'package:flutter/material.dart';

/// Helper para mostrar SnackBars consistentes en toda la aplicación.
///
/// Proporciona métodos estáticos para mostrar mensajes de éxito, error, info y warning.
///
/// Uso:
/// ```dart
/// SnackBarHelper.showSuccess(context, 'operation.successful');
/// SnackBarHelper.showError(context, 'operation.failed');
/// SnackBarHelper.showInfo(context, 'info.message');
/// SnackBarHelper.showWarning(context, 'warning.message');
/// ```
class SnackBarHelper {
  /// Muestra un SnackBar de éxito (verde).
  ///
  /// - [message]: Clave de traducción del mensaje
  /// - [duration]: Duración de visualización (default: 2 segundos)
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _showSnackBar(
      context,
      message,
      backgroundColor: Colors.green.shade600,
      icon: Icons.check_circle_outline,
      duration: duration,
    );
  }

  /// Muestra un SnackBar de error (rojo).
  ///
  /// - [messageKey]: Clave de traducción del mensaje
  /// - [duration]: Duración de visualización (default: 3 segundos)
  static void showError(
    BuildContext context,
    String messageKey, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _showSnackBar(
      context,
      messageKey,
      backgroundColor: Colors.red.shade600,
      icon: Icons.error_outline,
      duration: duration,
    );
  }

  /// Muestra un SnackBar de error con código del backend (auto-traducido).
  ///
  /// Útil para mostrar errores de HeatError, RepositoryException, etc.
  /// Si el código es nulo, usa el mensaje fallback.
  ///
  /// Ejemplo:
  /// ```dart
  /// if (state is HeatError) {
  ///   SnackBarHelper.showBackendError(
  ///     context,
  ///     errorCode: state.code, // 'heat.already.closed'
  ///     fallbackMessage: state.message,
  ///   );
  /// }
  /// ```
  ///
  /// - [errorCode]: Código de error del backend (se traduce automáticamente)
  /// - [fallbackMessage]: Mensaje fallback si errorCode es nulo
  /// - [duration]: Duración de visualización (default: 4 segundos)
  static void showBackendError(
    BuildContext context, {
    String? errorCode,
    String? fallbackMessage,
    Duration duration = const Duration(seconds: 4),
  }) {
    final messageKey = errorCode ?? fallbackMessage ?? LocaleKeys.error;
    _showSnackBar(
      context,
      messageKey,
      backgroundColor: Colors.red.shade600,
      icon: Icons.error_outline,
      duration: duration,
    );
  }

  /// Muestra un SnackBar de información (azul).
  ///
  /// - [messageKey]: Clave de traducción del mensaje
  /// - [duration]: Duración de visualización (default: 2 segundos)
  static void showInfo(
    BuildContext context,
    String messageKey, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _showSnackBar(
      context,
      messageKey,
      backgroundColor: Colors.blue.shade600,
      icon: Icons.info_outline,
      duration: duration,
    );
  }

  /// Muestra un SnackBar de advertencia (naranja).
  ///
  /// - [messageKey]: Clave de traducción del mensaje
  /// - [duration]: Duración de visualización (default: 3 segundos)
  static void showWarning(
    BuildContext context,
    String messageKey, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _showSnackBar(
      context,
      messageKey,
      backgroundColor: Colors.orange.shade600,
      icon: Icons.warning_amber_rounded,
      duration: duration,
    );
  }

  /// Muestra un SnackBar personalizado sin traducción.
  ///
  /// Útil para mensajes dinámicos o que vienen del servidor.
  ///
  /// - [message]: Texto del mensaje (sin traducir)
  /// - [type]: Tipo de mensaje (success, error, info, warning)
  static void showCustom(
    BuildContext context,
    String message, {
    String? title,
    SnackBarType type = SnackBarType.info,
    Duration? duration,
  }) {
    Color backgroundColor;
    IconData icon;

    switch (type) {
      case SnackBarType.success:
        backgroundColor = Colors.green.shade600;
        icon = Icons.check_circle_outline;
        duration ??= const Duration(seconds: 2);
        break;
      case SnackBarType.error:
        backgroundColor = Colors.red.shade600;
        icon = Icons.error_outline;
        duration ??= const Duration(seconds: 3);
        break;
      case SnackBarType.warning:
        backgroundColor = Colors.orange.shade600;
        icon = Icons.warning_amber_rounded;
        duration ??= const Duration(seconds: 3);
        break;
      case SnackBarType.info:
        backgroundColor = Colors.blue.shade600;
        icon = Icons.info_outline;
        duration ??= const Duration(seconds: 2);
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    MyText(
                      title,
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      noTranslation: true,
                    ),
                  MyText(
                    message,
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    noTranslation: true,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Método interno para mostrar SnackBars con traducción.
  static void _showSnackBar(
    BuildContext context,
    String messageKey, {
    required Color backgroundColor,
    required IconData icon,
    required Duration duration,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: MyText(
                messageKey,

                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        // margin: const EdgeInsets.all(16),
        width: 600,
      ),
    );
  }

  /// Cierra el SnackBar actual si está visible.
  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  /// Limpia todos los SnackBars pendientes.
  static void clearAll(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
  }
}

/// Tipos de SnackBar para el método showCustom.
enum SnackBarType { success, error, warning, info }
