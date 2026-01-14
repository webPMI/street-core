package entities

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Registration type constants
const (
	RegistrationTypeFull       = "full"       // Registered to entire tournament
	RegistrationTypeIndividual = "individual" // Registered to specific competitions only
)

// Registration status constants
const (
	RegistrationStatusPending  = "pending"   // Awaiting approval
	RegistrationStatusApproved = "approved"  // Approved and active
	RegistrationStatusRejected = "rejected"  // Rejected
	RegistrationStatusCancelled = "cancelled" // Cancelled by athlete
	RegistrationStatusWithdrawn = "withdrawn" // Withdrawn during tournament
)

// Payment status constants
const (
	PaymentStatusPending   = "pending"
	PaymentStatusCompleted = "completed"
	PaymentStatusFailed    = "failed"
	PaymentStatusRefunded  = "refunded"
	PaymentStatusWaived    = "waived" // Fee waived (e.g., for organizers, sponsors)
)

// PaymentInfo represents payment information for registration
type PaymentInfo struct {
	Amount          float64    `json:"amount" bson:"amount"`
	Currency        string     `json:"currency" bson:"currency"`
	Status          string     `json:"status" bson:"status"`
	PaymentMethod   string     `json:"paymentMethod,omitempty" bson:"paymentMethod,omitempty"` // credit_card, bank_transfer, cash, etc.
	TransactionID   string     `json:"transactionId,omitempty" bson:"transactionId,omitempty"`
	PaymentDate     *time.Time `json:"paymentDate,omitempty" bson:"paymentDate,omitempty"`
	RefundDate      *time.Time `json:"refundDate,omitempty" bson:"refundDate,omitempty"`
	RefundAmount    *float64   `json:"refundAmount,omitempty" bson:"refundAmount,omitempty"`
	RefundReason    string     `json:"refundReason,omitempty" bson:"refundReason,omitempty"`
}

// ApprovalInfo represents approval information for registration
type ApprovalInfo struct {
	IsRequired    bool                `json:"isRequired" bson:"isRequired"`
	Status        string              `json:"status" bson:"status"` // pending, approved, rejected
	ApprovedBy    *primitive.ObjectID `json:"approvedBy,omitempty" bson:"approvedBy,omitempty"`
	ApprovedByName string             `json:"approvedByName,omitempty" bson:"approvedByName,omitempty"`
	ApprovedAt    *time.Time          `json:"approvedAt,omitempty" bson:"approvedAt,omitempty"`
	RejectedBy    *primitive.ObjectID `json:"rejectedBy,omitempty" bson:"rejectedBy,omitempty"`
	RejectedByName string             `json:"rejectedByName,omitempty" bson:"rejectedByName,omitempty"`
	RejectedAt    *time.Time          `json:"rejectedAt,omitempty" bson:"rejectedAt,omitempty"`
	RejectionReason string            `json:"rejectionReason,omitempty" bson:"rejectionReason,omitempty"`
	Notes         string              `json:"notes,omitempty" bson:"notes,omitempty"`
}

