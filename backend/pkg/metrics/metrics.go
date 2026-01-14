package metrics

import (
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
	// HTTP metrics
	httpRequestsTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "fitriders_http_requests_total",
			Help: "Total number of HTTP requests",
		},
		[]string{"method", "path", "status"},
	)

	httpRequestDuration = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "fitriders_http_request_duration_seconds",
			Help:    "HTTP request duration in seconds",
			Buckets: prometheus.DefBuckets,
		},
		[]string{"method", "path"},
	)

	httpRequestsInFlight = promauto.NewGauge(
		prometheus.GaugeOpts{
			Name: "fitriders_http_requests_in_flight",
			Help: "Current number of HTTP requests being processed",
		},
	)

	// Database metrics
	dbQueryDuration = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "fitriders_db_query_duration_seconds",
			Help:    "Database query duration in seconds",
			Buckets: []float64{.001, .005, .01, .025, .05, .1, .25, .5, 1, 2.5, 5},
		},
		[]string{"operation", "collection"},
	)

	dbConnectionPoolSize = promauto.NewGauge(
		prometheus.GaugeOpts{
			Name: "fitriders_db_connection_pool_size",
			Help: "Current size of database connection pool",
		},
	)

	dbConnectionPoolInUse = promauto.NewGauge(
		prometheus.GaugeOpts{
			Name: "fitriders_db_connection_pool_in_use",
			Help: "Number of database connections currently in use",
		},
	)

	// Cache metrics
	cacheHitsTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "fitriders_cache_hits_total",
			Help: "Total number of cache hits",
		},
		[]string{"cache_name"},
	)

	cacheMissesTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "fitriders_cache_misses_total",
			Help: "Total number of cache misses",
		},
		[]string{"cache_name"},
	)

	// JWT metrics
	jwtTokensIssued = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "fitriders_jwt_tokens_issued_total",
			Help: "Total number of JWT tokens issued",
		},
		[]string{"token_type"},
	)

	jwtTokenValidationErrors = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "fitriders_jwt_validation_errors_total",
			Help: "Total number of JWT token validation errors",
		},
		[]string{"error_type"},
	)

	// Business metrics
	competitionsCreated = promauto.NewCounter(
		prometheus.CounterOpts{
			Name: "fitriders_competitions_created_total",
			Help: "Total number of competitions created",
		},
	)

	competitionsPublished = promauto.NewCounter(
		prometheus.CounterOpts{
			Name: "fitriders_competitions_published_total",
			Help: "Total number of competitions published",
		},
	)

	usersRegistered = promauto.NewCounter(
		prometheus.CounterOpts{
			Name: "fitriders_users_registered_total",
			Help: "Total number of users registered",
		},
	)

	participantsRegistered = promauto.NewCounter(
		prometheus.CounterOpts{
			Name: "fitriders_participants_registered_total",
			Help: "Total number of participants registered for competitions",
		},
	)

	scoresSubmitted = promauto.NewCounter(
		prometheus.CounterOpts{
			Name: "fitriders_scores_submitted_total",
			Help: "Total number of scores submitted",
		},
	)

	emailsSent = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "fitriders_emails_sent_total",
			Help: "Total number of emails sent",
		},
		[]string{"template"},
	)

	emailErrors = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "fitriders_email_errors_total",
			Help: "Total number of email sending errors",
		},
		[]string{"template"},
	)
)

// PrometheusMiddleware creates a Gin middleware for Prometheus metrics
func PrometheusMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Skip metrics endpoint itself
		if c.Request.URL.Path == "/metrics" {
			c.Next()
			return
		}

		start := time.Now()
		path := c.FullPath()
		if path == "" {
			path = c.Request.URL.Path
		}

		// Increment in-flight requests
		httpRequestsInFlight.Inc()
		defer httpRequestsInFlight.Dec()

		// Process request
		c.Next()

		// Record metrics
		duration := time.Since(start).Seconds()
		status := strconv.Itoa(c.Writer.Status())

		httpRequestsTotal.WithLabelValues(c.Request.Method, path, status).Inc()
		httpRequestDuration.WithLabelValues(c.Request.Method, path).Observe(duration)
	}
}

// RecordDBQuery records a database query duration
func RecordDBQuery(operation, collection string, duration time.Duration) {
	dbQueryDuration.WithLabelValues(operation, collection).Observe(duration.Seconds())
}

// RecordCacheHit records a cache hit
func RecordCacheHit(cacheName string) {
	cacheHitsTotal.WithLabelValues(cacheName).Inc()
}

// RecordCacheMiss records a cache miss
func RecordCacheMiss(cacheName string) {
	cacheMissesTotal.WithLabelValues(cacheName).Inc()
}

// RecordJWTTokenIssued records a JWT token issuance
func RecordJWTTokenIssued(tokenType string) {
	jwtTokensIssued.WithLabelValues(tokenType).Inc()
}

// RecordJWTValidationError records a JWT validation error
func RecordJWTValidationError(errorType string) {
	jwtTokenValidationErrors.WithLabelValues(errorType).Inc()
}

// RecordCompetitionCreated records a competition creation
func RecordCompetitionCreated() {
	competitionsCreated.Inc()
}

// RecordCompetitionPublished records a competition publication
func RecordCompetitionPublished() {
	competitionsPublished.Inc()
}

// RecordUserRegistered records a user registration
func RecordUserRegistered() {
	usersRegistered.Inc()
}

// RecordParticipantRegistered records a participant registration
func RecordParticipantRegistered() {
	participantsRegistered.Inc()
}

// RecordScoreSubmitted records a score submission
func RecordScoreSubmitted() {
	scoresSubmitted.Inc()
}

// RecordEmailSent records an email sent
func RecordEmailSent(template string) {
	emailsSent.WithLabelValues(template).Inc()
}

// RecordEmailError records an email error
func RecordEmailError(template string) {
	emailErrors.WithLabelValues(template).Inc()
}

// UpdateDBConnectionPoolMetrics updates database connection pool metrics
func UpdateDBConnectionPoolMetrics(poolSize, inUse int) {
	dbConnectionPoolSize.Set(float64(poolSize))
	dbConnectionPoolInUse.Set(float64(inUse))
}

// SetupMetricsRoute sets up the /metrics endpoint for Prometheus scraping
func SetupMetricsRoute(router *gin.Engine) {
	router.GET("/metrics", gin.WrapH(promhttp.Handler()))
}
