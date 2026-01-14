import 'dart:io';

void main() {
  print('🔍 Analizando sistema de traducciones...\n');
  
  final translationsDir = Directory('lib/core/lang/translations/es');
  final files = translationsDir.listSync().whereType<File>().where((f) => f.path.endsWith('.dart')).toList();
  
  final Map<String, List<String>> allKeys = {};
  final Map<String, int> keyCount = {};
  
  for (var file in files) {
    final fileName = file.path.split('\\').last;
    print('📄 Analizando: $fileName');
    
    final content = file.readAsStringSync();
    final regex = RegExp(r"'([^']+)':\s*'");
    final matches = regex.allMatches(content);
    
    for (var match in matches) {
      final key = match.group(1)!;
      
      if (!allKeys.containsKey(key)) {
        allKeys[key] = [];
        keyCount[key] = 0;
      }
      
      allKeys[key]!.add(fileName);
      keyCount[key] = keyCount[key]! + 1;
    }
  }
  
  // Buscar claves duplicadas
  print('\n🔴 CLAVES DUPLICADAS:');
  print('=' * 80);
  
  final duplicates = keyCount.entries.where((e) => e.value > 1).toList();
  duplicates.sort((a, b) => b.value.compareTo(a.value));
  
  if (duplicates.isEmpty) {
    print('✅ No se encontraron claves duplicadas');
  } else {
    for (var entry in duplicates) {
      print('\n❌ "${entry.key}" aparece ${entry.value} veces en:');
      for (var file in allKeys[entry.key]!) {
        print('   - $file');
      }
    }
  }
  
  print('\n\n📊 ESTADÍSTICAS:');
  print('=' * 80);
  print('Total de archivos: ${files.length}');
  print('Total de claves únicas: ${allKeys.length}');
  print('Total de claves duplicadas: ${duplicates.length}');
  
  // Mostrar conteo por archivo
  print('\n📈 Claves por archivo:');
  for (var file in files) {
    final fileName = file.path.split('\\').last;
    final content = file.readAsStringSync();
    final regex = RegExp(r"'([^']+)':\s*'");
    final count = regex.allMatches(content).length;
    print('   $fileName: $count claves');
  }
}
