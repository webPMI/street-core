# StreetCore - Ejemplos de Queries

Queries útiles para trabajar con los datos de ejemplo importados.

## Conexión MongoDB

```bash
# Conectar a la base de datos
mongosh fitriders

# O con URI completa
mongosh "mongodb://localhost:27017/fitriders"
```

## Queries Básicas

### Users

```javascript
// Contar usuarios
db.users.countDocuments()

// Buscar admin
db.users.findOne({ role: "admin" })

// Buscar atleta por email
db.users.findOne({ email: "carlos.martinez@example.com" })

// Listar usuarios premium
db.users.find({ isPremium: true }).pretty()

// Usuarios con más followers
db.users.find({}, { firstName: 1, lastName: 1, followersCount: 1 })
  .sort({ followersCount: -1 })
  .limit(5)

// Buscar por género
db.users.find({ gender: "female" }).pretty()

// Buscar por userName
db.users.findOne({ userName: "lucia_inline" })
```

### Skateparks

```javascript
// Contar skateparks
db.skateparks.countDocuments()

// Buscar por ciudad
db.skateparks.find({ city: "Barcelona" }).pretty()

// Skateparks gratuitos
db.skateparks.find({ isFree: true }).pretty()

// Skateparks con bowl
db.skateparks.find({ features: { $regex: /Bowl/i } }).pretty()

// Mejor valorados
db.skateparks.find({}, { name: 1, city: 1, rating: 1 })
  .sort({ rating: -1 })
  .limit(5)

// Por disciplina
db.skateparks.find({ disciplines: "bmx" }).pretty()

// Skateparks 24/7
db.skateparks.find({ openHours: "24/7" }).pretty()

// Indoor/cubiertos
db.skateparks.find({ isIndoor: true }).pretty()

// Cerca de coordenadas (ejemplo Barcelona)
db.skateparks.find({
  latitude: { $gte: 41.3, $lte: 41.5 },
  longitude: { $gte: 2.0, $lte: 2.3 }
}).pretty()
```

### Competitions

```javascript
// Contar competiciones
db.competitions.countDocuments()

// Competiciones upcoming
db.competitions.find({ status: "upcoming" }).pretty()

// Por disciplina
db.competitions.find({ discipline: "skateboard" }).pretty()

// Próximas competiciones (ordenadas por fecha)
db.competitions.find(
  { status: "upcoming" },
  { title: 1, discipline: 1, "schedule.startDate": 1 }
).sort({ "schedule.startDate": 1 }).pretty()

// Competiciones en Barcelona
db.competitions.find({ "schedule.city": "Barcelona" }).pretty()

// Con registro abierto
db.competitions.find({ "registration.participantStatus": "open" }).pretty()

// Por premios (mayores a 10k)
db.competitions.find({
  "registration.entryFee": { $exists: true },
  // Puedes añadir campo de premios si existe
}).pretty()

// Competiciones multi-ronda
db.competitions.find({ format: "multi_round" }).pretty()

// Con espacios disponibles
db.competitions.find({
  $expr: {
    $lt: [
      "$registration.currentParticipants",
      "$registration.maxParticipants"
    ]
  }
}).pretty()
```

## Queries Avanzadas

### Agregaciones

```javascript
// Usuarios por género
db.users.aggregate([
  { $group: { _id: "$gender", count: { $sum: 1 } } }
])

// Skateparks por ciudad
db.skateparks.aggregate([
  { $group: { _id: "$city", count: { $sum: 1 } } },
  { $sort: { count: -1 } }
])

// Competiciones por disciplina
db.competitions.aggregate([
  { $group: { _id: "$discipline", count: { $sum: 1 } } }
])

// Rating promedio de skateparks
db.skateparks.aggregate([
  { $group: { _id: null, avgRating: { $avg: "$rating" } } }
])

// Skateparks por disciplina
db.skateparks.aggregate([
  { $unwind: "$disciplines" },
  { $group: { _id: "$disciplines", count: { $sum: 1 } } },
  { $sort: { count: -1 } }
])

// Total de participantes por competición
db.competitions.aggregate([
  {
    $project: {
      title: 1,
      participants: "$registration.currentParticipants",
      maxParticipants: "$registration.maxParticipants",
      fillRate: {
        $multiply: [
          { $divide: [
            "$registration.currentParticipants",
            "$registration.maxParticipants"
          ] },
          100
        ]
      }
    }
  },
  { $sort: { fillRate: -1 } }
])
```

### Búsquedas de Texto

```javascript
// Crear índice de texto (si no existe)
db.skateparks.createIndex({ name: "text", description: "text" })
db.competitions.createIndex({ title: "text", description: "text" })

// Buscar skateparks por texto
db.skateparks.find({ $text: { $search: "bowl" } }).pretty()

// Buscar competiciones por texto
db.competitions.find({ $text: { $search: "street" } }).pretty()
```

### Joins (Lookups)

```javascript
// Competiciones con info del organizador
db.competitions.aggregate([
  {
    $lookup: {
      from: "users",
      localField: "organizerId",
      foreignField: "_id",
      as: "organizer"
    }
  },
  { $unwind: "$organizer" },
  {
    $project: {
      title: 1,
      "organizer.firstName": 1,
      "organizer.lastName": 1,
      "organizer.email": 1
    }
  }
]).pretty()
```

## Queries de Testing

