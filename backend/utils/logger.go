package utils

import (
	"fmt"
	"io"
	"os"
	"runtime"
	"strings"
	"time"
)

// LogLevel representa el nivel de severidad del log
type LogLevel int

const (
	DEBUG LogLevel = iota
	INFO
	WARN
	ERROR
	FATAL
)

// String convierte el LogLevel a string
func (l LogLevel) String() string {
	return [...]string{" DEBUG", " INFO", " WARN", " ERROR", " FATAL"}[l]
}

// Color ANSI para terminal
func (l LogLevel) Color() string {
	return [...]string{
		"\033[36m", // DEBUG - Cyan
		"\033[32m", // INFO - Green
		"\033[33m", // WARN - Yellow
		"\033[31m", // ERROR - Red
		"\033[35m", // FATAL - Magenta
	}[l]
}

// Logger es la estructura principal del logger
type Logger struct {
	level       LogLevel
	format      string // "json" o "pretty"
	output      io.Writer
	prefix      string
	timeFormat  string
	fileWriter  *FileWriter  // Escritor de archivos (opcional)
	mongoWriter *MongoWriter // Escritor de MongoDB (opcional)
}

// AppLogger es la instancia global del logger
var AppLogger *Logger

// InitLogger inicializa el logger global con la configuración especificada
func InitLogger(level string, format string) {
	logLevel := parseLogLevel(level)

	AppLogger = &Logger{
		level:       logLevel,
		format:      format,
		output:      os.Stdout,
		prefix:      "",
		timeFormat:  "2006-01-02 15:04:05",
		fileWriter:  nil, // Se configura luego con EnableFileLogging
		mongoWriter: nil, // Se configura luego con EnableMongoLogging
	}

	AppLogger.Info("Logger inicializado", map[string]interface{}{
		"level":  logLevel.String(),
		"format": format,
	})
}

// EnableFileLogging habilita el logging a archivos
func EnableFileLogging(baseDir string, maxFileSize int64, maxAge time.Duration) error {
	if AppLogger == nil {
		return fmt.Errorf("logger no inicializado, llama a InitLogger primero")
	}

	fw, err := NewFileWriter(baseDir, maxFileSize, maxAge, true)
	if err != nil {
		return fmt.Errorf("error habilitando logging a archivos: %w", err)
	}

	AppLogger.fileWriter = fw

	AppLogger.Info("Logging a archivos habilitado", map[string]interface{}{
		"baseDir":     baseDir,
		"maxFileSize": fmt.Sprintf("%d MB", maxFileSize/(1024*1024)),
		"maxAge":      maxAge.String(),
	})

	return nil
}

// DisableFileLogging deshabilita el logging a archivos
func DisableFileLogging() error {
	if AppLogger == nil || AppLogger.fileWriter == nil {
		return nil
	}

	if err := AppLogger.fileWriter.Close(); err != nil {
		return err
	}

	AppLogger.fileWriter = nil
	AppLogger.Info("Logging a archivos deshabilitado", nil)

	return nil
}

// GetFileStats devuelve estadísticas de los archivos de log
func GetFileStats() map[string]interface{} {
	if AppLogger == nil || AppLogger.fileWriter == nil {
		return map[string]interface{}{
			"enabled": false,
		}
	}

	return AppLogger.fileWriter.GetStats()
}

// EnableMongoLogging habilita el logging a MongoDB
func EnableMongoLogging(config MongoWriterConfig) error {
	if AppLogger == nil {
		return fmt.Errorf("logger no inicializado, llama a InitLogger primero")
	}

	mw, err := NewMongoWriter(config)
	if err != nil {
		return fmt.Errorf("error habilitando logging a MongoDB: %w", err)
	}

	AppLogger.mongoWriter = mw

	AppLogger.Info("Logging a MongoDB habilitado", map[string]interface{}{
		"collection":  "logs",
		"environment": config.Environment,
		"ttlDays":     config.TTLDays,
	})

	return nil
}

