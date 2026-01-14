package handlers

import (
	"log"
	"net/http"

	"backend/features/competitions/application/dto"
	"backend/features/competitions/application/usecases"
	"backend/features/competitions/domain/entities"
	"backend/middlewares"

	"github.com/gin-gonic/gin"
)

// CategoryHandler handles HTTP requests for categories
type CategoryHandler struct {
	createCategory   *usecases.CreateCategoryUseCase
	listCategories   *usecases.ListCategoriesUseCase
	getCategory      *usecases.GetCategoryUseCase
	updateCategory   *usecases.UpdateCategoryUseCase
	deleteCategory   *usecases.DeleteCategoryUseCase
	assignParticipant *usecases.AssignCategoryParticipantUseCase
	assignJudge      *usecases.AssignCategoryJudgeUseCase
}

// NewCategoryHandler creates a new category handler
func NewCategoryHandler(
	createCategory *usecases.CreateCategoryUseCase,
	listCategories *usecases.ListCategoriesUseCase,
	getCategory *usecases.GetCategoryUseCase,
	updateCategory *usecases.UpdateCategoryUseCase,
	deleteCategory *usecases.DeleteCategoryUseCase,
	assignParticipant *usecases.AssignCategoryParticipantUseCase,
	assignJudge *usecases.AssignCategoryJudgeUseCase,
) *CategoryHandler {
	return &CategoryHandler{
		createCategory:   createCategory,
		listCategories:   listCategories,
		getCategory:      getCategory,
		updateCategory:   updateCategory,
		deleteCategory:   deleteCategory,
		assignParticipant: assignParticipant,
		assignJudge:      assignJudge,
	}
}

// List handles listing all categories for a competition
// GET /competitions/:id/categories
func (h *CategoryHandler) List(c *gin.Context) {
	competitionID := c.Param("id")

	// Parse and validate pagination params
	pagination, err := middlewares.ParsePagination(c)
	if err != nil {
		return // Response already sent
	}

	categories, total, err := h.listCategories.Execute(c.Request.Context(), competitionID, pagination.Page, pagination.Limit)
	if err != nil {
		handleCategoryError(c, err)
		return
	}

	log.Printf("Listed %d categories for competition %s", len(categories), competitionID)
	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data": gin.H{
			"categories": dto.ToCategoryResponseList(categories),
			"total":      total,
			"page":       pagination.Page,
			"limit":      pagination.Limit,
		},
	})
}

// Get handles getting a single category by ID
// GET /competitions/:id/categories/:categoryId
func (h *CategoryHandler) Get(c *gin.Context) {
	categoryID := c.Param("categoryId")

	category, err := h.getCategory.Execute(c.Request.Context(), categoryID)
	if err != nil {
		handleCategoryError(c, err)
		return
	}

	log.Printf("Retrieved category %s", categoryID)
	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data":   dto.ToCategoryResponse(category),
	})
}

// Create handles creating a new category
// POST /competitions/:id/categories
func (h *CategoryHandler) Create(c *gin.Context) {
	competitionID := c.Param("id")

	// Get authenticated user from context
	_, err := middlewares.GetUserIDFromContext(c)
	if err != nil {
		log.Printf("[Handler] Unauthorized: %v", err)
		c.JSON(http.StatusUnauthorized, gin.H{
			"status":  "error",
			"message": "Unauthorized",
		})
		return
	}

	// Parse request body
	var req dto.CreateCategoryRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		log.Printf("[Handler] Invalid request: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "Invalid request body: " + err.Error(),
		})
		return
	}

	// Execute use case
	category, err := h.createCategory.Execute(c.Request.Context(), competitionID, req)
	if err != nil {
		handleCategoryError(c, err)
		return
	}

	log.Printf("Created category %s for competition %s", category.ID.Hex(), competitionID)
	c.JSON(http.StatusCreated, gin.H{
		"status":  "success",
		"message": "Category created successfully",
		"data":    dto.ToCategoryResponse(category),
	})
}

// Update handles updating a category
// PUT /competitions/:id/categories/:categoryId
func (h *CategoryHandler) Update(c *gin.Context) {
	categoryID := c.Param("categoryId")

	// Get authenticated user from context
	_, err := middlewares.GetUserIDFromContext(c)
	if err != nil {
		log.Printf("[Handler] Unauthorized: %v", err)
		c.JSON(http.StatusUnauthorized, gin.H{
			"status":  "error",
			"message": "Unauthorized",
		})
		return
	}

	// Parse request body
	var req dto.UpdateCategoryRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		log.Printf("[Handler] Invalid request: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "Invalid request body: " + err.Error(),
		})
		return
	}

	// Execute use case
	category, err := h.updateCategory.Execute(c.Request.Context(), categoryID, req)
	if err != nil {
		handleCategoryError(c, err)
		return
	}

	log.Printf("Updated category %s", categoryID)
	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Category updated successfully",
		"data":    dto.ToCategoryResponse(category),
	})
}

