package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// ThreatIntelligence represents comprehensive threat intelligence for an IP address
type ThreatIntelligence struct {
	ID        primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	IPAddress string             `bson:"ip_address" json:"ip_address"` // Indexed, unique
	IPHash    string             `bson:"ip_hash" json:"ip_hash"`       // SHA256 hash for privacy

	// Reputation Information
	Reputation ReputationInfo `bson:"reputation" json:"reputation"`

	// Statistics
	Statistics ThreatStatistics `bson:"statistics" json:"statistics"`

	// Blocking Information
	Blocking BlockingInfo `bson:"blocking" json:"blocking"`

	// Geographic Intelligence
	GeoIntelligence GeoIntelligence `bson:"geo_intelligence" json:"geo_intelligence"`

	// ASN Intelligence
	ASNIntelligence ASNIntelligence `bson:"asn_intelligence" json:"asn_intelligence"`

	// External Threat Feeds Data
	ThreatFeeds ThreatFeedsData `bson:"threat_feeds" json:"threat_feeds"`

	// Behavioral Analysis
	BehavioralAnalysis BehavioralAnalysis `bson:"behavioral_analysis" json:"behavioral_analysis"`

	// Attack Patterns
	AttackPatterns []AttackPattern `bson:"attack_patterns,omitempty" json:"attack_patterns,omitempty"`

	// Mitigation Measures
	Mitigation MitigationMeasures `bson:"mitigation" json:"mitigation"`

	// Related Incidents
	RelatedIncidents []primitive.ObjectID `bson:"related_incidents,omitempty" json:"related_incidents,omitempty"`

	// Tags and Notes
	Tags []string `bson:"tags" json:"tags"`
	//	Notes []Note   `bson:"notes,omitempty" json:"notes,omitempty"`

	// Metadata
	Metadata ThreatIntelMetadata `bson:"metadata" json:"metadata"`
}

// ReputationInfo contains IP reputation information
type ReputationInfo struct {
	Score int `bson:"score" json:"score"` // 0-100 (0=worst, 100=best)
	//	Level            ThreatLevel            `bson:"level" json:"level"`
	LastCalculated     time.Time      `bson:"last_calculated" json:"last_calculated"`
	CalculationFactors map[string]int `bson:"calculation_factors" json:"calculation_factors"`
}

// ThreatStatistics contains statistical information about the threat
type ThreatStatistics struct {
	FirstSeen           time.Time      `bson:"first_seen" json:"first_seen"`
	LastSeen            time.Time      `bson:"last_seen" json:"last_seen"`
	TotalEvents         int            `bson:"total_events" json:"total_events"`
	EventsLastHour      int            `bson:"events_last_hour" json:"events_last_hour"`
	EventsLast24Hours   int            `bson:"events_last_24h" json:"events_last_24h"`
	EventsByType        map[string]int `bson:"events_by_type" json:"events_by_type"`
	UniqueUsersTargeted int            `bson:"unique_users_targeted" json:"unique_users_targeted"`
	UniqueEndpoints     int            `bson:"unique_endpoints_accessed" json:"unique_endpoints_accessed"`
}

// BlockingInfo contains IP blocking information
type BlockingInfo struct {
	IsBlocked         bool                `bson:"is_blocked" json:"is_blocked"`
	BlockedAt         *time.Time          `bson:"blocked_at,omitempty" json:"blocked_at,omitempty"`
	BlockedBy         string              `bson:"blocked_by,omitempty" json:"blocked_by,omitempty"` // admin:user_id or system
	BlockedUntil      *time.Time          `bson:"blocked_until,omitempty" json:"blocked_until,omitempty"`
	BlockReason       string              `bson:"block_reason,omitempty" json:"block_reason,omitempty"`
	BlockType         string              `bson:"block_type,omitempty" json:"block_type,omitempty"` // temporary, permanent, conditional
	BypassAllowed     bool                `bson:"bypass_allowed" json:"bypass_allowed"`
	WhitelistEligible bool                `bson:"whitelist_eligible" json:"whitelist_eligible"`
	BlockHistory      []BlockHistoryEntry `bson:"block_history,omitempty" json:"block_history,omitempty"`
}

// BlockHistoryEntry represents a historical blocking event
type BlockHistoryEntry struct {
	BlockedAt    time.Time  `bson:"blocked_at" json:"blocked_at"`
	UnblockedAt  *time.Time `bson:"unblocked_at,omitempty" json:"unblocked_at,omitempty"`
	BlockedBy    string     `bson:"blocked_by" json:"blocked_by"`
	UnblockedBy  string     `bson:"unblocked_by,omitempty" json:"unblocked_by,omitempty"`
	Reason       string     `bson:"reason" json:"reason"`
	DurationMins int        `bson:"duration_mins" json:"duration_mins"`
}