// DisableMongoLogging deshabilita el logging a MongoDB
func DisableMongoLogging() error {
	if AppLogger == nil || AppLogger.mongoWriter == nil {
		return nil
	}

	if err := AppLogger.mongoWriter.Close(); err != nil {
		return err
	}

	AppLogger.mongoWriter = nil
	AppLogger.Info("Logging a MongoDB deshabilitado", nil)

	return nil
}

// GetMongoStats devuelve estadísticas de los logs en MongoDB
func GetMongoStats() (map[string]interface{}, error) {
	if AppLogger == nil || AppLogger.mongoWriter == nil || !AppLogger.mongoWriter.IsEnabled() {
		return map[string]interface{}{
			"enabled": false,
		}, nil
	}

	stats, err := AppLogger.mongoWriter.GetStats()
	if err != nil {
		return nil, err
	}

	return map[string]interface{}{
		"enabled":   true,
		"totalLogs": stats.TotalLogs,
		"byLevel":   stats.ByLevel,
	}, nil
}

// parseLogLevel convierte un string a LogLevel
func parseLogLevel(level string) LogLevel {
	switch strings.ToUpper(level) {
	case "DEBUG":
		return DEBUG
	case "INFO":
		return INFO
	case "WARN", "WARNING":
		return WARN
	case "ERROR":
		return ERROR
	case "FATAL":
		return FATAL
	default:
		return INFO
	}
}

// shouldLog determina si un mensaje debe ser logueado según el nivel
func (l *Logger) shouldLog(level LogLevel) bool {
	return level >= l.level
}

// getCaller obtiene información del caller
func getCaller() string {
	_, file, line, ok := runtime.Caller(3)
	if !ok {
		return "unknown:0"
	}

	// Extraer solo el nombre del archivo
	parts := strings.Split(file, "/")
	if len(parts) > 0 {
		file = parts[len(parts)-1]
	}

	return fmt.Sprintf("%s:%d", file, line)
}

// formatMessage formatea el mensaje según el formato configurado
func (l *Logger) formatMessage(level LogLevel, message string, fields map[string]interface{}) string {
	timestamp := time.Now().Format(l.timeFormat)
	caller := getCaller()

	if l.format == "json" {
		return l.formatJSON(level, timestamp, caller, message, fields)
	}
	return l.formatPretty(level, timestamp, caller, message, fields)
}

// formatJSON formatea el mensaje en formato JSON
func (l *Logger) formatJSON(level LogLevel, timestamp, caller, message string, fields map[string]interface{}) string {
	jsonFields := fmt.Sprintf(`"time":"%s","level":"%s","caller":"%s","message":"%s"`,
		timestamp, level.String(), caller, escapeJSON(message))

	if len(fields) > 0 {
		for key, value := range fields {
			jsonFields += fmt.Sprintf(`,"%s":"%v"`, escapeJSON(key), escapeJSON(fmt.Sprintf("%v", value)))
		}
	}

	return fmt.Sprintf("{%s}", jsonFields)
}

// formatPretty formatea el mensaje en formato legible (con colores)
func (l *Logger) formatPretty(level LogLevel, timestamp, caller, message string, fields map[string]interface{}) string {
	reset := "\033[0m"
	gray := "\033[90m"

	// Emoji según nivel
	emoji := map[LogLevel]string{
		DEBUG: "🔍 ",
		INFO:  "ℹ️ ",
		WARN:  "⚠️ ",
		ERROR: "❌ ",
		FATAL: "💀 ",
	}[level]

	result := fmt.Sprintf("%s%s %s[%s]%s %s%-5s%s %s%s%s %s",
		gray, timestamp, reset,
		caller,
		level.Color(), emoji, level.String(), reset,
		"\033[1m", message, reset, // Bold para el mensaje
		gray,
	)

	// Añadir campos si existen
	if len(fields) > 0 {
		var fieldStrings []string
		for key, value := range fields {
			fieldStrings = append(fieldStrings, fmt.Sprintf("%s=%v", key, value))
		}
		result += fmt.Sprintf(" | %s", strings.Join(fieldStrings, ", "))
	}

	result += reset

	return result
}

