/**
 * StreetCore - Script de Validación de Datos
 *
 * Valida que los datos importados cumplen con los requisitos:
 * - Conteos correctos
 * - Integridad referencial
 * - Índices creados
 * - Formato de datos
 *
 * Uso:
 *   node validate.js
 */

const { MongoClient, ObjectId } = require('mongodb');

// Configuración
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017';
const DB_NAME = 'fitriders';

// Conteos esperados
const EXPECTED_COUNTS = {
  users: 21,
  skateparks: 12,
  clubs: 8,
  competitions: 5
};

// Colores para output
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m'
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

/**
 * Valida conteos de documentos
 */
async function validateCounts(db) {
  log('\n📊 Validando conteos...', 'blue');
  let passed = 0;
  let failed = 0;

  for (const [collection, expected] of Object.entries(EXPECTED_COUNTS)) {
    const actual = await db.collection(collection).countDocuments();
    if (actual === expected) {
      log(`   ✅ ${collection}: ${actual}`, 'green');
      passed++;
    } else {
      log(`   ❌ ${collection}: esperado ${expected}, actual ${actual}`, 'red');
      failed++;
    }
  }

  return { passed, failed };
}

/**
 * Valida índices
 */
async function validateIndexes(db) {
  log('\n🔍 Validando índices...', 'blue');
  let passed = 0;
  let failed = 0;

  const expectedIndexes = {
    users: ['email_1', 'userName_1'],
    skateparks: ['city_1', 'disciplines_1', 'latitude_1_longitude_1'],
    clubs: ['city_1', 'disciplines_1', 'name_1', 'ownerId_1'],
    competitions: ['organizerId_1', 'status_1', 'schedule.startDate_1', 'discipline_1']
  };

  for (const [collection, expectedNames] of Object.entries(expectedIndexes)) {
    const indexes = await db.collection(collection).indexes();
    const indexNames = indexes.map(i => i.name).filter(n => n !== '_id_');

    for (const expectedName of expectedNames) {
      if (indexNames.includes(expectedName)) {
        log(`   ✅ ${collection}.${expectedName}`, 'green');
        passed++;
      } else {
        log(`   ❌ ${collection}.${expectedName} - NO ENCONTRADO`, 'red');
        failed++;
      }
    }
  }

  return { passed, failed };
}

/**
 * Valida integridad referencial
 */
async function validateReferences(db) {
  log('\n🔗 Validando integridad referencial...', 'blue');
  let passed = 0;
  let failed = 0;

  // Validar competitions.organizerId → users._id
  const competitions = await db.collection('competitions').find({}).toArray();
  for (const comp of competitions) {
    const user = await db.collection('users').findOne({ _id: comp.organizerId });
    if (user) {
      passed++;
    } else {
      log(`   ❌ Competition "${comp.title}" referencia organizerId inexistente: ${comp.organizerId}`, 'red');
      failed++;
    }
  }

  // Validar clubs.ownerId → users._id
  const clubs = await db.collection('clubs').find({}).toArray();
  for (const club of clubs) {
    const user = await db.collection('users').findOne({ _id: club.ownerId });
    if (user) {
      passed++;
    } else {
      log(`   ❌ Club "${club.name}" referencia ownerId inexistente: ${club.ownerId}`, 'red');
      failed++;
    }
  }

  // Validar competitions.registeredAthleteIds → users._id
  for (const comp of competitions) {
    if (comp.registration && comp.registration.registeredAthleteIds) {
      for (const athleteId of comp.registration.registeredAthleteIds) {
        const user = await db.collection('users').findOne({ _id: athleteId });
        if (user) {
          passed++;
        } else {
          log(`   ❌ Competition "${comp.title}" referencia athleteId inexistente: ${athleteId}`, 'red');
          failed++;
        }
      }
    }
  }

  if (failed === 0) {
    log(`   ✅ Todas las referencias válidas (${passed} verificadas)`, 'green');
  }

  return { passed, failed };
}

/**
 * Valida formato de datos
 */
async function validateDataFormat(db) {
  log('\n📋 Validando formato de datos...', 'blue');
  let passed = 0;
  let failed = 0;

  // Validar emails únicos
  const emails = await db.collection('users').distinct('email');
  const userCount = await db.collection('users').countDocuments();
  if (emails.length === userCount) {
    log('   ✅ Emails únicos', 'green');
    passed++;
  } else {
    log('   ❌ Emails duplicados detectados', 'red');
    failed++;
  }

  // Validar que admin existe
  const admin = await db.collection('users').findOne({ role: 'admin' });
  if (admin && admin.email === 'admin@streetcore.com') {
    log('   ✅ Usuario admin existe', 'green');
    passed++;
  } else {
    log('   ❌ Usuario admin no encontrado o email incorrecto', 'red');
    failed++;
  }

  // Validar coordenadas en skateparks
  const invalidCoords = await db.collection('skateparks').countDocuments({
    $or: [
      { latitude: { $exists: false } },
      { longitude: { $exists: false } },
      { latitude: null },
      { longitude: null }
    ]
  });

  if (invalidCoords === 0) {
    log('   ✅ Todos los skateparks tienen coordenadas', 'green');
    passed++;
  } else {
    log(`   ❌ ${invalidCoords} skateparks sin coordenadas`, 'red');
    failed++;
  }

  // Validar fechas futuras en competiciones
  const now = new Date();
  const pastComps = await db.collection('competitions').countDocuments({
    'schedule.startDate': { $lt: now }
  });

  if (pastComps === 0) {
    log('   ✅ Todas las competiciones son futuras', 'green');
    passed++;
  } else {
    log(`   ⚠️  ${pastComps} competiciones con fechas pasadas`, 'yellow');
    // No contamos como failed porque puede ser válido
    passed++;
  }

  // Validar status de competiciones
  const invalidStatus = await db.collection('competitions').countDocuments({
    status: { $nin: ['upcoming', 'live', 'completed', 'cancelled', 'postponed'] }
  });

  if (invalidStatus === 0) {
    log('   ✅ Todos los status de competiciones válidos', 'green');
    passed++;
  } else {
    log(`   ❌ ${invalidStatus} competiciones con status inválido`, 'red');
    failed++;
  }

  return { passed, failed };
}