// TournamentRegistration represents an athlete's registration to a tournament
type TournamentRegistration struct {
	ID           primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	TournamentID primitive.ObjectID `json:"tournamentId" bson:"tournamentId" validate:"required"`
	AthleteID    primitive.ObjectID `json:"athleteId" bson:"athleteId" validate:"required"`
	AthleteName  string             `json:"athleteName" bson:"athleteName"`
	AthleteEmail string             `json:"athleteEmail" bson:"athleteEmail"`
	AthletePhone string             `json:"athletePhone,omitempty" bson:"athletePhone,omitempty"`

	// Registration details
	RegistrationType string    `json:"registrationType" bson:"registrationType" validate:"required,oneof=full individual"` // full or individual
	RegistrationDate time.Time `json:"registrationDate" bson:"registrationDate"`
	Status           string    `json:"status" bson:"status" validate:"required"` // pending, approved, rejected, cancelled, withdrawn

	// For individual registration: specific competitions selected
	SelectedCompetitionIDs []primitive.ObjectID `json:"selectedCompetitionIds,omitempty" bson:"selectedCompetitionIds,omitempty"`

	// Race information
	RaceNumber         *int   `json:"raceNumber,omitempty" bson:"raceNumber,omitempty"`           // Assigned race number
	Team               string `json:"team,omitempty" bson:"team,omitempty"`                       // Team name (if applicable)
	VehicleMake        string `json:"vehicleMake,omitempty" bson:"vehicleMake,omitempty"`         // Motorcycle make
	VehicleModel       string `json:"vehicleModel,omitempty" bson:"vehicleModel,omitempty"`       // Motorcycle model
	VehicleYear        *int   `json:"vehicleYear,omitempty" bson:"vehicleYear,omitempty"`         // Year
	LicenseNumber      string `json:"licenseNumber,omitempty" bson:"licenseNumber,omitempty"`     // Racing license number
	LicenseFederation  string `json:"licenseFederation,omitempty" bson:"licenseFederation,omitempty"` // Federation (FIM, AMA, etc.)

	// Emergency contact
	EmergencyContactName  string `json:"emergencyContactName,omitempty" bson:"emergencyContactName,omitempty"`
	EmergencyContactPhone string `json:"emergencyContactPhone,omitempty" bson:"emergencyContactPhone,omitempty"`
	MedicalNotes          string `json:"medicalNotes,omitempty" bson:"medicalNotes,omitempty"`

	// Payment
	Payment PaymentInfo `json:"payment" bson:"payment"`

	// Approval (if required)
	Approval ApprovalInfo `json:"approval" bson:"approval"`

	// Documents (URLs to uploaded files)
	DocumentUrls map[string]string `json:"documentUrls,omitempty" bson:"documentUrls,omitempty"` // e.g., "license": "url", "insurance": "url"

	// Participation tracking
	CompetitionsCompleted int      `json:"competitionsCompleted" bson:"competitionsCompleted"`
	CompetitionsMissed    int      `json:"competitionsMissed" bson:"competitionsMissed"`
	LastParticipation     *time.Time `json:"lastParticipation,omitempty" bson:"lastParticipation,omitempty"`

	// Withdrawal
	WithdrawnAt     *time.Time `json:"withdrawnAt,omitempty" bson:"withdrawnAt,omitempty"`
	WithdrawalReason string    `json:"withdrawalReason,omitempty" bson:"withdrawalReason,omitempty"`

	// Admin notes
	AdminNotes string `json:"adminNotes,omitempty" bson:"adminNotes,omitempty"`

	// Metadata
	CreatedAt time.Time `json:"createdAt" bson:"createdAt"`
	UpdatedAt time.Time `json:"updatedAt" bson:"updatedAt"`
}

// NewTournamentRegistration creates a new tournament registration
func NewTournamentRegistration(
	tournamentID, athleteID primitive.ObjectID,
	athleteName, athleteEmail string,
	registrationType string,
) *TournamentRegistration {
	now := time.Now()

	registration := &TournamentRegistration{
		ID:                     primitive.NewObjectID(),
		TournamentID:           tournamentID,
		AthleteID:              athleteID,
		AthleteName:            athleteName,
		AthleteEmail:           athleteEmail,
		RegistrationType:       registrationType,
		RegistrationDate:       now,
		Status:                 RegistrationStatusPending,
		SelectedCompetitionIDs: []primitive.ObjectID{},
		Payment: PaymentInfo{
			Status: PaymentStatusPending,
		},
		Approval: ApprovalInfo{
			IsRequired: false,
			Status:     RegistrationStatusApproved, // Auto-approved by default
		},
		CompetitionsCompleted: 0,
		CompetitionsMissed:    0,
		DocumentUrls:          make(map[string]string),
		CreatedAt:             now,
		UpdatedAt:             now,
	}

	return registration
}

// IsFullRegistration checks if this is a full tournament registration
func (tr *TournamentRegistration) IsFullRegistration() bool {
	return tr.RegistrationType == RegistrationTypeFull
}

// IsIndividualRegistration checks if this is an individual competition registration
func (tr *TournamentRegistration) IsIndividualRegistration() bool {
	return tr.RegistrationType == RegistrationTypeIndividual
}

// IsActive checks if the registration is active
func (tr *TournamentRegistration) IsActive() bool {
	return tr.Status == RegistrationStatusApproved
}

