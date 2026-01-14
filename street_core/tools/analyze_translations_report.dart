import 'dart:io';

void main() {
  print('🔍 Analizando claves de traducción Vs LocaleKeys...\n');

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
  final files = translationsDir.listSync().whereType<File>().where((f) => f.path.endsWith('.dart')).toList();

  final translationKeys = <String, String>{}; // key -> file
  final regex = RegExp(r"'([^']+)':\s*'([\s\S]*?)',",
      multiLine: true);

  for (var file in files) {
    final content = file.readAsStringSync();
    for (var m in regex.allMatches(content)) {
      translationKeys[m.group(1)!] = file.path.split('\\').last;
    }
  }

  final missing = localeKeys.where((k) => !translationKeys.containsKey(k)).toList()..sort();
  final unused = translationKeys.keys.where((k) => !localeKeys.contains(k)).toList()..sort();

  // Write missing keys to a file to help manual sync
  final missingFile = File('tools/missing_locale_keys.txt');
  missingFile.writeAsStringSync(missing.join('\n'));

  print('\n📌 Resumen corto:');
  print('  - Total keys in LocaleKeys: ${localeKeys.length}');
  print('  - Total keys in Spanish translations: ${translationKeys.length}');
  print('  - Missing keys (in LocaleKeys but NOT translated): ${missing.length}');
  print('  - Extra translation keys (in es but not in LocaleKeys): ${unused.length}');

  if (missing.isNotEmpty) {
    print('\n📝 Se han guardado las claves faltantes en tools/missing_locale_keys.txt');
  }

  if (unused.isNotEmpty) {
    print('\n📌 Ejemplos de claves extra (primeros 50):');
    for (var k in unused.take(50)) print('   - ${k} (en ${translationKeys[k]})');
    if (unused.length > 50) print('   ... (${unused.length - 50} más)');
  }

  // Show per-file counts
  print('\n📈 Claves por archivo:');
  for (var file in files) {
    final fileName = file.path.split('\\').last;
    final content = file.readAsStringSync();
    final regex = RegExp(r"'([^']+)':\s*'");
    final count = regex.allMatches(content).length;
    print('   - $fileName: $count claves');
  }

  print('\n✅ Análisis completado. Próximo paso sugerido: revisar tools/missing_locale_keys.txt y decidir si añadimos las claves a locale_keys.dart o eliminamos claves de traducciones no usadas.');
}
