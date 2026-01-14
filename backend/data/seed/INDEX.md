# StreetCore - Índice de Datos de Ejemplo

## Archivos Creados

### 📚 Documentación
| Archivo | Descripción | Estado |
|---------|-------------|--------|
| `README.md` | Documentación completa del seed | ✅ Completo |
| `SEED_DATA_SUMMARY.md` | Resumen ejecutivo | ✅ Completo |
| `QUERIES_EXAMPLES.md` | Ejemplos de queries MongoDB | ✅ Completo |
| `INDEX.md` | Este archivo (índice general) | ✅ Completo |

### 📦 Datos JSON
| Archivo | Colección | Registros | Estado |
|---------|-----------|-----------|--------|
| `01_users.json` | users | 21 | ✅ Completo |
| `02_skateparks.json` | skateparks | 12 | ✅ Completo |
| `03_clubs.json` | clubs | 8 | ✅ Completo |
| `04_competitions.json` | competitions | 5 | ✅ Completo |
| `05_categories.json` | categories | - | ⏸️ Pendiente |
| `06_participants.json` | participants | - | ⏸️ Pendiente |
| `07_scores.json` | scores | - | ⏸️ Pendiente |
| `08_leaderboards.json` | leaderboards | - | ⏸️ Pendiente |

### 🔧 Scripts de Importación
| Archivo | Tipo | Descripción | Estado |
|---------|------|-------------|--------|
| `import.js` | Node.js | Script automatizado con MongoDB driver | ✅ Completo |
| `import.sh` | Bash | Script shell para Linux/Mac | ✅ Completo |
| `package.json` | NPM | Dependencias y scripts npm | ✅ Completo |

---

## Resumen de Datos

### 👥 Users (21 registros)
**Admin:**
- ID: `65c0001a1234567890abcd21`
- Email: `admin@streetcore.com`
- Role: `admin`

**Atletas destacados:**
1. Carlos Martínez (`65c0001a1234567890abcd01`) - Street Skate, Element
2. Lucía Fernández (`65c0001a1234567890abcd02`) - Inline, USD Skates
3. Marc Vilanova (`65c0001a1234567890abcd03`) - BMX Park, Mongoose
4. Alba Ruiz (`65c0001a1234567890abcd04`) - Scooter Pro, Ethic DTC
5. Daniel López (`65c0001a1234567890abcd05`) - Vert Skate, Vans

... y 15 más (total 20 atletas)

### 🏞️ Skateparks (12 registros)
**Por ciudad:**
- Barcelona (2): Gavà, Forum
- Madrid (2): Madrid Río, La Elipa
- Valencia (2): Marxalenes, Benimaclet
- Sevilla (1): Nervión
- Málaga (1): El Morlaco
- Bilbao (1): La Casilla (Indoor)
- Granada (1): Armilla
- Alicante (1): San Juan
- Zaragoza (1): Valdespartera

**Características:**
- Todos con coordenadas GPS reales
- 11 outdoor + 1 indoor
- 11 gratuitos + 1 de pago
- Ratings: 4.2 - 4.9

### 🏠 Clubs (8 registros)
1. **Barcelona Street Collective** - Street Skate
2. **Madrid BMX Crew** - BMX
3. **Valencia Inline Association** - Inline
4. **Andalucía Scooter Club** - Scooter
5. **Bilbao Urban Riders** - Multi-disciplina
6. **Zaragoza Skate Team** - Skateboard (Competitivo)
7. **Alicante Beach Crew** - Multi-disciplina (Beach)
8. **Granada Bowl Society** - Bowl/Transición

**Estadísticas:**
- Total miembros: 369
- Clubs públicos: 7
- Clubs privados: 1
- Cuota promedio: 14€/año

### 🏆 Competitions (5 registros)
1. **Barcelona Street Series 2026**
   - Fecha: 15-16 Feb
   - Disciplina: Skateboard Street
   - Premios: 15.000€
   - Participantes: 42/60

2. **Madrid BMX Open**
   - Fecha: 22-23 Feb
   - Disciplina: BMX Park
   - Premios: 12.000€
   - Participantes: 28/40

3. **Valencia Inline Challenge**
   - Fecha: 1-2 Mar
   - Disciplina: Inline Street
   - Premios: 8.000€
   - Participantes: 22/35

4. **Andalucía Scooter Fest**
   - Fecha: 8-9 Mar
   - Disciplina: Scooter Park
   - Premios: 6.000€
   - Participantes: 38/50

5. **Copa de España Street**
   - Fecha: 15-16 Mar
   - Disciplina: Multi
   - Premios: 20.000€
   - Participantes: 56/80

**Estadísticas:**
- Total premios: 61.000€
- Total capacity: 265 atletas
- Total registrados: 186 atletas
- Fill rate promedio: 70%

---

## Validación

### ✅ Esquemas Validados
- **User**: `backend/models/user.go`
- **Competition**: `backend/features/competitions/domain/entities/competition.go`
- **Category**: `backend/features/competitions/domain/entities/category.go`
- **Club**: Compatible con `backend/app/dto/request/club_request.go`

### ✅ Integridad Referencial
- Todos los ObjectIDs son válidos
- Referencias entre colecciones consistentes:
  - `competitions.organizerId` → `users._id`
  - `clubs.ownerId` → `users._id`
  - `competitions.registration.registeredAthleteIds` → `users._id`