### Autenticación

```javascript
// Verificar que el admin existe
db.users.findOne({ email: "admin@streetcore.com" })

// Verificar hash de password (debería existir)
db.users.findOne(
  { email: "admin@streetcore.com" },
  { password: 1 }
)

// Contar usuarios activos
db.users.countDocuments({ isActive: true })
```

### Validación de Datos

```javascript
// Usuarios sin email (debería ser 0)
db.users.countDocuments({ email: { $exists: false } })

// Competiciones sin organizador (debería ser 0)
db.competitions.countDocuments({ organizerId: { $exists: false } })

// Skateparks sin coordenadas
db.skateparks.countDocuments({
  $or: [
    { latitude: { $exists: false } },
    { longitude: { $exists: false } }
  ]
})

// Verificar fechas futuras en competiciones
db.competitions.find({
  "schedule.startDate": { $lt: new Date() }
}).count()
```

### Estadísticas

```javascript
// Total de registros por colección
print("Users:", db.users.countDocuments())
print("Skateparks:", db.skateparks.countDocuments())
print("Competitions:", db.competitions.countDocuments())

// Usuarios premium vs free
db.users.aggregate([
  { $group: { _id: "$isPremium", count: { $sum: 1 } } }
])

// Capacidad total de competiciones
db.competitions.aggregate([
  {
    $group: {
      _id: null,
      totalCapacity: { $sum: "$registration.maxParticipants" },
      totalRegistered: { $sum: "$registration.currentParticipants" }
    }
  }
])
```

## Queries de Desarrollo

### Obtener IDs para Testing

```javascript
// Obtener ID de admin
db.users.findOne({ role: "admin" }, { _id: 1 })

// Obtener IDs de atletas
db.users.find({ role: "user" }, { _id: 1, userName: 1 }).limit(5)

// Obtener ID de competición
db.competitions.findOne({}, { _id: 1, title: 1 })

// Obtener ID de skatepark
db.skateparks.findOne({ city: "Barcelona" }, { _id: 1, name: 1 })
```

### Modificaciones de Testing

```javascript
// Cambiar estado de competición a "live"
db.competitions.updateOne(
  { title: "Barcelona Street Series 2026" },
  { $set: { status: "live", isLive: true } }
)

// Agregar un participante a competición
db.competitions.updateOne(
  { title: "Barcelona Street Series 2026" },
  {
    $push: { "registration.registeredAthleteIds": ObjectId("65c0001a1234567890abcd01") },
    $inc: { "registration.currentParticipants": 1 }
  }
)

// Actualizar rating de skatepark
db.skateparks.updateOne(
  { name: "Skatepark de Gavà" },
  { $set: { rating: 5.0 } }
)
```

## Queries de Limpieza

```javascript
// Resetear base de datos
db.dropDatabase()

// Eliminar solo una colección
db.users.drop()
db.skateparks.drop()
db.competitions.drop()

// Eliminar usuarios de prueba (mantener admin)
db.users.deleteMany({ role: { $ne: "admin" } })

// Resetear participantes en competiciones
db.competitions.updateMany(
  {},
  {
    $set: {
      "registration.registeredAthleteIds": [],
      "registration.currentParticipants": 0,
      "registration.participantStatus": "open"
    }
  }
)
```

## Queries de Performance

```javascript
// Explain query (ver índices usados)
db.competitions.find({ status: "upcoming" }).explain("executionStats")

// Ver índices existentes
db.users.getIndexes()
db.skateparks.getIndexes()
db.competitions.getIndexes()

// Tamaño de colecciones
db.users.stats()
db.skateparks.stats()
db.competitions.stats()
```

## Queries Go (Ejemplos para código)

### Go con MongoDB Driver

```go
// Buscar skatepark por ciudad
filter := bson.M{"city": "Barcelona"}
var skateparks []Skatepark
cursor, err := collection.Find(ctx, filter)

// Buscar competiciones upcoming
filter := bson.M{
    "status": "upcoming",
    "schedule.startDate": bson.M{"$gte": time.Now()},
}
var competitions []Competition
cursor, err := collection.Find(ctx, filter)

// Buscar usuario por email
filter := bson.M{"email": "carlos.martinez@example.com"}
var user User
err := collection.FindOne(ctx, filter).Decode(&user)

// Agregación: usuarios por género
pipeline := mongo.Pipeline{
    {{Key: "$group", Value: bson.D{
        {Key: "_id", Value: "$gender"},
        {Key: "count", Value: bson.D{{Key: "$sum", Value: 1}}},
    }}},
}
cursor, err := collection.Aggregate(ctx, pipeline)
```

## Tips

1. **Usar pretty()** para output legible en mongosh
2. **Usar explain()** para optimizar queries
3. **Crear índices** para campos frecuentemente consultados
4. **Usar agregaciones** para estadísticas complejas
5. **Validar ObjectIDs** antes de queries con refs

## Recursos

- [MongoDB Manual](https://docs.mongodb.com/manual/)
- [Aggregation Pipeline](https://docs.mongodb.com/manual/aggregation/)
- [Query Operators](https://docs.mongodb.com/manual/reference/operator/query/)
- [Go MongoDB Driver](https://pkg.go.dev/go.mongodb.org/mongo-driver/mongo)

---

**Database Agent** - StreetCore MongoDB Queries
Última actualización: 2026-01-11
