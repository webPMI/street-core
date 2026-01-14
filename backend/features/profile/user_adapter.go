package profile

import (
	"context"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// UserAdapter adapta el servicio de usuarios a la interfaz local IProfileUserService
type UserAdapter struct {
	globalService UserService
}

// NewUserAdapter crea una nueva instancia del adaptador de usuario
func NewUserAdapter(globalService UserService) IProfileUserService {
	return &UserAdapter{globalService: globalService}
}

// IncrementPostCountWithContext incrementa el contador de publicaciones
func (a *UserAdapter) IncrementPostCountWithContext(ctx context.Context, userID string) error {
	return a.globalService.IncrementPostCountWithContext(ctx, userID)
}

// DecrementPostCountWithContext decrementa el contador de publicaciones
func (a *UserAdapter) DecrementPostCountWithContext(ctx context.Context, userID string) error {
	return a.globalService.DecrementPostCountWithContext(ctx, userID)
}

// GetUser obtiene la información básica de un usuario
func (a *UserAdapter) GetUser(id string) (*User, error) {
	objID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, err
	}

	user, err := a.globalService.GetUserByObjectID(context.Background(), objID)
	if err != nil {
		return nil, err
	}
	if user == nil {
		return nil, nil
	}

	// Mapeamos de models.User (global) a profile.User (local)
	return &User{
		ID:        user.ID,
		UserName:  user.UserName,
		AvatarURL: user.AvatarURL,
		IsPrivate: user.IsPrivate,
	}, nil
}
