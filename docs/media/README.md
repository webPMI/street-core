# Documentación del Sistema de Media

Esta carpeta contiene la documentación completa del sistema de uploads y gestión de archivos multimedia de StreetCore.

---

## 📚 Documentos Disponibles

### 1. [AUDIT_REPORT_2026-01-05.md](./AUDIT_REPORT_2026-01-05.md) ⭐ ACTUALIZADO
**Reporte de auditoría del sistema**

Para: Ingenieros, arquitectos, gerentes de proyecto

Contenido:
- Verificación completa documentación vs implementación
- Análisis de 31 features del sistema
- Resultado: **100% Compliant** 🎉 (31/31 features completas)
- GetPostMedia endpoint implementado completamente
- Límites de archivos verificados
- Endpoints verificados
- Seguridad multi-capa validada
- Estado: PRODUCTION-READY - CERO ISSUES PENDIENTES

**Usa este documento cuando**:
- Necesites verificar que todo funciona como se documentó
- Quieras conocer el estado real del sistema
- Busques validación antes de producción
- Necesites reportar compliance
- Planees auditorías futuras

---

### 2. [MEDIA_SYSTEM_GUIDE.md](./MEDIA_SYSTEM_GUIDE.md)
**Guía completa del sistema de media**

Para: Ingenieros, arquitectos, agentes IA

Contenido:
- Resumen ejecutivo del sistema
- Tipos de archivos y límites detallados
- Todos los puntos de upload (frontend + backend)
- Endpoints completos con ejemplos
- Estructura de almacenamiento
- Capas de seguridad y validación
- Flujos de datos paso a paso
- Configuración avanzada
- Troubleshooting
- Roadmap y pendientes

**Usa este documento cuando**:
- Necesites entender la arquitectura completa
- Vayas a modificar el sistema de uploads
- Necesites documentar nuevas funcionalidades
- Estés haciendo debugging profundo
- Planees optimizaciones o refactorización

---

### 3. [QUICK_REFERENCE.md](./QUICK_REFERENCE.md)
**Referencia rápida para desarrolladores**

Para: Desarrolladores frontend/backend, integraciones rápidas

Contenido:
- Tabla de límites de archivos
- Ejemplos de código frontend (Dart)
- Curl examples para backend
- Snippets de validación
- Configuración rápida
- Troubleshooting one-liners
- Integración por módulo

**Usa este documento cuando**:
- Necesites implementar un upload nuevo
- Busques un ejemplo de código específico
- Necesites recordar límites o endpoints
- Estés haciendo integraciones rápidas
- Necesites resolver un error común

---

## 🎯 ¿Qué Documento Usar?

### Escenario 1: Nuevo Desarrollador en el Equipo
1. Lee **MEDIA_SYSTEM_GUIDE.md** (sección "Resumen Ejecutivo")
2. Revisa **QUICK_REFERENCE.md** completo
3. Experimenta con ejemplos de QUICK_REFERENCE
4. Consulta MEDIA_SYSTEM_GUIDE para detalles específicos

### Escenario 2: Agregar Upload en Nueva Feature
1. Consulta **QUICK_REFERENCE.md** > "Integración por Módulo"
2. Copia snippet relevante
3. Ajusta parámetros según necesidad
4. Verifica límites en QUICK_REFERENCE > "Límites de Archivos"

### Escenario 3: Modificar Configuración
1. **QUICK_REFERENCE.md** > "Configuración Rápida"
2. Modifica archivos indicados
3. Verifica en **MEDIA_SYSTEM_GUIDE.md** > "Configuración" si hay efectos secundarios

### Escenario 4: Debugging de Error
1. **QUICK_REFERENCE.md** > "Errores Comunes"
2. Si no resuelve: **MEDIA_SYSTEM_GUIDE.md** > "Troubleshooting"
3. Si aún persiste: revisa "Capas de Seguridad" en MEDIA_SYSTEM_GUIDE

