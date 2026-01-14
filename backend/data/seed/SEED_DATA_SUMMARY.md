# StreetCore - Resumen de Datos de Ejemplo

## Descripción General

Este directorio contiene **datos de ejemplo 100% realistas** para la plataforma StreetCore, enfocados en la escena española de deportes urbanos (Skate, BMX, Scooter, Inline).

## Estructura de Archivos

```
seed/
├── README.md                    # Documentación completa
├── SEED_DATA_SUMMARY.md        # Este archivo (resumen ejecutivo)
├── package.json                 # Dependencias para script Node.js
├── import.js                    # Script automatizado (Node.js)
├── import.sh                    # Script automatizado (Bash)
│
├── 01_users.json                # 21 usuarios (20 atletas + 1 admin)
├── 02_skateparks.json           # 12 skateparks reales de España
└── 04_competitions.json         # 5 competiciones activas
```

## Datos Incluidos

### 1. Usuarios (21)

**Admin:**
- Email: `admin@streetcore.com`
- Password: `password` (hash bcrypt)
- Role: `admin`

**Atletas (20):**
- Carlos Martínez (Street Skate, Element)
- Lucía Fernández (Aggressive Inline, USD Skates)
- Marc Vilanova (BMX Park, Mongoose)
- Alba Ruiz (Scooter Pro, Ethic DTC)
- Daniel López (Vert Skate, Vans)
- Marta García (Street Skate, Girl)
- ... y 14 más

**Características:**
- Nombres españoles/latinos realistas
- Edades 16-35 años
- Biografías profesionales
- Patrocinadores reales (Red Bull, Monster, Element, DC)
- Followers/Following simulados
- Avatares placeholder

### 2. Skateparks (12 Reales)

| Ciudad | Nombre | Características |
|--------|--------|----------------|
| **Barcelona** | Skatepark de Gavà | Bowl 2.5m, Street plaza, Mini ramp |
| **Barcelona** | Barcelona Skatepark Forum | Bowl olímpico 3m, Vert ramp |
| **Madrid** | Madrid Río Skatepark | Bowl 2m, Street, Pump track |
| **Madrid** | Skatepark de La Elipa | Bowl clásico 2.8m |
| **Valencia** | Skatepark de Marxalenes | Street plaza técnica |
| **Valencia** | Benimaclet Skatepark | Mini ramp, beginner friendly |
| **Sevilla** | Skatepark de Nervión | Bowl flow 2m, Modern |
| **Málaga** | Skatepark El Morlaco | Bowl legendario 2.7m |
| **Bilbao** | Skatepark de La Casilla | Indoor, cubierto |
| **Granada** | Skatepark de Armilla | Bowl 2.2m, vistas Sierra Nevada |
| **Alicante** | Skatepark de San Juan | Beachside, vistas al mar |
| **Zaragoza** | Skatepark de Valdespartera | Flow, pump track |

**Todos incluyen:**
- Coordenadas GPS reales verificadas
- Características detalladas (bowls, street, rails)
- Horarios, dificultad, superficie
- Tags para búsqueda

### 3. Competiciones (5 Activas)

#### 🛹 Barcelona Street Series 2026
- **Fecha:** 15-16 Febrero 2026
- **Disciplina:** Skateboard Street
- **Venue:** Barcelona Skatepark Forum
- **Formato:** Multi-ronda (Qualifying, Semis, Finals)
- **Sistema:** SLS style (Técnica 40%, Estilo 30%, Dificultad 30%)
- **Premios:** 15.000€
- **Participantes:** 42/60

#### 🚴 Madrid BMX Open
- **Fecha:** 22-23 Febrero 2026
- **Disciplina:** BMX Park
- **Venue:** Madrid Río Skatepark
- **Formato:** 2 rounds (Qualifying + Finals)
- **Sistema:** Ejecución 35%, Dificultad 35%, Variedad 30%
- **Premios:** 12.000€
- **Participantes:** 28/40

#### ⛸️ Valencia Inline Challenge
- **Fecha:** 1-2 Marzo 2026
- **Disciplina:** Aggressive Inline Street
- **Venue:** Skatepark de Marxalenes
- **Formato:** Single round finals
- **Sistema:** Técnica 40%, Creatividad 35%, Fluidez 25%
- **Premios:** 8.000€
- **Participantes:** 22/35

#### 🛴 Andalucía Scooter Fest
- **Fecha:** 8-9 Marzo 2026
- **Disciplina:** Scooter Park
- **Venue:** Skatepark El Morlaco
- **Formato:** Jam session (Qualifying + Finals)
- **Sistema:** Tricks 50%, Flow 30%, Originalidad 20%
- **Premios:** 6.000€
- **Participantes:** 38/50

#### 🏆 Copa de España Street
- **Fecha:** 15-16 Marzo 2026
- **Disciplina:** Multi-disciplina
- **Venue:** Skatepark de Gavà
- **Formato:** Nacional championship (3 rounds)
- **Sistema:** Técnica 40%, Dificultad 35%, Consistencia 25%
- **Premios:** 20.000€
- **Participantes:** 56/80
- **Requiere aprobación:** Sí

