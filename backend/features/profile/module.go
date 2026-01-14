package profile

import (
	"time"

	"go.mongodb.org/mongo-driver/mongo"
)

// Module agrupa todos los servicios de la sección de perfil
type Module struct {
	FollowService    IFollowService
	PostService      IPostService
	PrivacyService   IPrivacyService
	StoryService     IStoryService
	SavedPostService ISavedPostService
}

// NewModule crea una nueva instancia del módulo de perfil e inicializa todos sus servicios
func NewModule(db *mongo.Database, userService UserService) *Module {
	// Inicializar servicios base
	followService := NewFollowService(db)

	// Inicializar servicios que dependen de otros
	privacyService := NewPrivacyService(db)
	storyService := NewStoryService(db, followService)

	// PostService requiere UserService (circularidad potencial manejada vía interfaz o setter)
	// Asumimos que NewPostService toma la DB y devolvemos la interfaz.
	// Si NewPostService no acepta userService, usaremos SetUserService.
	postService := NewPostService(db)
	postService.SetUserService(userService)

	savedPostService := NewSavedPostService(db)

	return &Module{
		FollowService:    followService,
		PostService:      postService,
		PrivacyService:   privacyService,
		StoryService:     storyService,
		SavedPostService: savedPostService,
	}
}

// WaitForBackgroundTasks waits for all background tasks in the module to complete.
// Returns true if all tasks completed within timeout, false if timed out.
func (m *Module) WaitForBackgroundTasks(timeout time.Duration) bool {
	// Wait for PostService background tasks
	return m.PostService.WaitForBackgroundTasks(timeout)
}
