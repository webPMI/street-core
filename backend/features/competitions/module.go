// Package competitions provides a self-contained module for competition management.
//
// This module follows Clean Architecture and the modular monolith pattern where each domain
// is a self-contained unit with:
// - Domain entities and business rules
// - Use cases (application logic)
// - Repository interfaces and implementations
// - HTTP handlers (controllers)
// - Route definitions
//
// Usage in main application:
//
//	// In app/container.go
//	competitionsModule := competitions.NewModule(db)
//	// In routes/routes.go
//	container.Competitions.RegisterRoutes(version, container.Services.Auth)
//
// This pattern allows:
// - Easy testing of individual modules
// - Clear boundaries between domains
// - Simple migration to microservices if needed
// - Reduced coupling between different parts of the application
package competitions

import (
	"context"

	"backend/features/competitions/application/usecases"
	"backend/features/competitions/application/usecases/emergency"
	"backend/features/competitions/domain/services"
	"backend/features/competitions/infrastructure/http/handlers"
	compMiddlewares "backend/features/competitions/infrastructure/http/middlewares"
	"backend/features/competitions/infrastructure/http/routes"
	"backend/features/competitions/infrastructure/persistence/mongodb"
	"backend/features/competitions/infrastructure/realtime"
	"backend/features/competitions/ports"
	"backend/middlewares"
	"backend/models"
	"backend/pkg/repository"
	"backend/pkg/users"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

// Module represents the competitions module with all its dependencies
type Module struct {
	// Use Cases (Application Layer)
	CreateCompetitionUseCase *usecases.CreateCompetitionUseCase
	ListCompetitionsUseCase  *usecases.ListCompetitionsUseCase
	GetCompetitionUseCase    *usecases.GetCompetitionUseCase
	UpdateCompetitionUseCase *usecases.UpdateCompetitionUseCase
	DeleteCompetitionUseCase *usecases.DeleteCompetitionUseCase
	RegisterAthleteUseCase   *usecases.RegisterAthleteUseCase
	SubmitScoresUseCase      *usecases.SubmitScoresUseCase

	// Tournament Use Cases
	CreateTournamentUseCase           *usecases.CreateTournamentUseCase
	GetTournamentUseCase              *usecases.GetTournamentUseCase
	ListTournamentsUseCase            *usecases.ListTournamentsUseCase
	AddCompetitionToTournamentUseCase *usecases.AddCompetitionToTournamentUseCase
	UpdateTournamentStandingsUseCase  *usecases.UpdateTournamentStandingsUseCase

	// Heat Use Cases
	CreateHeatsUseCase   *usecases.CreateHeatsUseCase
	GetHeatsUseCase      *usecases.GetHeatsUseCase
	CompleteHeatUseCase  *usecases.CompleteHeatUseCase
	ResetHeatsUseCase    *usecases.ResetHeatsUseCase

	// Security Use Cases
	CheckInToHeatUseCase        *usecases.CheckInToHeatUseCase
	ReplaceHeatRoleUseCase      *usecases.ReplaceHeatRoleUseCase
	BypassJudgeRequirementUseCase *usecases.BypassJudgeRequirementUseCase
	GetSpeakerDashboardUseCase  *usecases.GetSpeakerDashboardUseCase
	RequestScoreUnlockUseCase   *usecases.RequestScoreUnlockUseCase
	AuthorizeScoreUnlockUseCase *usecases.AuthorizeScoreUnlockUseCase
	PauseHeatUseCase            *usecases.PauseHeatUseCase
	ResumeHeatUseCase           *usecases.ResumeHeatUseCase

	// Emergency Use Cases (Crisis Management)
	ResolveTieBreakUseCase     *emergency.ResolveTieBreakUseCase
	SetScoreUnderReviewUseCase *emergency.SetScoreUnderReviewUseCase
	FreezeHeatStateUseCase     *emergency.FreezeHeatStateUseCase
	SwapAthleteScoresUseCase   *emergency.SwapAthleteScoresUseCase
	RollbackHeatStateUseCase   *emergency.RollbackHeatStateUseCase

	// Handler (Infrastructure Layer)
	Handler                *handlers.CompetitionHandler
	CategoryHandler        *handlers.CategoryHandler
	JudgeInvitationHandler *handlers.JudgeInvitationHandler
	TournamentHandler      *handlers.TournamentHandler
	HeatHandler            *handlers.HeatHandler
	SecurityHandler        *handlers.SecurityHandler
	EmergencyHandler       *handlers.EmergencyHandler
	SSEHandler             *handlers.SSEHandler // BLOQUE 3: Real-time events

	// Infrastructure
	SSEHub                     *realtime.SSEHub // Exposed for graceful shutdown
	CompetitionOwnershipValidator middlewares.OwnershipValidator // 🔒 SECURITY (CRITICAL-1): Ownership validation for routes
}

// NewModule creates and initializes a new competitions module with all dependencies.
// This is the single entry point for setting up the competitions functionality.
//
// Parameters:
//   - db: MongoDB database instance
//
// Returns:
//   - *Module: A fully initialized competitions module ready to register routes
//
// Usage:
//
//	competitionsModule := competitions.NewModule(mongoDatabase)
//	competitionsModule.RegisterRoutes(apiRouter, authService)
func NewModule(db *mongo.Database) *Module {
	// Infrastructure Layer: Initialize repositories
	competitionRepo := mongodb.NewCompetitionRepository(db)
	scoreRepo := mongodb.NewScoreRepository(db)
	leaderboardRepo := mongodb.NewLeaderboardRepository(db)
	categoryRepo := mongodb.NewCategoryRepository(db)
	invitationRepo := mongodb.NewJudgeInvitationRepository(db)
	roundRepo := mongodb.NewRoundRepository(db)
	heatRepo := mongodb.NewHeatRepository(db)
	snapshotRepo := mongodb.NewHeatSnapshotRepository(db)

	// BLOQUE 1: Emergency audit repository and authorization service
	auditRepo := mongodb.NewEmergencyAuditRepository(db)
	emergencyAuthService := services.NewEmergencyAuthorizationService()

	// BLOQUE 3: Real-Time Broadcaster (SSE for Speaker updates)
	sseHub := realtime.NewSSEHub()
	broadcaster := realtime.NewSSEBroadcaster(sseHub)

	// Tournament repositories
	tournamentRepo := mongodb.NewTournamentRepository(db)
	tournamentStandingRepo := mongodb.NewTournamentStandingRepository(db)
	_ = mongodb.NewTournamentRegistrationRepository(db) // Reserved for future tournament registration features

	// Cross-module dependencies
	userClient := users.NewMongoUserClient(db)

	// Application Layer: Initialize use cases with repository dependency
	createCompetitionUseCase := usecases.NewCreateCompetitionUseCase(competitionRepo)
	listCompetitionsUseCase := usecases.NewListCompetitionsUseCase(competitionRepo)
	getCompetitionUseCase := usecases.NewGetCompetitionUseCase(competitionRepo)
	updateCompetitionUseCase := usecases.NewUpdateCompetitionUseCase(competitionRepo)
	deleteCompetitionUseCase := usecases.NewDeleteCompetitionUseCase(competitionRepo)
	registerAthleteUseCase := usecases.NewRegisterAthleteUseCase(competitionRepo)

	// Participant-related use cases
	getMyCompetitionsUseCase := usecases.NewGetMyCompetitionsUseCase(competitionRepo)
	getParticipantsUseCase := usecases.NewGetParticipantsUseCase(competitionRepo, userClient)

	// Initialize score-related use cases (with userClient for name resolution)
	updateLeaderboardUseCase := usecases.NewUpdateLeaderboardUseCase(leaderboardRepo, scoreRepo, competitionRepo, userClient)
	submitScoresUseCase := usecases.NewSubmitScoresUseCase(competitionRepo, scoreRepo, heatRepo, updateLeaderboardUseCase, userClient)
	getScoresUseCase := usecases.NewGetScoresUseCase(scoreRepo)
	getLeaderboardUseCase := usecases.NewGetLeaderboardUseCase(leaderboardRepo, competitionRepo)

	// Category-related use cases
	createCategoryUseCase := usecases.NewCreateCategoryUseCase(categoryRepo, competitionRepo)
	listCategoriesUseCase := usecases.NewListCategoriesUseCase(categoryRepo)
	getCategoryUseCase := usecases.NewGetCategoryUseCase(categoryRepo)
	updateCategoryUseCase := usecases.NewUpdateCategoryUseCase(categoryRepo)
	deleteCategoryUseCase := usecases.NewDeleteCategoryUseCase(categoryRepo)
	assignCategoryParticipantUseCase := usecases.NewAssignCategoryParticipantUseCase(categoryRepo)
	assignCategoryJudgeUseCase := usecases.NewAssignCategoryJudgeUseCase(categoryRepo)

	// Judge invitation-related use cases
	createInvitationUseCase := usecases.NewCreateJudgeInvitationUseCase(invitationRepo, competitionRepo, userClient)
	respondToInvitationUseCase := usecases.NewRespondToInvitationUseCase(invitationRepo, competitionRepo)
	listInvitationsUseCase := usecases.NewListJudgeInvitationsUseCase(invitationRepo)
	cancelInvitationUseCase := usecases.NewCancelJudgeInvitationUseCase(invitationRepo)

	// Search use case
	searchCompetitionsUseCase := usecases.NewSearchCompetitionsUseCase(competitionRepo)

	// Competition lifecycle use cases
	startCompetitionUseCase := usecases.NewStartCompetitionUseCase(competitionRepo, categoryRepo, db)
	endCompetitionUseCase := usecases.NewEndCompetitionUseCase(competitionRepo)
	postponeCompetitionUseCase := usecases.NewPostponeCompetitionUseCase(competitionRepo)
	publishResultsUseCase := usecases.NewPublishResultsUseCase(competitionRepo)
	validateStartRequirementsUseCase := usecases.NewValidateStartRequirementsUseCase(competitionRepo, categoryRepo)

	// Tournament use cases
	createTournamentUseCase := usecases.NewCreateTournamentUseCase(tournamentRepo)
	getTournamentUseCase := usecases.NewGetTournamentUseCase(tournamentRepo)
	listTournamentsUseCase := usecases.NewListTournamentsUseCase(tournamentRepo)
	addCompetitionToTournamentUseCase := usecases.NewAddCompetitionToTournamentUseCase(tournamentRepo, competitionRepo)
	updateTournamentStandingsUseCase := usecases.NewUpdateTournamentStandingsUseCase(tournamentRepo, tournamentStandingRepo)

	// Heat use cases
	createHeatsUseCase := usecases.NewCreateHeatsUseCase(heatRepo, roundRepo, categoryRepo, competitionRepo)
	getHeatsUseCase := usecases.NewGetHeatsUseCase(heatRepo)
	completeHeatUseCase := usecases.NewCompleteHeatUseCase(heatRepo, roundRepo)
	resetHeatsUseCase := usecases.NewResetHeatsUseCase(heatRepo, roundRepo, scoreRepo)

	// Security use cases
	checkInToHeatUseCase := usecases.NewCheckInToHeatUseCase(heatRepo)
	replaceHeatRoleUseCase := usecases.NewReplaceHeatRoleUseCase(heatRepo)
	bypassJudgeRequirementUseCase := usecases.NewBypassJudgeRequirementUseCase(heatRepo)
	getSpeakerDashboardUseCase := usecases.NewGetSpeakerDashboardUseCase(heatRepo, scoreRepo)
	requestScoreUnlockUseCase := usecases.NewRequestScoreUnlockUseCase(scoreRepo)
	authorizeScoreUnlockUseCase := usecases.NewAuthorizeScoreUnlockUseCase(scoreRepo, competitionRepo)
	pauseHeatUseCase := usecases.NewPauseHeatUseCase(heatRepo)
	resumeHeatUseCase := usecases.NewResumeHeatUseCase(heatRepo)

	// Emergency use cases (Crisis Management - X-Games, UCI BMX)
	resolveTieBreakUseCase := emergency.NewResolveTieBreakUseCase(scoreRepo)
	setScoreUnderReviewUseCase := emergency.NewSetScoreUnderReviewUseCase(scoreRepo)
	freezeHeatStateUseCase := emergency.NewFreezeHeatStateUseCase(heatRepo, scoreRepo, snapshotRepo)
	swapAthleteScoresUseCase := emergency.NewSwapAthleteScoresUseCase(
		scoreRepo,
		competitionRepo,
		heatRepo,
		auditRepo,
		emergencyAuthService,
		broadcaster,
	)
	rollbackHeatStateUseCase := emergency.NewRollbackHeatStateUseCase(heatRepo, scoreRepo, snapshotRepo)

	// BLOQUE 2: New emergency use cases (Score Management)
	mongoClient := db.Client()
	resetSingleAthleteScoreUseCase := emergency.NewResetSingleAthleteScoreUseCase(
		scoreRepo,
		competitionRepo,
		heatRepo,
		auditRepo,
		emergencyAuthService,
		broadcaster,
		mongoClient,
	)
	adminOverrideScoreUseCase := emergency.NewAdminOverrideScoreUseCase(
		scoreRepo,
		competitionRepo,
		heatRepo,
		auditRepo,
		emergencyAuthService,
		broadcaster,
		mongoClient,
	)

	// Infrastructure Layer: Initialize handler with use cases
	handler := handlers.NewCompetitionHandler(
		createCompetitionUseCase,
		listCompetitionsUseCase,
		getCompetitionUseCase,
		updateCompetitionUseCase,
		deleteCompetitionUseCase,
		registerAthleteUseCase,
		submitScoresUseCase,
		getScoresUseCase,
		getLeaderboardUseCase,
		updateLeaderboardUseCase,
		getMyCompetitionsUseCase,
		getParticipantsUseCase,
		searchCompetitionsUseCase,
		startCompetitionUseCase,
		endCompetitionUseCase,
		postponeCompetitionUseCase,
		publishResultsUseCase,
		validateStartRequirementsUseCase,
	)

	// Category handler
	categoryHandler := handlers.NewCategoryHandler(
		createCategoryUseCase,
		listCategoriesUseCase,
		getCategoryUseCase,
		updateCategoryUseCase,
		deleteCategoryUseCase,
		assignCategoryParticipantUseCase,
		assignCategoryJudgeUseCase,
	)

	// Judge invitation handler
	invitationHandler := handlers.NewJudgeInvitationHandler(
		createInvitationUseCase,
		respondToInvitationUseCase,
		listInvitationsUseCase,
		cancelInvitationUseCase,
	)

	// Tournament handler
	tournamentHandler := handlers.NewTournamentHandler(
		createTournamentUseCase,
		getTournamentUseCase,
		listTournamentsUseCase,
		addCompetitionToTournamentUseCase,
		updateTournamentStandingsUseCase,
	)

	// Heat handler
	heatHandler := handlers.NewHeatHandler(
		createHeatsUseCase,
		getHeatsUseCase,
		completeHeatUseCase,
		resetHeatsUseCase,
	)

	// Security handler
	securityHandler := handlers.NewSecurityHandler(
		checkInToHeatUseCase,
		replaceHeatRoleUseCase,
		bypassJudgeRequirementUseCase,
		getSpeakerDashboardUseCase,
		requestScoreUnlockUseCase,
		authorizeScoreUnlockUseCase,
		pauseHeatUseCase,
		resumeHeatUseCase,
	)

	// Emergency handler
	emergencyHandler := handlers.NewEmergencyHandler(
		resolveTieBreakUseCase,
		setScoreUnderReviewUseCase,
		freezeHeatStateUseCase,
		swapAthleteScoresUseCase,
		rollbackHeatStateUseCase,
		resetSingleAthleteScoreUseCase,  // BLOQUE 2
		adminOverrideScoreUseCase,        // BLOQUE 2
	)

	// SSE handler (BLOQUE 3: Real-time events)
	// 🔒 SECURITY: Pass competition repository for authorization checks (CRITICAL-2 fix)
	sseHandler := handlers.NewSSEHandler(sseHub, competitionRepo)

	// 🔒 SECURITY: Competition ownership validator (CRITICAL-1 fix)
	// This validator is used by route middleware to enforce ownership checks before Update/Delete operations
	ownershipValidator := compMiddlewares.NewCompetitionOwnershipValidator(competitionRepo)

	return &Module{
		CreateCompetitionUseCase: createCompetitionUseCase,
		ListCompetitionsUseCase:  listCompetitionsUseCase,
		GetCompetitionUseCase:    getCompetitionUseCase,
		UpdateCompetitionUseCase: updateCompetitionUseCase,
		DeleteCompetitionUseCase: deleteCompetitionUseCase,
		RegisterAthleteUseCase:   registerAthleteUseCase,
		SubmitScoresUseCase:      submitScoresUseCase,
		// Tournament use cases
		CreateTournamentUseCase:           createTournamentUseCase,
		GetTournamentUseCase:              getTournamentUseCase,
		ListTournamentsUseCase:            listTournamentsUseCase,
		AddCompetitionToTournamentUseCase: addCompetitionToTournamentUseCase,
		UpdateTournamentStandingsUseCase:  updateTournamentStandingsUseCase,
		// Heat use cases
		CreateHeatsUseCase:  createHeatsUseCase,
		GetHeatsUseCase:     getHeatsUseCase,
		CompleteHeatUseCase: completeHeatUseCase,
		ResetHeatsUseCase:   resetHeatsUseCase,
		// Security use cases
		CheckInToHeatUseCase:        checkInToHeatUseCase,
		ReplaceHeatRoleUseCase:      replaceHeatRoleUseCase,
		BypassJudgeRequirementUseCase: bypassJudgeRequirementUseCase,
		GetSpeakerDashboardUseCase:  getSpeakerDashboardUseCase,
		RequestScoreUnlockUseCase:   requestScoreUnlockUseCase,
		AuthorizeScoreUnlockUseCase: authorizeScoreUnlockUseCase,
		PauseHeatUseCase:            pauseHeatUseCase,
		ResumeHeatUseCase:           resumeHeatUseCase,
		// Emergency use cases
		ResolveTieBreakUseCase:     resolveTieBreakUseCase,
		SetScoreUnderReviewUseCase: setScoreUnderReviewUseCase,
		FreezeHeatStateUseCase:     freezeHeatStateUseCase,
		SwapAthleteScoresUseCase:   swapAthleteScoresUseCase,
		RollbackHeatStateUseCase:   rollbackHeatStateUseCase,
		// Handlers
		Handler:                handler,
		CategoryHandler:        categoryHandler,
		JudgeInvitationHandler: invitationHandler,
		TournamentHandler:      tournamentHandler,
		HeatHandler:            heatHandler,
		SecurityHandler:        securityHandler,
		EmergencyHandler:       emergencyHandler,
		SSEHandler:             sseHandler, // BLOQUE 3
		// Infrastructure
		SSEHub:                     sseHub, // BLOQUE 3
		CompetitionOwnershipValidator: ownershipValidator, // 🔒 SECURITY (CRITICAL-1)
	}
}

// RegisterRoutes registers all competition-related routes to the given router group.
// This method should be called from the main router setup.
//
// Parameters:
//   - v1: The API version router group (e.g., /api/v1)
//   - authService: The authentication service for protected routes
//
// Routes registered:
//
// Public (no auth):
//   - GET  /competitions          - List all competitions (paginated, filtered)
//   - GET  /competitions/upcoming - List upcoming competitions
//   - GET  /competitions/live     - List live competitions
//   - GET  /competitions/:id      - Get competition by ID
//   - GET  /competitions/:id/leaderboard - Get leaderboard
//   - GET  /competitions/:id/participants - List participants
//   - GET  /competitions/:id/participants/count - Get participant count
//   - GET  /competitions/:id/categories - List categories
//   - GET  /competitions/:id/categories/:categoryId - Get category
//
// Protected (auth required):
//   - GET    /competitions/my      - Get authenticated user's competitions
//   - POST   /competitions         - Create a new competition (Admin, Verified Special)
//   - PUT    /competitions/:id     - Update a competition (Owner, Admin)
//   - DELETE /competitions/:id     - Delete a competition (Owner, Admin)
//   - POST   /competitions/:id/register   - Register for competition
//   - DELETE /competitions/:id/register   - Unregister from competition
//   - POST   /competitions/:id/scores     - Submit scores (Judge, Admin)
//   - POST   /competitions/:id/categories - Create category (Admin, Organizer)
//   - PUT    /competitions/:id/categories/:categoryId - Update category (Admin, Organizer)
//   - DELETE /competitions/:id/categories/:categoryId - Delete category (Admin, Organizer)
//   - POST   /competitions/:id/categories/:categoryId/participants - Add participant to category
//   - DELETE /competitions/:id/categories/:categoryId/participants/:participantId - Remove participant
//   - POST   /competitions/:id/categories/:categoryId/judges - Add judge to category
//   - DELETE /competitions/:id/categories/:categoryId/judges/:judgeId - Remove judge
//
// Judge Invitations:
//   - GET    /competitions/judge-invitations/my - Get my invitations
//   - POST   /competitions/judge-invitations/:invitationId/respond - Accept/decline invitation
//   - GET    /competitions/:id/judge-invitations - List competition invitations (Admin, Organizer)
//   - POST   /competitions/:id/judge-invitations - Create invitation (Admin, Organizer)
//   - DELETE /competitions/:id/judge-invitations/:invitationId - Cancel invitation (Admin, Organizer)
func (m *Module) RegisterRoutes(version *gin.RouterGroup, authService middlewares.AuthTokenVerifier, tokenRevocationService middlewares.TokenRevocationChecker, userRepo repository.IRepository[models.User]) {
	// 🔒 SECURITY (CRITICAL-1): Pass ownership validator for route-level authorization
	routes.SetupCompetitionRoutes(version, m.Handler, m.CategoryHandler, m.JudgeInvitationHandler, m.HeatHandler, m.SecurityHandler, m.EmergencyHandler, m.SSEHandler, m.CompetitionOwnershipValidator, authService, tokenRevocationService, userRepo)
	routes.SetupTournamentRoutes(version, m.TournamentHandler, authService, tokenRevocationService, userRepo)
}

// RegisterRoutesWithDeps registers routes using the ports.Dependencies interface.
// This method provides a more decoupled way to register routes.
func (m *Module) RegisterRoutesWithDeps(v1 *gin.RouterGroup, deps *ports.Dependencies) {
	routes.SetupCompetitionRoutesWithPorts(v1, m.Handler, m.CategoryHandler, m.JudgeInvitationHandler, m.HeatHandler, m.SecurityHandler, m.EmergencyHandler, m.SSEHandler, deps)
}

// NewModuleWithDeps creates a module using the ports.Dependencies interface.
// This provides a more decoupled initialization.
func NewModuleWithDeps(db *mongo.Database, deps *ports.Dependencies) *Module {
	// Infrastructure Layer: Initialize repositories
	competitionRepo := mongodb.NewCompetitionRepository(db)
	scoreRepo := mongodb.NewScoreRepository(db)
	leaderboardRepo := mongodb.NewLeaderboardRepository(db)
	categoryRepo := mongodb.NewCategoryRepository(db)
	invitationRepo := mongodb.NewJudgeInvitationRepository(db)
	roundRepo := mongodb.NewRoundRepository(db)
	heatRepo := mongodb.NewHeatRepository(db)

	// Create internal user client adapter
	userClient := &portsUserClientAdapter{provider: deps.UserProvider}

	// Application Layer: Initialize use cases
	createCompetitionUseCase := usecases.NewCreateCompetitionUseCase(competitionRepo)
	listCompetitionsUseCase := usecases.NewListCompetitionsUseCase(competitionRepo)
	getCompetitionUseCase := usecases.NewGetCompetitionUseCase(competitionRepo)
	updateCompetitionUseCase := usecases.NewUpdateCompetitionUseCase(competitionRepo)
	deleteCompetitionUseCase := usecases.NewDeleteCompetitionUseCase(competitionRepo)
	registerAthleteUseCase := usecases.NewRegisterAthleteUseCase(competitionRepo)

	// Participant-related use cases
	getMyCompetitionsUseCase := usecases.NewGetMyCompetitionsUseCase(competitionRepo)
	getParticipantsUseCase := usecases.NewGetParticipantsUseCase(competitionRepo, userClient)

	// Score-related use cases
	updateLeaderboardUseCase := usecases.NewUpdateLeaderboardUseCase(leaderboardRepo, scoreRepo, competitionRepo, userClient)
	submitScoresUseCase := usecases.NewSubmitScoresUseCase(competitionRepo, scoreRepo, heatRepo, updateLeaderboardUseCase, userClient)
	getScoresUseCase := usecases.NewGetScoresUseCase(scoreRepo)
	getLeaderboardUseCase := usecases.NewGetLeaderboardUseCase(leaderboardRepo, competitionRepo)

	// Category-related use cases
	createCategoryUseCase := usecases.NewCreateCategoryUseCase(categoryRepo, competitionRepo)
	listCategoriesUseCase := usecases.NewListCategoriesUseCase(categoryRepo)
	getCategoryUseCase := usecases.NewGetCategoryUseCase(categoryRepo)
	updateCategoryUseCase := usecases.NewUpdateCategoryUseCase(categoryRepo)
	deleteCategoryUseCase := usecases.NewDeleteCategoryUseCase(categoryRepo)
	assignCategoryParticipantUseCase := usecases.NewAssignCategoryParticipantUseCase(categoryRepo)
	assignCategoryJudgeUseCase := usecases.NewAssignCategoryJudgeUseCase(categoryRepo)

	// Judge invitation use cases
	createInvitationUseCase := usecases.NewCreateJudgeInvitationUseCase(invitationRepo, competitionRepo, userClient)
	respondToInvitationUseCase := usecases.NewRespondToInvitationUseCase(invitationRepo, competitionRepo)
	listInvitationsUseCase := usecases.NewListJudgeInvitationsUseCase(invitationRepo)
	cancelInvitationUseCase := usecases.NewCancelJudgeInvitationUseCase(invitationRepo)

	// Competition lifecycle use cases
	searchCompetitionsUseCase := usecases.NewSearchCompetitionsUseCase(competitionRepo)
	startCompetitionUseCase := usecases.NewStartCompetitionUseCase(competitionRepo, categoryRepo, db)
	endCompetitionUseCase := usecases.NewEndCompetitionUseCase(competitionRepo)
	postponeCompetitionUseCase := usecases.NewPostponeCompetitionUseCase(competitionRepo)
	publishResultsUseCase := usecases.NewPublishResultsUseCase(competitionRepo)
	validateStartRequirementsUseCase := usecases.NewValidateStartRequirementsUseCase(competitionRepo, categoryRepo)

	// Heat use cases
	createHeatsUseCase := usecases.NewCreateHeatsUseCase(heatRepo, roundRepo, categoryRepo, competitionRepo)
	getHeatsUseCase := usecases.NewGetHeatsUseCase(heatRepo)
	completeHeatUseCase := usecases.NewCompleteHeatUseCase(heatRepo, roundRepo)
	resetHeatsUseCase := usecases.NewResetHeatsUseCase(heatRepo, roundRepo, scoreRepo)

	// Initialize handlers
	handler := handlers.NewCompetitionHandler(
		createCompetitionUseCase,
		listCompetitionsUseCase,
		getCompetitionUseCase,
		updateCompetitionUseCase,
		deleteCompetitionUseCase,
		registerAthleteUseCase,
		submitScoresUseCase,
		getScoresUseCase,
		getLeaderboardUseCase,
		updateLeaderboardUseCase,
		getMyCompetitionsUseCase,
		getParticipantsUseCase,
		searchCompetitionsUseCase,
		startCompetitionUseCase,
		endCompetitionUseCase,
		postponeCompetitionUseCase,
		publishResultsUseCase,
		validateStartRequirementsUseCase,
	)

	categoryHandler := handlers.NewCategoryHandler(
		createCategoryUseCase,
		listCategoriesUseCase,
		getCategoryUseCase,
		updateCategoryUseCase,
		deleteCategoryUseCase,
		assignCategoryParticipantUseCase,
		assignCategoryJudgeUseCase,
	)

	invitationHandler := handlers.NewJudgeInvitationHandler(
		createInvitationUseCase,
		respondToInvitationUseCase,
		listInvitationsUseCase,
		cancelInvitationUseCase,
	)

	heatHandler := handlers.NewHeatHandler(
		createHeatsUseCase,
		getHeatsUseCase,
		completeHeatUseCase,
		resetHeatsUseCase,
	)

	return &Module{
		CreateCompetitionUseCase: createCompetitionUseCase,
		ListCompetitionsUseCase:  listCompetitionsUseCase,
		GetCompetitionUseCase:    getCompetitionUseCase,
		UpdateCompetitionUseCase: updateCompetitionUseCase,
		DeleteCompetitionUseCase: deleteCompetitionUseCase,
		RegisterAthleteUseCase:   registerAthleteUseCase,
		SubmitScoresUseCase:      submitScoresUseCase,
		// Heat use cases
		CreateHeatsUseCase:  createHeatsUseCase,
		GetHeatsUseCase:     getHeatsUseCase,
		CompleteHeatUseCase: completeHeatUseCase,
		ResetHeatsUseCase:   resetHeatsUseCase,
		// Handlers
		Handler:                handler,
		CategoryHandler:        categoryHandler,
		JudgeInvitationHandler: invitationHandler,
		HeatHandler:            heatHandler,
	}
}

// portsUserClientAdapter adapts ports.UserProvider to the internal users.UserClient interface
type portsUserClientAdapter struct {
	provider ports.UserProvider
}

// GetUserBasicInfo implements users.UserClient
func (a *portsUserClientAdapter) GetUserBasicInfo(ctx context.Context, userID primitive.ObjectID) (*users.UserBasicInfo, error) {
	info, err := a.provider.GetUserByID(ctx, userID)
	if err != nil || info == nil {
		return nil, err
	}
	return &users.UserBasicInfo{
		ID:        info.ID,
		FirstName: info.FirstName,
		LastName:  info.LastName,
		AvatarURL: info.Avatar,
		UserName:  info.UserName,
	}, nil
}

// GetUsersBasicInfo implements users.UserClient
func (a *portsUserClientAdapter) GetUsersBasicInfo(ctx context.Context, userIDs []primitive.ObjectID) (map[string]*users.UserBasicInfo, error) {
	infos, err := a.provider.GetUsersByIDs(ctx, userIDs)
	if err != nil {
		return nil, err
	}
	result := make(map[string]*users.UserBasicInfo)
	for _, info := range infos {
		result[info.ID.Hex()] = &users.UserBasicInfo{
			ID:        info.ID,
			FirstName: info.FirstName,
			LastName:  info.LastName,
			AvatarURL: info.Avatar,
			UserName:  info.UserName,
		}
	}
	return result, nil
}