### Escenario 5: Planear Nueva Funcionalidad
1. **MEDIA_SYSTEM_GUIDE.md** > "Arquitectura"
2. **MEDIA_SYSTEM_GUIDE.md** > "Flujo de Datos"
3. **MEDIA_SYSTEM_GUIDE.md** > "Próximos Pasos / Roadmap"
4. Documenta tu cambio siguiendo el formato existente

---

## 🔄 Mantenimiento de la Documentación

### Cuándo Actualizar

Actualiza estos documentos cuando:
- ✅ Cambies límites de tamaño
- ✅ Agregues nuevo endpoint de upload
- ✅ Modifiques validaciones
- ✅ Cambies estructura de almacenamiento
- ✅ Implementes nueva funcionalidad (video processing, etc.)
- ✅ Corrijas un bug relacionado con uploads
- ✅ Agregues nuevo tipo de archivo permitido

### Cómo Actualizar

1. **Cambios menores** (límites, configuración):
   - Actualiza **QUICK_REFERENCE.md** primero
   - Actualiza sección correspondiente en **MEDIA_SYSTEM_GUIDE.md**
   - Actualiza versión y changelog en MEDIA_SYSTEM_GUIDE

2. **Cambios mayores** (nueva funcionalidad):
   - Actualiza **MEDIA_SYSTEM_GUIDE.md** completo
   - Agrega ejemplo en **QUICK_REFERENCE.md**
   - Actualiza roadmap si aplica
   - Incrementa versión major

3. **Correcciones**:
   - Corrige en ambos documentos
   - No cambies versión

### Formato de Changelog

```markdown
### vX.Y (YYYY-MM-DD)
- Descripción del cambio 1
- Descripción del cambio 2
- Bugs corregidos
```

---

## 📋 Checklist de Actualización

Usa este checklist cuando hagas cambios al sistema de media:

```markdown
- [ ] Código actualizado (frontend/backend)
- [ ] Tests actualizados (cuando aplique)
- [ ] MEDIA_SYSTEM_GUIDE.md actualizado
  - [ ] Sección afectada modificada
  - [ ] Changelog agregado
  - [ ] Versión incrementada
- [ ] QUICK_REFERENCE.md actualizado
  - [ ] Tabla de límites (si cambió)
  - [ ] Ejemplos de código (si cambió)
  - [ ] Errores comunes (si aplica)
- [ ] README.md revisado (este archivo)
- [ ] Commits con mensaje descriptivo
```

---

## 🤖 Guía para Agentes IA

Si eres un agente IA trabajando con el sistema de media:

### Antes de Modificar Código
1. Lee **MEDIA_SYSTEM_GUIDE.md** completo
2. Identifica secciones afectadas por tu tarea
3. Verifica límites y restricciones actuales

### Durante Modificación
1. Mantén consistencia frontend/backend
2. Actualiza validaciones en ambos lados
3. Respeta convenciones de nombres
4. Sigue patrones existentes

### Después de Modificar
1. Actualiza documentación según checklist
2. Verifica que ejemplos sigan funcionando
3. Agrega entrada al changelog
4. Documenta decisiones de diseño

### Reglas Importantes
- ⚠️ **NUNCA** cambies límites solo en un lado (frontend o backend)
- ⚠️ **NUNCA** omitas validación CSRF en nuevos endpoints
- ⚠️ **SIEMPRE** usa MediaValidator en frontend antes de upload
- ⚠️ **SIEMPRE** documenta nuevos endpoints en ambos archivos

---

## 📞 Contacto y Preguntas

Para preguntas sobre el sistema de media:
1. Consulta primero **QUICK_REFERENCE.md**
2. Si no resuelve, revisa **MEDIA_SYSTEM_GUIDE.md**
3. Si aún tienes dudas, revisa código fuente:
   - Frontend: `street_core/lib/core/media/`
   - Backend: `backend/features/media/`

---

**Última actualización**: 2026-01-05
**Versión de documentación**: 1.0
**Sistema compatible**: StreetCore v0.1
