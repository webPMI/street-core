package profile

import "go.mongodb.org/mongo-driver/bson/primitive"

// User representa la información básica de un usuario para el módulo de perfil
// Esto desacopla el módulo de perfil del paquete models global
type User struct {
	ID        primitive.ObjectID `json:"id" bson:"_id"`
	UserName  string             `json:"userName" bson:"userName"`
	AvatarURL string             `json:"avatarUrl" bson:"avatarUrl"`
	IsPrivate bool               `json:"isPrivate" bson:"isPrivate"`
}
