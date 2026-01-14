# Informe de auditoría de traducciones (ES)

Resumen rápido:

- Total claves en `LocaleKeys`: 1272
- Total claves en traducciones ES: 2774 (tras añadir placeholders)
- Claves faltantes (antes): 396 → ahora 0 (se añadieron placeholders en `missing_es.dart`)
- Claves extra (presentes en ES pero no en `LocaleKeys`): 1502
- Claves duplicadas detectadas: 78 (ver salida de `analyze_translations.dart` para detalles)

Qué hice:

1. Ejecuté un análisis que compara `locale_keys.dart` con las traducciones en `lib/core/lang/translations/es`.
2. Generé `tools/missing_locale_keys.txt` con las 396 claves que faltaban.
3. Generé `lib/core/lang/translations/es/missing_es.dart` con placeholders (texto "(POR TRADUCIR)") para esas claves.
4. Importé `missing_es.dart` en `lib/core/lang/translations/es.dart` y lo incluí en el `spanish` map.
5. Re-ejecuté el análisis: ahora *no hay claves faltantes* según `LocaleKeys`.

Siguientes pasos recomendados:

- Revisar las 1502 claves extra (muchas son nombres de idiomas y docs) y decidir si deben añadirse a `LocaleKeys` o eliminarse de las traducciones si no se usan.
- Revisar las 78 claves duplicadas y decidir la ubicación canónica para cada una (p.ej. `core_es.dart` para claves globales).
- Reemplazar los placeholders en `missing_es.dart` por traducciones reales en español.

¿Quieres que proceda automáticamente con alguna de las siguientes acciones?

- A: Añadir automáticamente las claves extra a `locale_keys.dart` (generaría nuevas constantes).
- B: Consolidar claves duplicadas (eliminar duplicados manteniendo la definición en un único archivo, prefijado por `core_es.dart`).
- C: Generar PR con los cambios actuales y un resumen para revisión humana (recomendado si quieres revisar los textos antes de publicarlos).
- D: Empezar a sustituir los placeholders por traducciones reales (puedo aplicar traducción automática provisional si lo permites, o dejar los placeholders para traducción humana).

---

Si me dices la opción (o combinación) a seguir, la implemento y te muestro los cambios y el diff.  
