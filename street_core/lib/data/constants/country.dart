// lib/data/constants/countries.dart

class Country { // Clave de traducción o nombre completo (ej. "united_states")

  const Country({required this.code, required this.name});
  final String code; // Código ISO 3166-1 alpha-2 (ej. "US")
  final String
  name;
}

// 🌐 Extensión para generar el emoji de la bandera
extension CountryFlag on Country {
  String get flag {
    // Convierte el código de 2 letras a su representación Unicode de bandera
    return code
        .toUpperCase()
        .codeUnits
        .map(
          (e) => String.fromCharCode(e + 127397),
        ) // Offset Unicode para banderas
        .join();
  }
}

// 🌎 Lista Completa de Países (ISO 3166-1 alpha-2)
const List<Country> kCountries = [
  // =========================================================
  // 🇺🇸 NORTE Y SUR AMÉRICA
  // =========================================================
  Country(code: 'US', name: 'united_states'),
  Country(code: 'CA', name: 'canada'),
  Country(code: 'MX', name: 'mexico'),
  Country(code: 'AR', name: 'argentina'),
  Country(code: 'CL', name: 'chile'),
  Country(code: 'CO', name: 'colombia'),
  Country(code: 'BR', name: 'brazil'),
  Country(code: 'PE', name: 'peru'),
  Country(code: 'VE', name: 'venezuela'),
  Country(code: 'EC', name: 'ecuador'),
  Country(code: 'BO', name: 'bolivia'),
  Country(code: 'PY', name: 'paraguay'),
  Country(code: 'UY', name: 'uruguay'),
  Country(code: 'CR', name: 'costa_rica'),
  Country(code: 'PA', name: 'panama'),
  Country(code: 'GT', name: 'guatemala'),
  Country(code: 'HN', name: 'honduras'),
  Country(code: 'SV', name: 'el_salvador'),
  Country(code: 'NI', name: 'nicaragua'),
  Country(code: 'CU', name: 'cuba'),
  Country(code: 'DO', name: 'dominican_republic'),
  Country(code: 'PR', name: 'puerto_rico'), // Territorio
  Country(code: 'JM', name: 'jamaica'),
  Country(code: 'HT', name: 'haiti'),
  Country(code: 'BS', name: 'bahamas'),
  Country(code: 'TT', name: 'trinidad_and_tobago'),
  Country(code: 'BB', name: 'barbados'),
  Country(code: 'LC', name: 'saint_lucia'),
  Country(code: 'AG', name: 'antigua_and_barbuda'),
  Country(code: 'SR', name: 'suriname'),
  Country(code: 'GY', name: 'guyana'),

  // =========================================================
  // 🇪🇺 EUROPA
  // =========================================================
  Country(code: 'ES', name: 'spain'),
  Country(code: 'FR', name: 'france'),
  Country(code: 'DE', name: 'germany'),
  Country(code: 'IT', name: 'italy'),
  Country(code: 'GB', name: 'united_kingdom'),
  Country(code: 'PT', name: 'portugal'),
  Country(code: 'IE', name: 'ireland'),
  Country(code: 'NL', name: 'netherlands'),
  Country(code: 'BE', name: 'belgium'),
  Country(code: 'CH', name: 'switzerland'),
  Country(code: 'AT', name: 'austria'),
  Country(code: 'SE', name: 'sweden'),
  Country(code: 'NO', name: 'norway'),
  Country(code: 'DK', name: 'denmark'),
  Country(code: 'FI', name: 'finland'),
  Country(code: 'IS', name: 'iceland'),
  Country(code: 'GR', name: 'greece'),
  Country(code: 'PL', name: 'poland'),
  Country(code: 'CZ', name: 'czech_republic'),
  Country(code: 'HU', name: 'hungary'),
  Country(code: 'RO', name: 'romania'),
  Country(code: 'UA', name: 'ukraine'),
  Country(code: 'RU', name: 'russia'),
  Country(code: 'TR', name: 'turkey'),
  Country(code: 'HR', name: 'croatia'),
  Country(code: 'RS', name: 'serbia'),
  Country(code: 'BA', name: 'bosnia_and_herzegovina'),
  Country(code: 'AL', name: 'albania'),

  // =========================================================
  // 🌏 ASIA Y MEDIO ORIENTE
  // =========================================================
  Country(code: 'CN', name: 'china'),
  Country(code: 'IN', name: 'india'),
  Country(code: 'ID', name: 'indonesia'),
  Country(code: 'PK', name: 'pakistan'),
  Country(code: 'BD', name: 'bangladesh'),
  Country(code: 'JP', name: 'japan'),
  Country(code: 'KR', name: 'south_korea'),
  Country(code: 'VN', name: 'vietnam'),
  Country(code: 'PH', name: 'philippines'),
  Country(code: 'TH', name: 'thailand'),
  Country(code: 'MM', name: 'myanmar'),
  Country(code: 'MY', name: 'malaysia'),
  Country(code: 'SG', name: 'singapore'),
  Country(code: 'SA', name: 'saudi_arabia'),
  Country(code: 'AE', name: 'united_arab_emirates'),
  Country(code: 'IQ', name: 'iraq'),
  Country(code: 'IR', name: 'iran'),
  Country(code: 'IL', name: 'israel'),
  Country(code: 'QA', name: 'qatar'),
  Country(code: 'KW', name: 'kuwait'),
  Country(code: 'HK', name: 'hong_kong'), // Región administrativa especial
  // =========================================================
  // 🇦🇺 OCEANÍA
  // =========================================================
  Country(code: 'AU', name: 'australia'),
  Country(code: 'NZ', name: 'new_zealand'),
  Country(code: 'FJ', name: 'fiji'),
  Country(code: 'PG', name: 'papua_new_guinea'),

  // =========================================================
  // 🇿🇦 ÁFRICA
  // =========================================================
  Country(code: 'NG', name: 'nigeria'),
  Country(code: 'EG', name: 'egypt'),
  Country(code: 'ZA', name: 'south_africa'),
  Country(code: 'KE', name: 'kenya'),
  Country(code: 'DZ', name: 'algeria'),
  Country(code: 'MA', name: 'morocco'),
  Country(code: 'GH', name: 'ghana'),
  Country(code: 'CI', name: 'cote_d_ivoire'),
  Country(code: 'CM', name: 'cameroon'),
  Country(code: 'TN', name: 'tunisia'),
  Country(code: 'SD', name: 'sudan'),
  Country(code: 'ET', name: 'ethiopia'),
  Country(code: 'AO', name: 'angola'),
  Country(code: 'ZM', name: 'zambia'),

  // =========================================================
  // 🌐 EL RESTO DEL MUNDO (A-Z)
  // =========================================================
  Country(code: 'AF', name: 'afghanistan'),
  Country(code: 'AX', name: 'aland_islands'),
  Country(code: 'AS', name: 'american_samoa'),
  Country(code: 'AD', name: 'andorra'),
  Country(code: 'AI', name: 'anguilla'),
  Country(code: 'AQ', name: 'antarctica'),
  Country(code: 'AM', name: 'armenia'),
  Country(code: 'AW', name: 'aruba'),
  Country(code: 'AZ', name: 'azerbaijan'),
  Country(code: 'BH', name: 'bahrain'),
  Country(code: 'BY', name: 'belarus'),
  Country(code: 'BZ', name: 'belize'),
  Country(code: 'BJ', name: 'benin'),
  Country(code: 'BM', name: 'bermuda'),
  Country(code: 'BT', name: 'bhutan'),
  Country(code: 'IO', name: 'british_indian_ocean_territory'),
  Country(code: 'BN', name: 'brunei_darussalam'),
  Country(code: 'BG', name: 'bulgaria'),
  Country(code: 'BF', name: 'burkina_faso'),
  Country(code: 'BI', name: 'burundi'),
  Country(code: 'KH', name: 'cambodia'),
  Country(code: 'CV', name: 'cape_verde'),
  Country(code: 'KY', name: 'cayman_islands'),
  Country(code: 'CF', name: 'central_african_republic'),
  Country(code: 'TD', name: 'chad'),
  Country(code: 'KM', name: 'comoros'),
  Country(code: 'CD', name: 'congo_democratic_republic'),
  Country(code: 'CK', name: 'cook_islands'),
  Country(code: 'CY', name: 'cyprus'),
  Country(code: 'DJ', name: 'djibouti'),
  Country(code: 'DM', name: 'dominica'),
  Country(code: 'TL', name: 'east_timor'),
  Country(code: 'GQ', name: 'equatorial_guinea'),
  Country(code: 'ER', name: 'eritrea'),
  Country(code: 'EE', name: 'estonia'),
  Country(code: 'FK', name: 'falkland_islands'),
  Country(code: 'FO', name: 'faroe_islands'),
  Country(code: 'GF', name: 'french_guiana'),
  Country(code: 'PF', name: 'french_polynesia'),
  Country(code: 'GA', name: 'gabon'),
  Country(code: 'GM', name: 'gambia'),
  Country(code: 'GE', name: 'georgia'),
  Country(code: 'GI', name: 'gibraltar'),
  Country(code: 'GL', name: 'greenland'),
  Country(code: 'GD', name: 'grenada'),
  Country(code: 'GP', name: 'guadeloupe'),
  Country(code: 'GU', name: 'guam'),
  Country(code: 'GG', name: 'guernsey'),
  Country(code: 'GN', name: 'guinea'),
  Country(code: 'GW', name: 'guinea_bissau'),
  Country(code: 'HN', name: 'honduras'),
  Country(code: 'HM', name: 'heard_island_mcdonald_islands'),
  Country(code: 'HU', name: 'hungary'),
  Country(code: 'IM', name: 'isle_of_man'),
  Country(code: 'JE', name: 'jersey'),
  Country(code: 'JO', name: 'jordan'),
  Country(code: 'KZ', name: 'kazakhstan'),
  Country(code: 'KI', name: 'kiribati'),
  Country(code: 'KP', name: 'north_korea'),
  Country(code: 'KG', name: 'kyrgyzstan'),
  Country(code: 'LA', name: 'lao_peoples_democratic_republic'),
  Country(code: 'LV', name: 'latvia'),
  Country(code: 'LB', name: 'lebanon'),
  Country(code: 'LS', name: 'lesotho'),
  Country(code: 'LR', name: 'liberia'),
  Country(code: 'LY', name: 'libya'),
  Country(code: 'LI', name: 'liechtenstein'),
  Country(code: 'LT', name: 'lithuania'),
  Country(code: 'LU', name: 'luxembourg'),
  Country(code: 'MO', name: 'macao'),
  Country(code: 'MK', name: 'north_macedonia'),
  Country(code: 'MG', name: 'madagascar'),
  Country(code: 'MW', name: 'malawi'),
  Country(code: 'MV', name: 'maldives'),
  Country(code: 'ML', name: 'mali'),
  Country(code: 'MT', name: 'malta'),
  Country(code: 'MQ', name: 'martinique'),
  Country(code: 'MR', name: 'mauritania'),
  Country(code: 'MU', name: 'mauritius'),
  Country(code: 'YT', name: 'mayotte'),
  Country(code: 'FM', name: 'micronesia_federated_states'),
  Country(code: 'MD', name: 'moldova_republic_of'),
  Country(code: 'MC', name: 'monaco'),
  Country(code: 'MN', name: 'mongolia'),
  Country(code: 'ME', name: 'montenegro'),
  Country(code: 'MS', name: 'montserrat'),
  Country(code: 'MZ', name: 'mozambique'),
  Country(code: 'NA', name: 'namibia'),
  Country(code: 'NR', name: 'nauru'),
  Country(code: 'NP', name: 'nepal'),
  Country(code: 'NC', name: 'new_caledonia'),
  Country(code: 'NE', name: 'niger'),
  Country(code: 'NU', name: 'niue'),
  Country(code: 'NF', name: 'norfolk_island'),
  Country(code: 'MP', name: 'northern_mariana_islands'),
  Country(code: 'OM', name: 'oman'),
  Country(code: 'PW', name: 'palau'),
  Country(code: 'PS', name: 'palestine_state_of'),
  Country(code: 'PG', name: 'papua_new_guinea'),
  Country(code: 'PN', name: 'pitcairn'),
  Country(code: 'RE', name: 'reunion'),
  Country(code: 'RW', name: 'rwanda'),
  Country(code: 'SM', name: 'san_marino'),
  Country(code: 'ST', name: 'sao_tome_and_principe'),
  Country(code: 'SN', name: 'senegal'),
  Country(code: 'SC', name: 'seychelles'),
  Country(code: 'SL', name: 'sierra_leone'),
  Country(code: 'SK', name: 'slovakia'),
  Country(code: 'SI', name: 'slovenia'),
  Country(code: 'SB', name: 'solomon_islands'),
  Country(code: 'SO', name: 'somalia'),
  Country(code: 'SS', name: 'south_sudan'),
  Country(code: 'LK', name: 'sri_lanka'),
  Country(code: 'BL', name: 'st_barthelemy'),
  Country(code: 'SH', name: 'st_helena'),
  Country(code: 'PM', name: 'st_pierre_and_miquelon'),
  Country(code: 'VC', name: 'st_vincent_and_grenadines'),
  Country(code: 'SR', name: 'suriname'),
  Country(code: 'SJ', name: 'svalbard_and_jan_mayen'),
  Country(code: 'SZ', name: 'swaziland'),
  Country(code: 'SY', name: 'syrian_arab_republic'),
  Country(code: 'TJ', name: 'tajikistan'),
  Country(code: 'TZ', name: 'tanzania_united_republic_of'),
  Country(code: 'TG', name: 'togo'),
  Country(code: 'TK', name: 'tokelau'),
  Country(code: 'TO', name: 'tonga'),
  Country(code: 'TC', name: 'turks_and_caicos_islands'),
  Country(code: 'TV', name: 'tuvalu'),
  Country(code: 'UG', name: 'uganda'),
  Country(code: 'UZ', name: 'uzbekistan'),
  Country(code: 'VU', name: 'vanuatu'),
  Country(code: 'VA', name: 'holy_see_vatican_city_state'),
  Country(code: 'VG', name: 'virgin_islands_british'),
  Country(code: 'VI', name: 'virgin_islands_us'),
  Country(code: 'WF', name: 'wallis_and_futuna'),
  Country(code: 'EH', name: 'western_sahara'),
  Country(code: 'YE', name: 'yemen'),
  Country(code: 'ZW', name: 'zimbabwe'),
];