/**
 * Genera estadísticas
 */
async function generateStats(db) {
  log('\n📈 Estadísticas generales:', 'blue');

  // Users
  const usersByGender = await db.collection('users').aggregate([
    { $group: { _id: '$gender', count: { $sum: 1 } } }
  ]).toArray();
  log('   Usuarios por género:');
  usersByGender.forEach(g => log(`     - ${g._id || 'unknown'}: ${g.count}`));

  const premiumCount = await db.collection('users').countDocuments({ isPremium: true });
  log(`   Usuarios premium: ${premiumCount}`);

  // Skateparks
  const parksByCity = await db.collection('skateparks').aggregate([
    { $group: { _id: '$city', count: { $sum: 1 } } },
    { $sort: { count: -1 } }
  ]).toArray();
  log('\n   Skateparks por ciudad:');
  parksByCity.forEach(c => log(`     - ${c._id}: ${c.count}`));

  const freeParks = await db.collection('skateparks').countDocuments({ isFree: true });
  log(`   Skateparks gratuitos: ${freeParks}`);

  // Competitions
  const totalPrizes = await db.collection('competitions').aggregate([
    {
      $group: {
        _id: null,
        total: { $sum: { $ifNull: ['$registration.entryFee', 0] } }
      }
    }
  ]).toArray();

  const totalCapacity = await db.collection('competitions').aggregate([
    {
      $group: {
        _id: null,
        capacity: { $sum: '$registration.maxParticipants' },
        registered: { $sum: '$registration.currentParticipants' }
      }
    }
  ]).toArray();

  if (totalCapacity.length > 0) {
    const { capacity, registered } = totalCapacity[0];
    const fillRate = ((registered / capacity) * 100).toFixed(1);
    log(`\n   Competiciones:`);
    log(`     - Capacidad total: ${capacity}`);
    log(`     - Registrados: ${registered}`);
    log(`     - Fill rate: ${fillRate}%`);
  }

  // Clubs
  const totalMembers = await db.collection('clubs').aggregate([
    { $group: { _id: null, total: { $sum: '$memberCount' } } }
  ]).toArray();

  if (totalMembers.length > 0) {
    log(`\n   Clubs:`);
    log(`     - Total miembros: ${totalMembers[0].total}`);
  }
}

/**
 * Función principal
 */
async function main() {
  log('🚀 StreetCore - Validación de Datos\n', 'blue');
  log(`   MongoDB: ${MONGO_URI}`);
  log(`   Base de datos: ${DB_NAME}\n`);

  const client = new MongoClient(MONGO_URI);

  try {
    // Conectar
    log('🔌 Conectando a MongoDB...', 'yellow');
    await client.connect();
    log('   ✅ Conectado\n', 'green');

    const db = client.db(DB_NAME);

    // Ejecutar validaciones
    const results = {
      counts: await validateCounts(db),
      indexes: await validateIndexes(db),
      references: await validateReferences(db),
      format: await validateDataFormat(db)
    };

    // Generar estadísticas
    await generateStats(db);

    // Resumen
    const totalPassed = Object.values(results).reduce((sum, r) => sum + r.passed, 0);
    const totalFailed = Object.values(results).reduce((sum, r) => sum + r.failed, 0);
    const totalTests = totalPassed + totalFailed;
    const successRate = ((totalPassed / totalTests) * 100).toFixed(1);

    log('\n' + '='.repeat(60), 'blue');
    log('📊 RESUMEN DE VALIDACIÓN', 'blue');
    log('='.repeat(60) + '\n', 'blue');

    log(`   Tests ejecutados: ${totalTests}`);
    log(`   ✅ Pasados: ${totalPassed}`, 'green');
    log(`   ❌ Fallidos: ${totalFailed}`, totalFailed > 0 ? 'red' : 'green');
    log(`   📈 Tasa de éxito: ${successRate}%\n`, successRate === '100.0' ? 'green' : 'yellow');

    if (totalFailed === 0) {
      log('✨ ¡Todos los tests pasaron! Datos válidos.\n', 'green');
      process.exit(0);
    } else {
      log('⚠️  Algunos tests fallaron. Revisa los errores arriba.\n', 'yellow');
      process.exit(1);
    }

  } catch (error) {
    log('\n❌ Error durante la validación:', 'red');
    console.error(error);
    process.exit(1);
  } finally {
    await client.close();
    log('👋 Conexión cerrada');
  }
}

// Ejecutar
if (require.main === module) {
  main().catch(console.error);
}

module.exports = { main };
