/// SEO Meta Tags - Platform-agnostic interface
///
/// This file exports the correct implementation based on the platform:
/// - Web: Uses dart:html to manipulate DOM meta tags
/// - Non-web (Android, iOS, Desktop): Provides no-op stubs
library;

// Conditional exports based on platform
export 'seo_meta_tags_stub.dart'
    if (dart.library.html) 'seo_meta_tags_web.dart';
