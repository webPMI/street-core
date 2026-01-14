package middlewares

import (
	"errors"
	"net/http"
	"strconv"

	"backend/app/dto/response"
	"backend/models"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Common validation errors
var (
	ErrInvalidID         = errors.New("invalid object id")
	ErrInvalidPagination = errors.New("invalid pagination parameter")
)

// PaginationParams holds validated pagination parameters
type PaginationParams struct {
	Page   int
	Limit  int
	Offset int
}

// Default pagination values
const (
	DefaultPage  = 1
	DefaultLimit = 20
	MaxLimit     = 100
	MinLimit     = 1
)

// ParsePagination extracts and validates pagination parameters from query string.
// Returns validated PaginationParams with sensible defaults and bounds.
//
// Example usage:
//
//	func (h *Handler) List(c *gin.Context) {
//	    pagination, err := middlewares.ParsePagination(c)
//	    if err != nil {
//	        return // Response already sent
//	    }
//	    // Use pagination.Page, pagination.Limit, pagination.Offset
//	}
func ParsePagination(c *gin.Context) (PaginationParams, error) {
	params := PaginationParams{
		Page:  DefaultPage,
		Limit: DefaultLimit,
	}

	// Parse page
	if pageStr := c.Query("page"); pageStr != "" {
		page, err := strconv.Atoi(pageStr)
		if err != nil {
			response.ErrorWithDetails(c, http.StatusBadRequest, models.InvalidPage, map[string]string{
				"page": "must be a valid integer",
			})
			c.Abort()
			return PaginationParams{}, ErrInvalidPagination
		}
		if page < 1 {
			page = 1
		}
		params.Page = page
	}

	// Parse limit
	if limitStr := c.Query("limit"); limitStr != "" {
		limit, err := strconv.Atoi(limitStr)
		if err != nil {
			response.ErrorWithDetails(c, http.StatusBadRequest, models.InvalidLimit, map[string]string{
				"limit": "must be a valid integer",
			})
			c.Abort()
			return PaginationParams{}, ErrInvalidPagination
		}
		// Apply bounds
		if limit < MinLimit {
			limit = MinLimit
		}
		if limit > MaxLimit {
			limit = MaxLimit
		}
		params.Limit = limit
	}

	// Calculate offset
	params.Offset = (params.Page - 1) * params.Limit

	return params, nil
}

// ParsePaginationWithDefaults is like ParsePagination but allows custom defaults.
func ParsePaginationWithDefaults(c *gin.Context, defaultPage, defaultLimit, maxLimit int) (PaginationParams, error) {
	params := PaginationParams{
		Page:  defaultPage,
		Limit: defaultLimit,
	}

	// Parse page
	if pageStr := c.Query("page"); pageStr != "" {
		page, err := strconv.Atoi(pageStr)
		if err != nil {
			response.ErrorWithDetails(c, http.StatusBadRequest, models.InvalidPage, map[string]string{
				"page": "must be a valid integer",
			})
			c.Abort()
			return PaginationParams{}, ErrInvalidPagination
		}
		if page < 1 {
			page = 1
		}
		params.Page = page
	}

	// Parse limit
	if limitStr := c.Query("limit"); limitStr != "" {
		limit, err := strconv.Atoi(limitStr)
		if err != nil {
			response.ErrorWithDetails(c, http.StatusBadRequest, models.InvalidLimit, map[string]string{
				"limit": "must be a valid integer",
			})
			c.Abort()
			return PaginationParams{}, ErrInvalidPagination
		}
		// Apply bounds
		if limit < MinLimit {
			limit = MinLimit
		}
		if limit > maxLimit {
			limit = maxLimit
		}
		params.Limit = limit
	}

	// Calculate offset
	params.Offset = (params.Page - 1) * params.Limit

	return params, nil
}

// ValidateObjectIDParam validates a URL parameter as a MongoDB ObjectID.
// Returns the ObjectID and nil on success, or zero ObjectID and aborts the request with 400 Bad Request.
// Use this for any endpoint that accepts an :id parameter.
//
// Example usage:
//
//	func (h *Handler) GetUser(c *gin.Context) {
//	    userID, err := middlewares.ValidateObjectIDParam(c, "id")
//	    if err != nil {
//	        return // Response already sent
//	    }
//	    // Use userID...
//	}
func ValidateObjectIDParam(c *gin.Context, paramName string) (primitive.ObjectID, error) {
	idStr := c.Param(paramName)
	if idStr == "" {
		response.Error(c, http.StatusBadRequest, models.InvalidID)
		c.Abort()
		return primitive.NilObjectID, ErrInvalidID
	}

	objID, err := primitive.ObjectIDFromHex(idStr)
	if err != nil {
		response.Error(c, http.StatusBadRequest, models.InvalidID)
		c.Abort()
		return primitive.NilObjectID, err
	}

	return objID, nil
}

// ValidateObjectIDQuery validates a query parameter as a MongoDB ObjectID.
// Returns the ObjectID and nil on success, or zero ObjectID and aborts the request with 400 Bad Request.
// If the parameter is optional and not provided, returns zero ObjectID and nil error.
//
// Example usage:
//
//	func (h *Handler) Search(c *gin.Context) {
//	    categoryID, err := middlewares.ValidateObjectIDQuery(c, "categoryId", false)
//	    if err != nil {
//	        return // Response already sent
//	    }
//	    // categoryID might be zero if not provided and not required
//	}
func ValidateObjectIDQuery(c *gin.Context, paramName string, required bool) (primitive.ObjectID, error) {
	idStr := c.Query(paramName)
	if idStr == "" {
		if required {
			response.Error(c, http.StatusBadRequest, models.MissingID)
			c.Abort()
			return primitive.NilObjectID, ErrInvalidID
		}
		return primitive.NilObjectID, nil
	}

	objID, err := primitive.ObjectIDFromHex(idStr)
	if err != nil {
		response.Error(c, http.StatusBadRequest, models.InvalidID)
		c.Abort()
		return primitive.NilObjectID, err
	}

	return objID, nil
}

// MustValidateObjectID is a middleware that validates an ObjectID parameter
// and stores it in the context for later use by handlers.
// Use this as route middleware for endpoints that always need a valid ObjectID.
//
// Example usage:
//
//	router.GET("/users/:id", middlewares.MustValidateObjectID("id", "validatedUserID"), handler.GetUser)
//
// Then in handler:
//
//	userID := c.MustGet("validatedUserID").(primitive.ObjectID)
func MustValidateObjectID(paramName, contextKey string) gin.HandlerFunc {
	return func(c *gin.Context) {
		objID, err := ValidateObjectIDParam(c, paramName)
		if err != nil {
			return // Response already sent by ValidateObjectIDParam
		}
		c.Set(contextKey, objID)
		c.Next()
	}
}