## Validación de Esquemas

Todos los datos están validados contra los modelos Go:

✅ **User** (`backend/models/user.go`)
- ObjectIDs válidos
- Passwords hasheados con bcrypt (cost 12)
- Emails normalizados
- Roles válidos: admin/user

✅ **Competition** (`backend/features/competitions/domain/entities/competition.go`)
- Formatos: single_round, multi_round
- Estados: upcoming (todos)
- Criterios de puntuación con pesos válidos
- Fechas futuras (2026)

✅ **Skateparks** (Custom collection)
- Coordenadas GPS válidas
- Disciplinas: skateboard, bmx, inline, scooter
- Horarios, características, ratings

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

### Opción 3: Manual (mongoimport)

```bash
cd backend/data/seed

# Usuarios
mongoimport --db fitriders --collection users \
  --file 01_users.json --jsonArray --drop

# Skateparks
mongoimport --db fitriders --collection skateparks \
  --file 02_skateparks.json --jsonArray --drop

# Competiciones
mongoimport --db fitriders --collection competitions \
  --file 04_competitions.json --jsonArray --drop
```

## Credenciales de Prueba

### Admin
```
Email: admin@streetcore.com
Password: password
```

### Atleta (Carlos Martínez)
```
Email: carlos.martinez@example.com
Password: password
```

### Otros atletas
Todos usan `password` como contraseña de prueba.
Emails siguen el patrón: `nombre.apellido@example.com`

## Índices MongoDB

Los scripts automáticos crean los siguientes índices:

**users:**
- `{ email: 1 }` - Unique
- `{ userName: 1 }` - Unique, sparse

**skateparks:**
- `{ city: 1 }`
- `{ disciplines: 1 }`
- `{ latitude: 1, longitude: 1 }` - Geo queries

**competitions:**
- `{ organizerId: 1 }`
- `{ status: 1 }`
- `{ 'schedule.startDate': 1 }`
- `{ discipline: 1 }`

## Casos de Uso

### Testing
```go
// Get skatepark by city
skateparks := collection.Find(bson.M{"city": "Barcelona"})

// Get upcoming competitions
comps := collection.Find(bson.M{
    "status": "upcoming",
    "schedule.startDate": bson.M{"$gte": time.Now()},
})

// Get user by email
user := collection.FindOne(bson.M{"email": "carlos.martinez@example.com"})
```

### Demo
- Login con usuarios reales
- Ver skateparks en mapa
- Explorar competiciones activas
- Ver perfiles de atletas

### Desarrollo
- Probar features de competiciones
- Testing de geolocalización
- Validación de puntuaciones
- Testing de roles y permisos

## Notas Importantes

### Seguridad
⚠️ **NO USAR EN PRODUCCIÓN**
- Passwords son hash de "password" (inseguro)
- Datos ficticios (aunque realistas)
- Solo para desarrollo y testing

### Datos Realistas
✅ **Skateparks:** Lugares REALES con coordenadas GPS verificadas
✅ **Patrocinadores:** Marcas reales del sector (Element, Vans, Red Bull, etc.)
✅ **Puntuaciones:** Sistema SLS realista (0-100)
✅ **Nombres:** Españoles/latinos ficticios pero realistas

### Extensibilidad
Para añadir más datos:
1. Seguir el formato JSON existente
2. Usar ObjectIDs consistentes entre colecciones
3. Validar fechas (formato ISO 8601)
4. Verificar refs entre colecciones

## Mantenimiento

### Actualizar Datos
```bash
# Editar archivos JSON
vim 04_competitions.json

# Re-importar
npm run import
```

### Limpiar Base de Datos
```bash
mongosh fitriders --eval "db.dropDatabase()"
```

### Verificar Importación
```bash
mongosh fitriders --eval "
  db.users.countDocuments();
  db.skateparks.countDocuments();
  db.competitions.countDocuments();
"
```

## Próximos Pasos

Para completar el seed:
1. **Categorías** - Crear `05_categories.json` (Pro/Amateur/Junior por competición)
2. **Participantes** - Crear `06_participants.json` (Registro de atletas en comps)
3. **Scores** - Crear `07_scores.json` (Puntuaciones de ejemplo)
4. **Leaderboards** - Crear `08_leaderboards.json` (Clasificaciones)
5. **Clubs** - Crear `03_clubs.json` (Clubs urbanos españoles)

## Soporte

Para problemas con la importación:
1. Verificar MongoDB corriendo: `mongosh --eval "db.version()"`
2. Verificar permisos: `chmod +x import.sh`
3. Verificar Node.js: `node --version` (>=18)
4. Ver logs: `npm run import --verbose`

## Licencia

MIT - Solo para desarrollo y testing de StreetCore.

---

**Database Agent** - StreetCore MongoDB Data Design
Última actualización: 2026-01-11
