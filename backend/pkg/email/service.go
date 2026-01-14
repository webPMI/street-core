package email

import (
	"backend/utils"
	"bytes"
	"fmt"
	"html/template"
	"net/smtp"

	"github.com/sendgrid/sendgrid-go"
	"github.com/sendgrid/sendgrid-go/helpers/mail"
)

// EmailService defines the interface for email operations
type EmailService interface {
	SendEmail(to, subject, htmlBody string) error
	SendEmailWithTemplate(to, subject, templateName string, data interface{}) error
}

// emailService implements EmailService
type emailService struct {
	config    *Config
	templates *template.Template
}

// NewEmailService creates a new email service
func NewEmailService(config *Config) (EmailService, error) {
	// Load templates
	templates, err := loadTemplates()
	if err != nil {
		return nil, fmt.Errorf("failed to load email templates: %w", err)
	}

	return &emailService{
		config:    config,
		templates: templates,
	}, nil
}

// SendEmail sends a raw HTML email
func (s *emailService) SendEmail(to, subject, htmlBody string) error {
	if s.config.Provider == "sendgrid" {
		return s.sendWithSendGrid(to, subject, htmlBody)
	}
	return s.sendWithSMTP(to, subject, htmlBody)
}

// SendEmailWithTemplate sends an email using a predefined template
func (s *emailService) SendEmailWithTemplate(to, subject, templateName string, data interface{}) error {
	var body bytes.Buffer
	if err := s.templates.ExecuteTemplate(&body, templateName, data); err != nil {
		return fmt.Errorf("error executing template %s: %w", templateName, err)
	}

	return s.SendEmail(to, subject, body.String())
}

// sendWithSMTP sends email via SMTP
func (s *emailService) sendWithSMTP(to, subject, htmlBody string) error {
	// Validate configuration
	if s.config.SMTPUser == "" || s.config.SMTPPassword == "" {
		// If SMTP is not configured, just log and return (don't fail the operation)
		utils.WarnWithTag("Email", "SMTP not configured, skipping email", map[string]interface{}{
			"to": to,
		})
		return nil
	}

	// Set up authentication
	auth := smtp.PlainAuth("", s.config.SMTPUser, s.config.SMTPPassword, s.config.SMTPHost)

	// Build message
	from := fmt.Sprintf("%s <%s>", s.config.FromName, s.config.FromEmail)
	msg := []byte(fmt.Sprintf(
		"From: %s\r\n"+
			"To: %s\r\n"+
			"Subject: %s\r\n"+
			"MIME-Version: 1.0\r\n"+
			"Content-Type: text/html; charset=UTF-8\r\n"+
			"\r\n"+
			"%s",
		from, to, subject, htmlBody,
	))

	// Send email
	addr := fmt.Sprintf("%s:%d", s.config.SMTPHost, s.config.SMTPPort)
	err := smtp.SendMail(addr, auth, s.config.FromEmail, []string{to}, msg)
	if err != nil {
		return fmt.Errorf("failed to send email via SMTP: %w", err)
	}

	utils.InfoWithTag("Email", "Email sent via SMTP", map[string]interface{}{
		"to": to,
	})
	return nil
}

// sendWithSendGrid sends email via SendGrid API
func (s *emailService) sendWithSendGrid(to, subject, htmlBody string) error {
	// Validate API key
	if s.config.SendGridKey == "" {
		utils.WarnWithTag("Email", "SendGrid not configured, falling back to SMTP", nil)
		return s.sendWithSMTP(to, subject, htmlBody)
	}

	// Create email message
	from := mail.NewEmail(s.config.FromName, s.config.FromEmail)
	toEmail := mail.NewEmail("", to)
	message := mail.NewSingleEmail(from, subject, toEmail, "", htmlBody)

	// Create SendGrid client and send
	client := sendgrid.NewSendClient(s.config.SendGridKey)
	response, err := client.Send(message)
	if err != nil {
		return fmt.Errorf("failed to send email via SendGrid: %w", err)
	}

	// Check response status (2xx is success)
	if response.StatusCode >= 300 {
		return fmt.Errorf("SendGrid returned error status %d: %s", response.StatusCode, response.Body)
	}

	utils.InfoWithTag("Email", "Email sent via SendGrid", map[string]interface{}{
		"to":     to,
		"status": response.StatusCode,
	})
	return nil
}

// MockEmailService is a mock implementation for testing
type MockEmailService struct {
	SentEmails []struct {
		To       string
		Subject  string
		Template string
		Data     interface{}
	}
}

// NewMockEmailService creates a mock email service for testing
func NewMockEmailService() *MockEmailService {
	return &MockEmailService{
		SentEmails: make([]struct {
			To       string
			Subject  string
			Template string
			Data     interface{}
		}, 0),
	}
}

// SendEmail implements EmailService for mock
func (m *MockEmailService) SendEmail(to, subject, htmlBody string) error {
	utils.DebugWithTag("Email", "Mock email sent", map[string]interface{}{
		"to":      to,
		"subject": subject,
	})
	return nil
}

// SendEmailWithTemplate implements EmailService for mock
func (m *MockEmailService) SendEmailWithTemplate(to, subject, templateName string, data interface{}) error {
	m.SentEmails = append(m.SentEmails, struct {
		To       string
		Subject  string
		Template string
		Data     interface{}
	}{
		To:       to,
		Subject:  subject,
		Template: templateName,
		Data:     data,
	})
	utils.DebugWithTag("Email", "Mock template email sent", map[string]interface{}{
		"template": templateName,
		"to":       to,
		"subject":  subject,
	})
	return nil
}
