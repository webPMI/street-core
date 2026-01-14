package profile

import (
	"context"
	"fmt"
	"backend/pkg/pagination"
	"backend/pkg/repository"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

// followService implementa IFollowService
type followService struct {
	followRepo      repository.IRepository[Follow]
	blockRepo       repository.IRepository[Block]
	usersCollection *mongo.Collection // Acceso directo para contadores
}

// NewFollowService crea una nueva instancia del servicio de seguidores
func NewFollowService(db *mongo.Database) IFollowService {
	return &followService{
		followRepo:      repository.NewRepository[Follow](db.Collection("follows")),
		blockRepo:       repository.NewRepository[Block](db.Collection("blocks")),
		usersCollection: db.Collection("users"),
	}
}

// FollowUser crea una relación de seguimiento
func (s *followService) FollowUser(followerID, followingID string, followerName, followerAvatar, followingName, followingAvatar string, targetUserIsPrivate bool) (*Follow, error) {
	followerObjID, err := primitive.ObjectIDFromHex(followerID)
	if err != nil {
		return nil, fmt.Errorf("ID de seguidor inválido: %w", err)
	}

	followingObjID, err := primitive.ObjectIDFromHex(followingID)
	if err != nil {
		return nil, fmt.Errorf("ID de seguido inválido: %w", err)
	}

	// Verificar si ya sigue
	existing, err := s.GetFollow(followerID, followingID)
	if err == nil && existing != nil {
		return nil, fmt.Errorf("ya está siguiendo o solicitud pendiente")
	}

	// Verificar si está bloqueado
	isBlocked, err := s.IsBlocked(followerID, followingID)
	if err != nil {
		return nil, err
	}
	if isBlocked {
		return nil, fmt.Errorf("no se puede seguir a un usuario bloqueado")
	}

	// Verificar si es el bloqueador
	isBlocker, err := s.IsBlocked(followingID, followerID)
	if err != nil {
		return nil, err
	}
	if isBlocker {
		return nil, fmt.Errorf("no se puede seguir a un usuario que te ha bloqueado")
	}

	// Crear seguimiento
	follow := &Follow{
		FollowerID:      followerObjID,
		FollowingID:     followingObjID,
		FollowerName:    followerName,
		FollowerAvatar:  followerAvatar,
		FollowingName:   followingName,
		FollowingAvatar: followingAvatar,
	}

	// Establecer estado basado en privacidad
	if targetUserIsPrivate {
		follow.Status = FollowStatusPending
	} else {
		follow.Status = FollowStatusAccepted
	}

	follow.SetDefaults()

	if err := follow.Validate(); err != nil {
		return nil, err
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	created, err := s.followRepo.Create(ctx, follow)
	if err != nil {
		return nil, err
	}

	// Si es aceptado, incrementar contadores
	if follow.Status == FollowStatusAccepted {
		s.incrementFollowCounts(followerID, followingID)
	}

	return created, nil
}

// UnfollowUser elimina una relación de seguimiento
func (s *followService) UnfollowUser(followerID, followingID string) error {
	followerObjID, err := primitive.ObjectIDFromHex(followerID)
	if err != nil {
		return fmt.Errorf("ID de seguidor inválido: %w", err)
	}

	followingObjID, err := primitive.ObjectIDFromHex(followingID)
	if err != nil {
		return fmt.Errorf("ID de seguido inválido: %w", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Encontrar la relación primero
	query := repository.NewQuery().
		Where("followerId", followerObjID).
		Where("followingId", followingObjID)

	follow, err := s.followRepo.FindOne(ctx, query)
	if err != nil {
		return err
	}

	if follow == nil {
		return fmt.Errorf("relación de seguimiento no encontrada")
	}

	// Eliminar
	err = s.followRepo.Delete(ctx, follow.ID)
	if err != nil {
		return err
	}

	// Decrementar contadores
	s.decrementFollowCounts(followerID, followingID)

	return nil
}

// AcceptFollowRequest acepta una solicitud de seguimiento pendiente
func (s *followService) AcceptFollowRequest(followID string) error {
	followObjID, err := primitive.ObjectIDFromHex(followID)
	if err != nil {
		return fmt.Errorf("ID de seguimiento inválido: %w", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Obtener seguimiento
	follow, err := s.followRepo.GetByID(ctx, followObjID)
	if err != nil {
		return err
	}

	if follow == nil || follow.Status != FollowStatusPending {
		return fmt.Errorf("solicitud no encontrada o no pendiente")
	}

	follow.Accept()

	// Actualizar estado
	update := bson.M{
		"$set": bson.M{
			"status":     follow.Status,
			"acceptedAt": follow.AcceptedAt,
		},
	}

	err = s.followRepo.Update(ctx, followObjID, update)
	if err != nil {
		return err
	}

	// Incrementar contadores
	s.incrementFollowCounts(follow.FollowerID.Hex(), follow.FollowingID.Hex())

	return nil
}

// RejectFollowRequest rechaza una solicitud de seguimiento
func (s *followService) RejectFollowRequest(followID string) error {
	followObjID, err := primitive.ObjectIDFromHex(followID)
	if err != nil {
		return fmt.Errorf("ID de seguimiento inválido: %w", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Verificar que es pendiente
	follow, err := s.followRepo.GetByID(ctx, followObjID)
	if err != nil {
		return err
	}

	if follow == nil || follow.Status != FollowStatusPending {
		return fmt.Errorf("solicitud no encontrada o no pendiente")
	}

	// Eliminar solicitud
	err = s.followRepo.Delete(ctx, followObjID)
	if err != nil {
		return err
	}

	return nil
}

// GetFollowers obtiene los seguidores de un usuario
func (s *followService) GetFollowers(userID string, params *pagination.Params) ([]Follow, int64, error) {
	userObjID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return nil, 0, fmt.Errorf("ID de usuario inválido: %w", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	query := repository.NewQuery().
		Where("followingId", userObjID).
		Where("status", FollowStatusAccepted).
		SortByCreatedAt(false)

	if params != nil {
		query.Limit(int64(params.Limit)).Skip(int64(params.Skip))
	}

	follows, total, err := s.followRepo.Find(ctx, query)
	if err != nil {
		return nil, 0, err
	}

	return follows, total, nil
}

// GetFollowing obtiene a quién sigue un usuario
func (s *followService) GetFollowing(userID string, params *pagination.Params) ([]Follow, int64, error) {
	userObjID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return nil, 0, fmt.Errorf("ID de usuario inválido: %w", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	query := repository.NewQuery().
		Where("followerId", userObjID).
		Where("status", FollowStatusAccepted).
		SortByCreatedAt(false)

	if params != nil {
		query.Limit(int64(params.Limit)).Skip(int64(params.Skip))
	}

	follows, total, err := s.followRepo.Find(ctx, query)
	if err != nil {
		return nil, 0, err
	}

	return follows, total, nil
}

// IsFollowing verifica si un usuario sigue a otro
func (s *followService) IsFollowing(followerID, followingID string) (bool, FollowStatus, error) {
	follow, err := s.GetFollow(followerID, followingID)
	if err != nil || follow == nil {
		return false, "", err
	}

	return true, follow.Status, nil
}

// GetFollow obtiene una relación de seguimiento específica
func (s *followService) GetFollow(followerID, followingID string) (*Follow, error) {
	followerObjID, err := primitive.ObjectIDFromHex(followerID)
	if err != nil {
		return nil, fmt.Errorf("ID de seguidor inválido: %w", err)
	}

	followingObjID, err := primitive.ObjectIDFromHex(followingID)
	if err != nil {
		return nil, fmt.Errorf("ID de seguido inválido: %w", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	query := repository.NewQuery().
		Where("followerId", followerObjID).
		Where("followingId", followingObjID)

	follow, err := s.followRepo.FindOne(ctx, query)
	if err != nil {
		return nil, err
	}

	return follow, nil
}

// GetFollowStats obtiene estadísticas de seguimiento
func (s *followService) GetFollowStats(userID string) (*FollowStats, error) {
	userObjID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return nil, fmt.Errorf("ID de usuario inválido: %w", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Contar seguidores
	followersCount, err := s.followRepo.Count(ctx, bson.M{
		"followingId": userObjID,
		"status":      FollowStatusAccepted,
	})
	if err != nil {
		return nil, err
	}

	// Contar seguidos
	followingCount, err := s.followRepo.Count(ctx, bson.M{
		"followerId": userObjID,
		"status":     FollowStatusAccepted,
	})
	if err != nil {
		return nil, err
	}

	// Contar solicitudes pendientes
	pendingCount, err := s.followRepo.Count(ctx, bson.M{
		"followingId": userObjID,
		"status":      FollowStatusPending,
	})
	if err != nil {
		return nil, err
	}

	return &FollowStats{
		FollowersCount:       int(followersCount),
		FollowingCount:       int(followingCount),
		PendingRequestsCount: int(pendingCount),
	}, nil
}

// GetPendingRequests obtiene solicitudes pendientes
func (s *followService) GetPendingRequests(userID string) ([]Follow, error) {
	userObjID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return nil, fmt.Errorf("ID de usuario inválido: %w", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	query := repository.NewQuery().
		Where("followingId", userObjID).
		Where("status", FollowStatusPending).
		SortByCreatedAt(false)

	follows, _, err := s.followRepo.Find(ctx, query)
	if err != nil {
		return nil, err
	}

	return follows, nil
}

// BlockUser bloquea a un usuario
func (s *followService) BlockUser(blockerID, blockedID string, blockerName, blockedName, blockedAvatar string, reason string) error {
	blockerObjID, err := primitive.ObjectIDFromHex(blockerID)
	if err != nil {
		return fmt.Errorf("ID de bloqueador inválido: %w", err)
	}

	blockedObjID, err := primitive.ObjectIDFromHex(blockedID)
	if err != nil {
		return fmt.Errorf("ID de bloqueado inválido: %w", err)
	}

	// Verificar si ya está bloqueado
	isBlocked, err := s.IsBlocked(blockerID, blockedID)
	if err != nil {
		return err
	}
	if isBlocked {
		return fmt.Errorf("usuario ya bloqueado")
	}

	// Crear bloqueo
	block := &Block{
		BlockerID:     blockerObjID,
		BlockedID:     blockedObjID,
		BlockedName:   blockedName,
		BlockedAvatar: blockedAvatar,
		Reason:        reason,
	}

	block.SetDefaults()

	if err := block.Validate(); err != nil {
		return err
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	_, err = s.blockRepo.Create(ctx, block)
	if err != nil {
		return err
	}

	// Eliminar seguimientos mutuos
	orQuery1 := repository.NewQuery().
		Where("followerId", blockerObjID).
		Where("followingId", blockedObjID)

	orQuery2 := repository.NewQuery().
		Where("followerId", blockedObjID).
		Where("followingId", blockerObjID)

	filter := bson.M{
		"$or": []bson.M{
			orQuery1.GetFilter(),
			orQuery2.GetFilter(),
		},
	}

	s.followRepo.DeleteMany(ctx, filter)

	return nil
}

// UnblockUser desbloquea a un usuario
func (s *followService) UnblockUser(blockerID, blockedID string) error {
	blockerObjID, err := primitive.ObjectIDFromHex(blockerID)
	if err != nil {
		return fmt.Errorf("ID de bloqueador inválido: %w", err)
	}

	blockedObjID, err := primitive.ObjectIDFromHex(blockedID)
	if err != nil {
		return fmt.Errorf("ID de bloqueado inválido: %w", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Encontrar bloqueo
	query := repository.NewQuery().
		Where("blockerId", blockerObjID).
		Where("blockedId", blockedObjID)

	block, err := s.blockRepo.FindOne(ctx, query)
	if err != nil {
		return err
	}

	if block == nil {
		return fmt.Errorf("bloqueo no encontrado")
	}

	// Eliminar
	err = s.blockRepo.Delete(ctx, block.ID)
	if err != nil {
		return err
	}

	return nil
}

// IsBlocked verifica si un usuario está bloqueado
func (s *followService) IsBlocked(blockerID, blockedID string) (bool, error) {
	blockerObjID, err := primitive.ObjectIDFromHex(blockerID)
	if err != nil {
		return false, fmt.Errorf("ID de bloqueador inválido: %w", err)
	}

	blockedObjID, err := primitive.ObjectIDFromHex(blockedID)
	if err != nil {
		return false, fmt.Errorf("ID de bloqueado inválido: %w", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	count, err := s.blockRepo.Count(ctx, bson.M{
		"blockerId": blockerObjID,
		"blockedId": blockedObjID,
	})

	if err != nil {
		return false, err
	}

	return count > 0, nil
}

// GetBlockedUsers obtiene usuarios bloqueados
func (s *followService) GetBlockedUsers(blockerID string) ([]Block, error) {
	blockerObjID, err := primitive.ObjectIDFromHex(blockerID)
	if err != nil {
		return nil, fmt.Errorf("ID de bloqueador inválido: %w", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	query := repository.NewQuery().
		Where("blockerId", blockerObjID).
		SortByCreatedAt(false)

	blocks, _, err := s.blockRepo.Find(ctx, query)
	if err != nil {
		return nil, err
	}

	return blocks, nil
}

// Métodos auxiliares para contadores
func (s *followService) incrementFollowCounts(followerID, followingID string) {
	followerObjID, _ := primitive.ObjectIDFromHex(followerID)
	followingObjID, _ := primitive.ObjectIDFromHex(followingID)

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Incrementar siguiendo del seguidor
	s.usersCollection.UpdateOne(
		ctx,
		bson.M{"_id": followerObjID},
		bson.M{"$inc": bson.M{"followingCount": 1}},
	)

	// Incrementar seguidores del seguido
	s.usersCollection.UpdateOne(
		ctx,
		bson.M{"_id": followingObjID},
		bson.M{"$inc": bson.M{"followersCount": 1}},
	)
}

func (s *followService) decrementFollowCounts(followerID, followingID string) {
	followerObjID, _ := primitive.ObjectIDFromHex(followerID)
	followingObjID, _ := primitive.ObjectIDFromHex(followingID)

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Decrementar siguiendo
	s.usersCollection.UpdateOne(
		ctx,
		bson.M{"_id": followerObjID, "followingCount": bson.M{"$gt": 0}},
		bson.M{"$inc": bson.M{"followingCount": -1}},
	)

	// Decrementar seguidores
	s.usersCollection.UpdateOne(
		ctx,
		bson.M{"_id": followingObjID, "followersCount": bson.M{"$gt": 0}},
		bson.M{"$inc": bson.M{"followersCount": -1}},
	)
}
