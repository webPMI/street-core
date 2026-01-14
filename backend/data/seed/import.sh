#!/bin/bash

###############################################################################
# StreetCore - Script de Importación Rápida
#
# Este script importa todos los datos de ejemplo a MongoDB usando mongoimport.
#
# Uso:
#   chmod +x import.sh
#   ./import.sh
#
# Requisitos:
#   - MongoDB corriendo en localhost:27017
#   - mongoimport disponible en PATH
###############################################################################

set -e  # Exit on error

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuración
DB_NAME="fitriders"
MONGO_HOST="localhost:27017"

echo -e "${BLUE}🚀 StreetCore - Importación de Datos${NC}\n"
echo -e "   MongoDB: ${MONGO_HOST}"
echo -e "   Base de datos: ${DB_NAME}\n"

# Verificar que MongoDB está corriendo
echo -e "${YELLOW}🔍 Verificando conexión a MongoDB...${NC}"
if ! mongosh --host ${MONGO_HOST} --eval "db.version()" --quiet > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: No se puede conectar a MongoDB en ${MONGO_HOST}${NC}"
    echo -e "${YELLOW}   Asegúrate de que MongoDB está corriendo${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Conexión exitosa${NC}\n"

# Función para importar colección
import_collection() {
    local file=$1
    local collection=$2

    echo -e "${YELLOW}📦 Importando ${collection}...${NC}"

    if [ ! -f "${file}" ]; then
        echo -e "${RED}   ❌ Archivo no encontrado: ${file}${NC}"
        return 1
    fi

    if mongoimport \
        --host ${MONGO_HOST} \
        --db ${DB_NAME} \
        --collection ${collection} \
        --file ${file} \
        --jsonArray \
        --drop \
        --quiet; then

        # Contar documentos importados
        local count=$(mongosh --host ${MONGO_HOST} --quiet --eval "db.getSiblingDB('${DB_NAME}').${collection}.countDocuments()")
        echo -e "${GREEN}   ✅ Importados ${count} documentos${NC}"
    else
        echo -e "${RED}   ❌ Error importando ${collection}${NC}"
        return 1
    fi
}

# Importar colecciones
import_collection "05_test_users_fixed.json" "users"
import_collection "02_skateparks.json" "skateparks"
import_collection "03_clubs_fixed.json" "clubs"
import_collection "06_real_competitions_skate_bmx_scooter.json" "competitions"

# Resumen
echo -e "\n${BLUE}📊 Resumen de importación:${NC}"
mongosh --host ${MONGO_HOST} --quiet --eval "
    const db = db.getSiblingDB('${DB_NAME}');
    console.log('   - users:', db.users.countDocuments());
    console.log('   - skateparks:', db.skateparks.countDocuments());
    console.log('   - clubs:', db.clubs.countDocuments());
    console.log('   - competitions:', db.competitions.countDocuments());
"

echo -e "\n${GREEN}✅ Importación completada con éxito${NC}\n"

# Información adicional
echo -e "${BLUE}ℹ️  Información:${NC}"
echo -e "   - Usuarios: 21 (20 atletas + 1 admin)"
echo -e "   - Skateparks: 12 reales de España"
echo -e "   - Clubs: 8 comunidades urbanas"
echo -e "   - Competiciones: 5 activas (Feb-Mar 2026)"
echo -e ""
echo -e "${YELLOW}🔐 Credenciales de prueba:${NC}"
echo -e "   Admin:"
echo -e "     Email: admin@streetcore.com"
echo -e "     Pass: password"
echo -e ""
echo -e "   Atleta (Carlos Martínez):"
echo -e "     Email: carlos.martinez@example.com"
echo -e "     Pass: password"
echo -e ""
echo -e "${GREEN}✨ Todo listo para empezar!${NC}\n"
