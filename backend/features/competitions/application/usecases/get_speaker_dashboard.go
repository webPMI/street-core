package usecases

import (
	"context"
	"errors"

	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// SpeakerDashboardData contains real-time data for the speaker panel
type SpeakerDashboardData struct {
	// Heat information
	HeatID     string `json:"heatId"`
	HeatName   string `json:"heatName"`
	HeatStatus string `json:"heatStatus"`
	HeatMode   string `json:"heatMode"` // sequential | simultaneous

	// Current state
	CurrentAthleteIndex int                    `json:"currentAthleteIndex"`
	CurrentAthlete      *SpeakerAthleteInfo    `json:"currentAthlete,omitempty"`
	NextAthlete         *SpeakerAthleteInfo    `json:"nextAthlete,omitempty"`

	// Scoring progress (for sequential mode)
	ScoringProgress     *ScoringProgressInfo   `json:"scoringProgress,omitempty"`

	// All athletes in heat (for simultaneous mode)
	Athletes            []SpeakerAthleteInfo   `json:"athletes,omitempty"`

	// Live results (provisional, recalculated in real-time)
	ProvisionalResults  []ProvisionalResult    `json:"provisionalResults,omitempty"`
}

// SpeakerAthleteInfo contains athlete data for speaker commentary
type SpeakerAthleteInfo struct {
	AthleteID    string  `json:"athleteId"`
	AthleteName  string  `json:"athleteName"`
	PhotoURL     string  `json:"photoUrl,omitempty"`
	Country      string  `json:"country,omitempty"`
	Position     int     `json:"position"`         // Order in heat
	IsCompleted  bool    `json:"isCompleted"`      // Has all judges scored?
	ScoreCount   int     `json:"scoreCount"`       // Number of judges who scored
	TotalJudges  int     `json:"totalJudges"`      // Total judges assigned
}

// ScoringProgressInfo shows which judges have/haven't scored
type ScoringProgressInfo struct {
	AthleteID        string   `json:"athleteId"`
	AthleteName      string   `json:"athleteName"`
	JudgesScored     []string `json:"judgesScored"`     // Judge names who scored
	JudgesPending    []string `json:"judgesPending"`    // Judge names pending
	IsComplete       bool     `json:"isComplete"`
}

// ProvisionalResult shows live leaderboard
type ProvisionalResult struct {
	Rank        int     `json:"rank"`
	AthleteID   string  `json:"athleteId"`
	AthleteName string  `json:"athleteName"`
	AverageScore float64 `json:"averageScore"`
	ScoreCount  int     `json:"scoreCount"`
}

// GetSpeakerDashboardUseCase provides real-time data for speaker panel
type GetSpeakerDashboardUseCase struct {
	heatRepo  repositories.HeatRepository
	scoreRepo repositories.ScoreRepository
	// TODO: Add athlete repository when available
}

// NewGetSpeakerDashboardUseCase creates a new GetSpeakerDashboardUseCase
func NewGetSpeakerDashboardUseCase(
	heatRepo repositories.HeatRepository,
	scoreRepo repositories.ScoreRepository,
) *GetSpeakerDashboardUseCase {
	return &GetSpeakerDashboardUseCase{
		heatRepo:  heatRepo,
		scoreRepo: scoreRepo,
	}
}

// Execute retrieves real-time dashboard data for a heat
func (uc *GetSpeakerDashboardUseCase) Execute(ctx context.Context, heatID string) (*SpeakerDashboardData, error) {
	// Parse heat ID
	heatObjID, err := primitive.ObjectIDFromHex(heatID)
	if err != nil {
		return nil, errors.New("invalid heat ID")
	}

	// Get heat
	heat, err := uc.heatRepo.FindByID(ctx, heatObjID)
	if err != nil {
		return nil, errors.New("heat not found")
	}

	// Get all scores for this heat
	// TODO: Implement when ScoreRepository.FindByHeatID() method is added
	scores := []interface{}{} // Empty for now - will be populated when repository method exists
	/*
	scores, err := uc.scoreRepo.FindByHeatID(ctx, heatID)
	if err != nil {
		// If no scores yet, that's fine - return empty arrays
		scores = []interface{}{}
	}
	*/

	// Build dashboard data
	dashboard := &SpeakerDashboardData{
		HeatID:     heatID,
		HeatName:   heat.Name,
		HeatStatus: heat.Status,
		HeatMode:   heat.Mode,
	}

	// Get number of judges assigned (checked-in judges)
	totalJudges := 0
	if heat.CheckInEnabled {
		totalJudges = heat.GetCheckedInCount("judge")
	} else {
		// If check-in not enabled, get from assigned roles
		if heat.AssignedRoles != nil {
			totalJudges = len(heat.AssignedRoles["judge"])
		}
	}

	// Process athletes based on heat mode
	if heat.IsSequential() {
		dashboard.CurrentAthleteIndex = uc.findCurrentAthleteIndex(heat, scores)
		dashboard.CurrentAthlete = uc.buildAthleteInfo(heat, dashboard.CurrentAthleteIndex, scores, totalJudges)

		// Get next athlete if not at the end
		if dashboard.CurrentAthleteIndex < len(heat.AthleteOrder)-1 {
			dashboard.NextAthlete = uc.buildAthleteInfo(heat, dashboard.CurrentAthleteIndex+1, scores, totalJudges)
		}

		// Build scoring progress for current athlete
		if dashboard.CurrentAthlete != nil {
			dashboard.ScoringProgress = uc.buildScoringProgress(heat, dashboard.CurrentAthlete.AthleteID, scores)
		}
	} else {
		// Simultaneous mode - show all athletes
		dashboard.Athletes = uc.buildAllAthletesInfo(heat, scores, totalJudges)
	}

	// Calculate provisional results
	dashboard.ProvisionalResults = uc.calculateProvisionalResults(heat, scores)

	return dashboard, nil
}

// findCurrentAthleteIndex finds which athlete should be scoring now (sequential mode)
func (uc *GetSpeakerDashboardUseCase) findCurrentAthleteIndex(heat interface{}, scores []interface{}) int {
	// TODO: Implement logic to find current athlete based on scores
	// For now, return 0 (first athlete)
	return 0
}

// buildAthleteInfo builds speaker info for a specific athlete
func (uc *GetSpeakerDashboardUseCase) buildAthleteInfo(heat interface{}, index int, scores []interface{}, totalJudges int) *SpeakerAthleteInfo {
	// TODO: Implement athlete info building
	// This requires athlete repository to get name, photo, country
	return &SpeakerAthleteInfo{
		Position:    index + 1,
		TotalJudges: totalJudges,
	}
}

// buildAllAthletesInfo builds info for all athletes (simultaneous mode)
func (uc *GetSpeakerDashboardUseCase) buildAllAthletesInfo(heat interface{}, scores []interface{}, totalJudges int) []SpeakerAthleteInfo {
	// TODO: Implement
	return []SpeakerAthleteInfo{}
}

// buildScoringProgress builds live scoring progress (which judges scored/pending)
func (uc *GetSpeakerDashboardUseCase) buildScoringProgress(heat interface{}, athleteID string, scores []interface{}) *ScoringProgressInfo {
	// TODO: Implement scoring progress tracking
	return &ScoringProgressInfo{
		AthleteID:     athleteID,
		JudgesScored:  []string{},
		JudgesPending: []string{},
	}
}

// calculateProvisionalResults calculates live leaderboard
func (uc *GetSpeakerDashboardUseCase) calculateProvisionalResults(heat interface{}, scores []interface{}) []ProvisionalResult {
	// TODO: Implement provisional results calculation
	// Group scores by athlete, calculate average, sort by score
	return []ProvisionalResult{}
}