// GeoIntelligence contains geographic intelligence
type GeoIntelligence struct {
	Country           string          `bson:"country" json:"country"`
	CountryCode       string          `bson:"country_code" json:"country_code"`
	City              string          `bson:"city" json:"city"`
	Region            string          `bson:"region" json:"region"`
	Coordinates       []float64       `bson:"coordinates" json:"coordinates"` // [lat, lon]
	Timezone          string          `bson:"timezone" json:"timezone"`
	IsHighRiskCountry bool            `bson:"is_high_risk_country" json:"is_high_risk_country"`
	TravelPattern     []TravelPattern `bson:"travel_pattern,omitempty" json:"travel_pattern,omitempty"`
}

// TravelPattern represents geographic movement pattern
type TravelPattern struct {
	Location   string    `bson:"location" json:"location"`
	FirstSeen  time.Time `bson:"first_seen" json:"first_seen"`
	LastSeen   time.Time `bson:"last_seen" json:"last_seen"`
	EventCount int       `bson:"event_count" json:"event_count"`
}

// ASNIntelligence contains Autonomous System Number intelligence
type ASNIntelligence struct {
	Number            int    `bson:"number" json:"number"`
	Organization      string `bson:"organization" json:"organization"`
	Network           string `bson:"network" json:"network"`
	IsDatacenter      bool   `bson:"is_datacenter" json:"is_datacenter"`
	IsHostingProvider bool   `bson:"is_hosting_provider" json:"is_hosting_provider"`
	IsVPNProvider     bool   `bson:"is_vpn_provider" json:"is_vpn_provider"`
	Reputation        string `bson:"reputation" json:"reputation"` // good, neutral, bad
}

// ThreatFeedsData contains data from external threat intelligence feeds
type ThreatFeedsData struct {
	AbuseIPDB    *AbuseIPDBData   `bson:"abuseipdb,omitempty" json:"abuseipdb,omitempty"`
	VirusTotal   *VirusTotalData  `bson:"virustotal,omitempty" json:"virustotal,omitempty"`
	AlienVault   *AlienVaultData  `bson:"alienvault,omitempty" json:"alienvault,omitempty"`
	Shodan       *ShodanData      `bson:"shodan,omitempty" json:"shodan,omitempty"`
	CustomFeeds  []CustomFeedData `bson:"custom_feeds,omitempty" json:"custom_feeds,omitempty"`
	LastEnriched time.Time        `bson:"last_enriched" json:"last_enriched"`
}

// AbuseIPDBData contains data from AbuseIPDB
type AbuseIPDBData struct {
	AbuseConfidenceScore int       `bson:"abuse_confidence_score" json:"abuse_confidence_score"` // 0-100
	TotalReports         int       `bson:"total_reports" json:"total_reports"`
	LastReported         time.Time `bson:"last_reported" json:"last_reported"`
	Categories           []string  `bson:"categories" json:"categories"` // brute_force, bad_web_bot, etc.
	CountryCode          string    `bson:"country_code" json:"country_code"`
	IsWhitelisted        bool      `bson:"is_whitelisted" json:"is_whitelisted"`
}

// VirusTotalData contains data from VirusTotal
type VirusTotalData struct {
	MaliciousCount  int       `bson:"malicious_count" json:"malicious_count"`
	SuspiciousCount int       `bson:"suspicious_count" json:"suspicious_count"`
	HarmlessCount   int       `bson:"harmless_count" json:"harmless_count"`
	UndetectedCount int       `bson:"undetected_count" json:"undetected_count"`
	LastAnalysis    time.Time `bson:"last_analysis" json:"last_analysis"`
	ReputationScore int       `bson:"reputation_score" json:"reputation_score"`
}

// AlienVaultData contains data from AlienVault OTX
type AlienVaultData struct {
	PulseCount   int       `bson:"pulse_count" json:"pulses"`
	ThreatScore  int       `bson:"threat_score" json:"threat_score"`
	Tags         []string  `bson:"tags" json:"tags"`
	LastModified time.Time `bson:"last_modified" json:"last_modified"`
}

// ShodanData contains data from Shodan
type ShodanData struct {
	OpenPorts       []int     `bson:"open_ports" json:"open_ports"`
	Services        []string  `bson:"services" json:"services"`
	Vulnerabilities []string  `bson:"vulnerabilities,omitempty" json:"vulnerabilities,omitempty"`
	LastScan        time.Time `bson:"last_scan" json:"last_scan"`
	HostNames       []string  `bson:"hostnames,omitempty" json:"hostnames,omitempty"`
	ISP             string    `bson:"isp" json:"isp"`
}

// CustomFeedData contains data from custom threat feeds
type CustomFeedData struct {
	FeedName       string                 `bson:"feed_name" json:"feed_name"`
	Matched        bool                   `bson:"matched" json:"matched"`
	Reason         string                 `bson:"reason" json:"reason"`
	Confidence     float64                `bson:"confidence" json:"confidence"`
	LastChecked    time.Time              `bson:"last_checked" json:"last_checked"`
	AdditionalData map[string]interface{} `bson:"additional_data,omitempty" json:"additional_data,omitempty"`
}

