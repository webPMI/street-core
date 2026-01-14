package base

import (
	"backend/pkg/errors"
	"backend/pkg/helpers"
	"backend/pkg/response"
	"backend/utils"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// ValidateIDParam validates and converts a URL parameter ID to ObjectID
func ValidateIDParam(c *gin.Context, paramName string) (primitive.ObjectID, error) {
	id := c.Param(paramName)
	if id == "" {
		err := errors.ErrInvalidInput("ID parameter is required")
		response.HandleError(c, err)
		return primitive.NilObjectID, err
	}

	objectID, err := helpers.StringToObjectID(id)
	if err != nil {
		response.HandleError(c, err)
		return primitive.NilObjectID, err
	}

	return objectID, nil
}

// BindJSON binds JSON from request and handles errors
func BindJSON(c *gin.Context, obj interface{}) error {
	if err := c.ShouldBindJSON(obj); err != nil {
		utils.Warn("JSON binding failed", map[string]interface{}{
			"error": err.Error(),
			"path":  c.Request.URL.Path,
		})

		appErr := errors.ErrJSONParsingFailed(err)
		response.HandleError(c, appErr)
		return appErr
	}
	return nil
}

