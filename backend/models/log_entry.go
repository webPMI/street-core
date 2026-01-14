package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// LogEntry representa una entrada de log en MongoDB
type LogEntry struct {
	ID        primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	Timestamp time.Time          `bson:"timestamp" json:"timestamp"`
	Level     string             `bson:"level" json:"level"` // DEBUG, INFO, WARN, ERROR, FATAL
	Message   string             `bson:"message" json:"message"`
	Caller    string             `bson:"caller" json:"caller"` // archivo:linea

	// Contexto estructurado (campos dinámicos)
	Context map[string]interface{} `bson:"context,omitempty" json:"context,omitempty"`

	// Metadata del sistema
	Service     string `bson:"service" json:"service"`         // "fitriders-backend"
	Environment string `bson:"environment" json:"environment"` // development, staging, production
	Version     string `bson:"version" json:"version"`         // Versión de la API

	// TTL - MongoDB eliminará automáticamente después de expiresAt
	ExpiresAt time.Time `bson:"expiresAt" json:"expiresAt"`

	// Timestamps de auditoría
	CreatedAt time.Time `bson:"createdAt" json:"createdAt"`
}

// NewLogEntry crea una nueva entrada de log
func NewLogEntry(level, message, caller string, context map[string]interface{}, env, service, version string, ttlDays int) *LogEntry {
	now := time.Now()

	return &LogEntry{
		ID:          primitive.NewObjectID(),
		Timestamp:   now,
		Level:       level,
		Message:     message,
		Caller:      caller,
		Context:     context,
		Service:     service,
		Environment: env,
		Version:     version,
		ExpiresAt:   now.AddDate(0, 0, ttlDays), // Ahora + ttlDays
		CreatedAt:   now,
	}
}

// IsExpired verifica si el log ha expirado
func (l *LogEntry) IsExpired() bool {
	return time.Now().After(l.ExpiresAt)
}

// LogStats representa estadísticas de logs
type LogStats struct {
	TotalLogs     int64            `json:"totalLogs"`
	ByLevel       map[string]int64 `json:"byLevel"`
	ByEnvironment map[string]int64 `json:"byEnvironment"`
	OldestLog     *time.Time       `json:"oldestLog,omitempty"`
	NewestLog     *time.Time       `json:"newestLog,omitempty"`
}
