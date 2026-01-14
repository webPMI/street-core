package profile

import (
	"context"
	"fmt"
	"backend/pkg/repository"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

// PrivacySettings representa la configuración de privacidad de un usuario.
type PrivacySettings struct {
	ID                 primitive.ObjectID   `bson:"_id,omitempty" json:"id"`
	UserID             primitive.ObjectID   `bson:"userId" json:"userId"`
	IsPrivate          bool                 `bson:"isPrivate" json:"isPrivate"`                   // Si el perfil es privado
	AllowTagging       bool                 `bson:"allowTagging" json:"allowTagging"`             // Permitir que otros etiqueten al usuario
	AllowMentions      bool                 `bson:"allowMentions" json:"allowMentions"`           // Permitir que otros mencionen al usuario
	ShowActivityStatus bool                 `bson:"showActivityStatus" json:"showActivityStatus"` // Mostrar estado de actividad (online/última vez visto)
	BlockedUsers       []primitive.ObjectID `bson:"blockedUsers" json:"blockedUsers"`             // IDs de usuarios bloqueados
	MutedUsers         []primitive.ObjectID `bson:"mutedUsers" json:"mutedUsers"`                 // IDs de usuarios silenciados
	CloseFriends       []primitive.ObjectID `bson:"closeFriends" json:"closeFriends"`             // IDs de amigos cercanos
	StoryVisibility    string               `bson:"storyVisibility" json:"storyVisibility"`       // Visibilidad de las historias (e.g., "everyone", "closeFriends", "private")
	CreatedAt          time.Time            `bson:"createdAt" json:"createdAt"`
	UpdatedAt          time.Time            `bson:"updatedAt" json:"updatedAt"`
}

// SetDefaults establece los valores predeterminados para la configuración de privacidad.
func (ps *PrivacySettings) SetDefaults() {
	if ps.ID.IsZero() {
		ps.ID = primitive.NewObjectID()
	}
	if ps.CreatedAt.IsZero() {
		ps.CreatedAt = time.Now()
	}
	ps.UpdatedAt = time.Now()

	// Establecer valores predeterminados si no están ya establecidos
	if ps.StoryVisibility == "" {
		ps.StoryVisibility = "everyone"
	}
}

// UpdatePrivacySettingsRequest representa la solicitud para actualizar la configuración de privacidad.
type UpdatePrivacySettingsRequest struct {
	IsPrivate          *bool   `json:"isPrivate,omitempty"`
	AllowTagging       *bool   `json:"allowTagging,omitempty"`
	AllowMentions      *bool   `json:"allowMentons,omitempty"`
	ShowActivityStatus *bool   `json:"showActivityStatus,omitempty"`
	StoryVisibility    *string `json:"storyVisibility,omitempty"`
}

// BlockUserRequest representa la solicitud para bloquear a un usuario.
type BlockUserRequest struct {
	UserIDToBlock string `json:"userIdToBlock" binding:"required"`
}

// privacyService implementa IPrivacyService
type privacyService struct {
	repo repository.IRepository[PrivacySettings]
}

// NewPrivacyService crea una nueva instancia del servicio de privacidad
func NewPrivacyService(db *mongo.Database) IPrivacyService {
	collection := db.Collection("privacy_settings")
	return &privacyService{
		repo: repository.NewRepository[PrivacySettings](collection),
	}
}

// GetOrCreatePrivacySettings obtiene o crea la configuración de privacidad de un usuario
func (s *privacyService) GetOrCreatePrivacySettings(userID primitive.ObjectID) (*PrivacySettings, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Intentar encontrar existente
	query := repository.NewQuery().Where("userId", userID)
	settings, err := s.repo.FindOne(ctx, query)

	if err != nil && err != mongo.ErrNoDocuments {
		return nil, fmt.Errorf("error al buscar la configuración de privacidad para el usuario %s: %w", userID.Hex(), err)
	}

	// Si existe, devolver
	if settings != nil {
		return settings, nil
	}

	// Si no existe, crear por defecto
	defaultSettings := &PrivacySettings{
		UserID:             userID,
		IsPrivate:          false,
		AllowTagging:       true,
		AllowMentions:      true,
		ShowActivityStatus: true,
		BlockedUsers:       []primitive.ObjectID{},
		MutedUsers:         []primitive.ObjectID{},
		CloseFriends:       []primitive.ObjectID{},
		StoryVisibility:    "everyone",
	}
	defaultSettings.SetDefaults()

	created, err := s.repo.Create(ctx, defaultSettings)
	if err != nil {
		return nil, fmt.Errorf("error al crear la configuración de privacidad predeterminada para el usuario %s: %w", userID.Hex(), err)
	}

	return created, nil
}

// UpdatePrivacySettings actualiza la configuración de privacidad
func (s *privacyService) UpdatePrivacySettings(userID primitive.ObjectID, req UpdatePrivacySettingsRequest) (*PrivacySettings, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Verificar si existe primero
	settings, err := s.GetOrCreatePrivacySettings(userID)
	if err != nil {
		return nil, err
	}

	updateFields := bson.M{
		"updatedAt": time.Now(),
	}

	if req.IsPrivate != nil {
		updateFields["isPrivate"] = *req.IsPrivate
	}
	if req.AllowTagging != nil {
		updateFields["allowTagging"] = *req.AllowTagging
	}
	if req.AllowMentions != nil {
		updateFields["allowMentions"] = *req.AllowMentions
	}
	if req.ShowActivityStatus != nil {
		updateFields["showActivityStatus"] = *req.ShowActivityStatus
	}
	if req.StoryVisibility != nil {
		updateFields["storyVisibility"] = *req.StoryVisibility
	}

	// Actualizar
	err = s.repo.Update(ctx, settings.ID, bson.M{"$set": updateFields})
	if err != nil {
		return nil, fmt.Errorf("error al actualizar la configuración de privacidad para el usuario %s: %w", userID.Hex(), err)
	}

	// Obtener actualizado
	return s.repo.GetByID(ctx, settings.ID)
}

// BlockUser bloquea a un usuario agregándolo a la lista de bloqueados
func (s *privacyService) BlockUser(userID, userToBlockID primitive.ObjectID) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if userID == userToBlockID {
		return fmt.Errorf("cannot block yourself")
	}

	// Asegurar que existan los settings
	settings, err := s.GetOrCreatePrivacySettings(userID)
	if err != nil {
		return err
	}

	// Verificar si ya está bloqueado
	for _, blockedID := range settings.BlockedUsers {
		if blockedID == userToBlockID {
			return nil // Ya está bloqueado
		}
	}

	// Usar $addToSet para agregar sin duplicados
	update := bson.M{
		"$addToSet": bson.M{
			"blockedUsers": userToBlockID,
		},
		"$set": bson.M{
			"updatedAt": time.Now(),
		},
	}

	// Actualizar usando el ID de settings
	err = s.repo.Update(ctx, settings.ID, update)
	if err != nil {
		return fmt.Errorf("error blocking user %s: %w", userToBlockID.Hex(), err)
	}

	// Note: Follow service integration removed to avoid circular dependencies
	// Block/unblock in follow service should be handled separately

	return nil
}

