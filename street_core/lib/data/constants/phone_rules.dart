// lib/data/constants/country_phone_rules.dart

/// 📏 Reglas de validación telefónica por país (Código ISO 3166-1 alpha-2).
///
/// Cada país tiene:
/// - 'min': Longitud mínima requerida (solo dígitos).
/// - 'max': Longitud máxima permitida (solo dígitos).
/// - 'regex': Expresión regular para el formato del número.
const Map<String, Map<String, dynamic>> kPhoneValidationRules = {
  // === Norteamérica y Caribe (+1) ===
  'US': {'min': 10, 'max': 10, 'regex': r'^\d{10}$'}, // Estados Unidos
  'CA': {'min': 10, 'max': 10, 'regex': r'^\d{10}$'}, // Canadá
  'DO': {'min': 10, 'max': 10, 'regex': r'^\d{10}$'}, // Rep. Dominicana
  'MX': {'min': 10, 'max': 10, 'regex': r'^\d{10}$'}, // México
  // === Latinoamérica ===
  'AR': {
    'min': 6,
    'max': 15,
    'regex': r'^\d{6,15}$',
  }, // Argentina (muy variable)
  'BR': {
    'min': 10,
    'max': 11,
    'regex': r'^\d{10,11}$',
  }, // Brasil (con/sin 9º dígito)
  'CL': {'min': 8, 'max': 9, 'regex': r'^\d{8,9}$'}, // Chile (fijo/móvil)
  'CO': {
    'min': 10,
    'max': 10,
    'regex': r'^\d{10}$',
  }, // Colombia (10 dígitos fijo)
  'PE': {'min': 9, 'max': 9, 'regex': r'^\d{9}$'}, // Perú
  'VE': {'min': 10, 'max': 10, 'regex': r'^\d{10}$'}, // Venezuela
  'EC': {'min': 9, 'max': 9, 'regex': r'^\d{9}$'}, // Ecuador
  'UY': {'min': 8, 'max': 9, 'regex': r'^\d{8,9}$'}, // Uruguay
  'PA': {'min': 8, 'max': 8, 'regex': r'^\d{8}$'}, // Panamá
  'CR': {'min': 8, 'max': 8, 'regex': r'^\d{8}$'}, // Costa Rica
  'PR': {'min': 10, 'max': 10, 'regex': r'^\d{10}$'}, // Puerto Rico
  // === Europa ===
  'ES': {'min': 9, 'max': 9, 'regex': r'^\d{9}$'}, // España
  'FR': {'min': 9, 'max': 9, 'regex': r'^\d{9}$'}, // Francia
  'DE': {'min': 8, 'max': 11, 'regex': r'^\d{8,11}$'}, // Alemania (variable)
  'IT': {'min': 8, 'max': 11, 'regex': r'^\d{8,11}$'}, // Italia (variable)
  'GB': {'min': 10, 'max': 10, 'regex': r'^\d{10}$'}, // Reino Unido
  'RU': {'min': 10, 'max': 10, 'regex': r'^\d{10}$'}, // Rusia
  'PT': {'min': 9, 'max': 9, 'regex': r'^\d{9}$'}, // Portugal
  // === Asia/Oceanía/África (Ejemplos) ===
  'CN': {'min': 11, 'max': 11, 'regex': r'^\d{11}$'}, // China
  'IN': {'min': 10, 'max': 10, 'regex': r'^\d{10}$'}, // India
  'AU': {'min': 9, 'max': 9, 'regex': r'^\d{9}$'}, // Australia
  'JP': {'min': 10, 'max': 10, 'regex': r'^\d{10}$'}, // Japón
  'SA': {'min': 9, 'max': 9, 'regex': r'^\d{9}$'}, // Arabia Saudita
  'ZA': {'min': 9, 'max': 9, 'regex': r'^\d{9}$'}, // Sudáfrica
  // --- Lista de países no cubiertos en el ejemplo anterior (A-Z) ---
  'AL': {'min': 9, 'max': 9, 'regex': r'^\d{9}$'}, // Albania
  'DZ': {'min': 9, 'max': 9, 'regex': r'^\d{9}$'}, // Argelia
  //  'AU': {'min': 9, 'max': 9, 'regex': r'^\d{9}$'}, // Australia
  'AT': {'min': 10, 'max': 11, 'regex': r'^\d{10,11}$'}, // Austria
  'BD': {'min': 10, 'max': 10, 'regex': r'^\d{10}$'}, // Bangladés
  'BE': {'min': 9, 'max': 9, 'regex': r'^\d{9}$'}, // Bélgica
  'BG': {'min': 8, 'max': 9, 'regex': r'^\d{8,9}$'}, // Bulgaria
  'HR': {'min': 8, 'max': 9, 'regex': r'^\d{8,9}$'}, // Croacia
  'CZ': {'min': 9, 'max': 9, 'regex': r'^\d{9}$'}, // Rep. Checa
  'DK': {'min': 8, 'max': 8, 'regex': r'^\d{8}$'}, // Dinamarca
  'EG': {'min': 10, 'max': 10, 'regex': r'^\d{10}$'}, // Egipto
  'FI': {'min': 9, 'max': 10, 'regex': r'^\d{9,10}$'}, // Finlandia
  'GR': {'min': 10, 'max': 10, 'regex': r'^\d{10}$'}, // Grecia
  'HU': {'min': 9, 'max': 9, 'regex': r'^\d{9}$'}, // Hungría
  'ID': {'min': 10, 'max': 12, 'regex': r'^\d{10,12}$'}, // Indonesia
  'IE': {'min': 9, 'max': 9, 'regex': r'^\d{9}$'}, // Irlanda
  'IL': {'min': 9, 'max': 9, 'regex': r'^\d{9}$'}, // Israel
  'KR': {'min': 10, 'max': 11, 'regex': r'^\d{10,11}$'}, // Corea del Sur
  'MY': {'min': 8, 'max': 11, 'regex': r'^\d{8,11}$'}, // Malasia
  'NG': {'min': 11, 'max': 11, 'regex': r'^\d{11}$'}, // Nigeria
  'NO': {'min': 8, 'max': 8, 'regex': r'^\d{8}$'}, // Noruega
  'PK': {'min': 10, 'max': 10, 'regex': r'^\d{10}$'}, // Pakistán
  'PH': {'min': 10, 'max': 10, 'regex': r'^\d{10}$'}, // Filipinas
  'PL': {'min': 9, 'max': 9, 'regex': r'^\d{9}$'}, // Polonia
  'SG': {'min': 8, 'max': 8, 'regex': r'^\d{8}$'}, // Singapur
  'SE': {'min': 9, 'max': 10, 'regex': r'^\d{9,10}$'}, // Suecia
  'CH': {'min': 9, 'max': 9, 'regex': r'^\d{9}$'}, // Suiza
  'TH': {'min': 9, 'max': 10, 'regex': r'^\d{9,10}$'}, // Tailandia
  'TR': {'min': 10, 'max': 10, 'regex': r'^\d{10}$'}, // Turquía
  'UA': {'min': 9, 'max': 9, 'regex': r'^\d{9}$'}, // Ucrania
  // ... (Añadir más países según sea necesario)
};
