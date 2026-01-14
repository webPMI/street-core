/**
 * StreetCore - Script de Importación de Datos de Ejemplo
 *
 * Este script importa datos realistas de skateparks, competiciones y atletas
 * a la base de datos MongoDB de StreetCore.
 *
 * Uso:
 *   node import.js
 *
 * Requisitos:
 *   - MongoDB corriendo en localhost:27017
 *   - Node.js v18+
 *   - npm install mongodb
 */

const { MongoClient, ObjectId } = require('mongodb');
const fs = require('fs').promises;
const path = require('path');

// Configuración
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017';
const DB_NAME = 'fitriders';

// Colecciones y archivos
const COLLECTIONS = [
  { name: 'users', file: '05_test_users_fixed.json' },
  { name: 'skateparks', file: '02_skateparks.json' },
  { name: 'clubs', file: '03_clubs.json' },
  {
    name: 'competitions', files: [
      '06_real_competitions_skate_bmx_scooter.json',
      '07_real_competitions_inline_aggressive.json'
    ]
  }
];

/**
 * Convierte los ObjectIds string a ObjectId de MongoDB
 */
function convertObjectIds(obj) {
  if (Array.isArray(obj)) {
    return obj.map(convertObjectIds);
  }

  if (obj !== null && typeof obj === 'object') {
    // Convertir campos $oid
    if (obj.$oid) {
      return new ObjectId(obj.$oid);
    }

    // Convertir campos $date
    if (obj.$date) {
      return new Date(obj.$date);
    }

    // Recursivamente convertir propiedades
    const converted = {};
    for (const [key, value] of Object.entries(obj)) {
      converted[key] = convertObjectIds(value);
    }
    return converted;
  }

  return obj;
}

/**
 * Lee un archivo JSON y convierte los IDs
 */
async function readJsonFile(filename) {
  const filePath = path.join(__dirname, filename);
  const content = await fs.readFile(filePath, 'utf8');
  const data = JSON.parse(content);
  return convertObjectIds(data);
}

/**
 * Importa una colección
 */
async function importCollection(db, collectionName, data, append = false) {
  console.log(`\n📦 Importando ${collectionName}${append ? ' (adjuntando)' : ''}...`);

  const collection = db.collection(collectionName);

  // Limpiar colección existente solo si no estamos adjuntando
  if (!append) {
    const count = await collection.countDocuments();
    if (count > 0) {
      console.log(`   ⚠️  Encontrados ${count} documentos existentes. Eliminando...`);
      await collection.deleteMany({});
    }
  }

  // Insertar datos
  if (data.length > 0) {
    const result = await collection.insertMany(data);
    console.log(`   ✅ Insertados ${result.insertedCount} documentos`);
  } else {
    console.log(`   ⚠️  No hay datos para importar`);
  }
}

/**
 * Crea índices necesarios
 */
async function createIndexes(db) {
  console.log('\n🔍 Creando índices...');

  // Users
  await db.collection('users').createIndex({ email: 1 }, { unique: true });
  await db.collection('users').createIndex({ userName: 1 }, { unique: true, sparse: true });
  console.log('   ✅ Índices de users creados');

  // Skateparks
  await db.collection('skateparks').createIndex({ city: 1 });
  await db.collection('skateparks').createIndex({ disciplines: 1 });
  await db.collection('skateparks').createIndex({
    latitude: 1,
    longitude: 1
  });
  console.log('   ✅ Índices de skateparks creados');

  // Clubs
  await db.collection('clubs').createIndex({ city: 1 });
  await db.collection('clubs').createIndex({ disciplines: 1 });
  await db.collection('clubs').createIndex({ name: 1 });
  await db.collection('clubs').createIndex({ ownerId: 1 });
  console.log('   ✅ Índices de clubs creados');

  // Competitions
  await db.collection('competitions').createIndex({ organizerId: 1 });
  await db.collection('competitions').createIndex({ status: 1 });
  await db.collection('competitions').createIndex({ 'schedule.startDate': 1 });
  await db.collection('competitions').createIndex({ discipline: 1 });
  console.log('   ✅ Índices de competitions creados');
}

/**
 * Función principal
 */
async function main() {
  console.log('🚀 StreetCore - Importación de Datos\n');
  console.log(`   MongoDB: ${MONGO_URI}`);
  console.log(`   Base de datos: ${DB_NAME}\n`);

  const client = new MongoClient(MONGO_URI);

  try {
    // Conectar
    console.log('🔌 Conectando a MongoDB...');
    await client.connect();
    console.log('   ✅ Conectado\n');

    const db = client.db(DB_NAME);

    // Importar colecciones
    for (const collection of COLLECTIONS) {
      const { name, file, files } = collection;
      try {
        if (files) {
          // Importar múltiples archivos para una colección
          let isFirst = true;
          for (const f of files) {
            const data = await readJsonFile(f);
            await importCollection(db, name, data, !isFirst);
            isFirst = false;
          }
        } else {
          // Importar un solo archivo
          const data = await readJsonFile(file);
          await importCollection(db, name, data, false);
        }
      } catch (error) {
        console.error(`   ❌ Error importando ${name}:`, error.message);
      }
    }

    // Crear índices
    await createIndexes(db);

    // Resumen
    console.log('\n📊 Resumen de importación:');
    for (const { name } of COLLECTIONS) {
      const count = await db.collection(name).countDocuments();
      console.log(`   - ${name}: ${count} documentos`);
    }

    console.log('\n✅ Importación completada con éxito\n');

  } catch (error) {
    console.error('\n❌ Error durante la importación:', error);
    process.exit(1);
  } finally {
    await client.close();
    console.log('👋 Conexión cerrada');
  }
}

// Ejecutar
if (require.main === module) {
  main().catch(console.error);
}

module.exports = { main, convertObjectIds };