// escapeJSON escapa caracteres especiales para JSON
func escapeJSON(s string) string {
	s = strings.ReplaceAll(s, "\\", "\\\\")
	s = strings.ReplaceAll(s, "\"", "\\\"")
	s = strings.ReplaceAll(s, "\n", "\\n")
	s = strings.ReplaceAll(s, "\r", "\\r")
	s = strings.ReplaceAll(s, "\t", "\\t")
	return s
}

// log es la función interna que maneja el logging
func (l *Logger) log(level LogLevel, message string, fields map[string]interface{}) {
	if !l.shouldLog(level) {
		return
	}

	formatted := l.formatMessage(level, message, fields)

	// Escribir a stdout/stderr
	fmt.Fprintln(l.output, formatted)

	// Escribir a archivo si está habilitado
	if l.fileWriter != nil && l.fileWriter.enabled {
		// Usar formato apropiado para archivo (siempre JSON para mejor análisis)
		fileFormatted := l.formatJSON(level, time.Now().Format(l.timeFormat), getCaller(), message, fields)
		if err := l.fileWriter.Write(level, fileFormatted); err != nil {
			// No fallar si el archivo falla, solo escribir a stderr
			fmt.Fprintf(os.Stderr, "Error escribiendo log a archivo: %v\n", err)
		}
	}

	// Escribir a MongoDB si está habilitado
	if l.mongoWriter != nil && l.mongoWriter.IsEnabled() {
		caller := getCaller()
		if err := l.mongoWriter.Write(level, message, caller, fields); err != nil {
			// No fallar si MongoDB falla, solo escribir a stderr
			fmt.Fprintf(os.Stderr, "Error escribiendo log a MongoDB: %v\n", err)
		}
	}

	// Si es FATAL, cerrar recursos antes de terminar
	if level == FATAL {
		if l.fileWriter != nil {
			l.fileWriter.Close()
		}
		if l.mongoWriter != nil {
			l.mongoWriter.Close()
		}
		os.Exit(1)
	}
}

// Debug registra un mensaje de nivel DEBUG
func (l *Logger) Debug(message string, fields ...map[string]interface{}) {
	var f map[string]interface{}
	if len(fields) > 0 {
		f = fields[0]
	}
	l.log(DEBUG, message, f)
}

// Info registra un mensaje de nivel INFO
func (l *Logger) Info(message string, fields ...map[string]interface{}) {
	var f map[string]interface{}
	if len(fields) > 0 {
		f = fields[0]
	}
	l.log(INFO, message, f)
}

// Warn registra un mensaje de nivel WARN
func (l *Logger) Warn(message string, fields ...map[string]interface{}) {
	var f map[string]interface{}
	if len(fields) > 0 {
		f = fields[0]
	}
	l.log(WARN, message, f)
}

// Error registra un mensaje de nivel ERROR
func (l *Logger) Error(message string, fields ...map[string]interface{}) {
	var f map[string]interface{}
	if len(fields) > 0 {
		f = fields[0]
	}
	l.log(ERROR, message, f)
}

// Fatal registra un mensaje de nivel FATAL y termina el programa
func (l *Logger) Fatal(message string, fields ...map[string]interface{}) {
	var f map[string]interface{}
	if len(fields) > 0 {
		f = fields[0]
	}
	l.log(FATAL, message, f)
}

// ============================================================================
// TAG-AWARE LOGGING METHODS
// ============================================================================
// These methods add a "tag" field for better log filtering and organization

// DebugWithTag registra un mensaje DEBUG con tag
func (l *Logger) DebugWithTag(tag, message string, fields ...map[string]interface{}) {
	f := mergeFieldsWithTag(tag, fields)
	l.log(DEBUG, message, f)
}

