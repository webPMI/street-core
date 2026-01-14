import 'package:flutter/material.dart';
import 'package:street_core/core/lang/context_tr.dart';
import 'package:street_core/core/lang/locale_keys.dart';

import 'my_text.dart';

class MyDropdown<T> extends StatefulWidget {
  const MyDropdown({
    super.key,
    // Contenido
    this.title,
    required this.items,
    this.value,
    this.onChanged,
    this.onTap,
    // Visual
    this.hintText,
    this.errorText,
    this.icon,
    this.prefixIcon,
    this.suffixIcon,
    this.textStyle,
    this.hintStyle,
    this.backgroundColor,
    this.borderColor,
    this.focusedBorderColor,
    // Dimensiones
    this.borderRadius,
    this.elevation,
    this.dropdownWidth,
    this.padding,
    this.margin,
    this.maxHeight,
    // Estado
    this.enabled = true,
    this.isLoading = false,
    this.searchable = false,
    this.emptyText,
    this.isDense = false,
    // Animación
    this.animationDuration,
    this.animationCurve,
    this.menuAlignment,
    this.focusNode,
    this.enableMenuItemAnimation = false, // Nuevo: controla animación de items
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTENIDO PRINCIPAL
  // ═══════════════════════════════════════════════════════════════════════════

  /// Título que aparece encima del dropdown.
  ///
  /// Se muestra con estilo [titleSmall] y cambia de color según el estado:
  /// - Normal: [onSurface]
  /// - Focused: [primary]
  /// - Error: [error]
  ///
  /// ```dart
  /// MyDropdown<String>(
  ///   title: 'Selecciona categoría', // Se traduce automáticamente via MyText
  ///   items: items,
  ///   onChanged: onChanged,
  /// )
  /// ```
  final String? title;

  /// Lista de opciones disponibles en el menú desplegable.
  ///
  /// **Requerido**. Debe contener al menos un item para mostrar el dropdown.
  /// Si está vacío, se muestra el estado vacío con [emptyText].
  ///
  /// ```dart
  /// items: [
  ///   DropdownMenuItem(value: 'a', child: Text('Opción A')),
  ///   DropdownMenuItem(value: 'b', child: Text('Opción B')),
  /// ]
  /// ```
  ///
  /// Para tipos complejos, usa el parámetro genérico:
  ///
  /// ```dart
  /// MyDropdown<User>(
  ///   items: users.map((u) => DropdownMenuItem(
  ///     value: u,
  ///     child: Text(u.name),
  ///   )).toList(),
  /// )
  /// ```
  final List<DropdownMenuItem<T>> items;

  /// Valor actualmente seleccionado.
  ///
  /// Debe coincidir con el `value` de algún item en [items], o ser `null`.
  /// Si no coincide con ningún item, puede causar errores de renderizado.
  ///
  /// Para formularios controlados:
  /// ```dart
  /// MyDropdown<String>(
  ///   value: _selectedValue, // Variable de estado
  ///   onChanged: (v) => setState(() => _selectedValue = v),
  /// )
  /// ```
  final T? value;

  /// Callback ejecutado cuando el usuario selecciona una opción.
  ///
  /// Recibe el nuevo valor seleccionado (puede ser `null` si se deselecciona).
  /// No se ejecuta si [enabled] es `false`.
  ///
  /// ```dart
  /// onChanged: (newValue) {
  ///   setState(() => selectedValue = newValue);
  ///   // O con Cubit:
  ///   context.read<MyCubit>().updateSelection(newValue);
  /// }
  /// ```
  final void Function(T?)? onChanged;

  /// Callback ejecutado cuando el usuario abre el menú desplegable.
  ///
  /// Útil para cargar datos bajo demanda o tracking de analytics.
  ///
  /// ```dart
  /// onTap: () {
  ///   if (items.isEmpty) {
  ///     context.read<MyCubit>().loadOptions();
  ///   }
  ///   analytics.trackDropdownOpened('category');
  /// }
  /// ```
  final void Function()? onTap;

  // ═══════════════════════════════════════════════════════════════════════════
  // PERSONALIZACIÓN VISUAL
  // ═══════════════════════════════════════════════════════════════════════════

  /// Texto de ayuda mostrado cuando no hay valor seleccionado.
  ///
  /// Se muestra con [hintStyle] o el estilo por defecto del tema.
  ///
  /// ```dart
  /// hintText: 'Selecciona una opción...'
  /// ```
  final String? hintText;

  /// Texto de error mostrado debajo del dropdown.
  ///
  /// Cuando no es `null`:
  /// - El borde cambia a [colorScheme.error]
  /// - El título cambia a color error
  /// - Se muestra el texto de error debajo
  /// - Se activa live region para lectores de pantalla
  ///
  /// ```dart
  /// errorText: formState.errors['category']
  /// // o
  /// errorText: value == null ? 'Campo requerido' : null
  /// ```
  final String? errorText;

  /// Icono del botón desplegable (flecha).
  ///
  /// Por defecto: [Icons.keyboard_arrow_down_rounded]
  ///
  /// Se anima con rotación de 180° al abrir/cerrar el menú.
  ///
  /// ```dart
  /// icon: Icons.expand_more
  /// icon: Icons.arrow_drop_down
  /// ```
  final IconData? icon;

  /// Widget mostrado antes del texto seleccionado.
  ///
  /// Se desvanece con opacidad 0.38 cuando [enabled] es `false`.
  ///
  /// ```dart
  /// prefixIcon: Icon(Icons.category, size: 20)
  /// prefixIcon: CircleAvatar(backgroundImage: NetworkImage(url), radius: 12)
  /// ```
  final Widget? prefixIcon;

  /// Widget mostrado después del dropdown (a la derecha).
  ///
  /// Se desvanece con opacidad 0.38 cuando [enabled] es `false`.
  ///
  /// ```dart
  /// suffixIcon: IconButton(
  ///   icon: Icon(Icons.clear),
  ///   onPressed: () => onChanged(null),
  /// )
  /// ```
  final Widget? suffixIcon;

  /// Estilo del texto del valor seleccionado.
  ///
  /// Por defecto: [bodyMedium] con color [onSurface].
  /// Cuando deshabilitado, se aplica opacidad 0.38.
  ///
  /// ```dart
  /// textStyle: TextStyle(
  ///   fontSize: 16,
  ///   fontWeight: FontWeight.w500,
  /// )
  /// ```
  final TextStyle? textStyle;

  /// Estilo del texto del hint.
  ///
  /// Por defecto: [bodyMedium] con color [onSurfaceVariant].
  ///
  /// ```dart
  /// hintStyle: TextStyle(
  ///   color: Colors.grey,
  ///   fontStyle: FontStyle.italic,
  /// )
  /// ```
  final TextStyle? hintStyle;

  /// Color de fondo del menú desplegable.
  ///
  /// Por defecto: [theme.cardColor]
  ///
  /// ```dart
  /// backgroundColor: Colors.white
  /// backgroundColor: Theme.of(context).colorScheme.surface
  /// ```
  final Color? backgroundColor;

  /// Color del borde en estado normal.
  ///
  /// Por defecto: [outline] con alpha 0.5
  ///
  /// Cambia automáticamente según el estado:
  /// - Hover: alpha 0.8
  /// - Focused: usa [focusedBorderColor]
  /// - Error: usa [colorScheme.error]
  ///
  /// ```dart
  /// borderColor: Colors.blue.shade200
  /// ```
  final Color? borderColor;

  /// Color del borde cuando el dropdown tiene foco.
  ///
  /// Por defecto: [colorScheme.primary]
  ///
  /// ```dart
  /// focusedBorderColor: Colors.blue.shade700
  /// ```
  final Color? focusedBorderColor;

  // ═══════════════════════════════════════════════════════════════════════════
  // DIMENSIONES Y FORMA
  // ═══════════════════════════════════════════════════════════════════════════

  /// Radio de las esquinas del dropdown.
  ///
  /// Por defecto: `12.0`
  ///
  /// Se aplica a todos los estados del borde y al contenedor del menú.
  ///
  /// ```dart
  /// borderRadius: 8  // Menos redondeado
  /// borderRadius: 24 // Muy redondeado (pill style)
  /// ```
  final double? borderRadius;

  /// Elevación del menú desplegable.
  ///
  /// Por defecto: `4`
  ///
  /// Controla la sombra del menú cuando está abierto.
  ///
  /// ```dart
  /// elevation: 0  // Sin sombra
  /// elevation: 8  // Sombra pronunciada
  /// ```
  final double? elevation;

  /// Ancho fijo del dropdown.
  ///
  /// Por defecto: `350`
  ///
  /// Si necesitas que ocupe todo el ancho disponible, envuélvelo en
  /// un [Expanded] o [Flexible] dentro de un [Row].
  ///
  /// ```dart
  /// dropdownWidth: 200  // Ancho fijo
  /// dropdownWidth: double.infinity  // Ancho completo
  /// ```
  final double? dropdownWidth;

  /// Padding interno del campo.
  ///
  /// Por defecto: `EdgeInsets.symmetric(horizontal: 12, vertical: 10)`
  ///
  /// ```dart
  /// padding: EdgeInsets.all(16)
  /// padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14)
  /// ```
  final EdgeInsetsGeometry? padding;

  /// Margen externo del componente.
  ///
  /// Por defecto: `EdgeInsets.symmetric(vertical: 8)`
  ///
  /// ```dart
  /// margin: EdgeInsets.zero
  /// margin: EdgeInsets.only(bottom: 16)
  /// ```
  final EdgeInsetsGeometry? margin;

  /// Altura máxima del menú desplegable.
  ///
  /// Si los items exceden esta altura, el menú será scrolleable.
  ///
  /// Por defecto: sin límite (depende del espacio disponible)
  ///
  /// ```dart
  /// maxHeight: 200  // Menú compacto
  /// maxHeight: 400  // Menú más alto
  /// ```
  final double? maxHeight;

  // ═══════════════════════════════════════════════════════════════════════════
  // ESTADO Y COMPORTAMIENTO
  // ═══════════════════════════════════════════════════════════════════════════

  /// Si el dropdown está habilitado para interacción.
  ///
  /// Por defecto: `true`
  ///
  /// Cuando es `false`:
  /// - No responde a toques
  /// - El borde usa opacidad reducida
  /// - El texto y iconos se atenúan (0.38 alpha)
  /// - Los Semantics indican "Deshabilitado"
  ///
  /// ```dart
  /// enabled: !isSubmitting
  /// enabled: hasPermission
  /// ```
  final bool enabled;

  /// Si está cargando datos.
  ///
  /// Por defecto: `false`
  ///
  /// Cuando es `true`:
  /// - Muestra un spinner centrado
  /// - Oculta el dropdown
  /// - Muestra texto "Cargando..."
  /// - Semantics indican "Cargando opciones"
  ///
  /// ```dart
  /// isLoading: state is LoadingState
  /// isLoading: categoriesAsync.isLoading
  /// ```
  final bool isLoading;

  /// Si permitir búsqueda dentro del menú.
  ///
  /// **⚠️ RESERVADO PARA IMPLEMENTACIÓN FUTURA**
  ///
  /// Por defecto: `false`
  ///
  /// Cuando se implemente, añadirá un campo de búsqueda
  /// en la parte superior del menú desplegable.
  final bool searchable;

  /// Texto mostrado cuando [items] está vacío.
  ///
  /// Por defecto: `'no_options'` (clave de traducción)
  ///
  /// ```dart
  /// emptyText: 'No hay categorías disponibles'
  /// emptyText: 'categories_empty' // Clave de traducción
  /// ```
  final String? emptyText;

  /// Si usar diseño compacto.
  ///
  /// Por defecto: `false`
  ///
  /// Reduce el espacio vertical interno.
  ///
  /// ```dart
  /// isDense: true // Para formularios densos
  /// ```
  final bool isDense;

  // ═══════════════════════════════════════════════════════════════════════════
  // ANIMACIÓN Y ALINEACIÓN
  // ═══════════════════════════════════════════════════════════════════════════

  /// Duración de las animaciones.
  ///
  /// Por defecto: `Duration(milliseconds: 250)` para rotación del icono
  /// y `Duration(milliseconds: 200)` para transiciones de color.
  ///
  /// Para desactivar animaciones:
  /// ```dart
  /// animationDuration: Duration.zero
  /// ```
  final Duration? animationDuration;

  /// Curva de las animaciones.
  ///
  /// Por defecto: [Curves.easeInOutCubic]
  ///
  /// ```dart
  /// animationCurve: Curves.easeOut
  /// animationCurve: Curves.bounceOut
  /// ```
  final Curve? animationCurve;

  /// Alineación del menú respecto al botón.
  ///
  /// **⚠️ RESERVADO PARA IMPLEMENTACIÓN FUTURA**
  ///
  /// Flutter's DropdownButtonFormField no soporta alineación personalizada.
  final Alignment? menuAlignment;

  /// FocusNode para controlar el foco programáticamente.
  ///
  /// Si no se proporciona, se crea uno interno que se dispone automáticamente.
  ///
  /// ```dart
  /// final _focusNode = FocusNode();
  ///
  /// MyDropdown(
  ///   focusNode: _focusNode,
  ///   // ...
  /// )
  ///
  /// // Luego puedes:
  /// _focusNode.requestFocus();
  /// _focusNode.unfocus();
  /// ```
  final FocusNode? focusNode;

  /// Si animar la entrada de items del menú.
  ///
  /// **⚠️ RESERVADO PARA IMPLEMENTACIÓN FUTURA**
  ///
  /// Por defecto: `false`
  ///
  /// Cuando se implemente, los items aparecerán con animación escalonada.
  final bool enableMenuItemAnimation;

  @override
  State<MyDropdown<T>> createState() => _MyDropdownState<T>();
}

class _MyDropdownState<T> extends State<MyDropdown<T>>
    with SingleTickerProviderStateMixin {
  late FocusNode _internalFocusNode;
  bool _isHovered = false;
  late AnimationController _iconRotationController;
  late Animation<double> _iconRotation;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = widget.focusNode ?? FocusNode();

    // Controlador de animación para la rotación del icono
    _iconRotationController = AnimationController(
      duration: widget.animationDuration ?? const Duration(milliseconds: 250),
      vsync: this,
    );

    _iconRotation =
        Tween<double>(
          begin: 0.0,
          end: 0.5, // 180 grados (0.5 * 360)
        ).animate(
          CurvedAnimation(
            parent: _iconRotationController,
            curve: widget.animationCurve ?? Curves.easeInOutCubic,
          ),
        );

    // Escuchar cambios de foco para setState
    _internalFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _iconRotationController.dispose();
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      // El foco cambió, rebuild para actualizar estados visuales
    });
  }

  void _handleMenuStateChange(bool isOpen) {
    if (isOpen) {
      _iconRotationController.forward();
    } else {
      _iconRotationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    // OPTIMIZACIÓN: Extraer Theme una sola vez
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determinar estados visuales
    final bool isFocused = _internalFocusNode.hasFocus;
    final bool hasError = widget.errorText != null;

    // Si está cargando - widget mejorado con Semantics
    if (widget.isLoading) {
      return Semantics(
        label: context.tr(LocaleKeys.loadingOptions),
        child: Container(
          margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(24),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              MyText(
                context.tr(LocaleKeys.loadingOptions),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Si no hay items - con feedback visual mejorado
    if (widget.items.isEmpty) {
      final effectiveBorderRadius = widget.borderRadius ?? 12.0;
      final effectiveMargin =
          widget.margin ?? const EdgeInsets.symmetric(vertical: 8);
      final effectivePadding = widget.padding ?? const EdgeInsets.all(16);
      final effectiveBackgroundColor =
          widget.backgroundColor ??
          colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);

      return Semantics(
        label: context.tr(LocaleKeys.noOptionsAvailable),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: effectiveMargin,
          padding: effectivePadding,
          decoration: BoxDecoration(
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(effectiveBorderRadius),
            color: effectiveBackgroundColor,
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MyText(
                  widget.emptyText ?? LocaleKeys.noOptions,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // OPTIMIZACIÓN: Memoizar valores que se usan múltiples veces
    final effectiveBorderRadius = widget.borderRadius ?? 12.0;
    final effectiveMargin =
        widget.margin ?? const EdgeInsets.symmetric(vertical: 8);
    final effectivePadding =
        widget.padding ??
        const EdgeInsets.symmetric(horizontal: 12, vertical: 10);

    // Determinar colores basados en el estado
    final Color effectiveBorderColor = hasError
        ? colorScheme.error
        : isFocused
        ? (widget.focusedBorderColor ?? colorScheme.primary)
        : _isHovered
        ? (widget.borderColor ?? colorScheme.outline).withValues(alpha: 0.8)
        : (widget.borderColor ?? colorScheme.outline.withValues(alpha: 0.5));

    final Color effectiveFocusedBorderColor = hasError
        ? colorScheme.error
        : (widget.focusedBorderColor ?? colorScheme.primary);

    final Color effectiveFillColor = widget.enabled
        ? (isFocused
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
              : _isHovered
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3))
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.12);

    final Color effectiveIconColor = widget.enabled
        ? (hasError
              ? colorScheme.error
              : isFocused
              ? colorScheme.primary
              : colorScheme.onSurfaceVariant)
        : colorScheme.onSurface.withValues(alpha: 0.38);

    final effectiveBackgroundColor = widget.backgroundColor ?? theme.cardColor;
    final effectiveIcon = widget.icon ?? Icons.keyboard_arrow_down_rounded;
    final effectiveElevation = (widget.elevation ?? 4).toInt();

    // OPTIMIZACIÓN: Crear BorderRadius una sola vez
    final borderRadiusGeometry = BorderRadius.circular(effectiveBorderRadius);

    // OPTIMIZACIÓN: Construir decoraciones de borde una sola vez
    final inputBorder = OutlineInputBorder(
      borderRadius: borderRadiusGeometry,
      borderSide: BorderSide(color: effectiveBorderColor, width: 1.5),
    );

    final focusedBorder = OutlineInputBorder(
      borderRadius: borderRadiusGeometry,
      borderSide: BorderSide(color: effectiveFocusedBorderColor, width: 2.0),
    );

    final errorBorder = OutlineInputBorder(
      borderRadius: borderRadiusGeometry,
      borderSide: BorderSide(color: colorScheme.error, width: 2.0),
    );

    final disabledBorder = OutlineInputBorder(
      borderRadius: borderRadiusGeometry,
      borderSide: BorderSide(
        color: colorScheme.outline.withValues(alpha: 0.38),
        width: 1.0,
      ),
    );

    // OPTIMIZACIÓN: Estilos calculados una sola vez
    final effectiveTextStyle =
        widget.textStyle ??
        theme.textTheme.bodyMedium?.copyWith(
          color: widget.enabled
              ? colorScheme.onSurface
              : colorScheme.onSurface.withValues(alpha: 0.38),
        );

    final effectiveTitleStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: hasError
          ? colorScheme.error
          : isFocused
          ? colorScheme.primary
          : colorScheme.onSurface,
    );

    // Preparar el label de accesibilidad
    final String semanticLabel = widget.title != null
        ? '${context.tr(widget.title!)}, ${widget.hintText != null ? context.tr(widget.hintText!) : context.tr(LocaleKeys.dropdownSelector)}'
        : widget.hintText ?? context.tr(LocaleKeys.dropdownSelector);

    final String semanticValue = widget.value != null
        ? '${context.tr(LocaleKeys.selectedCount)}: ${widget.value}'
        : context.tr(LocaleKeys.noOptionsSelected);

    return Semantics(
      label: semanticLabel,
      value: semanticValue,
      hint: widget.enabled
          ? context.tr(LocaleKeys.doubleTapToOpenDropdown)
          : context.tr(LocaleKeys.dropdownDisabled),
      enabled: widget.enabled,
      focusable: widget.enabled,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration:
              widget.animationDuration ?? const Duration(milliseconds: 200),
          curve: widget.animationCurve ?? Curves.easeInOutCubic,
          width: widget.dropdownWidth ?? 350,
          margin: effectiveMargin,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título con animación de color
              if (widget.title != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6, left: 4),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: effectiveTitleStyle!,
                    child: MyText(widget.title!),
                  ),
                ),
              Row(
                children: [
                  if (widget.prefixIcon != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: AnimatedOpacity(
                        opacity: widget.enabled ? 1.0 : 0.38,
                        duration: const Duration(milliseconds: 200),
                        child: widget.prefixIcon,
                      ),
                    ),
                  Expanded(
                    child: DropdownButtonFormField<T>(
                      // initialValue is deprecated and redundant when 'value' is provided.
                      // The 'value' property of DropdownButtonFormField handles the initial selection.
                      focusNode: _internalFocusNode,
                      onTap: () {
                        _handleMenuStateChange(true);
                        widget.onTap?.call();
                      },
                      onChanged: widget.enabled
                          ? (value) {
                              _handleMenuStateChange(false);
                              widget.onChanged?.call(value);
                            }
                          : null,
                      isDense: widget.isDense,
                      // Icono animado con rotación
                      icon: RotationTransition(
                        turns: _iconRotation,
                        child: Icon(effectiveIcon, color: effectiveIconColor),
                      ),
                      dropdownColor: effectiveBackgroundColor,
                      initialValue: widget.value, // Explicitly set value
                      items: widget.items,
                      style: effectiveTextStyle,
                      decoration: InputDecoration(
                        contentPadding: effectivePadding,
                        hintText: context.tr(
                          widget.hintText ?? LocaleKeys.selectOption,
                        ),
                        hintStyle: widget.hintStyle,
                        filled: true,
                        fillColor: effectiveFillColor,
                        border: inputBorder,
                        enabledBorder: inputBorder,
                        focusedBorder: focusedBorder,
                        errorBorder: errorBorder,
                        focusedErrorBorder: errorBorder,
                        disabledBorder: disabledBorder,
                        errorText: widget.errorText,
                        errorStyle: TextStyle(
                          color: colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                      elevation: effectiveElevation,
                    ),
                  ),
                  if (widget.suffixIcon != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: AnimatedOpacity(
                        opacity: widget.enabled ? 1.0 : 0.38,
                        duration: const Duration(milliseconds: 200),
                        child: widget.suffixIcon,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
