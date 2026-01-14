# ADR-009: Cloud Storage Migration Strategy

**Status**: Accepted
**Date**: 2025-01-04
**Decision Makers**: DevOps Team
**Tags**: infrastructure, storage, cloud, migration

---

## Context

StreetCore actualmente almacena todos los archivos multimedia (imágenes, videos, avatares) en el filesystem local del servidor. Esta estrategia funciona bien para desarrollo y pruebas, pero presenta limitaciones significativas para producción:

### Problemas Actuales

1. **Escalabilidad Limitada**
   - El espacio en disco del servidor es finito
   - Crecimiento de archivos multimedia es imprevisible
   - Difícil agregar más capacidad sin downtime

2. **Disponibilidad**
   - Single point of failure (servidor único)
   - Backups manuales y complejos
   - Sin redundancia geográfica

3. **Performance**
   - Sin CDN para distribución global
   - Ancho de banda del servidor limitado
   - Latencia alta para usuarios distantes

4. **Costo Operacional**
   - Provisión de storage debe hacerse anticipadamente
   - Backup storage adicional necesario
   - Mantenimiento manual de limpieza

5. **Deployment Complexity**
   - Archivos deben migrarse entre servidores
   - Scaling horizontal requiere shared storage (NFS, etc.)
   - Containers son stateful (no cloud-native)

### Requisitos

1. **Cero Downtime**: La migración debe ser transparente para usuarios
2. **Reversibilidad**: Debe poder revertirse si hay problemas
3. **Gradualidad**: Migración por lotes, no todo de golpe
4. **Compatibilidad**: URLs existentes deben seguir funcionando
5. **Costo-Efectivo**: Pago por uso real, no provisión anticipada

---

## Decision

Implementaremos una **estrategia de migración gradual** de filesystem local a S3 (o S3-compatible storage) utilizando un **patrón híbrido** con las siguientes fases:

### Fase 1: Abstraction Layer (Storage Interface)

Crear una abstraction layer que permita múltiples backends de storage:

```go
type Storage interface {
    Save(ctx context.Context, file io.Reader, path string, metadata Metadata) (*SaveResult, error)
    Get(ctx context.Context, path string) (io.ReadCloser, error)
    Delete(ctx context.Context, path string) error
    Exists(ctx context.Context, path string) (bool, error)
    GetPublicURL(path string) string
}
```

**Implementaciones:**
- `FilesystemStorage`: Backend actual (local disk)
- `S3Storage`: Backend para AWS S3 o compatible (MinIO, DigitalOcean Spaces)
- `HybridStorage`: Combina ambos para migración gradual

### Fase 2: Feature Flags

Implementar feature flags para control granular:

```bash
FEATURE_S3_STORAGE=false       # Full S3 mode
FEATURE_HYBRID_STORAGE=false   # Hybrid mode (migration)
FEATURE_MIGRATION_ENABLED=false # Background migration
FEATURE_CDN_ENABLED=false      # CDN URLs
```

**Ventajas:**
- Toggle on/off sin cambios de código
- Rollback inmediato si hay problemas
- Testing en producción con tráfico real

### Fase 3: Hybrid Storage Mode

Durante la migración, usar `HybridStorage`:

```
┌─────────────┐
│   Backend   │
└──────┬──────┘
       │
       ├─── New Uploads ──────▶ S3
       │
       └─── Old Files ────────▶ Filesystem
                                    │
                                    ▼
                            Background Migration
                                    │
                                    ▼
                                   S3
```

**Comportamiento:**
- **Save**: Nuevos archivos van a S3
- **Get**: Busca en S3 primero, fallback a filesystem
- **Delete**: Elimina de ambos
- **GetPublicURL**: Siempre retorna URL de S3 (para estabilidad)

### Fase 4: Background Migration

Implementar un migrador que:
- Corre en background cada N minutos
- Migra lotes de M archivos por ejecución
- Bajo impacto en CPU/memoria
- Puede pausarse/reanudarse
- Logging detallado de progreso

```go
type Migrator struct {
    source      Storage         // Filesystem
    destination Storage         // S3
    batchSize   int             // 100 archivos por lote
    interval    time.Duration   // 5 minutos
}
```

### Fase 5: Full S3 Mode

Una vez migrados todos los archivos:
- Cambiar a `S3Storage` puro
- Desactivar `HybridStorage`
- Opcionalmente: Configurar CDN (CloudFront)
- Opcionalmente: Limpiar filesystem local

---

## Consequences

### Positive

1. **Escalabilidad Infinita**
   - S3 no tiene límite de capacidad
   - Auto-scaling sin intervención manual
   - Crecimiento predecible de costos

2. **Alta Disponibilidad**
   - 99.99% uptime SLA de AWS S3
   - Redundancia multi-AZ automática
   - Sin single point of failure

3. **Performance Global**
   - Integración fácil con CDN (CloudFront)
   - Baja latencia para usuarios globales
   - Ancho de banda ilimitado

4. **Simplifica Deployment**
   - Containers stateless
   - Horizontal scaling sin shared storage
   - Deployment más rápido

5. **Costo Optimizado**
   - Pago por uso real ($0.023/GB/mes)
   - Sin provisión anticipada
   - Lifecycle policies para archivos viejos

6. **Operaciones Simplificadas**
   - Backups automáticos con versionado
   - No hay limpieza manual de disco
   - Monitoreo con CloudWatch

### Negative

1. **Complejidad Temporal**
   - Migración requiere planificación
   - Periodo híbrido con dos storages
   - Más código para mantener (temporalmente)