### ✅ Datos Realistas
- Skateparks: Lugares REALES verificados
- Coordenadas GPS: Validadas
- Patrocinadores: Marcas reales del sector
- Nombres: Españoles/latinos ficticios
- Fechas: Futuras (2026)

---

## Importación

### Opción 1: Script Node.js (Recomendado)
```bash
cd backend/data/seed
npm install
npm run import
```

### Opción 2: Script Bash
```bash
cd backend/data/seed
chmod +x import.sh
./import.sh
```

### Opción 3: NPM individual
```bash
npm run import:users
npm run import:skateparks
npm run import:clubs
npm run import:competitions
```

### Opción 4: Manual (mongoimport)
```bash
mongoimport --db fitriders --collection users --file 01_users.json --jsonArray --drop
mongoimport --db fitriders --collection skateparks --file 02_skateparks.json --jsonArray --drop
mongoimport --db fitriders --collection clubs --file 03_clubs.json --jsonArray --drop
mongoimport --db fitriders --collection competitions --file 04_competitions.json --jsonArray --drop
```

---

## Verificación Post-Importación

```bash
mongosh fitriders --eval "
  print('Users:', db.users.countDocuments());
  print('Skateparks:', db.skateparks.countDocuments());
  print('Clubs:', db.clubs.countDocuments());
  print('Competitions:', db.competitions.countDocuments());
"
```

**Resultado esperado:**
```
Users: 21
Skateparks: 12
Clubs: 8
Competitions: 5
```

---

## Índices Creados

### users
- `{ email: 1 }` - Unique
- `{ userName: 1 }` - Unique, sparse

### skateparks
- `{ city: 1 }`
- `{ disciplines: 1 }`
- `{ latitude: 1, longitude: 1 }`

### clubs
- `{ city: 1 }`
- `{ disciplines: 1 }`
- `{ name: 1 }`
- `{ ownerId: 1 }`

### competitions
- `{ organizerId: 1 }`
- `{ status: 1 }`
- `{ 'schedule.startDate': 1 }`
- `{ discipline: 1 }`

---

## Credenciales de Prueba

### Admin
```
Email: admin@streetcore.com
Password: password
```

### Atletas (todos usan password: "password")
```
carlos.martinez@example.com
lucia.fernandez@example.com
marc.vilanova@example.com
alba.ruiz@example.com
daniel.lopez@example.com
... (16 más)
```

---

## Próximos Pasos (Extensión)

Para completar el seed completo, se necesitan:

### 📋 Prioridad Alta
1. **Categories** (`05_categories.json`)
   - 3 categorías por competición: Pro, Amateur, Junior
   - Total: ~15 registros

2. **Participants** (`06_participants.json`)
   - Participantes registrados en competiciones
   - Total: ~180 registros (basado en currentParticipants)

### 📊 Prioridad Media
3. **Scores** (`07_scores.json`)
   - Puntuaciones de ejemplo (para comps pasadas o demo)
   - Total: ~50-100 registros

4. **Leaderboards** (`08_leaderboards.json`)
   - Clasificaciones de competiciones
   - Total: 5 registros (uno por competición)

### 🎯 Prioridad Baja
5. **Posts** - Posts sociales de atletas
6. **Stories** - Stories de usuarios
7. **Follows** - Relaciones de seguimiento
8. **Notifications** - Notificaciones de ejemplo

---

## Uso de los Datos

### Testing
```go
// Get admin user
admin := getUserByEmail("admin@streetcore.com")

// Get skateparks in Barcelona
skateparks := getSkateparksByCity("Barcelona")

// Get upcoming competitions
competitions := getCompetitionsByStatus("upcoming")

// Get club members
club := getClubByName("Barcelona Street Collective")
```

### Demo
- Login con usuarios reales
- Ver mapa de skateparks
- Explorar competiciones
- Ver perfiles de atletas
- Ver clubs por ciudad

### Desarrollo
- Testing de features
- Validación de schemas
- Testing de queries
- Performance testing

---

## Soporte

**Problemas comunes:**

1. **MongoDB no conecta**
   ```bash
   # Verificar que MongoDB está corriendo
   mongosh --eval "db.version()"
   ```

2. **Error de permisos**
   ```bash
   chmod +x import.sh
   ```

3. **Error Node.js**
   ```bash
   # Verificar versión (>=18)
   node --version

   # Reinstalar dependencias
   rm -rf node_modules
   npm install
   ```

4. **Error mongoimport no encontrado**
   ```bash
   # Instalar MongoDB Tools
   # https://www.mongodb.com/try/download/database-tools
   ```

---

## Mantenimiento

### Limpiar Base de Datos
```bash
mongosh fitriders --eval "db.dropDatabase()"
```

### Re-importar Todo
```bash
npm run import
# o
./import.sh
```

### Actualizar Datos
```bash
# 1. Editar archivo JSON
vim 04_competitions.json

# 2. Re-importar
npm run import:competitions
```

---

## Licencia

MIT - Solo para desarrollo y testing de StreetCore.

**⚠️ NO USAR EN PRODUCCIÓN**

---

## Metadata

- **Autor**: Database Agent
- **Proyecto**: StreetCore
- **Versión**: 1.0.0
- **Fecha**: 2026-01-11
- **Última actualización**: 2026-01-11
- **Total archivos**: 12
- **Total registros**: 46
- **Tamaño estimado**: ~150KB

---

**Database Agent** - StreetCore MongoDB Data Design
