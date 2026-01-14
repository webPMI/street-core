package email

import (
	"html/template"
)

// Template names constants
const (
	TemplateJudgeInvitation   = "judge_invitation"
	TemplateJudgeAccepted     = "judge_accepted"
	TemplateJudgeRejected     = "judge_rejected"
	TemplateJudgeUnassigned   = "judge_unassigned"
	TemplateJudgeReminder     = "judge_reminder"
	TemplateCompetitionUpdate = "competition_update"
)

// loadTemplates loads all email templates
func loadTemplates() (*template.Template, error) {
	tmpl := template.New("")

	// Template: Judge Invitation
	_, err := tmpl.New(TemplateJudgeInvitation).Parse(`
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"></head>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
    <div style="max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;">
        <div style="text-align: center; margin-bottom: 20px;">
            <h1 style="color: #2c3e50; margin: 0;">FitRiders</h1>
        </div>
        <h2 style="color: #2c3e50;">Invitación para ser Juez</h2>
        <p>Hola <strong>{{.JudgeName}}</strong>,</p>
        <p>Has sido invitado para ser juez en la competición <strong>{{.CompetitionName}}</strong>.</p>
        <p><strong>Detalles de la competición:</strong></p>
        <ul style="background-color: #f9f9f9; padding: 15px; border-radius: 5px;">
            <li><strong>Fecha:</strong> {{.CompetitionDate}}</li>
            <li><strong>Ubicación:</strong> {{.CompetitionLocation}}</li>
            <li><strong>Rol:</strong> {{.JudgeRole}}</li>
        </ul>
        {{if .Message}}
        <p><strong>Mensaje del organizador:</strong></p>
        <p style="background-color: #f0f0f0; padding: 10px; border-radius: 5px; font-style: italic;">{{.Message}}</p>
        {{end}}
        <p>Por favor, confirma tu participación haciendo clic en uno de los siguientes enlaces:</p>
        <div style="margin: 30px 0; text-align: center;">
            <a href="{{.AcceptURL}}" style="background-color: #27ae60; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block; margin-right: 10px; font-weight: bold;">Aceptar Invitación</a>
            <a href="{{.RejectURL}}" style="background-color: #e74c3c; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block; font-weight: bold;">Rechazar</a>
        </div>
        <p style="color: #7f8c8d; font-size: 14px;">Esta invitación expira en {{.ExpiresIn}} días.</p>
        <hr style="border: none; border-top: 1px solid #e0e0e0; margin: 20px 0;">
        <p style="color: #7f8c8d; font-size: 12px; text-align: center;">
            Gracias por ser parte de FitRiders<br>
            Este es un correo automático, por favor no responder.
        </p>
    </div>
</body>
</html>
    `)
	if err != nil {
		return nil, err
	}

	// Template: Judge Accepted
	_, err = tmpl.New(TemplateJudgeAccepted).Parse(`
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"></head>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
    <div style="max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;">
        <div style="text-align: center; margin-bottom: 20px;">
            <h1 style="color: #2c3e50; margin: 0;">FitRiders</h1>
        </div>
        <h2 style="color: #27ae60;">Invitación Aceptada</h2>
        <p>Hola <strong>{{.OrganizerName}}</strong>,</p>
        <p>¡Buenas noticias! <strong>{{.JudgeName}}</strong> ha aceptado tu invitación para ser juez en la competición <strong>{{.CompetitionName}}</strong>.</p>
        {{if .Response}}
        <p><strong>Mensaje del juez:</strong></p>
        <p style="background-color: #f0f0f0; padding: 10px; border-radius: 5px; font-style: italic;">{{.Response}}</p>
        {{end}}
        <p style="background-color: #d4edda; padding: 15px; border-radius: 5px; border-left: 4px solid #27ae60;">
            <strong>Estado:</strong> El juez ha sido añadido exitosamente a tu competición.
        </p>
        <hr style="border: none; border-top: 1px solid #e0e0e0; margin: 20px 0;">
        <p style="color: #7f8c8d; font-size: 12px; text-align: center;">
            Gracias por usar FitRiders<br>
            Este es un correo automático, por favor no responder.
        </p>
    </div>
</body>
</html>
    `)
	if err != nil {
		return nil, err
	}

	// Template: Judge Rejected
	_, err = tmpl.New(TemplateJudgeRejected).Parse(`
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"></head>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
    <div style="max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;">
        <div style="text-align: center; margin-bottom: 20px;">
            <h1 style="color: #2c3e50; margin: 0;">FitRiders</h1>
        </div>
        <h2 style="color: #e74c3c;">Invitación Rechazada</h2>
        <p>Hola <strong>{{.OrganizerName}}</strong>,</p>
        <p><strong>{{.JudgeName}}</strong> ha rechazado la invitación para ser juez en la competición <strong>{{.CompetitionName}}</strong>.</p>
        {{if .Response}}
        <p><strong>Motivo:</strong></p>
        <p style="background-color: #f0f0f0; padding: 10px; border-radius: 5px; font-style: italic;">{{.Response}}</p>
        {{end}}
        <p style="background-color: #f8d7da; padding: 15px; border-radius: 5px; border-left: 4px solid #e74c3c;">
            <strong>Acción recomendada:</strong> Considera invitar a otro juez para cubrir esta posición.
        </p>
        <hr style="border: none; border-top: 1px solid #e0e0e0; margin: 20px 0;">
        <p style="color: #7f8c8d; font-size: 12px; text-align: center;">
            Gracias por usar FitRiders<br>
            Este es un correo automático, por favor no responder.
        </p>
    </div>
</body>
</html>
    `)
	if err != nil {
		return nil, err
	}

	// Template: Judge Unassigned
	_, err = tmpl.New(TemplateJudgeUnassigned).Parse(`
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"></head>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
    <div style="max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;">
        <div style="text-align: center; margin-bottom: 20px;">
            <h1 style="color: #2c3e50; margin: 0;">FitRiders</h1>
        </div>
        <h2 style="color: #f39c12;">Has sido desasignado como juez</h2>
        <p>Hola <strong>{{.JudgeName}}</strong>,</p>
        <p>Has sido desasignado como juez de la competición <strong>{{.CompetitionName}}</strong>.</p>
        {{if .Reason}}
        <p><strong>Motivo:</strong></p>
        <p style="background-color: #f0f0f0; padding: 10px; border-radius: 5px;">{{.Reason}}</p>
        {{end}}
        <p style="background-color: #fff3cd; padding: 15px; border-radius: 5px; border-left: 4px solid #f39c12;">
            Si tienes alguna pregunta sobre esta decisión, por favor contacta al organizador de la competición.
        </p>
        <hr style="border: none; border-top: 1px solid #e0e0e0; margin: 20px 0;">
        <p style="color: #7f8c8d; font-size: 12px; text-align: center;">
            Gracias por tu tiempo en FitRiders<br>
            Este es un correo automático, por favor no responder.
        </p>
    </div>
</body>
</html>
    `)
	if err != nil {
		return nil, err
	}

	// Template: Judge Reminder
	_, err = tmpl.New(TemplateJudgeReminder).Parse(`
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"></head>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
    <div style="max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;">
        <div style="text-align: center; margin-bottom: 20px;">
            <h1 style="color: #2c3e50; margin: 0;">FitRiders</h1>
        </div>
        <h2 style="color: #f39c12;">Recordatorio - Competición Próxima</h2>
        <p>Hola <strong>{{.JudgeName}}</strong>,</p>
        <p>Te recordamos que la competición <strong>{{.CompetitionName}}</strong> se llevará a cabo pronto.</p>
        <p><strong>Detalles importantes:</strong></p>
        <ul style="background-color: #fff3cd; padding: 15px; border-radius: 5px; border-left: 4px solid #f39c12;">
            <li><strong>Fecha:</strong> {{.CompetitionDate}}</li>
            <li><strong>Ubicación:</strong> {{.CompetitionLocation}}</li>
            <li><strong>Tu rol:</strong> {{.JudgeRole}}</li>
        </ul>
        {{if .AdditionalInfo}}
        <p><strong>Información adicional:</strong></p>
        <p style="background-color: #f0f0f0; padding: 10px; border-radius: 5px;">{{.AdditionalInfo}}</p>
        {{end}}
        <p style="background-color: #d1ecf1; padding: 15px; border-radius: 5px; border-left: 4px solid #17a2b8;">
            <strong>Nota:</strong> Por favor, asegúrate de llegar con al menos 30 minutos de anticipación.
        </p>
        <hr style="border: none; border-top: 1px solid #e0e0e0; margin: 20px 0;">
        <p style="color: #7f8c8d; font-size: 12px; text-align: center;">
            ¡Te esperamos!<br>
            Equipo FitRiders<br>
            Este es un correo automático, por favor no responder.
        </p>
    </div>
</body>
</html>
    `)
	if err != nil {
		return nil, err
	}

	return tmpl, nil
}
