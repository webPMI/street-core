package helpers

import (
	"context"
	"backend/pkg/errors"
	"backend/pkg/repository"
	"backend/utils"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// FindByEmail finds a document by normalized email
// Returns the query and normalized email for reuse
func BuildEmailQuery(email string) (*repository.Query, string) {
	normalizedEmail := utils.NormalizeEmail(email)
	query := repository.NewQuery().Where("email", normalizedEmail)
	return query, normalizedEmail
}

// FindOneByID is a generic helper to find a document by ID
// T is the model type, R is the repository type
func FindOneByID[T any](
	ctx context.Context,
	repo interface{ GetByID(context.Context, primitive.ObjectID) (*T, error) },
	id string,
) (*T, error) {
	objectID, err := StringToObjectID(id)
	if err != nil {
		return nil, err
	}

	result, err := repo.GetByID(ctx, objectID)
	if err != nil {
		return nil, errors.FromMongoError(err, "find document")
	}

	return result, nil
}

// UpdateByID is a generic helper to update a document by ID
func UpdateByID[T any](
	ctx context.Context,
	repo interface{ Update(context.Context, primitive.ObjectID, map[string]interface{}) error },
	id string,
	updates map[string]interface{},
) error {
	objectID, err := StringToObjectID(id)
	if err != nil {
		return err
	}

	err = repo.Update(ctx, objectID, updates)
	if err != nil {
		return errors.FromMongoError(err, "update document")
	}

	return nil
}

// DeleteByID is a generic helper to delete a document by ID
func DeleteByID(
	ctx context.Context,
	repo interface{ Delete(context.Context, primitive.ObjectID) error },
	id string,
) error {
	objectID, err := StringToObjectID(id)
	if err != nil {
		return err
	}

	err = repo.Delete(ctx, objectID)
	if err != nil {
		return errors.FromMongoError(err, "delete document")
	}

	return nil
}
