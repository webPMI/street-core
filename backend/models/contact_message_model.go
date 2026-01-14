package models

import (
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// ContactMessageStatus represents the status of a contact message
type ContactMessageStatus string

const (
	ContactStatusNew      ContactMessageStatus = "new"      // Not yet reviewed
	ContactStatusRead     ContactMessageStatus = "read"     // Admin has viewed it
	ContactStatusReplied  ContactMessageStatus = "replied"  // Response sent
	ContactStatusArchived ContactMessageStatus = "archived" // Archived by admin
)

// ContactMessageCategory represents the category of a contact message
type ContactMessageCategory string

const (
	ContactCategoryGeneral  ContactMessageCategory = "general"
	ContactCategorySupport  ContactMessageCategory = "support"
	ContactCategorySales    ContactMessageCategory = "sales"
	ContactCategoryFeedback ContactMessageCategory = "feedback"
	ContactCategoryOther    ContactMessageCategory = "other"
)

// ContactMessage represents a contact form submission from public users
type ContactMessage struct {
	ID primitive.ObjectID `bson:"_id,omitempty" json:"id"`

	// Sender information
	Name  string `bson:"name" json:"name" binding:"required,min=2,max=100"`
	Email string `bson:"email" json:"email" binding:"required,email,max=100"`
	Phone string `bson:"phone,omitempty" json:"phone,omitempty"`

	// Message content
	Subject  string                 `bson:"subject" json:"subject" binding:"required,min=5,max=200"`
	Message  string                 `bson:"message" json:"message" binding:"required,min=10,max=5000"`
	Category ContactMessageCategory `bson:"category" json:"category"`

	// Status and tracking
	Status ContactMessageStatus `bson:"status" json:"status"`
	IsRead bool                 `bson:"isRead" json:"isRead"`

	// Admin response
	ReplyMessage string              `bson:"replyMessage,omitempty" json:"replyMessage,omitempty"`
	RepliedBy    *primitive.ObjectID `bson:"repliedBy,omitempty" json:"repliedBy,omitempty"`
	RepliedAt    *time.Time          `bson:"repliedAt,omitempty" json:"repliedAt,omitempty"`

	// Admin notes (internal)
	AdminNotes string              `bson:"adminNotes,omitempty" json:"adminNotes,omitempty"`
	AssignedTo *primitive.ObjectID `bson:"assignedTo,omitempty" json:"assignedTo,omitempty"`

	// Security
	IPAddress string `bson:"ipAddress,omitempty" json:"ipAddress,omitempty"`
	UserAgent string `bson:"userAgent,omitempty" json:"userAgent,omitempty"`

	// Timestamps
	CreatedAt time.Time  `bson:"createdAt" json:"createdAt"`
	UpdatedAt time.Time  `bson:"updatedAt" json:"updatedAt"`
	ReadAt    *time.Time `bson:"readAt,omitempty" json:"readAt,omitempty"`
}

// ContactMessageStats represents statistics for contact messages
type ContactMessageStats struct {
	TotalCount   int64 `json:"totalCount"`
	UnreadCount  int64 `json:"unreadCount"`
	NewCount     int64 `json:"newCount"`
	RepliedCount int64 `json:"repliedCount"`
}

// Validate validates contact message fields
func (cm *ContactMessage) Validate() error {
	if cm.Name == "" {
		return fmt.Errorf("name is required")
	}
	if len(cm.Name) < 2 || len(cm.Name) > 100 {
		return fmt.Errorf("name must be between 2 and 100 characters")
	}
	if cm.Email == "" {
		return fmt.Errorf("email is required")
	}
	if cm.Subject == "" {
		return fmt.Errorf("subject is required")
	}
	if len(cm.Subject) < 5 || len(cm.Subject) > 200 {
		return fmt.Errorf("subject must be between 5 and 200 characters")
	}
	if cm.Message == "" {
		return fmt.Errorf("message is required")
	}
	if len(cm.Message) < 10 || len(cm.Message) > 5000 {
		return fmt.Errorf("message must be between 10 and 5000 characters")
	}
	return nil
}

// SetDefaults sets default values for a new contact message
func (cm *ContactMessage) SetDefaults() {
	if cm.ID.IsZero() {
		cm.ID = primitive.NewObjectID()
	}
	now := time.Now()
	cm.CreatedAt = now
	cm.UpdatedAt = now
	cm.Status = ContactStatusNew
	cm.IsRead = false

	// Default category if not set
	if cm.Category == "" {
		cm.Category = ContactCategoryGeneral
	}
}

// MarkAsRead marks the message as read
func (cm *ContactMessage) MarkAsRead() {
	now := time.Now()
	cm.IsRead = true
	cm.ReadAt = &now
	cm.UpdatedAt = now
	if cm.Status == ContactStatusNew {
		cm.Status = ContactStatusRead
	}
}

// SetReply sets the admin reply for the message
func (cm *ContactMessage) SetReply(adminID primitive.ObjectID, replyMessage string) {
	now := time.Now()
	cm.ReplyMessage = replyMessage
	cm.RepliedBy = &adminID
	cm.RepliedAt = &now
	cm.Status = ContactStatusReplied
	cm.UpdatedAt = now
}

// ValidCategories returns the list of valid contact message categories
func ValidCategories() []string {
	return []string{
		string(ContactCategoryGeneral),
		string(ContactCategorySupport),
		string(ContactCategorySales),
		string(ContactCategoryFeedback),
		string(ContactCategoryOther),
	}
}

// ValidStatuses returns the list of valid contact message statuses
func ValidStatuses() []string {
	return []string{
		string(ContactStatusNew),
		string(ContactStatusRead),
		string(ContactStatusReplied),
		string(ContactStatusArchived),
	}
}

// IsValidCategory checks if a category is valid
func IsValidCategory(category string) bool {
	for _, c := range ValidCategories() {
		if c == category {
			return true
		}
	}
	return false
}

// IsValidStatus checks if a status is valid
func IsValidStatus(status string) bool {
	for _, s := range ValidStatuses() {
		if s == status {
			return true
		}
	}
	return false
}
