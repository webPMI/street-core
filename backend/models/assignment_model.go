package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Assignment represents a homework/project for students
type Assignment struct {
	ID       primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	LessonID primitive.ObjectID `json:"lessonId" bson:"lessonId" validate:"required"`

	Title        string `json:"title" bson:"title" validate:"required,min=3,max=255"`
	Description  string `json:"description" bson:"description" validate:"required,min=10,max=5000"`
	Instructions string `json:"instructions" bson:"instructions" validate:"required"`

	// Grading
	MaxScore     int `json:"maxScore" bson:"maxScore" validate:"required,gte=0"`
	PassingScore int `json:"passingScore" bson:"passingScore" validate:"gte=0"`

	// Submission
	AllowedFileTypes []string `json:"allowedFileTypes,omitempty" bson:"allowedFileTypes,omitempty"` // pdf, doc, zip, etc.
	MaxFileSize      int64    `json:"maxFileSize" bson:"maxFileSize"`                                // Bytes
	MaxSubmissions   int      `json:"maxSubmissions" bson:"maxSubmissions"`                          // 0 = unlimited

	// Deadlines
	DueDate     *time.Time `json:"dueDate,omitempty" bson:"dueDate,omitempty"`
	LatePenalty int        `json:"latePenalty" bson:"latePenalty"` // Percentage per day

	// Settings
	RequiresGrading bool `json:"requiresGrading" bson:"requiresGrading"`
	AutoGrade       bool `json:"autoGrade" bson:"autoGrade"`

	CreatedAt time.Time `json:"createdAt" bson:"createdAt"`
	UpdatedAt time.Time `json:"updatedAt" bson:"updatedAt"`
}

// PrepareForInsert initializes default values before inserting
func (a *Assignment) PrepareForInsert() {
	a.ID = primitive.NewObjectID()
	now := time.Now()
	a.CreatedAt = now
	a.UpdatedAt = now

	// Default settings
	a.RequiresGrading = true
	a.AutoGrade = false
	a.LatePenalty = 0
	a.MaxSubmissions = 0 // Unlimited by default

	// Initialize arrays if nil
	if a.AllowedFileTypes == nil {
		a.AllowedFileTypes = []string{}
	}
}

// PrepareForUpdate updates the timestamp
func (a *Assignment) PrepareForUpdate() {
	a.UpdatedAt = time.Now()
}

// CreateAssignmentRequest represents the request to create an assignment
type CreateAssignmentRequest struct {
	Title            string     `json:"title" binding:"required,min=3,max=255"`
	Description      string     `json:"description" binding:"required,min=10,max=5000"`
	Instructions     string     `json:"instructions" binding:"required"`
	MaxScore         int        `json:"maxScore" binding:"required,gte=0"`
	PassingScore     int        `json:"passingScore" binding:"gte=0"`
	AllowedFileTypes []string   `json:"allowedFileTypes,omitempty"`
	MaxFileSize      int64      `json:"maxFileSize" binding:"gte=0"`
	MaxSubmissions   int        `json:"maxSubmissions" binding:"gte=0"`
	DueDate          *time.Time `json:"dueDate,omitempty"`
	LatePenalty      int        `json:"latePenalty" binding:"gte=0,lte=100"`
	RequiresGrading  bool       `json:"requiresGrading"`
	AutoGrade        bool       `json:"autoGrade"`
}

// UpdateAssignmentRequest represents the request to update an assignment
type UpdateAssignmentRequest struct {
	Title            *string    `json:"title,omitempty" binding:"omitempty,min=3,max=255"`
	Description      *string    `json:"description,omitempty" binding:"omitempty,min=10,max=5000"`
	Instructions     *string    `json:"instructions,omitempty"`
	MaxScore         *int       `json:"maxScore,omitempty" binding:"omitempty,gte=0"`
	PassingScore     *int       `json:"passingScore,omitempty" binding:"omitempty,gte=0"`
	AllowedFileTypes *[]string  `json:"allowedFileTypes,omitempty"`
	MaxFileSize      *int64     `json:"maxFileSize,omitempty" binding:"omitempty,gte=0"`
	MaxSubmissions   *int       `json:"maxSubmissions,omitempty" binding:"omitempty,gte=0"`
	DueDate          *time.Time `json:"dueDate,omitempty"`
	LatePenalty      *int       `json:"latePenalty,omitempty" binding:"omitempty,gte=0,lte=100"`
	RequiresGrading  *bool      `json:"requiresGrading,omitempty"`
	AutoGrade        *bool      `json:"autoGrade,omitempty"`
}

// Submission status constants
const (
	SubmissionStatusPending   = "pending"
	SubmissionStatusSubmitted = "submitted"
	SubmissionStatusGraded    = "graded"
	SubmissionStatusReturned  = "returned"
)

// AssignmentSubmission represents a student's submission for an assignment
type AssignmentSubmission struct {
	ID           primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	AssignmentID primitive.ObjectID `json:"assignmentId" bson:"assignmentId" validate:"required"`
	StudentID    primitive.ObjectID `json:"studentId" bson:"studentId" validate:"required"`

	// Submission details
	SubmissionText string   `json:"submissionText,omitempty" bson:"submissionText,omitempty"`
	FileUrls       []string `json:"fileUrls,omitempty" bson:"fileUrls,omitempty"`

	// Grading
	Score    *float64 `json:"score,omitempty" bson:"score,omitempty"`       // 0-100
	Feedback string   `json:"feedback,omitempty" bson:"feedback,omitempty"`
	GradedBy *primitive.ObjectID `json:"gradedBy,omitempty" bson:"gradedBy,omitempty"` // Instructor ID

	// Status
	Status string `json:"status" bson:"status" validate:"required,oneof=pending submitted graded returned"`

	// Timestamps
	SubmittedAt time.Time  `json:"submittedAt" bson:"submittedAt"`
	GradedAt    *time.Time `json:"gradedAt,omitempty" bson:"gradedAt,omitempty"`
	IsLate      bool       `json:"isLate" bson:"isLate"`
}

// PrepareForInsert initializes default values before inserting
func (as *AssignmentSubmission) PrepareForInsert() {
	as.ID = primitive.NewObjectID()
	as.SubmittedAt = time.Now()
	as.Status = SubmissionStatusSubmitted

	// Initialize arrays if nil
	if as.FileUrls == nil {
		as.FileUrls = []string{}
	}
}

// PrepareForGrading updates grading information
func (as *AssignmentSubmission) PrepareForGrading() {
	as.Status = SubmissionStatusGraded
	now := time.Now()
	as.GradedAt = &now
}

// SubmitAssignmentRequest represents the request to submit an assignment
type SubmitAssignmentRequest struct {
	SubmissionText string   `json:"submissionText,omitempty"`
	FileUrls       []string `json:"fileUrls,omitempty"`
}

// GradeSubmissionRequest represents the request to grade a submission
type GradeSubmissionRequest struct {
	Score    float64 `json:"score" binding:"required,gte=0,lte=100"`
	Feedback string  `json:"feedback,omitempty"`
}