// IsPending checks if the registration is pending approval
func (tr *TournamentRegistration) IsPending() bool {
	return tr.Status == RegistrationStatusPending
}

// IsRejected checks if the registration was rejected
func (tr *TournamentRegistration) IsRejected() bool {
	return tr.Status == RegistrationStatusRejected
}

// IsWithdrawn checks if the athlete has withdrawn
func (tr *TournamentRegistration) IsWithdrawn() bool {
	return tr.Status == RegistrationStatusWithdrawn
}

// IsCancelled checks if the registration was cancelled
func (tr *TournamentRegistration) IsCancelled() bool {
	return tr.Status == RegistrationStatusCancelled
}

// RequiresApproval sets the registration to require approval
func (tr *TournamentRegistration) RequiresApproval() {
	tr.Approval.IsRequired = true
	tr.Approval.Status = RegistrationStatusPending
	tr.Status = RegistrationStatusPending
	tr.UpdatedAt = time.Now()
}

// Approve approves the registration
func (tr *TournamentRegistration) Approve(approvedBy primitive.ObjectID, approvedByName string) error {
	if !tr.Approval.IsRequired {
		return ErrRegistrationNoApprovalRequired
	}
	if tr.Status != RegistrationStatusPending {
		return ErrRegistrationInvalidStatus
	}

	now := time.Now()
	tr.Status = RegistrationStatusApproved
	tr.Approval.Status = RegistrationStatusApproved
	tr.Approval.ApprovedBy = &approvedBy
	tr.Approval.ApprovedByName = approvedByName
	tr.Approval.ApprovedAt = &now
	tr.UpdatedAt = now

	return nil
}

// Reject rejects the registration
func (tr *TournamentRegistration) Reject(rejectedBy primitive.ObjectID, rejectedByName, reason string) error {
	if !tr.Approval.IsRequired {
		return ErrRegistrationNoApprovalRequired
	}
	if tr.Status != RegistrationStatusPending {
		return ErrRegistrationInvalidStatus
	}

	now := time.Now()
	tr.Status = RegistrationStatusRejected
	tr.Approval.Status = RegistrationStatusRejected
	tr.Approval.RejectedBy = &rejectedBy
	tr.Approval.RejectedByName = rejectedByName
	tr.Approval.RejectionReason = reason
	tr.Approval.RejectedAt = &now
	tr.UpdatedAt = now

	return nil
}

// AddSelectedCompetition adds a competition to individual registration
func (tr *TournamentRegistration) AddSelectedCompetition(competitionID primitive.ObjectID) error {
	if !tr.IsIndividualRegistration() {
		return ErrRegistrationNotIndividual
	}

	// Check if already selected
	for _, id := range tr.SelectedCompetitionIDs {
		if id == competitionID {
			return ErrRegistrationCompetitionAlreadySelected
		}
	}

	tr.SelectedCompetitionIDs = append(tr.SelectedCompetitionIDs, competitionID)
	tr.UpdatedAt = time.Now()

	return nil
}

// RemoveSelectedCompetition removes a competition from individual registration
func (tr *TournamentRegistration) RemoveSelectedCompetition(competitionID primitive.ObjectID) error {
	if !tr.IsIndividualRegistration() {
		return ErrRegistrationNotIndividual
	}

	found := false
	for i, id := range tr.SelectedCompetitionIDs {
		if id == competitionID {
			tr.SelectedCompetitionIDs = append(
				tr.SelectedCompetitionIDs[:i],
				tr.SelectedCompetitionIDs[i+1:]...,
			)
			found = true
			break
		}
	}

	if !found {
		return ErrRegistrationCompetitionNotFound
	}

	tr.UpdatedAt = time.Now()
	return nil
}

// MarkPaymentCompleted marks the payment as completed
func (tr *TournamentRegistration) MarkPaymentCompleted(transactionID, paymentMethod string) {
	now := time.Now()
	tr.Payment.Status = PaymentStatusCompleted
	tr.Payment.TransactionID = transactionID
	tr.Payment.PaymentMethod = paymentMethod
	tr.Payment.PaymentDate = &now
	tr.UpdatedAt = now
}

// MarkPaymentFailed marks the payment as failed
func (tr *TournamentRegistration) MarkPaymentFailed() {
	tr.Payment.Status = PaymentStatusFailed
	tr.UpdatedAt = time.Now()
}

