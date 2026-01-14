package entities

import (
	"errors"
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Heat mode constants - determines scoring workflow
const (
	HeatModeSequential   = "sequential"   // One athlete at a time (street/park skating, BMX freestyle)
	HeatModeSimultaneous = "simultaneous" // Multiple athletes together (racing, park jams)
)

// Heat status constants
const (
	HeatStatusPending   = "pending"
	HeatStatusActive    = "active"
	HeatStatusPaused    = "paused"    // SECURITY: Master pause - blocks all scoring
	HeatStatusCompleted = "completed"
)

// Heat role constants - for check-in system
const (
	HeatRoleJudge    = "judge"
	HeatRoleSpeaker  = "speaker"
	HeatRoleMarshall = "marshall"
)

// Heat represents a group of athletes competing together in a round
type Heat struct {
	ID            primitive.ObjectID   `json:"id" bson:"_id,omitempty"`
	CompetitionID primitive.ObjectID   `json:"competitionId" bson:"competitionId" validate:"required"`
	RoundID       primitive.ObjectID   `json:"roundId" bson:"roundId" validate:"required"`
	CategoryID    *primitive.ObjectID  `json:"categoryId,omitempty" bson:"categoryId,omitempty"`

	// Heat identification
	Name  string `json:"name" bson:"name" validate:"required"`
	Order int    `json:"order" bson:"order" validate:"required"`

	// Heat configuration
	Mode        string `json:"mode" bson:"mode" validate:"required,oneof=sequential simultaneous"`
	MaxAthletes int    `json:"maxAthletes,omitempty" bson:"maxAthletes,omitempty"`

	// Athlete assignments
	AthleteIDs   []primitive.ObjectID `json:"athleteIds" bson:"athleteIds"`
	AthleteOrder []primitive.ObjectID `json:"athleteOrder,omitempty" bson:"athleteOrder,omitempty"` // For sequential mode

	// Scheduling
	StartTime *time.Time `json:"startTime,omitempty" bson:"startTime,omitempty"`
	EndTime   *time.Time `json:"endTime,omitempty" bson:"endTime,omitempty"`
	Duration  int        `json:"duration,omitempty" bson:"duration,omitempty"` // Minutes

	// Status
	Status string `json:"status" bson:"status" validate:"required,oneof=pending active paused completed"`

	// SECURITY: Check-In System (Ready Protocol)
	CheckInEnabled  bool                       `json:"checkInEnabled" bson:"checkInEnabled"`
	RequiredRoles   []string                   `json:"requiredRoles,omitempty" bson:"requiredRoles,omitempty"`         // e.g., ["judge", "speaker", "marshall"]
	AssignedRoles   map[string][]string        `json:"assignedRoles,omitempty" bson:"assignedRoles,omitempty"`         // role -> userIDs
	CheckedInRoles  map[string][]string        `json:"checkedInRoles,omitempty" bson:"checkedInRoles,omitempty"`       // role -> userIDs who checked in
	MinJudgesActive int                        `json:"minJudgesActive,omitempty" bson:"minJudgesActive,omitempty"`     // Minimum judges to start/continue (for bypass)
	PausedBy        *primitive.ObjectID        `json:"pausedBy,omitempty" bson:"pausedBy,omitempty"`                   // UserID who paused
	PausedAt        *time.Time                 `json:"pausedAt,omitempty" bson:"pausedAt,omitempty"`
	PauseReason     string                     `json:"pauseReason,omitempty" bson:"pauseReason,omitempty"`

	// Metadata
	CreatedAt time.Time `json:"createdAt" bson:"createdAt"`
	UpdatedAt time.Time `json:"updatedAt" bson:"updatedAt"`
}

// NewHeat creates a new Heat entity
func NewHeat(competitionID, roundID primitive.ObjectID, name string, order int, mode string) *Heat {
	now := time.Now()
	return &Heat{
		ID:            primitive.NewObjectID(),
		CompetitionID: competitionID,
		RoundID:       roundID,
		Name:          name,
		Order:         order,
		Mode:          mode,
		AthleteIDs:    []primitive.ObjectID{},
		AthleteOrder:  []primitive.ObjectID{},
		Status:        HeatStatusPending,
		CreatedAt:     now,
		UpdatedAt:     now,
	}
}

// AddAthlete adds an athlete to the heat
func (h *Heat) AddAthlete(athleteID primitive.ObjectID) error {
	// Check if athlete already in heat
	if h.HasAthlete(athleteID) {
		return errors.New("athlete already in heat")
	}

	// Check capacity
	if h.IsFull() {
		return errors.New("heat is at maximum capacity")
	}

	h.AthleteIDs = append(h.AthleteIDs, athleteID)
	h.UpdatedAt = time.Now()
	return nil
}

// RemoveAthlete removes an athlete from the heat
func (h *Heat) RemoveAthlete(athleteID primitive.ObjectID) error {
	index := -1
	for i, id := range h.AthleteIDs {
		if id == athleteID {
			index = i
			break
		}
	}

	if index == -1 {
		return errors.New("athlete not in heat")
	}

	// Remove from AthleteIDs
	h.AthleteIDs = append(h.AthleteIDs[:index], h.AthleteIDs[index+1:]...)

	// Remove from AthleteOrder if present
	orderIndex := -1
	for i, id := range h.AthleteOrder {
		if id == athleteID {
			orderIndex = i
			break
		}
	}
	if orderIndex != -1 {
		h.AthleteOrder = append(h.AthleteOrder[:orderIndex], h.AthleteOrder[orderIndex+1:]...)
	}

	h.UpdatedAt = time.Now()
	return nil
}

// SetAthleteOrder sets the order for athletes in sequential mode
func (h *Heat) SetAthleteOrder(order []primitive.ObjectID) error {
	if h.Mode != HeatModeSequential {
		return errors.New("athlete order only applicable in sequential mode")
	}

	// Validate all IDs in order are in AthleteIDs
	for _, orderedID := range order {
		if !h.HasAthlete(orderedID) {
			return errors.New("cannot order athlete not in heat")
		}
	}

	// Validate all athletes are in order
	if len(order) != len(h.AthleteIDs) {
		return errors.New("order must include all athletes in heat")
	}

	h.AthleteOrder = order
	h.UpdatedAt = time.Now()
	return nil
}

// CanStart checks if the heat can be started
func (h *Heat) CanStart() bool {
	// Must be in pending status
	if h.Status != HeatStatusPending {
		return false
	}

	// Must have at least one athlete
	if len(h.AthleteIDs) == 0 {
		return false
	}

	// In sequential mode, must have athlete order set
	if h.Mode == HeatModeSequential && len(h.AthleteOrder) != len(h.AthleteIDs) {
		return false
	}

	return true
}

// Start marks the heat as active
func (h *Heat) Start() error {
	if !h.CanStart() {
		return errors.New("heat cannot be started")
	}

	now := time.Now()
	h.Status = HeatStatusActive
	h.StartTime = &now
	h.UpdatedAt = now
	return nil
}

// Complete marks the heat as completed
func (h *Heat) Complete() error {
	if h.Status != HeatStatusActive {
		return errors.New("heat must be active to complete")
	}

	now := time.Now()
	h.Status = HeatStatusCompleted
	h.EndTime = &now
	h.UpdatedAt = now
	return nil
}

// IsFull checks if the heat is at maximum capacity
func (h *Heat) IsFull() bool {
	if h.MaxAthletes <= 0 {
		return false
	}
	return len(h.AthleteIDs) >= h.MaxAthletes
}

// HasAthlete checks if an athlete is in this heat
func (h *Heat) HasAthlete(athleteID primitive.ObjectID) bool {
	for _, id := range h.AthleteIDs {
		if id == athleteID {
			return true
		}
	}
	return false
}

// IsSequential returns true if heat is in sequential mode
func (h *Heat) IsSequential() bool {
	return h.Mode == HeatModeSequential
}

// IsSimultaneous returns true if heat is in simultaneous mode
func (h *Heat) IsSimultaneous() bool {
	return h.Mode == HeatModeSimultaneous
}

// IsPending returns true if heat is pending
func (h *Heat) IsPending() bool {
	return h.Status == HeatStatusPending
}

// IsActive returns true if heat is active
func (h *Heat) IsActive() bool {
	return h.Status == HeatStatusActive
}

// IsCompleted returns true if heat is completed
func (h *Heat) IsCompleted() bool {
	return h.Status == HeatStatusCompleted
}

// GetAthleteCount returns the number of athletes in the heat
func (h *Heat) GetAthleteCount() int {
	return len(h.AthleteIDs)
}

// GetAvailableSlots returns the number of available slots
func (h *Heat) GetAvailableSlots() int {
	if h.MaxAthletes <= 0 {
		return -1 // Unlimited
	}
	return h.MaxAthletes - len(h.AthleteIDs)
}

// =============================================================================
// SECURITY: CHECK-IN SYSTEM (Ready Protocol)
// =============================================================================

// InitializeCheckIn initializes the check-in system for the heat
func (h *Heat) InitializeCheckIn(requiredRoles []string, minJudges int) {
	h.CheckInEnabled = true
	h.RequiredRoles = requiredRoles
	h.MinJudgesActive = minJudges
	h.AssignedRoles = make(map[string][]string)
	h.CheckedInRoles = make(map[string][]string)
	h.UpdatedAt = time.Now()
}

// AssignRole assigns a user to a role (judge, speaker, marshall)
func (h *Heat) AssignRole(role string, userID string) error {
	if !h.CheckInEnabled {
		return errors.New("check-in not enabled for this heat")
	}

	// Validate role
	validRole := false
	for _, r := range h.RequiredRoles {
		if r == role {
			validRole = true
			break
		}
	}
	if !validRole {
		return errors.New("invalid role for this heat")
	}

	// Initialize map if needed
	if h.AssignedRoles == nil {
		h.AssignedRoles = make(map[string][]string)
	}

	// Check if already assigned
	if h.IsRoleAssigned(role, userID) {
		return errors.New("user already assigned to this role")
	}

	// Add to assigned roles
	h.AssignedRoles[role] = append(h.AssignedRoles[role], userID)
	h.UpdatedAt = time.Now()
	return nil
}

// UnassignRole removes a user from a role
func (h *Heat) UnassignRole(role string, userID string) error {
	if !h.CheckInEnabled {
		return errors.New("check-in not enabled for this heat")
	}

	if h.AssignedRoles == nil {
		return errors.New("no roles assigned")
	}

	users, exists := h.AssignedRoles[role]
	if !exists {
		return errors.New("role not found")
	}

	// Find and remove user
	index := -1
	for i, uid := range users {
		if uid == userID {
			index = i
			break
		}
	}

	if index == -1 {
		return errors.New("user not assigned to this role")
	}

	h.AssignedRoles[role] = append(users[:index], users[index+1:]...)

	// Also remove from checked-in if present
	if h.CheckedInRoles != nil {
		if checkedUsers, exists := h.CheckedInRoles[role]; exists {
			for i, uid := range checkedUsers {
				if uid == userID {
					h.CheckedInRoles[role] = append(checkedUsers[:i], checkedUsers[i+1:]...)
					break
				}
			}
		}
	}

	h.UpdatedAt = time.Now()
	return nil
}

// ReplaceRole replaces a user in a role with another user (for contingencies)
func (h *Heat) ReplaceRole(role string, oldUserID string, newUserID string) error {
	// Unassign old user
	if err := h.UnassignRole(role, oldUserID); err != nil {
		return err
	}

	// Assign new user
	if err := h.AssignRole(role, newUserID); err != nil {
		return err
	}

	return nil
}

// CheckIn marks a user as checked-in for their assigned role
func (h *Heat) CheckIn(role string, userID string) error {
	if !h.CheckInEnabled {
		return errors.New("check-in not enabled for this heat")
	}

	// Verify user is assigned to this role
	if !h.IsRoleAssigned(role, userID) {
		return errors.New("user not assigned to this role")
	}

	// Initialize map if needed
	if h.CheckedInRoles == nil {
		h.CheckedInRoles = make(map[string][]string)
	}

	// Check if already checked in
	if h.IsCheckedIn(role, userID) {
		return errors.New("user already checked in")
	}

	// Add to checked-in roles
	h.CheckedInRoles[role] = append(h.CheckedInRoles[role], userID)
	h.UpdatedAt = time.Now()
	return nil
}

// CheckOut marks a user as checked-out (e.g., for role replacement)
func (h *Heat) CheckOut(role string, userID string) error {
	if h.CheckedInRoles == nil {
		return errors.New("no checked-in roles")
	}

	users, exists := h.CheckedInRoles[role]
	if !exists {
		return errors.New("role not found in checked-in list")
	}

	// Find and remove user
	index := -1
	for i, uid := range users {
		if uid == userID {
			index = i
			break
		}
	}

	if index == -1 {
		return errors.New("user not checked in for this role")
	}

	h.CheckedInRoles[role] = append(users[:index], users[index+1:]...)
	h.UpdatedAt = time.Now()
	return nil
}

// IsAllRolesReady checks if all required roles have checked in
func (h *Heat) IsAllRolesReady() bool {
	if !h.CheckInEnabled {
		return true // Check-in not required, always ready
	}

	// Check each required role
	for _, role := range h.RequiredRoles {
		// Special handling for judges (can use min judges)
		if role == HeatRoleJudge {
			checkedInCount := len(h.CheckedInRoles[role])
			if checkedInCount < h.MinJudgesActive {
				return false
			}
		} else {
			// Other roles must have at least one person checked in
			if len(h.CheckedInRoles[role]) == 0 {
				return false
			}
		}
	}

	return true
}

// IsRoleAssigned checks if a user is assigned to a role
func (h *Heat) IsRoleAssigned(role string, userID string) bool {
	if h.AssignedRoles == nil {
		return false
	}

	users, exists := h.AssignedRoles[role]
	if !exists {
		return false
	}

	for _, uid := range users {
		if uid == userID {
			return true
		}
	}

	return false
}

// IsCheckedIn checks if a user has checked in for their role
func (h *Heat) IsCheckedIn(role string, userID string) bool {
	if h.CheckedInRoles == nil {
		return false
	}

	users, exists := h.CheckedInRoles[role]
	if !exists {
		return false
	}

	for _, uid := range users {
		if uid == userID {
			return true
		}
	}

	return false
}

// GetCheckedInCount returns the number of checked-in users for a role
func (h *Heat) GetCheckedInCount(role string) int {
	if h.CheckedInRoles == nil {
		return 0
	}

	return len(h.CheckedInRoles[role])
}

// =============================================================================
// SECURITY: PAUSE/RESUME SYSTEM (Master Pause)
// =============================================================================

// Pause pauses the heat (blocks all scoring)
func (h *Heat) Pause(userID primitive.ObjectID, reason string) error {
	if h.Status == HeatStatusPaused {
		return errors.New("heat already paused")
	}

	if h.Status != HeatStatusActive {
		return errors.New("can only pause active heats")
	}

	now := time.Now()
	h.Status = HeatStatusPaused
	h.PausedBy = &userID
	h.PausedAt = &now
	h.PauseReason = reason
	h.UpdatedAt = now
	return nil
}

// Resume resumes a paused heat
func (h *Heat) Resume() error {
	if h.Status != HeatStatusPaused {
		return errors.New("heat is not paused")
	}

	h.Status = HeatStatusActive
	h.PausedBy = nil
	h.PausedAt = nil
	h.PauseReason = ""
	h.UpdatedAt = time.Now()
	return nil
}

// IsPaused returns true if heat is paused
func (h *Heat) IsPaused() bool {
	return h.Status == HeatStatusPaused
}

// CanAcceptScores checks if the heat can currently accept score submissions
func (h *Heat) CanAcceptScores() bool {
	// Must be active (not paused, not completed, not pending)
	if h.Status != HeatStatusActive {
		return false
	}

	// If check-in enabled, all roles must be ready
	if h.CheckInEnabled && !h.IsAllRolesReady() {
		return false
	}

	return true
}

// =============================================================================
// EMERGENCY: CONTINGENCY METHODS (Crisis Management)
// =============================================================================
// These methods are ONLY used during emergencies (injuries, equipment failure, etc.)
// All emergency operations are logged in emergency_actions collection with full audit trail

// EmergencyRemoveAthlete removes an athlete from the heat during an emergency
// USE CASES:
// - Athlete injured during heat and cannot continue
// - Equipment failure requiring athlete removal
// - Medical emergency requiring immediate removal
//
// SECURITY: This bypasses normal validation - reason is MANDATORY
// AUDIT: State before/after is captured in EmergencyAction entity
func (h *Heat) EmergencyRemoveAthlete(athleteID primitive.ObjectID, reason string) error {
	// Validate reason (minimum 10 characters as per emergency requirements)
	if len(reason) < 10 {
		return errors.New("emergency reason must be at least 10 characters")
	}

	// Check if athlete is in heat
	if !h.HasAthlete(athleteID) {
		return errors.New("athlete not in heat")
	}

	// EMERGENCY BYPASS: Allow removal even if heat is active
	// Normal RemoveAthlete would block this

	// Remove from AthleteIDs
	newAthleteIDs := []primitive.ObjectID{}
	for _, id := range h.AthleteIDs {
		if id != athleteID {
			newAthleteIDs = append(newAthleteIDs, id)
		}
	}
	h.AthleteIDs = newAthleteIDs

	// Remove from AthleteOrder (if sequential mode)
	if h.Mode == HeatModeSequential {
		newOrder := []primitive.ObjectID{}
		for _, id := range h.AthleteOrder {
			if id != athleteID {
				newOrder = append(newOrder, id)
			}
		}
		h.AthleteOrder = newOrder
	}

	h.UpdatedAt = time.Now()
	return nil
}

// EmergencyUpdateAthleteOrder re-orders athletes during an active heat
// USE CASES:
// - Athlete injury requires skipping to next athlete
// - Technical issue requires order change
// - Safety concern requires immediate re-ordering
//
// SECURITY: Only works in sequential mode - reason is MANDATORY
// AUDIT: State before/after is captured in EmergencyAction entity
func (h *Heat) EmergencyUpdateAthleteOrder(newOrder []primitive.ObjectID, reason string) error {
	// Validate reason (minimum 10 characters)
	if len(reason) < 10 {
		return errors.New("emergency reason must be at least 10 characters")
	}

	// Only applicable to sequential mode
	if h.Mode != HeatModeSequential {
		return errors.New("athlete order only applicable to sequential mode heats")
	}

	// Validate that newOrder contains exactly the same athletes
	if len(newOrder) != len(h.AthleteIDs) {
		return errors.New("new order must contain all athletes in heat")
	}

	// Validate that all athletes in newOrder are in the heat
	athleteMap := make(map[primitive.ObjectID]bool)
	for _, id := range h.AthleteIDs {
		athleteMap[id] = true
	}

	for _, id := range newOrder {
		if !athleteMap[id] {
			return errors.New("athlete in new order not found in heat")
		}
	}

	// EMERGENCY BYPASS: Allow order change even if heat is active
	// Normal SetAthleteOrder would block this

	h.AthleteOrder = newOrder
	h.UpdatedAt = time.Now()
	return nil
}

// EmergencyAddAthlete adds an athlete during an active heat (emergency replacement)
// USE CASES:
// - Replacement athlete needed due to last-minute withdrawal
// - Administrative error correction during live heat
//
// SECURITY: This bypasses capacity checks - reason is MANDATORY
// AUDIT: State before/after is captured in EmergencyAction entity
func (h *Heat) EmergencyAddAthlete(athleteID primitive.ObjectID, reason string) error {
	// Validate reason (minimum 10 characters)
	if len(reason) < 10 {
		return errors.New("emergency reason must be at least 10 characters")
	}

	// Check if athlete already in heat
	if h.HasAthlete(athleteID) {
		return errors.New("athlete already in heat")
	}

	// EMERGENCY BYPASS: Allow addition even if heat is at capacity or active

	// Add to AthleteIDs
	h.AthleteIDs = append(h.AthleteIDs, athleteID)

	// Add to end of order (if sequential mode)
	if h.Mode == HeatModeSequential {
		h.AthleteOrder = append(h.AthleteOrder, athleteID)
	}

	h.UpdatedAt = time.Now()
	return nil
}