// Delete handles deleting a category
// DELETE /competitions/:id/categories/:categoryId
func (h *CategoryHandler) Delete(c *gin.Context) {
	categoryID := c.Param("categoryId")

	// Get authenticated user from context
	_, err := middlewares.GetUserIDFromContext(c)
	if err != nil {
		log.Printf("[Handler] Unauthorized: %v", err)
		c.JSON(http.StatusUnauthorized, gin.H{
			"status":  "error",
			"message": "Unauthorized",
		})
		return
	}

	// Execute use case
	err = h.deleteCategory.Execute(c.Request.Context(), categoryID)
	if err != nil {
		handleCategoryError(c, err)
		return
	}

	log.Printf("Deleted category %s", categoryID)
	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Category deleted successfully",
	})
}

// AddParticipant handles adding a participant to a category
// POST /competitions/:id/categories/:categoryId/participants
func (h *CategoryHandler) AddParticipant(c *gin.Context) {
	categoryID := c.Param("categoryId")

	// Get authenticated user from context
	userIDObj, err := middlewares.GetUserIDFromContext(c)
	if err != nil {
		log.Printf("[Handler] Unauthorized: %v", err)
		c.JSON(http.StatusUnauthorized, gin.H{
			"status":  "error",
			"message": "Unauthorized",
		})
		return
	}

	// Parse request body
	var req dto.AssignParticipantRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		// If no body, use current user's ID
		req.ParticipantID = userIDObj.Hex()
	}

	// Execute use case
	err = h.assignParticipant.AddParticipant(c.Request.Context(), categoryID, req.ParticipantID)
	if err != nil {
		handleCategoryError(c, err)
		return
	}

	log.Printf("Added participant %s to category %s", req.ParticipantID, categoryID)
	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Participant added to category successfully",
	})
}

// RemoveParticipant handles removing a participant from a category
// DELETE /competitions/:id/categories/:categoryId/participants/:participantId
func (h *CategoryHandler) RemoveParticipant(c *gin.Context) {
	categoryID := c.Param("categoryId")
	participantID := c.Param("participantId")

	// Get authenticated user from context
	_, err := middlewares.GetUserIDFromContext(c)
	if err != nil {
		log.Printf("[Handler] Unauthorized: %v", err)
		c.JSON(http.StatusUnauthorized, gin.H{
			"status":  "error",
			"message": "Unauthorized",
		})
		return
	}

	// Execute use case
	err = h.assignParticipant.RemoveParticipant(c.Request.Context(), categoryID, participantID)
	if err != nil {
		handleCategoryError(c, err)
		return
	}

	log.Printf("Removed participant %s from category %s", participantID, categoryID)
	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Participant removed from category successfully",
	})
}

// AddJudge handles adding a judge to a category
// POST /competitions/:id/categories/:categoryId/judges
func (h *CategoryHandler) AddJudge(c *gin.Context) {
	categoryID := c.Param("categoryId")

	// Get authenticated user from context
	_, err := middlewares.GetUserIDFromContext(c)
	if err != nil {
		log.Printf("[Handler] Unauthorized: %v", err)
		c.JSON(http.StatusUnauthorized, gin.H{
			"status":  "error",
			"message": "Unauthorized",
		})
		return
	}

	// Parse request body
	var req dto.AssignJudgeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		log.Printf("[Handler] Invalid request: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "Invalid request body: " + err.Error(),
		})
		return
	}

	// Execute use case
	err = h.assignJudge.AddJudge(c.Request.Context(), categoryID, req.JudgeID)
	if err != nil {
		handleCategoryError(c, err)
		return
	}

	log.Printf("Added judge %s to category %s", req.JudgeID, categoryID)
	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Judge added to category successfully",
	})
}

// RemoveJudge handles removing a judge from a category
// DELETE /competitions/:id/categories/:categoryId/judges/:judgeId
func (h *CategoryHandler) RemoveJudge(c *gin.Context) {
	categoryID := c.Param("categoryId")
	judgeID := c.Param("judgeId")

	// Get authenticated user from context
	_, err := middlewares.GetUserIDFromContext(c)
	if err != nil {
		log.Printf("[Handler] Unauthorized: %v", err)
		c.JSON(http.StatusUnauthorized, gin.H{
			"status":  "error",
			"message": "Unauthorized",
		})
		return
	}

	// Execute use case
	err = h.assignJudge.RemoveJudge(c.Request.Context(), categoryID, judgeID)
	if err != nil {
		handleCategoryError(c, err)
		return
	}

	log.Printf("Removed judge %s from category %s", judgeID, categoryID)
	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Judge removed from category successfully",
	})
}

// handleCategoryError maps domain errors to HTTP responses
func handleCategoryError(c *gin.Context, err error) {
	log.Printf("[CategoryHandler] Error: %v", err)

	switch err {
	case entities.ErrCategoryNotFound:
		c.JSON(http.StatusNotFound, gin.H{
			"status":  "error",
			"message": "Category not found",
		})
	case entities.ErrAlreadyInCategory:
		c.JSON(http.StatusConflict, gin.H{
			"status":  "error",
			"message": "Participant already in category",
		})
	case entities.ErrNotInCategory:
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "Participant not in category",
		})
	case entities.ErrCategoryFull:
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "Category is full",
		})
	case entities.ErrAlreadyJudge:
		c.JSON(http.StatusConflict, gin.H{
			"status":  "error",
			"message": "User is already a judge in this category",
		})
	case entities.ErrNotJudgeInCategory:
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "User is not a judge in this category",
		})
	default:
		c.JSON(http.StatusInternalServerError, gin.H{
			"status":  "error",
			"message": "Internal server error",
		})
	}
}