// =========================================================
// Priority Countries for Progressive Loading
// =========================================================
// These are the most commonly used countries, loaded first for better UX
// Selected based on population, economic activity, and app usage patterns
const List<Country> kPriorityCountries = [
  // Americas (most used in this region)
  Country(code: 'US', name: 'united_states'),
  Country(code: 'MX', name: 'mexico'),
  Country(code: 'CA', name: 'canada'),
  Country(code: 'BR', name: 'brazil'),
  Country(code: 'AR', name: 'argentina'),
  Country(code: 'CO', name: 'colombia'),
  Country(code: 'CL', name: 'chile'),
  Country(code: 'PE', name: 'peru'),

  // Europe (major markets)
  Country(code: 'ES', name: 'spain'),
  Country(code: 'GB', name: 'united_kingdom'),
  Country(code: 'FR', name: 'france'),
  Country(code: 'DE', name: 'germany'),
  Country(code: 'IT', name: 'italy'),
  Country(code: 'PT', name: 'portugal'),
  Country(code: 'NL', name: 'netherlands'),

  // Asia (major markets)
  Country(code: 'CN', name: 'china'),
  Country(code: 'IN', name: 'india'),
  Country(code: 'JP', name: 'japan'),
  Country(code: 'KR', name: 'south_korea'),
  Country(code: 'ID', name: 'indonesia'),
  Country(code: 'TH', name: 'thailand'),
  Country(code: 'SG', name: 'singapore'),

  // Oceania
  Country(code: 'AU', name: 'australia'),
  Country(code: 'NZ', name: 'new_zealand'),

  // Africa (major markets)
  Country(code: 'ZA', name: 'south_africa'),
  Country(code: 'NG', name: 'nigeria'),
  Country(code: 'EG', name: 'egypt'),

  // Middle East
  Country(code: 'AE', name: 'united_arab_emirates'),
  Country(code: 'SA', name: 'saudi_arabia'),
];

/// Helper function to get remaining countries (not in priority list)
/// Used for progressive loading - these are loaded after priority countries
List<Country> getRemainingCountries() {
  final priorityCodes = kPriorityCountries.map((c) => c.code).toSet();
  return kCountries.where((c) => !priorityCodes.contains(c.code)).toList();
}

/// Helper function to get a country by code (for pre-selecting non-priority countries)
/// Returns null if country code is not found
Country? getCountryByCode(String code) {
  try {
    return kCountries.firstWhere((country) => country.code == code);
  } catch (e) {
    return null;
  }
}
