package utils

import (
	"fmt"
	"os"
	"path/filepath"
	"sync"
	"time"
)

// FileWriter maneja la escritura de logs a archivos con rotación
type FileWriter struct {
	baseDir        string                // Directorio base para logs
	files          map[LogLevel]*os.File // Archivos abiertos por nivel
	fileSizes      map[LogLevel]int64    // Tamaño actual de cada archivo
	maxFileSize    int64                 // Tamaño máximo antes de rotar (bytes)
	maxAge         time.Duration         // Edad máxima de logs antes de eliminar
	mu             sync.Mutex            // Mutex para escrituras concurrentes
	enableRotation bool                  // Si está habilitada la rotación
	enabled        bool                  // Si está habilitado el logging a archivo
}

const (
	// Tamaño máximo por defecto: 10 MB
	defaultMaxFileSize = 10 * 1024 * 1024
	// Edad máxima por defecto: 7 días
	defaultMaxAge = 7 * 24 * time.Hour
)

// NewFileWriter crea un nuevo escritor de archivos de log
func NewFileWriter(baseDir string, maxFileSize int64, maxAge time.Duration, enabled bool) (*FileWriter, error) {
	if !enabled {
		return &FileWriter{enabled: false}, nil
	}

	// Crear directorio de logs si no existe
	if err := os.MkdirAll(baseDir, 0755); err != nil {
		return nil, fmt.Errorf("error creando directorio de logs: %w", err)
	}

	// Valores por defecto
	if maxFileSize <= 0 {
		maxFileSize = defaultMaxFileSize
	}
	if maxAge <= 0 {
		maxAge = defaultMaxAge
	}

	fw := &FileWriter{
		baseDir:        baseDir,
		files:          make(map[LogLevel]*os.File),
		fileSizes:      make(map[LogLevel]int64),
		maxFileSize:    maxFileSize,
		maxAge:         maxAge,
		enableRotation: true,
		enabled:        true,
	}

	// Abrir archivos para cada nivel
	levels := []LogLevel{DEBUG, INFO, WARN, ERROR, FATAL}
	for _, level := range levels {
		if err := fw.openFile(level); err != nil {
			fw.Close() // Cerrar archivos ya abiertos
			return nil, err
		}
	}

	// Iniciar limpieza automática de logs antiguos
	go fw.cleanupOldLogs()

	return fw, nil
}

// getFileName devuelve el nombre del archivo para un nivel
func (fw *FileWriter) getFileName(level LogLevel, timestamp time.Time) string {
	// Formato: debug_2025-12-11.log
	return fmt.Sprintf("%s_%s.log",
		levelToFileName(level),
		timestamp.Format("2006-01-02"))
}

// levelToFileName convierte LogLevel a nombre de archivo
func levelToFileName(level LogLevel) string {
	return [...]string{"debug", "info", "warn", "error", "fatal"}[level]
}

// openFile abre o crea un archivo de log para un nivel específico
func (fw *FileWriter) openFile(level LogLevel) error {
	filename := fw.getFileName(level, time.Now())
	filepath := filepath.Join(fw.baseDir, filename)

	// Abrir en modo append, crear si no existe
	file, err := os.OpenFile(filepath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		return fmt.Errorf("error abriendo archivo %s: %w", filepath, err)
	}

	// Obtener tamaño actual del archivo
	info, err := file.Stat()
	if err != nil {
		file.Close()
		return fmt.Errorf("error obteniendo info del archivo: %w", err)
	}

	fw.files[level] = file
	fw.fileSizes[level] = info.Size()

	return nil
}

// Write escribe un mensaje en el archivo correspondiente al nivel
func (fw *FileWriter) Write(level LogLevel, message string) error {
	if !fw.enabled {
		return nil
	}

	fw.mu.Lock()
	defer fw.mu.Unlock()

	// Verificar si necesita rotación
	if fw.enableRotation && fw.fileSizes[level] >= fw.maxFileSize {
		if err := fw.rotate(level); err != nil {
			return err
		}
	}

	// Escribir mensaje
	file := fw.files[level]
	if file == nil {
		return fmt.Errorf("archivo no disponible para nivel %s", level.String())
	}

	messageWithNewline := message + "\n"
	n, err := file.WriteString(messageWithNewline)
	if err != nil {
		return fmt.Errorf("error escribiendo en archivo: %w", err)
	}

	// Actualizar tamaño
	fw.fileSizes[level] += int64(n)

	// Asegurar que se escriba inmediatamente
	if err := file.Sync(); err != nil {
		return fmt.Errorf("error sincronizando archivo: %w", err)
	}

	return nil
}

