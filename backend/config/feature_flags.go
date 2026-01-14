package config

import (
	"fmt"
)

// FeatureFlags holds feature flag configuration for gradual rollout of new features.
// Feature flags allow enabling/disabling features without code changes.
type FeatureFlags struct {
	// Storage feature flags
	UseS3Storage      bool // Enable S3 storage (all uploads go to S3)
	UseHybridStorage  bool // Enable hybrid storage (new to S3, old on filesystem)
	CDNEnabled        bool // Enable CDN URLs for media
	MigrationEnabled  bool // Enable background migration from filesystem to S3

	// Future feature flags can be added here
	// EnableNewDashboard bool
	// EnableBetaFeatures bool
}

// Features is the global feature flags instance
var Features FeatureFlags

// LoadFeatureFlags loads feature flags from environment variables
func LoadFeatureFlags() {
	Features = FeatureFlags{
		UseS3Storage:     getEnvAsBool("FEATURE_S3_STORAGE", false),
		UseHybridStorage: getEnvAsBool("FEATURE_HYBRID_STORAGE", false),
		CDNEnabled:       getEnvAsBool("FEATURE_CDN_ENABLED", false),
		MigrationEnabled: getEnvAsBool("FEATURE_MIGRATION_ENABLED", false),
	}

	// Validation: Can't have both S3 and Hybrid enabled
	if Features.UseS3Storage && Features.UseHybridStorage {
		fmt.Println("⚠️  Warning: Both FEATURE_S3_STORAGE and FEATURE_HYBRID_STORAGE are enabled")
		fmt.Println("   Hybrid mode will be used (gradual migration)")
		Features.UseS3Storage = false // Hybrid takes precedence
	}

	// Log feature flags status
	logFeatureFlags()
}

// logFeatureFlags logs the current state of all feature flags
func logFeatureFlags() {
	fmt.Println("🚩 Feature Flags:")

	// Storage flags
	if Features.UseS3Storage {
		fmt.Println("   ✅ S3 Storage: Enabled (all uploads to S3)")
	} else if Features.UseHybridStorage {
		fmt.Println("   ✅ Hybrid Storage: Enabled (gradual migration)")
		if Features.MigrationEnabled {
			fmt.Println("   ✅ Background Migration: Enabled")
		} else {
			fmt.Println("   ⚠️  Background Migration: Disabled (enable with FEATURE_MIGRATION_ENABLED=true)")
		}
	} else {
		fmt.Println("   📁 Storage: Filesystem (default)")
	}

	if Features.CDNEnabled {
		fmt.Println("   ✅ CDN: Enabled")
	} else {
		fmt.Println("   ❌ CDN: Disabled")
	}

	// Warn if migration is enabled but hybrid is not
	if Features.MigrationEnabled && !Features.UseHybridStorage {
		fmt.Println("   ⚠️  Warning: FEATURE_MIGRATION_ENABLED=true but FEATURE_HYBRID_STORAGE=false")
		fmt.Println("      Migration only works in hybrid mode")
	}
}

// IsStorageFeatureEnabled returns true if any storage feature is enabled
func IsStorageFeatureEnabled() bool {
	return Features.UseS3Storage || Features.UseHybridStorage
}

// GetStorageMode returns the current storage mode as a string
func GetStorageMode() string {
	if Features.UseS3Storage {
		return "s3"
	}
	if Features.UseHybridStorage {
		return "hybrid"
	}
	return "filesystem"
}
