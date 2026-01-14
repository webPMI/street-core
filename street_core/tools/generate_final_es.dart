import 'dart:io';

void main() {
  final localeFile = File('lib/core/lang/locale_keys.dart');
  if (!localeFile.existsSync()) {
    print('locale_keys.dart not found');
    return;
  }

  final localeContent = localeFile.readAsStringSync();
  final keyRegex = RegExp(r"static const String [a-zA-Z0-9_]+ = '([^']+)';");
  final localeKeys = <String>[];
  for (var m in keyRegex.allMatches(localeContent)) {
    localeKeys.add(m.group(1)!);
  }
  print('Locale keys: ${localeKeys.length}');

  // Priority order -- same as previous es.dart but we'll use a sane order
  final order = [
    'core_es.dart',
    'languages_es.dart',
    'geo_es.dart',
    'help_guide_es.dart',
    'auth_es.dart',
    'profile_es.dart',
    'competitions_es.dart',
    'competitions_docs_es.dart',
    'tournaments_es.dart',
    'events_es.dart',
    'ui_es.dart',
    'media_es.dart',
    'public_es.dart',
    'missing_es.dart',
    'legal_es.dart',
  ];

  final translationsDir = Directory('lib/core/lang/translations/es');
  final files = order.map((n) => File('${translationsDir.path}\$n')).where((f) => f.existsSync()).toList();

  final map = <String, String>{};

  final entryRegex = RegExp(r"'([^']+)':\s*'([\s\S]*?)',", multiLine: true);

  for (var file in files) {
    final content = file.readAsStringSync();
    for (var m in entryRegex.allMatches(content)) {
      final key = m.group(1)!;
      var value = m.group(2) ?? '';
      if (map.containsKey(key)) continue; // first wins (priority)
      map[key] = value;
    }
  }

  // Now ensure we include only keys from localeKeys; for missing keys, insert a placeholder
  final finalMap = <String, String>{};
  for (var key in localeKeys) {
    if (map.containsKey(key)) {
      finalMap[key] = map[key]!;
    } else {
      finalMap[key] = key; // fallback to key itself; consider translating later
    }
  }

  // Write final file
  final outDir = Directory('lib/core/lang/translations/es');
  final outFile = File('${outDir.path}/final_es.dart');
  final buffer = StringBuffer();
  buffer.writeln('// Archivo generado automáticamente: traducción consolidada en español.');
  buffer.writeln('// Contiene únicamente claves definidas en LocaleKeys para evitar redundancias.');
  buffer.writeln('final Map<String, String> spanish = {');
  finalMap.forEach((k, v) {
    final escaped = v.replaceAll("'", "\\'");
    buffer.writeln("  '$k': '$escaped',");
  });
  buffer.writeln('};');

  outFile.writeAsStringSync(buffer.toString());
  print('Se generó ${outFile.path} con ${finalMap.length} claves.');
}
