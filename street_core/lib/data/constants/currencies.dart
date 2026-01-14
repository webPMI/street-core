// lib/data/constants/currencies.dart

class Currency {
  // Example: "us_dollar"

  const Currency({
    required this.code,
    required this.symbol,
    required this.name,
  });
  final String code; // Example: "USD"
  final String symbol; // Example: "$"
  final String name;
}

const List<Currency> kCurrencies = [
  // 🌎 America
  Currency(code: 'USD', symbol: r'$', name: 'us_dollar'),
  Currency(code: 'CAD', symbol: r'C$', name: 'canadian_dollar'),
  Currency(code: 'MXN', symbol: r'$', name: 'mexican_peso'),
  Currency(code: 'ARS', symbol: r'$', name: 'argentine_peso'),
  Currency(code: 'CLP', symbol: r'$', name: 'chilean_peso'),
  Currency(code: 'COP', symbol: r'$', name: 'colombian_peso'),
  Currency(code: 'BRL', symbol: r'R$', name: 'brazilian_real'),
  Currency(code: 'PEN', symbol: 'S/', name: 'peruvian_sol'),
  Currency(code: 'UYU', symbol: r'$', name: 'uruguayan_peso'),
  Currency(code: 'BOB', symbol: 'Bs', name: 'bolivian_boliviano'),
  Currency(code: 'PYG', symbol: '₲', name: 'paraguayan_guarani'),
  Currency(code: 'VEF', symbol: 'Bs.', name: 'venezuelan_bolivar'),

  // 💶 Europe
  Currency(code: 'EUR', symbol: '€', name: 'euro'),
  Currency(code: 'GBP', symbol: '£', name: 'british_pound'),
  Currency(code: 'CHF', symbol: 'CHF', name: 'swiss_franc'),
  Currency(code: 'SEK', symbol: 'kr', name: 'swedish_krona'),
  Currency(code: 'NOK', symbol: 'kr', name: 'norwegian_krone'),
  Currency(code: 'DKK', symbol: 'kr', name: 'danish_krone'),
  Currency(code: 'PLN', symbol: 'zł', name: 'polish_zloty'),
  Currency(code: 'CZK', symbol: 'Kč', name: 'czech_koruna'),

  // 💴 Asia
  Currency(code: 'JPY', symbol: '¥', name: 'japanese_yen'),
  Currency(code: 'CNY', symbol: '¥', name: 'chinese_yuan'),
  Currency(code: 'KRW', symbol: '₩', name: 'south_korean_won'),
  Currency(code: 'INR', symbol: '₹', name: 'indian_rupee'),
  Currency(code: 'THB', symbol: '฿', name: 'thai_baht'),
  Currency(code: 'SGD', symbol: r'S$', name: 'singapore_dollar'),
  Currency(code: 'HKD', symbol: r'HK$', name: 'hong_kong_dollar'),

  // 🌍 Oceania
  Currency(code: 'AUD', symbol: r'A$', name: 'australian_dollar'),
  Currency(code: 'NZD', symbol: r'NZ$', name: 'new_zealand_dollar'),

  // 🌍 Africa
  Currency(code: 'ZAR', symbol: 'R', name: 'south_african_rand'),
  Currency(code: 'EGP', symbol: '£E', name: 'egyptian_pound'),
  Currency(code: 'NGN', symbol: '₦', name: 'nigerian_naira'),
  Currency(code: 'KES', symbol: 'KSh', name: 'kenyan_shilling'),
  Currency(code: 'MAD', symbol: 'د.م.', name: 'moroccan_dirham'),

  // 💰 Middle East
  Currency(code: 'AED', symbol: 'د.إ', name: 'uae_dirham'),
  Currency(code: 'SAR', symbol: 'ر.س', name: 'saudi_riyal'),
  Currency(code: 'TRY', symbol: '₺', name: 'turkish_lira'),
  Currency(code: 'ILS', symbol: '₪', name: 'israeli_shekel'),
  Currency(code: 'QAR', symbol: 'ر.ق', name: 'qatari_riyal'),
];

// lib/data/constants/currencies.dart

// ... (Tus clases Currency y kCurrencies existentes) ...

/// Extensión para convertir el código de moneda a un emoji de bandera.
extension CurrencyFlag on Currency {
  // Mapeo manual de códigos de moneda (ISO 4217) a códigos de país (ISO 3166-1 alpha-2)
  // cuando las dos primeras letras no son suficientes o correctas.
  static const Map<String, String> _currencyToCountryMap = {
    // Casos especiales y organizaciones
    'EUR': '🇪🇺', // Euro -> Unión Europea (Emoji específico)
    // Monedas que usan un código de país diferente
    'GBP': 'GB', // Great Britain (Reino Unido)
    'DKK': 'DK', // Denmark
    'SEK': 'SE', // Sweden
    'NOK': 'NO', // Norway
    'CHF': 'CH', // Switzerland (Confederación Helvética)
    'ZAR': 'ZA', // South Africa (Zuid-Afrika)
    'EGP': 'EG', // Egypt
    'AED': 'AE', // United Arab Emirates
    'SAR': 'SA', // Saudi Arabia
    'TRY': 'TR', // Turkey
    'ILS': 'IL', // Israel
    'QAR': 'QA', // Qatar
    'INR': 'IN', // India
    'KRW': 'KR', // South Korea
    'JPY': 'JP', // Japan
    'CNY': 'CN', // China
    'HKD': 'HK', // Hong Kong
    'SGD': 'SG', // Singapore
    'THB': 'TH', // Thailand
    'NGN': 'NG', // Nigeria
    'KES': 'KE', // Kenya
    'MAD': 'MA', // Morocco
    // ... puedes añadir más según sea necesario ...
  };

  /// Función interna para convertir el código de país de 2 letras (ej. 'US') a emoji.
  String _codeToEmoji(String code) {
    if (code == '🇪🇺') return '🇪🇺'; // Retorna el emoji si es la UE

    // Convierte el código de 2 letras a su representación Unicode de bandera
    return code
        .toUpperCase()
        .codeUnits
        .map((e) => String.fromCharCode(e + 127397)) // Offset para banderas
        .join();
  }

  /// Retorna el emoji de bandera para la moneda.
  String get flag {
    // 1. Verificar si está en el mapeo de excepciones
    if (_currencyToCountryMap.containsKey(code)) {
      final String mappedValue = _currencyToCountryMap[code]!;
      return _codeToEmoji(mappedValue);
    }

    // 2. Regla General: Usar las dos primeras letras del código de moneda
    // (Ej: UY de UYU, PE de PEN). Esto funciona para la mayoría de las monedas de América Latina.
    try {
      final String baseCode = code.substring(0, 2);
      return _codeToEmoji(baseCode);
    } catch (e) {
      // Fallback si el código es demasiado corto (no debería pasar con ISO 4217)
      return '❓';
    }
  }
}
