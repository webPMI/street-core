package models

// EmergencyError represents a generic emergency error
type EmergencyError struct {
	Message string
	Details map[string]interface{}
}

func (e *EmergencyError) Error() string {
	return e.Message
}

// HeatError represents a generic heat error
type HeatError struct {
	Message string
	Details map[string]interface{}
}

func (e *HeatError) Error() string {
	return e.Message
}

// ScoreError represents a generic score error
type ScoreError struct {
	Message string
	Details map[string]interface{}
}

func (e *ScoreError) Error() string {
	return e.Message
}

// BroadcastError represents a generic broadcast error
type BroadcastError struct {
	Message string
	Details map[string]interface{}
}

func (e *BroadcastError) Error() string {
	return e.Message
}
