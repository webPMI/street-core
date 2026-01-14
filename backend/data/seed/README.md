# StreetCore - Datos de Ejemplo Realistas

## Descripción

Datos de ejemplo 100% realistas para la plataforma de deportes urbanos StreetCore, enfocados en la escena española de Skate, BMX, Scooter e Inline.

## Estructura

```
seed/
├── README.md                          # Este archivo
├── 01_users.json                      # Usuarios/Atletas (20 perfiles)
├── 02_skateparks.json                 # Skateparks reales de España (12)
├── 03_clubs.json                      # Clubs urbanos (8)
├── 04_competitions.json               # Competiciones activas (5)
├── 05_categories.json                 # Categorías por competición
├── 06_participants.json               # Participantes registrados
├── 07_scores.json                     # Puntuaciones de ejemplo
├── 08_leaderboards.json               # Clasificaciones
└── import.js                          # Script de importación MongoDB

```

## Características

### Skateparks (12 reales)
- **Barcelona**: Skatepark de Gavà, Barcelona Skatepark (Forum)
- **Madrid**: Madrid Río Skatepark, Skatepark de La Elipa
- **Valencia**: Skatepark de Marxalenes, Benimaclet Skatepark
- **Sevilla**: Skatepark de Nervión
- **Málaga**: Skatepark El Morlaco
- **Bilbao**: Skatepark de La Casilla
- **Granada**: Skatepark de Armilla
- **Alicante**: Skatepark de San Juan
- **Zaragoza**: Skatepark de Valdespartera

Todos con:
- Coordenadas GPS reales
- Características: bowls, street, rails, rampas
- Horarios, dificultad, superficie

### Competiciones (5 activas)
1. **Barcelona Street Series 2026** - Street Skate (Feb 15-16)
2. **Madrid BMX Open** - BMX Park (Feb 22-23)
3. **Valencia Inline Challenge** - Inline Street (Mar 1-2)
4. **Andalucía Scooter Fest** - Scooter Park (Mar 8-9)
5. **Copa de España Street** - Multi-disciplina (Mar 15-16)

Con:
- Categorías: Pro/Amateur/Junior
- Sistemas de puntuación: SLS style (criterios ponderados)
- Premios en euros, patrocinadores reales

### Atletas (20 perfiles)
- Nombres ficticios pero realistas españoles/latinos
- Edades 16-35 años
- Especialidades variadas
- Biografías breves
- Patrocinadores reales (Red Bull, Monster, DC, Element)

### Puntuaciones
- Heats con 4-6 atletas
- Scores 70-95 puntos (realistas para SLS)
- Criterios: Técnica (40%), Estilo (30%), Dificultad (30%)
- Tricks ejecutados

## Importación

### Manual (mongoimport)

```bash
# Importar usuarios
mongoimport --db fitriders --collection users --file 01_users.json --jsonArray

# Importar skateparks
mongoimport --db fitriders --collection skateparks --file 02_skateparks.json --jsonArray

# Importar clubs
mongoimport --db fitriders --collection clubs --file 03_clubs.json --jsonArray

# Importar competiciones
mongoimport --db fitriders --collection competitions --file 04_competitions.json --jsonArray

# Importar categorías
mongoimport --db fitriders --collection categories --file 05_categories.json --jsonArray

# Importar participantes
mongoimport --db fitriders --collection participants --file 06_participants.json --jsonArray

# Importar puntuaciones
mongoimport --db fitriders --collection scores --file 07_scores.json --jsonArray

# Importar leaderboards
mongoimport --db fitriders --collection leaderboards --file 08_leaderboards.json --jsonArray
```

### Script automatizado (Node.js)

```bash
node import.js
```

## Validación

Los datos están validados contra los esquemas MongoDB:
- ✅ User model (backend/models/user.go)
- ✅ Competition entity (backend/features/competitions/domain/entities/competition.go)
- ✅ Category entity (backend/features/competitions/domain/entities/category.go)
- ✅ Participant entity (backend/features/competitions/domain/entities/participant.go)
- ✅ Score entity (backend/features/competitions/domain/entities/score.go)
- ✅ Leaderboard entity (backend/features/competitions/domain/entities/leaderboard.go)

## Notas

- Todos los ObjectIDs son válidos y consistentes entre colecciones
- Las fechas son actuales (Enero-Marzo 2026)
- Los skateparks son lugares REALES con coordenadas GPS verificadas
- Los patrocinadores son marcas reales del sector
- Las puntuaciones siguen el sistema SLS (Street League Skateboarding)
- Las biografías y nombres son ficticios pero realistas

## Uso

Estos datos están diseñados para:
1. **Testing** - Pruebas de funcionalidad
2. **Demo** - Presentaciones del producto
3. **Desarrollo** - Desarrollo de nuevas features
4. **QA** - Pruebas de calidad

**IMPORTANTE**: NO usar en producción. Solo para desarrollo y testing.