// rotate rota el archivo de log para un nivel
func (fw *FileWriter) rotate(level LogLevel) error {
	// Cerrar archivo actual
	if file := fw.files[level]; file != nil {
		if err := file.Close(); err != nil {
			return fmt.Errorf("error cerrando archivo para rotación: %w", err)
		}
	}

	// Renombrar archivo actual con timestamp
	oldFilename := fw.getFileName(level, time.Now())
	oldPath := filepath.Join(fw.baseDir, oldFilename)

	// Nuevo nombre con timestamp exacto
	timestamp := time.Now().Format("2006-01-02_15-04-05")
	newFilename := fmt.Sprintf("%s_%s.log", levelToFileName(level), timestamp)
	newPath := filepath.Join(fw.baseDir, newFilename)

	// Renombrar
	if err := os.Rename(oldPath, newPath); err != nil {
		// Si falla, intentar abrir de nuevo el archivo original
		fw.openFile(level)
		return fmt.Errorf("error rotando archivo: %w", err)
	}

	// Abrir nuevo archivo
	if err := fw.openFile(level); err != nil {
		return err
	}

	return nil
}

// cleanupOldLogs elimina logs más antiguos que maxAge
func (fw *FileWriter) cleanupOldLogs() {
	ticker := time.NewTicker(24 * time.Hour) // Revisar cada 24 horas
	defer ticker.Stop()

	for range ticker.C {
		fw.mu.Lock()
		fw.performCleanup()
		fw.mu.Unlock()
	}
}

// performCleanup realiza la limpieza de archivos antiguos
func (fw *FileWriter) performCleanup() {
	cutoffTime := time.Now().Add(-fw.maxAge)

	// Leer todos los archivos en el directorio de logs
	entries, err := os.ReadDir(fw.baseDir)
	if err != nil {
		return // Ignorar error silenciosamente
	}

	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}

		// Verificar si es un archivo de log
		if !isLogFile(entry.Name()) {
			continue
		}

		// Obtener info del archivo
		filepath := filepath.Join(fw.baseDir, entry.Name())
		info, err := os.Stat(filepath)
		if err != nil {
			continue
		}

		// Si es más antiguo que el cutoff, eliminar
		if info.ModTime().Before(cutoffTime) {
			os.Remove(filepath)
		}
	}
}

// isLogFile verifica si un nombre de archivo es un log
func isLogFile(filename string) bool {
	ext := filepath.Ext(filename)
	return ext == ".log"
}

// Close cierra todos los archivos abiertos
func (fw *FileWriter) Close() error {
	if !fw.enabled {
		return nil
	}

	fw.mu.Lock()
	defer fw.mu.Unlock()

	var lastErr error
	for level, file := range fw.files {
		if file != nil {
			if err := file.Close(); err != nil {
				lastErr = err
			}
			delete(fw.files, level)
		}
	}

	return lastErr
}

// GetStats devuelve estadísticas de los archivos de log
func (fw *FileWriter) GetStats() map[string]interface{} {
	if !fw.enabled {
		return map[string]interface{}{
			"enabled": false,
		}
	}

	fw.mu.Lock()
	defer fw.mu.Unlock()

	stats := map[string]interface{}{
		"enabled":     true,
		"baseDir":     fw.baseDir,
		"maxFileSize": fmt.Sprintf("%d MB", fw.maxFileSize/(1024*1024)),
		"maxAge":      fw.maxAge.String(),
		"files":       make(map[string]string),
	}

	// Información de cada archivo
	for level, size := range fw.fileSizes {
		stats["files"].(map[string]string)[level.String()] = fmt.Sprintf("%.2f MB", float64(size)/(1024*1024))
	}

	return stats
}

// ForceRotate fuerza la rotación de un nivel específico (útil para testing)
func (fw *FileWriter) ForceRotate(level LogLevel) error {
	if !fw.enabled {
		return nil
	}

	fw.mu.Lock()
	defer fw.mu.Unlock()

	return fw.rotate(level)
}

// ForceCleanup fuerza la limpieza de archivos antiguos (útil para testing)
func (fw *FileWriter) ForceCleanup() {
	if !fw.enabled {
		return
	}

	fw.mu.Lock()
	defer fw.mu.Unlock()

	fw.performCleanup()
}
