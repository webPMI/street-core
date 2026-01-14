import 'dart:io';

void main() {
  final missingFile = File('tools/missing_locale_keys.txt');
  if (!missingFile.existsSync()) {
    print('No missing keys file found. Run analyzer first.');
    return;
  }

  final keys = missingFile.readAsLinesSync().where((l) => l.trim().isNotEmpty).toList();
  final buffer = StringBuffer();
  buffer.writeln('// Archivo generado automáticamente: entradas de traducciones faltantes (placeholders).');
  buffer.writeln('// Reemplaza los valores por traducciones reales en español cuando estén disponibles.');
  buffer.writeln();
  buffer.writeln('const Map<String, String> missingEs = {');
  for (var key in keys) {
    final human = humanize(key);
    buffer.writeln("  '$key': '$human (POR TRADUCIR)',");
  }
  buffer.writeln('};');

  final out = File('lib/core/lang/translations/es/missing_es.dart');
  out.writeAsStringSync(buffer.toString());
  print('Archivo generado: lib/core/lang/translations/es/missing_es.dart con ${keys.length} claves.');
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
