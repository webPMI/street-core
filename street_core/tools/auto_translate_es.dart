import 'dart:convert';
import 'dart:io';

// Detects non-Spanish entries in the es translation files and auto-translates
// them to Spanish using LibreTranslate. Outputs translated files under
// lib/core/lang/translations/es/auto_translated/<original_filename>
// Usage: dart tools/auto_translate_es.dart

final _apiBase = Platform.environment['LIBRETRANSLATE_URL'] ?? 'https://libretranslate.com';

Future<void> main() async {
  final translationsDir = Directory('lib/core/lang/translations/es');
  final outDir = Directory('lib/core/lang/translations/es/auto_translated');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  final files = translationsDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.contains('auto_translated'))
      .toList();

  final report = <String>[];

  for (var file in files) {
    print('Procesando ${file.path}...');
    final content = file.readAsStringSync();
    final regex = RegExp(r"'([^']+)':\s*'([\s\S]*?)',", multiLine: true);

    var modified = content;
    var changed = 0;

    for (var m in regex.allMatches(content)) {
      final key = m.group(1)!;
      final value = m.group(2) ?? '';
      if (value.trim().isEmpty) continue;

      // Skip obvious Spanish (contains common Spanish words) heuristics
      if (looksLikeSpanish(value)) continue;

      // Protect interpolation tokens like {count} or {name}
      final tokens = <String>[];
      var tmp = value.replaceAllMapped(RegExp(r"\{[^}]+\}"), (mm) {
        tokens.add(mm.group(0)!);
        return '___VAR${tokens.length - 1}___';
      });

      // Detect language
      final detected = await detectLanguage(tmp);
      if (detected == null) continue;
      if (detected.language == 'es' && detected.confidence > 0.6) continue;

      // Translate
      final translated = await translateText(tmp, detected.language, 'es');
      var restored = translated;
      for (var idx = 0; idx < tokens.length; idx++) {
        restored = restored.replaceAll('___VAR\$${idx}___', tokens[idx]);
      }
      restored = restored.replaceAll("'", "\\'");

      // Replace the exact match in the file content
      final originalLiteral = "'${key}': '${value}',";
      final newLiteral = "'${key}': '${restored}',";
      if (modified.contains(originalLiteral)) {
        modified = modified.replaceFirst(originalLiteral, newLiteral);
        changed++;
        report.add('${file.path} -> $key');
      }

      // Be polite
      await Future.delayed(Duration(milliseconds: 500));
    }

    if (changed > 0) {
      final outFile = File('${outDir.path}/${file.uri.pathSegments.last}');
      outFile.writeAsStringSync(modified);
      print('  Traducciones aplicadas: $changed -> ${outFile.path}');
    } else {
      print('  Sin cambios');
    }
  }

  final reportFile = File('tools/auto_translate_report.txt');
  reportFile.writeAsStringSync(report.join('\n'));
  print('\nReporte generado en tools/auto_translate_report.txt con ${report.length} entradas.');
}

bool looksLikeSpanish(String s) {
  final spanishWords = [
    'el', 'la', 'los', 'las', 'que', 'para', 'por', 'con', 'sin', 'y', 'o', 'muy', 'por', 'Hola', 'Hola', 'Página', 'Fecha', 'Mostrar', 'Ocultar', 'Cargando'
  ];
  final lower = s.toLowerCase();
  for (var w in spanishWords) {
    if (lower.contains(w)) return true;
  }
  // If it contains accented characters, likely Spanish
  if (s.contains(RegExp(r'[áéíóúñÁÉÍÓÚÑ]'))) return true;
  return false;
}

class DetectionResult {
  final String language;
  final double confidence;
  DetectionResult(this.language, this.confidence);
}

Future<DetectionResult?> detectLanguage(String text) async {
  try {
    final uri = Uri.parse('$_apiBase/detect');
    final payload = jsonEncode({'q': text});

    final httpClient = HttpClient();
    final request = await httpClient.postUrl(uri);
    request.headers.set('Content-Type', 'application/json');
    request.add(utf8.encode(payload));

    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode == 200) {
      final data = jsonDecode(body);
      if (data is List && data.isNotEmpty) {
        final top = data[0];
        return DetectionResult(top['language'] as String, (top['confidence'] as num).toDouble());
      }
    }
  } catch (e) {
    print('Error en detectLanguage: $e');
  }
  return null;
}

Future<String> translateText(String text, String source, String target) async {
  try {
    final uri = Uri.parse('$_apiBase/translate');
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
      return data.toString();
    } else {
      print('\nError ${response.statusCode} en la traducción: $body');
      return text;
    }
  } catch (e) {
    print('Excepción en translateText: $e');
    return text;
  }
}