// BehavioralAnalysis contains behavioral analysis of the IP
type BehavioralAnalysis struct {
	IsBot                  bool     `bson:"is_bot" json:"is_bot"`
	BotConfidence          float64  `bson:"bot_confidence" json:"bot_confidence"`   // 0.0-1.0
	BotType                string   `bson:"bot_type" json:"bot_type"`               // malicious, good, unknown
	RequestPattern         string   `bson:"request_pattern" json:"request_pattern"` // rapid_sequential, distributed, normal
	UserAgentRotation      bool     `bson:"user_agent_rotation" json:"user_agent_rotation"`
	CookieSupport          bool     `bson:"cookie_support" json:"cookie_support"`
	JavaScriptSupport      bool     `bson:"javascript_support" json:"javascript_support"`
	BehavioralAnomalies    []string `bson:"behavioral_anomalies" json:"behavioral_anomalies"`
	RequestVelocity        int      `bson:"request_velocity" json:"request_velocity"` // requests per minute
	UniqueEndpointsHit     int      `bson:"unique_endpoints_hit" json:"unique_endpoints_hit"`
	SessionDurationMinutes int      `bson:"session_duration_minutes" json:"session_duration_minutes"`
}

// AttackPattern represents a detected attack pattern
type AttackPattern struct {
	PatternID     string    `bson:"pattern_id" json:"pattern_id"`
	PatternType   string    `bson:"pattern_type" json:"pattern_type"` // CREDENTIAL_STUFFING, DDoS, etc.
	Confidence    float64   `bson:"confidence" json:"confidence"`     // 0.0-1.0
	FirstDetected time.Time `bson:"first_detected" json:"first_detected"`
	LastSeen      time.Time `bson:"last_seen" json:"last_seen"`
	Indicators    []string  `bson:"indicators" json:"indicators"`
	// Severity      SeverityLevel `bson:"severity" json:"severity"`
}

// MitigationMeasures contains active mitigation measures
type MitigationMeasures struct {
	CurrentRateLimit    string             `bson:"current_rate_limit" json:"current_rate_limit"` // e.g., "1 req/min"
	CaptchaRequired     bool               `bson:"captcha_required" json:"captcha_required"`
	MFARequired         bool               `bson:"mfa_required" json:"mfa_required"`
	ConnectionThrottled bool               `bson:"connection_throttled" json:"connection_throttled"`
	FirewallRuleID      string             `bson:"firewall_rule_id,omitempty" json:"firewall_rule_id,omitempty"`
	CustomMitigations   []CustomMitigation `bson:"custom_mitigations,omitempty" json:"custom_mitigations,omitempty"`
}

// CustomMitigation represents a custom mitigation action
type CustomMitigation struct {
	Type        string     `bson:"type" json:"type"` // rate_limit, block, captcha, etc.
	Description string     `bson:"description" json:"description"`
	AppliedAt   time.Time  `bson:"applied_at" json:"applied_at"`
	AppliedBy   string     `bson:"applied_by" json:"applied_by"`
	ExpiresAt   *time.Time `bson:"expires_at,omitempty" json:"expires_at,omitempty"`
}

// ThreatIntelMetadata contains metadata about the threat intelligence entry
type ThreatIntelMetadata struct {
	CreatedAt    time.Time `bson:"created_at" json:"created_at"`
	UpdatedAt    time.Time `bson:"updated_at" json:"updated_at"`
	LastEnriched time.Time `bson:"last_enriched" json:"last_enriched"`
	Version      int       `bson:"version" json:"version"` // Incremented on each update
}

// ThreatIntelFilter represents filter criteria for querying threat intelligence
type ThreatIntelFilter struct {
	//	ThreatLevels      []ThreatLevel
	IsBlocked         *bool
	MinReputation     int
	MaxReputation     int
	Countries         []string
	IsVPN             *bool
	IsProxy           *bool
	IsTor             *bool
	MinEventCount     int
	AttackPatternType string
	Page              int
	Limit             int
	SortBy            string
	SortOrder         int // 1 for ascending, -1 for descending
}

// IPBlockRequest represents a request to block an IP address
type IPBlockRequest struct {
	IPAddress       string `json:"ip_address" binding:"required"`
	DurationMinutes int    `json:"duration_minutes" binding:"required,min=1"`
	BlockType       string `json:"block_type" binding:"required,oneof=temporary permanent conditional"`
	Reason          string `json:"reason" binding:"required,min=10"`
	//	Severity         SeverityLevel          `json:"severity" binding:"required"`
	Notify               bool              `json:"notify"`
	NotificationChannels []string          `json:"notification_channels,omitempty"`
	BypassConditions     BypassConditions  `json:"bypass_conditions"`
	AutoUnblock          AutoUnblockConfig `json:"auto_unblock"`
	ApprovalRequired     bool              `json:"approval_required"`
	Approvers            []string          `json:"approvers,omitempty"`
}

// BypassConditions defines conditions under which a block can be bypassed
type BypassConditions struct {
	AllowIfMFA           bool `json:"allow_if_mfa"`
	AllowFromKnownDevice bool `json:"allow_from_known_device"`
}

// AutoUnblockConfig defines automatic unblock conditions
type AutoUnblockConfig struct {
	Enabled    bool     `json:"enabled"`
	Conditions []string `json:"conditions"` // e.g., "no_events_for_hours:24"
}

// Collection name
const ThreatIntelligenceCollection = "threat_intelligence"
