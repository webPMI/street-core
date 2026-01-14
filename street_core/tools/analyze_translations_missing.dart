import 'dart:io';

void main() {
  print('🔍 Analizando claves de traducción Vs LocaleKeys...\n');

  final root = Directory.current.path;
  final localeFile = File('lib/core/lang/locale_keys.dart');
  if (!localeFile.existsSync()) {
    print('No se encontró locale_keys.dart');
    return;
  }

  final localeContent = localeFile.readAsStringSync();
  final keyRegex = RegExp(r"static const String [a-zA-Z0-9_]+ = '([^']+)';");
  final localeKeys = <String>{};
  for (var m in keyRegex.allMatches(localeContent)) {
    localeKeys.add(m.group(1)!);
  }

  final translationsDir = Directory('lib/core/lang/translations/es');
  final files = translationsDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  final translationKeys = <String, String>{}; // key -> file
  final regex = RegExp(r"'([^']+)':\s*'([\s\S]*?)',", multiLine: true);

  for (var file in files) {
    final content = file.readAsStringSync();
    for (var m in regex.allMatches(content)) {
      translationKeys[m.group(1)!] = file.path.split('\\').last;
    }
  }

  final missing =
      localeKeys.where((k) => !translationKeys.containsKey(k)).toList()..sort();
  final unused =
      translationKeys.keys.where((k) => !localeKeys.contains(k)).toList()
        ..sort();

  print('\n📌 Resultados:');
  print('Total keys in LocaleKeys: ${localeKeys.length}');
  print('Total keys in Spanish translations: ${translationKeys.length}');
  print(
    'Missing keys (present in LocaleKeys but NOT translated): ${missing.length}',
  );
  if (missing.isNotEmpty) {
    for (var k in missing) print('  - $k');
  }

  print(
    '\nExtra translation keys (present in es but not in LocaleKeys): ${unused.length}',
  );
  if (unused.isNotEmpty) {
    for (var k in unused) print('  - ${k} (in ${translationKeys[k]})');
  }

  // Show per-file counts
  print('\n📈 Claves por archivo:');
  for (var file in files) {
    final count = RegExp(
      r"'([^']+)':\s*'",
    ).allMatches(file.readAsStringSync()).length;
    print('  - ${file.path.split('\\').last}: $count');
  }
}
