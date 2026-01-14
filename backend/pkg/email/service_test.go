package email

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestNewEmailService(t *testing.T) {
	config := &Config{
		SMTPHost:  "smtp.test.com",
		SMTPPort:  587,
		FromEmail: "test@test.com",
		FromName:  "Test",
	}

	service, err := NewEmailService(config)
	require.NoError(t, err)
	assert.NotNil(t, service)
}

func TestNewEmailService_TemplateLoading(t *testing.T) {
	config := &Config{
		SMTPHost:  "smtp.test.com",
		SMTPPort:  587,
		FromEmail: "test@test.com",
	}

	service, err := NewEmailService(config)
	require.NoError(t, err)

	// Verify templates are loaded
	emailSvc := service.(*emailService)
	assert.NotNil(t, emailSvc.templates)

	// Verify all templates exist
	templateNames := []string{
		TemplateJudgeInvitation,
		TemplateJudgeAccepted,
		TemplateJudgeRejected,
		TemplateJudgeUnassigned,
		TemplateJudgeReminder,
	}

	for _, name := range templateNames {
		tmpl := emailSvc.templates.Lookup(name)
		assert.NotNil(t, tmpl, "Template %s should exist", name)
	}
}

func TestSendEmailWithTemplate_JudgeInvitation(t *testing.T) {
	config := &Config{
		SMTPHost:  "smtp.test.com",
		SMTPPort:  587,
		FromEmail: "test@test.com",
		SMTPUser:  "", // Empty to skip actual sending
	}

	service, err := NewEmailService(config)
	require.NoError(t, err)

	data := map[string]interface{}{
		"JudgeName":           "John Doe",
		"CompetitionName":     "Test Competition",
		"CompetitionDate":     "25/12/2025",
		"CompetitionLocation": "Test Location",
		"JudgeRole":           "Juez Principal",
		"Message":             "¡Esperamos contar contigo!",
		"AcceptURL":           "http://localhost:3000/accept/123",
		"RejectURL":           "http://localhost:3000/reject/123",
		"ExpiresIn":           7,
	}

	// This should not fail even without SMTP configured
	err = service.SendEmailWithTemplate(
		"judge@test.com",
		"Invitación para ser Juez",
		TemplateJudgeInvitation,
		data,
	)
	assert.NoError(t, err)
}

func TestSendEmailWithTemplate_JudgeAccepted(t *testing.T) {
	config := &Config{
		SMTPHost:  "smtp.test.com",
		SMTPPort:  587,
		FromEmail: "test@test.com",
		SMTPUser:  "", // Empty to skip actual sending
	}

	service, err := NewEmailService(config)
	require.NoError(t, err)

	data := map[string]interface{}{
		"OrganizerName":   "Jane Smith",
		"JudgeName":       "John Doe",
		"CompetitionName": "Test Competition",
		"Response":        "¡Encantado de participar!",
	}

	err = service.SendEmailWithTemplate(
		"organizer@test.com",
		"Invitación Aceptada",
		TemplateJudgeAccepted,
		data,
	)
	assert.NoError(t, err)
}

func TestSendEmailWithTemplate_JudgeRejected(t *testing.T) {
	config := &Config{
		SMTPHost:  "smtp.test.com",
		SMTPPort:  587,
		FromEmail: "test@test.com",
		SMTPUser:  "", // Empty to skip actual sending
	}

	service, err := NewEmailService(config)
	require.NoError(t, err)

	data := map[string]interface{}{
		"OrganizerName":   "Jane Smith",
		"JudgeName":       "John Doe",
		"CompetitionName": "Test Competition",
		"Response":        "No estaré disponible en esas fechas.",
	}

	err = service.SendEmailWithTemplate(
		"organizer@test.com",
		"Invitación Rechazada",
		TemplateJudgeRejected,
		data,
	)
	assert.NoError(t, err)
}

func TestSendEmailWithTemplate_JudgeUnassigned(t *testing.T) {
	config := &Config{
		SMTPHost:  "smtp.test.com",
		SMTPPort:  587,
		FromEmail: "test@test.com",
		SMTPUser:  "", // Empty to skip actual sending
	}

	service, err := NewEmailService(config)
	require.NoError(t, err)

	data := map[string]interface{}{
		"JudgeName":       "John Doe",
		"CompetitionName": "Test Competition",
		"Reason":          "Cambios en la organización",
	}

	err = service.SendEmailWithTemplate(
		"judge@test.com",
		"Has sido desasignado",
		TemplateJudgeUnassigned,
		data,
	)
	assert.NoError(t, err)
}