// UnblockUser elimina a un usuario de la lista de bloqueados
func (s *privacyService) UnblockUser(userID, userToUnblockID primitive.ObjectID) error {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Asegurar que existan los settings
	settings, err := s.GetOrCreatePrivacySettings(userID)
	if err != nil {
		return err
	}

	update := bson.M{
		"$pull": bson.M{
			"blockedUsers": userToUnblockID,
		},
		"$set": bson.M{
			"updatedAt": time.Now(),
		},
	}

	err = s.repo.Update(ctx, settings.ID, update)
	if err != nil {
		return fmt.Errorf("error unblocking user %s: %w", userToUnblockID.Hex(), err)
	}

	// Note: Follow service integration removed to avoid circular dependencies
	// Block/unblock in follow service should be handled separately

	return nil
}

// GetBlockedUsers retrieves the list of blocked users
func (s *privacyService) GetBlockedUsers(userID primitive.ObjectID) ([]primitive.ObjectID, error) {
	settings, err := s.GetOrCreatePrivacySettings(userID)
	if err != nil {
		return nil, err
	}

	if settings.BlockedUsers == nil {
		return []primitive.ObjectID{}, nil
	}

	return settings.BlockedUsers, nil
}

// IsUserBlocked checks if a user is blocked
func (s *privacyService) IsUserBlocked(userID, targetUserID primitive.ObjectID) (bool, error) {
	blockedUsers, err := s.GetBlockedUsers(userID)
	if err != nil {
		return false, err
	}

	for _, blockedID := range blockedUsers {
		if blockedID == targetUserID {
			return true, nil
		}
	}

	return false, nil
}
