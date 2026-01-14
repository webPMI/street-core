package config

import (
	"context"
	"os"
	"time"

	"backend/models"
	"backend/utils"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
)

// getAdminCredentials retrieves admin credentials from environment variables.
// These should NEVER be hardcoded in source code.
func getAdminCredentials() (email, password, role, nickName string) {
	email = os.Getenv("ADMIN_EMAIL")
	password = os.Getenv("ADMIN_PASSWORD")
	role = os.Getenv("ADMIN_ROLE")
	nickName = os.Getenv("ADMIN_NICKNAME")

	// Set defaults if not provided
	if role == "" {
		role = models.RoleAdmin
	}
	if nickName == "" {
		nickName = "Admin"
	}

	return
}

// CreateAdminUser verifica si el usuario administrador existe y lo crea si no es así.
// Retorna el usuario administrador (existente o recién creado).
// Admin credentials are loaded from environment variables for security.
// Si ADMIN_EMAIL o ADMIN_PASSWORD están vacíos, se omite la creación (OPCIONAL).
func CreateAdminUser(db *mongo.Database) (*models.User, error) {

	// Get admin credentials from environment variables
	adminEmail, adminPassword, adminRole, adminNickName := getAdminCredentials()

	//  Si no hay credenciales de admin, simplemente omitir la creación
	if adminEmail == "" || adminPassword == "" {
		utils.Info("Credenciales de administrador no definidas - Bootstrap omitido", nil)
		return nil, nil // Retornar nil sin error
	}

	userCollection := db.Collection("users")

	// Usamos un contexto con timeout para la operación
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// 1. Verificar si el usuario ya existe
	var adminUser models.User
	filter := bson.M{"email": adminEmail}

	err := userCollection.FindOne(ctx, filter).Decode(&adminUser)

	if err == nil {
		// Usuario encontrado
		utils.Info("Usuario administrador encontrado", map[string]interface{}{
			"email": adminUser.Email,
		})
		return &adminUser, nil
	}

	if err != mongo.ErrNoDocuments {
		// Error inesperado en la base de datos
		utils.Error("Error al buscar usuario administrador", map[string]interface{}{
			"error": err.Error(),
		})
		return nil, err
	}

	// 2. Si llegamos aquí, el usuario no existe. Procedemos a crearlo.
	utils.Info("Creando usuario administrador", map[string]interface{}{
		"email": adminEmail,
	})

	nuevoUsuario := models.User{
		FirstName: adminNickName,
		Email:     adminEmail,
		// OJO: La contraseña debe ser texto plano aquí para que PrepareForInsert la hashee.
		Password:  adminPassword,
		Role:      adminRole,
		IsPremium: true,
		Gender:    models.GenderMale,
	}

	// 3. Preparar el usuario (hashing, ID, fechas, lowercase)
	if err := nuevoUsuario.PrepareForInsert(); err != nil {
		utils.Error("Error al preparar usuario administrador", map[string]interface{}{
			"error": err.Error(),
		})
		return nil, err
	}

	// 4. Insertar el documento en MongoDB
	_, err = userCollection.InsertOne(ctx, nuevoUsuario)
	if err != nil {
		utils.Error("Error al guardar usuario administrador", map[string]interface{}{
			"error": err.Error(),
		})
		return nil, err
	}

	utils.Info("Usuario administrador creado exitosamente", map[string]interface{}{
		"email": nuevoUsuario.Email,
	})
	return &nuevoUsuario, nil
}
