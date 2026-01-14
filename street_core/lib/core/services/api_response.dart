/// Generic API Response Model
///
/// Wraps all API responses in a consistent format with:
/// - status: 'success' or 'error'
/// - message: Human-readable message
/// - data: Generic typed data payload
/// - statusCode: HTTP status code (optional)
///
/// Usage:
/// ```dart
/// final response = ApiResponse<User>.fromJson(
///   jsonData,
///   (data) => User.fromJson(data as Map<String, dynamic>),
/// );
/// ```
class ApiResponse<T> {
  // Constructor inmutable (usando final)
  const ApiResponse({
    required this.status,
    this.message = '',
    this.code,
    this.data,
    this.statusCode,
  });

  // 1. Deserialización: Con manejo de tipo genérico y null safety
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    // La función parseT es crucial. Recibe el valor 'data' y devuelve el tipo T
    T Function(dynamic)? parseT,
  ) {
    // 💡 Paso clave: Intentar parsear los datos solo si están presentes y la función de parseo fue proporcionada.
    final rawData = json['data'];
    T? parsedData;

    if (rawData != null && parseT != null) {
      try {
        parsedData = parseT(rawData);
      } catch (e) {
        // En un entorno real, aquí se podría registrar un error de parseo.
        parsedData = null;
      }
    }

    return ApiResponse<T>(
      status: json['status']?.toString() ?? 'error',
      message: json['message']?.toString() ?? 'unknown_message',
      code: json['code']?.toString(), // Backend error code (e.g., 'heat.already.closed')
      data: parsedData ?? (rawData != null ? rawData as T? : null),
      statusCode: json['statusCode'] as int?, // Aseguramos que sea int o null
    );
  }
  final String status;
  final String message;
  final String? code; // Backend error code (e.g., 'heat.already.closed')
  final T? data;
  final int? statusCode;

  // 2. Serialización: Para debugging o reenvío
  Map<String, dynamic> toJson() {
    // ⚠️ Nota: 'data' debe ser serializable (ej. un Map) para que esto funcione correctamente.
    return {
      'status': status,
      'message': message,
      'code': code,
      'data': data,
      'statusCode': statusCode,
    };
  }
}
