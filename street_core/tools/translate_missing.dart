import 'dart:convert';
import 'dart:io';

// Simple script to translate missing_locale_keys.txt keys to Spanish using
// LibreTranslate (https://libretranslate.com or https://libretranslate.de).
// Usage: dart tools/translate_missing.dart
// Optional env var: LIBRETRANSLATE_URL (default https://libretranslate.com)
// Note: Respect rate limits of the service. This script inserts a short delay.

final _apiUrl = Platform.environment['LIBRETRANSLATE_URL'] ?? 'https://libretranslate.com/translate';

Future<void> main() async {
  final keysFile = File('tools/missing_locale_keys.txt');
  final keysExists = keysFile.existsSync();
  List<String> keys = [];

  if (keysExists) {
    keys = keysFile.readAsLinesSync().where((l) => l.trim().isNotEmpty).toList();
    print('Traducción de ${keys.length} claves desde tools/missing_locale_keys.txt usando $_apiUrl');
  }

  // Si no hay claves en tools/missing_locale_keys.txt, intenta parsear el archivo missing_es.dart
  if (keys.isEmpty) {
    final missingEsFile = File('lib/core/lang/translations/es/missing_es.dart');
    if (!missingEsFile.existsSync()) {
      print('No hay claves para traducir: ni tools/missing_locale_keys.txt ni missing_es.dart contienen entradas.');
      return;
    }

    final content = missingEsFile.readAsStringSync();
    final entryRegex = RegExp(r"'([^']+)':\s*'([^']*)',", multiLine: true);
    final entries = <MapEntry<String, String>>[];
    for (var m in entryRegex.allMatches(content)) {
      final key = m.group(1)!;
      final value = m.group(2)!;
      entries.add(MapEntry(key, value));
    }

    if (entries.isEmpty) {
      print('No se encontraron entradas en missing_es.dart para traducir.');
      return;
    }

    print('Traducción de ${entries.length} entradas desde missing_es.dart');

    final outFile = File('lib/core/lang/translations/es/missing_es_translated.dart');
    final buffer = StringBuffer();
    buffer.writeln('// Archivo generado automáticamente: traducciones automáticas de claves faltantes.');
    buffer.writeln('// Revísalas y ajusta el contexto si es necesario.');
    buffer.writeln();
    buffer.writeln('const Map<String, String> missingEs = {');

    int i = 0;
    for (var e in entries) {
      i++;
      final key = e.key;
      var value = e.value;
      // Remove placeholder marker if present
      value = value.replaceAll(RegExp(r"\(POR TRADUCIR\)", caseSensitive: false), '').trim();

      // Protect interpolation tokens like {count} or {name}
      final tokens = <String>[];
      var tmp = value.replaceAllMapped(RegExp(r"\{[^}]+\}"), (m) {
        tokens.add(m.group(0)!);
        return '___VAR${tokens.length - 1}___';
      });

      final translated = await translateText(tmp, 'en', 'es');
      // Reinstate tokens
      var restored = translated;
      for (var idx = 0; idx < tokens.length; idx++) {
        restored = restored.replaceAll('___VAR\$${idx}___', tokens[idx]);
      }

      // Ensure single quotes are escaped
      restored = restored.replaceAll("'", "\\'");

      buffer.writeln("  '$key': '$restored',");
      stdout.write('\r$i/${entries.length}');

      // Be polite with the translation API
      await Future.delayed(Duration(milliseconds: 500));
    }

    buffer.writeln('};');
    outFile.writeAsStringSync(buffer.toString());
    print('\nArchivo generado en ${outFile.path}');
    print('Nota: revisa y mueve o combina este archivo con missing_es.dart cuando confirmes las traducciones.');
    return;
  }

  // Si llegamos aquí, keys viene de tools/missing_locale_keys.txt
  print('Modo: traducción desde lista simple de claves');
  final outFile = File('lib/core/lang/translations/es/missing_es.dart');
  final buffer = StringBuffer();
  buffer.writeln('// Archivo generado automáticamente: traducciones automáticas de claves faltantes.');
  buffer.writeln('// Revísalas y ajusta el contexto si es necesario.');
  buffer.writeln();
  buffer.writeln('const Map<String, String> missingEs = {');

  int i = 0;
  for (var key in keys) {
    i++;
    final human = humanize(key);

    // Protect interpolation tokens like {count} or {name}
    final tokens = <String>[];
    var tmp = human.replaceAllMapped(RegExp(r"\{[^}]+\}"), (m) {
      tokens.add(m.group(0)!);
      return '___VAR${tokens.length - 1}___';
    });

    final translated = await translateText(tmp, 'en', 'es');
    // Reinstate tokens
    var restored = translated;
    for (var idx = 0; idx < tokens.length; idx++) {
      restored = restored.replaceAll('___VAR\$${idx}___', tokens[idx]);
    }

    // Ensure single quotes are escaped
    restored = restored.replaceAll("'", "\\'");

    buffer.writeln("  '$key': '$restored',");
    stdout.write('\r$i/${keys.length}');

    // Be polite with the translation API
    await Future.delayed(Duration(milliseconds: 500));
  }

  buffer.writeln('};');
  outFile.writeAsStringSync(buffer.toString());
  print('\nArchivo generado en ${outFile.path}');
}

String humanize(String key) {
  final parts = key.replaceAll('_', ' ').split('.');
  final words = <String>[];
  for (var p in parts) {
    words.addAll(p.split(' '));
  }
  final transformed = words.map((w) {
    if (w.isEmpty) return w;
    return w[0].toUpperCase() + w.substring(1);
  }).join(' ');
  return transformed;
}

Future<String> translateText(String text, String source, String target) async {
  try {
    final uri = Uri.parse(_apiUrl);
    final payload = jsonEncode({'q': text, 'source': source, 'target': target, 'format': 'text'});

    final httpClient = HttpClient();
    final request = await httpClient.postUrl(uri);
    request.headers.set('Content-Type', 'application/json');
    request.add(utf8.encode(payload));

    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode == 200) {
      final data = jsonDecode(body);
      if (data is Map && data.containsKey('translatedText')) {
        return data['translatedText'] as String;
      }
      // Some instances return a list for batch requests; handle simple map case only
      return data.toString();
    } else {
      print('\nError ${response.statusCode} en la traducción: $body');
      return text; // Fallback to source
    }
  } catch (e) {
    print('\nExcepción en translateText: $e');
    return text;
  }
}
