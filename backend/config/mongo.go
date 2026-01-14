package config

import (
	"context"
	"strings"
	"time"

	"backend/utils"

	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// Constantes para el reintento de conexión
const (
	MaxConnectionRetries = 5                // Número máximo de veces que intentaremos conectar
	RetryDelaySeconds    = 30               // 1 minuto de retardo entre reintentos
	ConnectionTimeout    = 10 * time.Second // Timeout para cada intento de conexión
)

func ConnectMongo() (*mongo.Client, *mongo.Database) {
	// 1. Determine if MONGO_URI is already a complete connection string
	var finalURI string

	// If MONGO_URI contains credentials (@), use it as-is (from docker-compose or full URI in .env)
	if strings.Contains(Cfg.MongoURI, "@") {
		finalURI = Cfg.MongoURI
		utils.Info("Conectando a MongoDB con URI completa", map[string]interface{}{
			"uri": finalURI,
		})
	} else if Cfg.DBUser != "" && Cfg.DBPassword != "" {
		// Construct URI with provided credentials
		hostAndPort := strings.TrimPrefix(Cfg.MongoURI, "mongodb://")
		finalURI = "mongodb://" + Cfg.DBUser + ":" + Cfg.DBPassword + "@" + hostAndPort + "/" + Cfg.DBName + "?authSource=" + Cfg.DBName
		utils.Info("Conectando a MongoDB con credenciales", map[string]interface{}{
			"host":     hostAndPort,
			"database": Cfg.DBName,
		})
	} else {
		// Simple URI without authentication
		hostAndPort := strings.TrimPrefix(Cfg.MongoURI, "mongodb://")
		finalURI = "mongodb://" + hostAndPort + "/" + Cfg.DBName
		utils.Info("Conectando a MongoDB sin autenticación", map[string]interface{}{
			"host":     hostAndPort,
			"database": Cfg.DBName,
		})
	}

	// Configure connection pool settings for optimal performance
	// Production-optimized settings based on workload characteristics
	clientOptions := options.Client().
		ApplyURI(finalURI).
		SetMaxPoolSize(100).                        // Maximum connections in pool (recommended: 100-200 for production)
		SetMinPoolSize(20).                         // Minimum connections to maintain (increased for faster response)
		SetMaxConnIdleTime(5 * time.Minute).        // Close idle connections after 5 minutes (was 30s, too aggressive)
		SetServerSelectionTimeout(5 * time.Second). // Timeout for server selection
		SetConnectTimeout(10 * time.Second).        // Connection timeout
		SetSocketTimeout(30 * time.Second).         // Socket timeout for operations
		SetHeartbeatInterval(10 * time.Second).     // Heartbeat interval for monitoring
		SetRetryWrites(true).                       // Enable retryable writes for resilience
		SetRetryReads(true)                         // Enable retryable reads for resilience

	// 2. BUCLE DE REINTENTO
	for i := 1; i <= MaxConnectionRetries; i++ {

		// Contexto con timeout para este intento
		ctx, cancel := context.WithTimeout(context.Background(), ConnectionTimeout)

		client, err := mongo.Connect(ctx, clientOptions)
		cancel() // Liberar el recurso del contexto

		if err != nil {
			utils.Error("Intento de conexión a MongoDB fallido", map[string]interface{}{
				"intento":     i,
				"maxIntentos": MaxConnectionRetries,
				"error":       err.Error(),
			})

			if i == MaxConnectionRetries {
				// Si es el último intento, devolvemos el error fatal.
				utils.Fatal("No se pudo conectar a MongoDB después de múltiples intentos", map[string]interface{}{
					"intentos": MaxConnectionRetries,
					"error":    err.Error(),
				})
			}

			// Esperar el retardo antes del siguiente intento
			utils.Warn("Esperando antes del próximo intento de conexión", map[string]interface{}{
				"segundos": RetryDelaySeconds,
			})
			time.Sleep(RetryDelaySeconds * time.Second)

			continue // Ir al siguiente intento del bucle
		}

		// 3. Verificar conexión (Ping)
		pingCtx, pingCancel := context.WithTimeout(context.Background(), 5*time.Second)
		err = client.Ping(pingCtx, nil)
		pingCancel()

		if err != nil {
			utils.Error("Ping a MongoDB fallido después de establecer conexión", map[string]interface{}{
				"intento":     i,
				"maxIntentos": MaxConnectionRetries,
				"error":       err.Error(),
			})
			client.Disconnect(context.Background()) // Cerrar conexión fallida

			if i == MaxConnectionRetries {
				utils.Fatal("La conexión a MongoDB fue rechazada después de múltiples intentos", map[string]interface{}{
					"intentos": MaxConnectionRetries,
					"error":    err.Error(),
				})
			}

			utils.Warn("Esperando antes del próximo intento de ping", map[string]interface{}{
				"segundos": RetryDelaySeconds,
			})
			time.Sleep(RetryDelaySeconds * time.Second)
			continue // Ir al siguiente intento
		}

		// 4. ÉXITO (Fuera del bucle)
		db := client.Database(Cfg.DBName)
		utils.Info("MongoDB conectado exitosamente", map[string]interface{}{
			"database": Cfg.DBName,
			"intento":  i,
		})

		// Create admin user (OPCIONAL - solo si ADMIN_EMAIL y ADMIN_PASSWORD están definidos)
		CreateAdminUser(db)

		return client, db
	}

	// Esto es inalcanzable si usamos log.Fatalf, pero es buena práctica de Go.
	return nil, nil
}
