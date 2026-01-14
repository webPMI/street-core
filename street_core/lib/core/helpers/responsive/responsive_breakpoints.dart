/// Sistema centralizado de breakpoints responsive
///
/// Define los breakpoints estándar para toda la aplicación
/// y proporciona utilidades para trabajar con diferentes tamaños de pantalla.
class ResponsiveBreakpoints {
  // Breakpoints estándar (basados en Material Design)
  static const double mobileSmall = 360; // Móviles pequeños
  static const double mobile = 600; // Móviles normales/grandes
  static const double tablet = 900; // Tablets pequeñas
  static const double desktop = 1200; // Desktop normal
  static const double desktopLarge = 1600; // Desktop grande
  static const double tv = 1920; // TV/Monitors grandes

  // Breakpoints semánticos
  static const double compact = mobile; // Compact layout
  static const double medium = tablet; // Medium layout
  static const double expanded = desktop; // Expanded layout

  /// Verifica si el ancho es móvil pequeño
  static bool isMobileSmall(double width) => width < mobile;

  /// Verifica si el ancho es móvil
  static bool isMobile(double width) => width < mobile;

  /// Verifica si el ancho es tablet
  static bool isTablet(double width) => width >= mobile && width < desktop;

  /// Verifica si el ancho es desktop
  static bool isDesktop(double width) => width >= desktop;

  /// Verifica si el ancho es desktop grande
  static bool isDesktopLarge(double width) => width >= desktopLarge;

  /// Obtiene el tipo de dispositivo basado en el ancho
  static DeviceType getDeviceType(double width) {
    if (width < mobileSmall) return DeviceType.mobileSmall;
    if (width < mobile) return DeviceType.mobile;
    if (width < tablet) return DeviceType.tabletSmall;
    if (width < desktop) return DeviceType.tablet;
    if (width < desktopLarge) return DeviceType.desktop;
    if (width < tv) return DeviceType.desktopLarge;
    return DeviceType.tv;
  }

  /// Obtiene el layout type basado en el ancho
  static LayoutType getLayoutType(double width) {
    if (width < mobile) return LayoutType.compact;
    if (width < desktop) return LayoutType.medium;
    return LayoutType.expanded;
  }

  /// Número de columnas para grid según el ancho
  static int getGridColumns(double width) {
    if (width < mobile) return 1;
    if (width < tablet) return 2;
    if (width < desktop) return 3;
    if (width < desktopLarge) return 4;
    return 6;
  }

  /// Espaciado recomendado según el ancho
  static double getSpacing(double width) {
    if (width < mobile) return 8;
    if (width < desktop) return 16;
    return 24;
  }

  /// Padding horizontal recomendado
  static double getHorizontalPadding(double width) {
    if (width < mobile) return 16;
    if (width < desktop) return 24;
    if (width < desktopLarge) return 32;
    return 48;
  }

  /// Padding vertical recomendado
  static double getVerticalPadding(double width) {
    if (width < mobile) return 16;
    if (width < desktop) return 24;
    return 32;
  }

  /// Ancho máximo de contenido centrado
  static double getMaxContentWidth(double width) {
    if (width < mobile) return double.infinity;
    if (width < tablet) return 540;
    if (width < desktop) return 720;
    if (width < desktopLarge) return 960;
    return 1140;
  }

  /// Radio de bordes según el tamaño
  static double getBorderRadius(double width) {
    if (width < mobile) return 8;
    if (width < desktop) return 12;
    return 16;
  }

  /// Tamaño de fuente para títulos
  static double getTitleFontSize(double width) {
    if (width < mobile) return 20;
    if (width < desktop) return 24;
    return 28;
  }

  /// Tamaño de fuente para cuerpo
  static double getBodyFontSize(double width) {
    if (width < mobile) return 14;
    if (width < desktop) return 16;
    return 16;
  }

  /// Altura de AppBar
  static double getAppBarHeight(double width) {
    if (width < mobile) return 56;
    if (width < desktop) return 64;
    return 72;
  }
}

/// Tipos de dispositivo
enum DeviceType {
  mobileSmall, // < 360
  mobile, // < 600
  tabletSmall, // < 900
  tablet, // < 1200
  desktop, // < 1600
  desktopLarge, // < 1920
  tv, // >= 1920
}

/// Tipos de layout
enum LayoutType {
  compact, // Mobile
  medium, // Tablet
  expanded, // Desktop
}

/// Extension para facilitar el uso
extension DeviceTypeExtension on DeviceType {
  bool get isMobile =>
      this == DeviceType.mobileSmall || this == DeviceType.mobile;

  bool get isTablet =>
      this == DeviceType.tabletSmall || this == DeviceType.tablet;

  bool get isDesktop =>
      this == DeviceType.desktop ||
      this == DeviceType.desktopLarge ||
      this == DeviceType.tv;

  String get name {
    switch (this) {
      case DeviceType.mobileSmall:
        return 'Mobile Small';
      case DeviceType.mobile:
        return 'Mobile';
      case DeviceType.tabletSmall:
        return 'Tablet Small';
      case DeviceType.tablet:
        return 'Tablet';
      case DeviceType.desktop:
        return 'Desktop';
      case DeviceType.desktopLarge:
        return 'Desktop Large';
      case DeviceType.tv:
        return 'TV';
    }
  }
}
