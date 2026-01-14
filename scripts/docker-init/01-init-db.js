// ========================================
// STREETCORE - MongoDB Initialization
// ========================================
// Crea usuario de aplicación y configuración inicial
// Se ejecuta automáticamente al crear el contenedor
// ========================================

print('========================================');
print('  MongoDB Initialization - StreetCore');
print('========================================');
print('');

// Obtener variables de entorno
const dbName = 'streetcore';
const appUser = 'streetcore_app';
const appPass = 'Aqq+dzBDz3s/4hQdnovyElHHNUaSvEFjQ0lOHOgTLFM=';

// Cambiar a la base de datos de la aplicación
db = db.getSiblingDB(dbName);

print(`[1/3] Creating database: ${dbName}`);

// ========================================
// 1. CREAR USUARIO DE APLICACIÓN
// ========================================
print('[2/3] Creating application user...');

try {
    db.createUser({
        user: appUser,
        pwd: appPass,
        roles: [
            {
                role: 'readWrite',
                db: dbName
            }
        ]
    });
    print(`✅ User created: ${appUser}`);
} catch (error) {
    if (error.code === 51003) {
        print(`⚠️  User already exists: ${appUser}`);
    } else {
        print(`❌ Error creating user: ${error.message}`);
        throw error;
    }
}

print('');

// ========================================
// 2. CREAR COLECCIONES INICIALES
// ========================================
print('[3/3] Creating initial collections...');

const collections = [
    'users',
    'refresh_tokens',
    'password_reset_tokens',
    'competitions',
    'clubs',
    'events',
    'posts',
    'comments',
    'market_items',
    'athletes',
    'schools',
    'calendar_events',
    'chat_messages',
    'chat_conversations',
    'notifications',
    'logs',
    'csrf_tokens'
];

collections.forEach(collectionName => {
    try {
        db.createCollection(collectionName);
        print(`   ✅ Collection created: ${collectionName}`);
    } catch (error) {
        if (error.code === 48) {
            print(`   ⚠️  Collection already exists: ${collectionName}`);
        } else {
            print(`   ❌ Error creating collection ${collectionName}: ${error.message}`);
        }
    }
});

print('');

// ========================================
// 3. CREAR ÍNDICES BÁSICOS
// ========================================
print('Creating basic indexes...');

// Users
db.users.createIndex({ email: 1 }, { unique: true });
db.users.createIndex({ username: 1 }, { unique: true, sparse: true });
db.users.createIndex({ createdAt: -1 });

// Refresh Tokens (TTL index)
db.refresh_tokens.createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 });

// Password Reset Tokens (TTL index)
db.password_reset_tokens.createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 });

// CSRF Tokens (TTL index)
db.csrf_tokens.createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 });

// Logs (TTL index - se eliminan después de 30 días)
db.logs.createIndex({ timestamp: 1 }, { expireAfterSeconds: 2592000 });

// Competitions
db.competitions.createIndex({ createdAt: -1 });
db.competitions.createIndex({ status: 1 });

// Posts
db.posts.createIndex({ authorID: 1 });
db.posts.createIndex({ createdAt: -1 });

// Market Items
db.market_items.createIndex({ sellerID: 1 });
db.market_items.createIndex({ status: 1 });
db.market_items.createIndex({ createdAt: -1 });

print('✅ Basic indexes created');
print('');

// ========================================
// RESUMEN
// ========================================
print('========================================');
print('  ✅ MongoDB Initialization Complete!');
print('========================================');
print('');
print(`Database: ${dbName}`);
print(`App User: ${appUser}`);
print(`Collections: ${collections.length} created`);
print('');
print('Ready to accept connections from backend');
print('========================================');
