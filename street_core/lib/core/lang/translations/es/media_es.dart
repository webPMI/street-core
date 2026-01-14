// lib/core/lang/translations/es/media_es.dart

/// Traducciones en español para el sistema de carga de archivos (media)
/// Todas las claves usan el namespace 'media.*' con dot notation
///
/// Formato: 'media.categoria.clave.especifica'
/// Ejemplo: 'media.error.file.too.large', 'media.upload.success'
const mediaEs = {
  // ============================================================================
  // SELECCIÓN - media.select.*
  // ============================================================================
  'media.select.files': 'Seleccionar Archivos',
  'media.select.file': 'Seleccionar Archivo',
  'media.select.image': 'Seleccionar imagen',
  'media.select.images': 'Seleccionar Imágenes',
  'media.select.video': 'Seleccionar Video',
  'media.select.source': 'Seleccionar Fuente',
  'media.select.tap.to.select': 'Toca para seleccionar',
  'media.select.tap.to.choose.gallery': 'Toca para elegir de la galería',
  'media.select.tap.to.choose.camera': 'Toca para tomar foto',
  'media.select.add.more': 'Agregar más',
  'media.select.selecting.files': 'Seleccionando archivos...',
  'media.select.take.photo': 'Tomar foto',
  'media.select.from.gallery': 'Desde galería',
  'media.select.camera': 'Cámara',
  'media.select.gallery': 'Galería',

  // ============================================================================
  // UPLOAD - media.upload.*
  // ============================================================================

  // Acciones de carga
  'media.upload.upload': 'Subir',
  'media.upload.image': 'Subir Imagen',
  'media.upload.video': 'Subir Video',
  'media.upload.avatar': 'Subir Avatar',
  'media.upload.files': 'Subir Archivos',
  'media.upload.cancel': 'Cancelar',
  'media.upload.retry': 'Reintentar',
  'media.upload.select.file': 'Seleccionar archivo',
  'media.upload.select.files': 'Seleccionar archivos',
  'media.upload.drop.files': 'Arrastra archivos aquí',
  'media.upload.or.click': 'o haz clic para seleccionar',

  // Estados de progreso
  'media.upload.uploading': 'Subiendo...',
  'media.upload.uploading.image': 'Subiendo imagen...',
  'media.upload.uploading.video': 'Subiendo video...',
  'media.upload.uploading.avatar': 'Subiendo avatar...',
  'media.upload.uploading.files': 'Subiendo archivos...',
  'media.upload.processing': 'Procesando...',
  'media.upload.progress': 'Subiendo: {progress}%',

  // Estados de resultado
  'media.upload.complete': 'Carga completa',
  'media.upload.successful': 'Carga exitosa',
  'media.upload.success': 'Archivo subido exitosamente',
  'media.upload.failed': 'Carga fallida',
  'media.upload.cancelled': 'Carga cancelada',

  // Mensajes específicos por tipo
  'media.upload.file.uploaded': 'Archivo subido exitosamente',
  'media.upload.files.uploaded': 'Archivos subidos exitosamente',
  'media.upload.files.uploaded.count': '{count} archivo(s) subido(s) correctamente',
  'media.upload.image.uploaded': 'Imagen subida exitosamente',
  'media.upload.video.uploaded': 'Video subido exitosamente',

  // ============================================================================
  // AVATAR - media.avatar.*
  // ============================================================================
  'media.avatar.updated': 'Avatar actualizado exitosamente',
  'media.avatar.upload': 'Carga de Avatar',
  'media.avatar.upload.desc': 'Sube foto de perfil con recorte',
  'media.avatar.upload.success': 'Avatar actualizado exitosamente',
  'media.avatar.uploading': 'Subiendo avatar...',
  'media.avatar.url': 'URL de Avatar:',
  'media.avatar.select': 'Seleccionar avatar',
  'media.avatar.change': 'Cambiar avatar',
  'media.avatar.remove': 'Eliminar avatar',
  'media.avatar.current': 'Avatar actual',

  // ============================================================================
  // IMAGEN - media.image.*
  // ============================================================================
  'media.image.select': 'Seleccionar imagen',
  'media.image.select.multiple': 'Seleccionar imágenes',
  'media.image.change': 'Cambiar imagen',
  'media.image.from.camera': 'Desde cámara',
  'media.image.from.gallery': 'Desde galería',
  'media.image.upload': 'Subir imagen',
  'media.image.uploading': 'Subiendo imagen...',
  'media.image.uploaded': 'Imagen subida exitosamente',
  'media.image.processing': 'Procesando imagen...',
  'media.image.url': 'URL de Imagen Subida:',

  // ============================================================================
  // VIDEO - media.video.*
  // ============================================================================
  'media.video.select': 'Seleccionar video',
  'media.video.upload': 'Subir video',
  'media.video.uploading': 'Subiendo video...',
  'media.video.uploaded': 'Video subido exitosamente',
  'media.video.recording': 'Grabando...',
  'media.video.url': 'URL de Video Subido:',

  // ============================================================================
  // ERRORES - media.error.*
  // ============================================================================

  // Errores de selección
  'media.error.no.files.selected': 'No se seleccionaron archivos',
  'media.error.selecting.files': 'Error al seleccionar archivos',
  'media.error.selecting.image': 'Error al seleccionar imagen',
  'media.error.reading.file': 'Error al leer el archivo {name}',

  // Errores de tamaño
  'media.error.file.too.large': 'Archivo demasiado grande',
  'media.error.file.too.small': 'Archivo demasiado pequeño (mínimo 1KB)',
  'media.error.image.too.large': 'Imagen demasiado grande (máximo 10MB)',
  'media.error.video.too.large': 'Video demasiado grande (máximo 500MB)',
  'media.error.avatar.too.large': 'Avatar demasiado grande (máximo 5MB)',
  'media.error.total.size.exceeded': 'El tamaño total de los archivos excede el límite',
  'media.error.all.files.too.large': 'Todos los archivos son demasiado grandes',

  // Errores de cantidad
  'media.error.too.many.files': 'Demasiados archivos seleccionados (máximo 10)',
  'media.error.no.valid.files': 'No hay archivos válidos para subir',
  'media.error.max.files.exceeded': 'Máximo {max} archivos permitidos',

  // Errores de tipo/formato
  'media.error.invalid.file.type': 'Tipo de archivo inválido',
  'media.error.invalid.mime.type': 'Formato de archivo no válido',
  'media.error.invalid.image.format': 'Formato de imagen inválido',
  'media.error.invalid.video.format': 'Formato de video inválido (usa mp4, webm, mov)',
  'media.error.invalid.extension': 'Extensión de archivo no permitida',

  // Errores de dimensiones
  'media.error.invalid.dimensions': 'Dimensiones inválidas',
  'media.error.dimensions.too.small': 'Imagen demasiado pequeña (mínimo 50x50)',
  'media.error.dimensions.too.large': 'Imagen demasiado grande (máximo 8192x8192)',

  // Errores de validación
  'media.error.validation.failed': 'Error de validación del archivo',

  // Errores de carga
  'media.error.upload.failed': 'Carga fallida',
  'media.error.upload.timeout': 'Tiempo de carga agotado - por favor intenta de nuevo',
  'media.error.network.error': 'Error de red - verifica tu conexión',
  'media.error.delete.failed': 'Error al eliminar',
  'media.error.unknown': 'Error desconocido al procesar el archivo',

  // ============================================================================
  // ARCHIVO - media.file.*
  // ============================================================================
  'media.file.selected': 'archivo seleccionado',
  'media.file.files.selected': 'archivos seleccionados',
  'media.file.file': 'archivo',
  'media.file.files': 'archivos',
  'media.file.size': 'Tamaño',
  'media.file.count': 'Cantidad',
  'media.file.calculating.size': 'Calculando tamaño...',
  'media.file.preview': 'Vista previa',
  'media.file.remove': 'Eliminar',
  'media.file.uploaded': 'Archivo subido exitosamente',
  'media.file.drop.here': 'Arrastra archivos aquí',

  // ============================================================================
  // INFORMACIÓN/LÍMITES - media.info.*
  // ============================================================================
  'media.info.max.files': 'Máximo de archivos',
  'media.info.max.size': 'Tamaño máximo',
  'media.info.each': 'cada uno',
  'media.info.uploaded.image.url': 'URL de Imagen Subida:',
  'media.info.uploaded.video.url': 'URL de Video Subido:',
  'media.info.uploaded.images': 'Imágenes subidas:',
  'media.info.photo.url': 'URL de Foto:',
  'media.info.files.uploaded': '{count} archivo(s) subido(s) correctamente',
  'media.info.some.files.skipped':
      'Algunos archivos fueron omitidos por exceder el tamaño máximo',
  'media.info.calculating.size': 'Calculando tamaño...',
  'media.info.selecting.files': 'Seleccionando archivos...',

  // ============================================================================
  // LÍMITES - media.limits.*
  // ============================================================================
  'media.limits.max.size': 'Tamaño máximo: {size}',
  'media.limits.max.files': 'Máximo {count} archivos',
  'media.limits.allowed.formats': 'Formatos permitidos: {formats}',

  // ============================================================================
  // CÁMARA - media.camera.*
  // ============================================================================
  'media.camera.take.photo': 'Tomar Foto',
  'media.camera.capture': 'Captura de Cámara',
  'media.camera.capture.desc': 'Toma foto y sube directamente',

  // ============================================================================
  // ACCIONES - media.action.*
  // ============================================================================
  'media.action.discard': 'Descartar',
  'media.action.retake': 'Retomar',
  'media.action.done': 'Hecho',
  'media.action.cancel': 'Cancelar',
  'media.action.retry': 'Reintentar',

  // ============================================================================
  // VALIDACIÓN - media.validation.*
  // ============================================================================
  'media.validation.checking': 'Validando archivo...',
  'media.validation.invalid': 'Archivo inválido',
  'media.validation.valid': 'Archivo válido',

  // ============================================================================
  // EJEMPLOS (para documentación/demos) - media.example.*
  // ============================================================================
  'media.example.upload.examples': 'Ejemplos de Carga',
  'media.example.single.image.upload': 'Carga de Imagen Individual',
  'media.example.multiple.images.upload': 'Carga de Múltiples Imágenes',
  'media.example.video.upload': 'Carga de Video',
  'media.example.avatar.upload': 'Carga de Avatar',
  'media.example.error.handling.retry': 'Manejo de Errores y Reintento',
  'media.example.single.image.desc': 'Sube una sola imagen con compresión',
  'media.example.multiple.images.desc': 'Sube hasta 10 imágenes a la vez',
  'media.example.video.upload.desc': 'Sube video con seguimiento de progreso',
  'media.example.error.handling.desc': 'Maneja errores de carga con gracia',

  // ============================================================================
  // PLACEHOLDERS Y HINTS - media.hint.*
  // ============================================================================
  'media.hint.select.files': 'Seleccionar Archivos',
  'media.hint.tap.to.select': 'Toca para seleccionar',
  'media.hint.files.selected': 'archivos seleccionados',
  'media.hint.file.selected': 'archivo seleccionado',
  'media.hint.add.more': 'Agregar más',
  'media.hint.max.info': 'Máximo {max} archivos • {size}',
};