2. **Dependencia Externa**
   - Dependencia de proveedor cloud (AWS, DigitalOcean, etc.)
   - Requiere conectividad a Internet
   - Posible vendor lock-in (mitigado con S3 API standard)

3. **Costos de Transferencia**
   - Bandwidth OUT tiene costo ($0.09/GB)
   - PUT/GET requests tienen costo mínimo
   - Puede ser más caro que filesystem local para sitios pequeños

4. **Latencia de Red**
   - Latencia adicional vs filesystem local (~10-50ms)
   - Mitigado con CDN en producción

5. **Complejidad de Testing**
   - Tests requieren mock de S3 o MinIO local
   - Integration tests más complejos

### Neutral

1. **URLs de Archivos**
   - URLs cambiarán de `/uploads/...` a S3 URLs
   - Mitigado con CDN (CNAME custom)
   - Backward compatibility con hybrid mode

2. **Seguridad**
   - Requiere gestión de IAM credentials
   - Bucket policies para acceso público
   - Similar complejidad a filesystem actual

---

## Alternatives Considered

### Alternative 1: Continuar con Filesystem + NFS

**Pros:**
- Sin cambios de arquitectura
- Latencia muy baja
- Sin costos de bandwidth

**Cons:**
- Requiere provisión de NFS
- Single point of failure (NFS server)
- Difícil escalar horizontalmente
- Backups manuales
- **Decisión:** Rechazado por baja escalabilidad

### Alternative 2: Big Bang Migration

Migrar todos los archivos de una vez en una ventana de mantenimiento.

**Pros:**
- Migración rápida (1-2 horas)
- Menos complejidad de código

**Cons:**
- Requiere downtime (inaceptable)
- Alto riesgo
- Difícil de revertir
- **Decisión:** Rechazado por requisito de cero downtime

### Alternative 3: Object Storage Alternativo (Azure Blob, GCS)

Usar Azure Blob Storage o Google Cloud Storage en lugar de S3.

**Pros:**
- Pricing competitivo
- Features similares

**Cons:**
- Menos adopción que S3
- S3 API es standard de facto
- Más proveedores soportan S3 (MinIO, DO Spaces, Backblaze)
- **Decisión:** Rechazado, pero storage interface permite soporte futuro

### Alternative 4: CDN Directo (sin S3)

Usar CDN que acepta origin filesystem (e.g., Cloudflare).

**Pros:**
- Sin migración necesaria
- CDN performance

**Cons:**
- No resuelve escalabilidad de storage
- No resuelve backups
- Origin server sigue siendo bottleneck
- **Decisión:** Rechazado, CDN se usará SOBRE S3

---

## Implementation Plan

### Week 1: Development

- [x] Crear `Storage` interface
- [x] Implementar `FilesystemStorage`
- [x] Implementar `S3Storage`
- [x] Implementar `HybridStorage`
- [x] Implementar `Migrator`
- [x] Feature flags configuration
- [x] Unit tests

### Week 2: Testing

- [ ] Integration tests con MinIO local
- [ ] Performance benchmarks
- [ ] Security audit (IAM, bucket policies)
- [ ] Documentation

### Week 3: Staging Deployment

- [ ] Deploy a staging con hybrid mode
- [ ] Test upload/download con tráfico real
- [ ] Monitor logs y performance
- [ ] Fix bugs

### Week 4: Production Migration

- [ ] Day 1-2: Enable hybrid mode
- [ ] Day 3-7: Enable background migration
- [ ] Week 2-3: Monitor migration progress
- [ ] Week 4: Switch to full S3 mode

### Week 5: Optimization

- [ ] Configure CDN (CloudFront)
- [ ] Lifecycle policies (move old to Glacier)
- [ ] Cleanup filesystem local
- [ ] Remove hybrid code

---

## Risks & Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| S3 downtime | High | Low | Hybrid mode con fallback a filesystem |
| Migration bugs | Medium | Medium | Feature flags para rollback inmediato |
| High S3 costs | Medium | Low | Monitoring de costos, lifecycle policies |
| Slow migration | Low | Medium | Ajustar batch size y frecuencia |
| Data loss | High | Very Low | Dual storage durante migración |

---

## Metrics & Success Criteria

### Migration Metrics

- Migration progress: X% de archivos migrados
- Migration rate: N archivos/hora
- Error rate: < 1% de fallos
- Downtime: 0 segundos

### Performance Metrics

- Upload latency: < 500ms (p95)
- Download latency: < 200ms (p95) con CDN
- Availability: > 99.9%

### Cost Metrics

- Storage cost: < $50/month inicial
- Bandwidth cost: Monitoring activo
- Total cost: < $100/month

### Success Criteria

- ✅ Zero downtime durante migración
- ✅ Todos los archivos migrados exitosamente
- ✅ Performance igual o mejor que antes
- ✅ Costo predecible y aceptable
- ✅ Capability de rollback en cualquier momento

---

## Related Documents

- [MIGRATION_GUIDE.md](../../media/MIGRATION_GUIDE.md) - Guía paso a paso
- [Storage Package README](../../../backend/pkg/storage/README.md) - Documentación técnica
- [docker-compose.minio.yml](../../../docker-compose.minio.yml) - Testing local
- [media_migration.sh](../../../scripts/media_migration.sh) - Script de gestión

---

## References

- [AWS S3 Documentation](https://docs.aws.amazon.com/s3/)
- [12-Factor App: Backing Services](https://12factor.net/backing-services)
- [Strangler Fig Pattern](https://martinfowler.com/bliki/StranglerFigApplication.html)

---

**Authors**: DevOps Team
**Reviewers**: Backend Team, Frontend Team
**Last Updated**: 2025-01-04