// InfoWithTag registra un mensaje INFO con tag
func (l *Logger) InfoWithTag(tag, message string, fields ...map[string]interface{}) {
	f := mergeFieldsWithTag(tag, fields)
	l.log(INFO, message, f)
}

// WarnWithTag registra un mensaje WARN con tag
func (l *Logger) WarnWithTag(tag, message string, fields ...map[string]interface{}) {
	f := mergeFieldsWithTag(tag, fields)
	l.log(WARN, message, f)
}

// ErrorWithTag registra un mensaje ERROR con tag
func (l *Logger) ErrorWithTag(tag, message string, fields ...map[string]interface{}) {
	f := mergeFieldsWithTag(tag, fields)
	l.log(ERROR, message, f)
}

// FatalWithTag registra un mensaje FATAL con tag y termina el programa
func (l *Logger) FatalWithTag(tag, message string, fields ...map[string]interface{}) {
	f := mergeFieldsWithTag(tag, fields)
	l.log(FATAL, message, f)
}

// mergeFieldsWithTag combina fields y añade el tag
func mergeFieldsWithTag(tag string, fieldMaps []map[string]interface{}) map[string]interface{} {
	f := make(map[string]interface{})
	f["tag"] = tag

	if len(fieldMaps) > 0 && fieldMaps[0] != nil {
		for k, v := range fieldMaps[0] {
			f[k] = v
		}
	}

	return f
}

// Funciones de conveniencia globales

// Debug log global
func Debug(message string, fields ...map[string]interface{}) {
	if AppLogger != nil {
		AppLogger.Debug(message, fields...)
	}
}

// Info log global
func Info(message string, fields ...map[string]interface{}) {
	if AppLogger != nil {
		AppLogger.Info(message, fields...)
	}
}

// Warn log global
func Warn(message string, fields ...map[string]interface{}) {
	if AppLogger != nil {
		AppLogger.Warn(message, fields...)
	}
}

// Error log global
func Error(message string, fields ...map[string]interface{}) {
	if AppLogger != nil {
		AppLogger.Error(message, fields...)
	}
}

// Fatal log global
func Fatal(message string, fields ...map[string]interface{}) {
	if AppLogger != nil {
		AppLogger.Fatal(message, fields...)
	} else {
		// Fallback si el logger no está inicializado
		fmt.Fprintf(os.Stderr, " FATAL: %s\n", message)
		os.Exit(1)
	}
}

// ============================================================================
// GLOBAL TAG-AWARE FUNCTIONS
// ============================================================================

// DebugWithTag log global con tag
func DebugWithTag(tag, message string, fields ...map[string]interface{}) {
	if AppLogger != nil {
		AppLogger.DebugWithTag(tag, message, fields...)
	}
}

// InfoWithTag log global con tag
func InfoWithTag(tag, message string, fields ...map[string]interface{}) {
	if AppLogger != nil {
		AppLogger.InfoWithTag(tag, message, fields...)
	}
}

// WarnWithTag log global con tag
func WarnWithTag(tag, message string, fields ...map[string]interface{}) {
	if AppLogger != nil {
		AppLogger.WarnWithTag(tag, message, fields...)
	}
}

// ErrorWithTag log global con tag
func ErrorWithTag(tag, message string, fields ...map[string]interface{}) {
	if AppLogger != nil {
		AppLogger.ErrorWithTag(tag, message, fields...)
	}
}

// FatalWithTag log global con tag
func FatalWithTag(tag, message string, fields ...map[string]interface{}) {
	if AppLogger != nil {
		AppLogger.FatalWithTag(tag, message, fields...)
	} else {
		// Fallback si el logger no está inicializado
		fmt.Fprintf(os.Stderr, " FATAL [%s]: %s\n", tag, message)
		os.Exit(1)
	}
}