// RefundPayment processes a refund
func (tr *TournamentRegistration) RefundPayment(amount float64, reason string) {
	now := time.Now()
	tr.Payment.Status = PaymentStatusRefunded
	tr.Payment.RefundAmount = &amount
	tr.Payment.RefundDate = &now
	tr.Payment.RefundReason = reason
	tr.UpdatedAt = now
}

// WaivePayment waives the payment requirement
func (tr *TournamentRegistration) WaivePayment() {
	tr.Payment.Status = PaymentStatusWaived
	tr.UpdatedAt = time.Now()
}

// Withdraw withdraws the athlete from the tournament
func (tr *TournamentRegistration) Withdraw(reason string) error {
	if !tr.IsActive() {
		return ErrRegistrationNotActive
	}

	now := time.Now()
	tr.Status = RegistrationStatusWithdrawn
	tr.WithdrawnAt = &now
	tr.WithdrawalReason = reason
	tr.UpdatedAt = now

	return nil
}

// Cancel cancels the registration
func (tr *TournamentRegistration) Cancel() error {
	if tr.IsActive() {
		return ErrRegistrationAlreadyActive
	}

	tr.Status = RegistrationStatusCancelled
	tr.UpdatedAt = time.Now()

	return nil
}

// RecordParticipation records participation in a competition
func (tr *TournamentRegistration) RecordParticipation() {
	now := time.Now()
	tr.CompetitionsCompleted++
	tr.LastParticipation = &now
	tr.UpdatedAt = now
}

// RecordMissedCompetition records a missed competition
func (tr *TournamentRegistration) RecordMissedCompetition() {
	tr.CompetitionsMissed++
	tr.UpdatedAt = time.Now()
}

// SetRaceNumber assigns a race number
func (tr *TournamentRegistration) SetRaceNumber(number int) {
	tr.RaceNumber = &number
	tr.UpdatedAt = time.Now()
}

// AddDocument adds a document URL
func (tr *TournamentRegistration) AddDocument(documentType, url string) {
	if tr.DocumentUrls == nil {
		tr.DocumentUrls = make(map[string]string)
	}
	tr.DocumentUrls[documentType] = url
	tr.UpdatedAt = time.Now()
}

// PrepareForUpdate updates the timestamp
func (tr *TournamentRegistration) PrepareForUpdate() {
	tr.UpdatedAt = time.Now()
}

// Validate performs basic validation
func (tr *TournamentRegistration) Validate() error {
	if tr.TournamentID.IsZero() {
		return ErrRegistrationInvalidInput
	}
	if tr.AthleteID.IsZero() {
		return ErrRegistrationInvalidInput
	}
	if tr.RegistrationType != RegistrationTypeFull && tr.RegistrationType != RegistrationTypeIndividual {
		return ErrRegistrationInvalidInput
	}
	if tr.IsIndividualRegistration() && len(tr.SelectedCompetitionIDs) == 0 {
		return ErrRegistrationNoCompetitionsSelected
	}

	return nil
}

// Domain errors for TournamentRegistration
var (
	ErrRegistrationInvalidInput               = newRegistrationDomainError("invalid registration input data")
	ErrRegistrationInvalidStatus              = newRegistrationDomainError("invalid registration status")
	ErrRegistrationNoApprovalRequired         = newRegistrationDomainError("registration does not require approval")
	ErrRegistrationNotIndividual              = newRegistrationDomainError("registration is not individual type")
	ErrRegistrationCompetitionAlreadySelected = newRegistrationDomainError("competition already selected")
	ErrRegistrationCompetitionNotFound        = newRegistrationDomainError("competition not found in selection")
	ErrRegistrationNotActive                  = newRegistrationDomainError("registration is not active")
	ErrRegistrationAlreadyActive              = newRegistrationDomainError("registration is already active")
	ErrRegistrationNoCompetitionsSelected     = newRegistrationDomainError("no competitions selected for individual registration")
)

type registrationDomainError struct {
	message string
}

func newRegistrationDomainError(message string) *registrationDomainError {
	return &registrationDomainError{message: message}
}

func (e *registrationDomainError) Error() string {
	return e.message
}
