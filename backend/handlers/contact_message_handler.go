package handlers

import (
	"backend/models"
	"backend/pkg/errors"
	"backend/pkg/response"
	"backend/services"

	"github.com/gin-gonic/gin"
)

// ContactMessageHandler handles contact message HTTP requests
type ContactMessageHandler struct {
	contactMessageService *services.ContactMessageService
}

// NewContactMessageHandler creates a new contact message handler
func NewContactMessageHandler(contactMessageService *services.ContactMessageService) *ContactMessageHandler {
	return &ContactMessageHandler{
		contactMessageService: contactMessageService,
	}
}

// SubmitContactForm handles public contact form submission
func (h *ContactMessageHandler) SubmitContactForm(c *gin.Context) {
	ctx := c.Request.Context()

	var message models.ContactMessage
	if err := c.ShouldBindJSON(&message); err != nil {
		response.HandleError(c, errors.ErrJSONParsingFailed(err))
		return
	}

	// Basic validation
	if message.Name == "" || message.Email == "" || message.Message == "" {
		response.HandleError(c, errors.ErrRequiredField("name, email, message"))
		return
	}

	// Store IP address for spam prevention
	message.IPAddress = c.ClientIP()

	if err := h.contactMessageService.SubmitMessage(ctx, &message); err != nil {
		response.HandleError(c, errors.ErrDatabaseError("submit contact", err))
		return
	}

	response.Created(c, models.MessageSent, gin.H{
		"message": "Thank you for your message. We will get back to you soon.",
	})
}

// GetMessages returns contact messages (admin only)
func (h *ContactMessageHandler) GetMessages(c *gin.Context) {
	ctx := c.Request.Context()

	page := int64(1)
	limit := int64(20)
	status := c.Query("status")

	messages, total, err := h.contactMessageService.GetMessages(ctx, page, limit, status)
	if err != nil {
		response.HandleError(c, errors.ErrDatabaseError("get messages", err))
		return
	}

	response.OK(c, models.MessagesRetrieved, gin.H{
		"messages": messages,
		"total":    total,
		"page":     page,
		"limit":    limit,
	})
}

// GetMessageByID returns a contact message by ID (admin only)
func (h *ContactMessageHandler) GetMessageByID(c *gin.Context) {
	ctx := c.Request.Context()
	id := c.Param("id")

	message, err := h.contactMessageService.GetMessageByID(ctx, id)
	if err != nil {
		response.HandleError(c, errors.ErrResourceNotFound("message"))
		return
	}

	response.OK(c, models.MessageRetrieved, gin.H{"message": message})
}

// UpdateMessageStatus updates the status of a contact message (admin only)
func (h *ContactMessageHandler) UpdateMessageStatus(c *gin.Context) {
	ctx := c.Request.Context()
	id := c.Param("id")

	var req struct {
		Status   string `json:"status" binding:"required,oneof=pending read responded archived"`
		Response string `json:"response,omitempty"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		response.HandleError(c, errors.ErrJSONParsingFailed(err))
		return
	}

	if err := h.contactMessageService.UpdateMessageStatus(ctx, id, req.Status, req.Response); err != nil {
		response.HandleError(c, errors.ErrDatabaseError("update message", err))
		return
	}

	response.OK(c, models.MessageUpdated, nil)
}

// DeleteMessage deletes a contact message (admin only)
func (h *ContactMessageHandler) DeleteMessage(c *gin.Context) {
	ctx := c.Request.Context()
	id := c.Param("id")

	if err := h.contactMessageService.DeleteMessage(ctx, id); err != nil {
		response.HandleError(c, errors.ErrDatabaseError("delete message", err))
		return
	}

	response.OK(c, models.MessageDeleted, nil)
}
