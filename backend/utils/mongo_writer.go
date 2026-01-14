package utils

import (
	"context"
	"fmt"
	"os"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
	"backend/models"
)

// MongoWriter maneja la escritura de logs a MongoDB
type MongoWriter struct {
	collection  *mongo.Collection
	environment string // development, staging, production
	service     string
	version     string
	ttlDays     int
	enabled     bool
}

// MongoWriterConfig configuración para MongoWriter
type MongoWriterConfig struct {
	Collection  *mongo.Collection
	Environment string
	Service     string
	Version     string
	TTLDays     int
	Enabled     bool
}

// NewMongoWriter crea un nuevo escritor de MongoDB para logs
func NewMongoWriter(config MongoWriterConfig) (*MongoWriter, error) {
	if !config.Enabled {
		return &MongoWriter{enabled: false}, nil
	}

	if config.Collection == nil {
		return nil, fmt.Errorf("collection no puede ser nil")
	}

	// Valores por defecto
	if config.Service == "" {
		config.Service = "fitriders-backend"
	}
	if config.Version == "" {
		config.Version = "1.0.0"
	}
	if config.TTLDays <= 0 {
		config.TTLDays = 30 // 30 días por defecto
	}

	mw := &MongoWriter{
		collection:  config.Collection,
		environment: config.Environment,
		service:     config.Service,
		version:     config.Version,
		ttlDays:     config.TTLDays,
		enabled:     true,
	}

	// Crear índices
	if err := mw.createIndexes(); err != nil {
		return nil, fmt.Errorf("error creando índices: %w", err)
	}

	return mw, nil
}

// createIndexes crea los índices necesarios en MongoDB
func (mw *MongoWriter) createIndexes() error {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	indexes := []mongo.IndexModel{
		// 1. TTL Index - auto-delete después de expiresAt
		{
			Keys:    bson.D{{Key: "expiresAt", Value: 1}},
			Options: options.Index().SetExpireAfterSeconds(0).SetName("logs_ttl_idx"),
		},
		// 2. Query principal - nivel y timestamp
		{
			Keys: bson.D{
				{Key: "level", Value: 1},
				{Key: "timestamp", Value: -1},
			},
			Options: options.Index().SetName("logs_level_timestamp_idx"),
		},
		// 3. Búsqueda por environment
		{
			Keys: bson.D{
				{Key: "environment", Value: 1},
				{Key: "timestamp", Value: -1},
			},
			Options: options.Index().SetName("logs_env_timestamp_idx"),
		},
	}

	_, err := mw.collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		return err
	}

	return nil
}

// Write escribe un log a MongoDB
func (mw *MongoWriter) Write(level LogLevel, message, caller string, fields map[string]interface{}) error {
	if !mw.enabled {
		return nil
	}

	// FILTRADO: Descartar INFO en producción
	if mw.environment == "production" && level == INFO {
		return nil // No guardar
	}

	// FILTRADO: Descartar DEBUG en producción
	if mw.environment == "production" && level == DEBUG {
		return nil // No guardar
	}

	// Crear entrada de log
	entry := models.NewLogEntry(
		level.String(),
		message,
		caller,
		fields,
		mw.environment,
		mw.service,
		mw.version,
		mw.ttlDays,
	)

	// Escribir a MongoDB con timeout
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := mw.collection.InsertOne(ctx, entry)
	if err != nil {
		// FAIL-SAFE: No fallar la app, solo log a stderr
		fmt.Fprintf(os.Stderr, "⚠️  MongoDB log write failed: %v\n", err)
		return nil // No propagar error
	}

	return nil
}

// GetStats obtiene estadísticas de los logs en MongoDB
func (mw *MongoWriter) GetStats() (*models.LogStats, error) {
	if !mw.enabled {
		return nil, fmt.Errorf("mongo writer no está habilitado")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Count total
	total, err := mw.collection.CountDocuments(ctx, map[string]interface{}{})
	if err != nil {
		return nil, err
	}

	// Aggregation por nivel
	pipeline := []interface{}{
		map[string]interface{}{
			"$group": map[string]interface{}{
				"_id":   "$level",
				"count": map[string]interface{}{"$sum": 1},
			},
		},
	}

	cursor, err := mw.collection.Aggregate(ctx, pipeline)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	byLevel := make(map[string]int64)
	for cursor.Next(ctx) {
		var result struct {
			ID    string `bson:"_id"`
			Count int64  `bson:"count"`
		}
		if err := cursor.Decode(&result); err != nil {
			continue
		}
		byLevel[result.ID] = result.Count
	}

	stats := &models.LogStats{
		TotalLogs: total,
		ByLevel:   byLevel,
	}

	return stats, nil
}

// Close cierra la conexión (noop, ya que usamos la conexión compartida)
func (mw *MongoWriter) Close() error {
	// No cerramos la conexión porque es compartida con el resto de la app
	return nil
}

// IsEnabled retorna si el writer está habilitado
func (mw *MongoWriter) IsEnabled() bool {
	return mw.enabled
}