func TestSendEmailWithTemplate_JudgeReminder(t *testing.T) {
	config := &Config{
		SMTPHost:  "smtp.test.com",
		SMTPPort:  587,
		FromEmail: "test@test.com",
		SMTPUser:  "", // Empty to skip actual sending
	}

	service, err := NewEmailService(config)
	require.NoError(t, err)

	data := map[string]interface{}{
		"JudgeName":           "John Doe",
		"CompetitionName":     "Test Competition",
		"CompetitionDate":     "25/12/2025",
		"CompetitionLocation": "Test Location",
		"JudgeRole":           "Juez Principal",
		"AdditionalInfo":      "Recuerda traer tu identificación oficial.",
	}

	err = service.SendEmailWithTemplate(
		"judge@test.com",
		"Recordatorio de Competición",
		TemplateJudgeReminder,
		data,
	)
	assert.NoError(t, err)
}

func TestSendEmailWithTemplate_InvalidTemplate(t *testing.T) {
	config := &Config{
		SMTPHost:  "smtp.test.com",
		SMTPPort:  587,
		FromEmail: "test@test.com",
	}

	service, err := NewEmailService(config)
	require.NoError(t, err)

	err = service.SendEmailWithTemplate(
		"test@test.com",
		"Test",
		"invalid_template",
		map[string]string{},
	)
	assert.Error(t, err)
	assert.Contains(t, err.Error(), "error executing template")
}

func TestMockEmailService(t *testing.T) {
	mock := NewMockEmailService()
	assert.NotNil(t, mock)
	assert.Empty(t, mock.SentEmails)

	// Test SendEmail
	err := mock.SendEmail("test@test.com", "Test Subject", "<p>Test</p>")
	assert.NoError(t, err)

	// Test SendEmailWithTemplate
	data := map[string]string{
		"Name": "Test",
	}
	err = mock.SendEmailWithTemplate(
		"test@test.com",
		"Test Template",
		"some_template",
		data,
	)
	assert.NoError(t, err)
	assert.Len(t, mock.SentEmails, 1)
	assert.Equal(t, "test@test.com", mock.SentEmails[0].To)
	assert.Equal(t, "Test Template", mock.SentEmails[0].Subject)
}

func TestNewConfigFromEnv(t *testing.T) {
	// This test verifies that config can be created with defaults
	config := NewConfigFromEnv()
	assert.NotNil(t, config)
	assert.NotEmpty(t, config.SMTPHost)
	assert.NotZero(t, config.SMTPPort)
	assert.NotEmpty(t, config.FromEmail)
	assert.NotEmpty(t, config.FromName)
	assert.NotEmpty(t, config.Provider)
}

func TestGetEnv(t *testing.T) {
	// Test default value
	value := getEnv("NONEXISTENT_VAR_12345", "default")
	assert.Equal(t, "default", value)
}

func TestGetEnvInt(t *testing.T) {
	// Test default value
	value := getEnvInt("NONEXISTENT_VAR_12345", 123)
	assert.Equal(t, 123, value)
}

// ============================================================================
// SendGrid Tests
// ============================================================================

func TestSendGrid_FallbackToSMTP_WhenNoAPIKey(t *testing.T) {
	// When SendGrid is configured but no API key, should fallback to SMTP
	config := &Config{
		Provider:    "sendgrid",
		SendGridKey: "", // No API key
		SMTPHost:    "smtp.test.com",
		SMTPPort:    587,
		FromEmail:   "test@test.com",
		FromName:    "Test",
		SMTPUser:    "", // Empty to skip actual SMTP sending
	}

	service, err := NewEmailService(config)
	require.NoError(t, err)

	// Should not error - will fallback to SMTP which skips when not configured
	err = service.SendEmail("recipient@test.com", "Test Subject", "<p>Test body</p>")
	assert.NoError(t, err)
}

func TestSendGrid_ProviderSelection(t *testing.T) {
	tests := []struct {
		name     string
		provider string
	}{
		{"SMTP provider", "smtp"},
		{"SendGrid provider", "sendgrid"},
		{"Empty provider defaults to SMTP", ""},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			config := &Config{
				Provider:  tt.provider,
				SMTPHost:  "smtp.test.com",
				SMTPPort:  587,
				FromEmail: "test@test.com",
				FromName:  "Test",
				SMTPUser:  "", // Empty to skip actual sending
			}

			service, err := NewEmailService(config)
			require.NoError(t, err)

			// Should not error regardless of provider
			err = service.SendEmail("recipient@test.com", "Test", "<p>Test</p>")
			assert.NoError(t, err)
		})
	}
}

func TestSendGrid_ConfigHasSendGridKey(t *testing.T) {
	config := NewConfigFromEnv()
	// Verify SendGridKey field exists in config
	assert.NotNil(t, config)
	// The field should exist (empty by default without env var)
	assert.Empty(t, config.SendGridKey, "SendGridKey should be empty by default")
}
