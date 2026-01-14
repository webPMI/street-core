package response

import "time"

// ClubResponse represents a public club response
// Excludes internal fields and sensitive data
type ClubResponse struct {
	ID          string   `json:"id"`
	Name        string   `json:"name"`
	Description string   `json:"description"`
	Disciplines []string `json:"disciplines"`
	LogoUrl     string   `json:"logoUrl,omitempty"`
	BannerUrl   string   `json:"bannerUrl,omitempty"`

	// Owner
	OwnerID   string `json:"ownerId"`
	OwnerName string `json:"ownerName"`

	// Location
	Address   string   `json:"address,omitempty"`
	City      string   `json:"city,omitempty"`
	Country   string   `json:"country,omitempty"`
	Latitude  *float64 `json:"latitude,omitempty"`
	Longitude *float64 `json:"longitude,omitempty"`

	// Contact
	Email   string `json:"email,omitempty"`
	Phone   string `json:"phone,omitempty"`
	Website string `json:"website,omitempty"`

	// Settings
	IsPublic         bool   `json:"isPublic"`
	IsVerified       bool   `json:"isVerified"`
	IsActive         bool   `json:"isActive"`
	RequiresApproval bool   `json:"requiresApproval"`
	MembershipFee    *int   `json:"membershipFee,omitempty"`
	Currency         string `json:"currency,omitempty"`

	// Statistics
	MembersCount      int `json:"membersCount"`
	AthletesCount     int `json:"athletesCount"`
	CompetitionsCount int `json:"competitionsCount"`
	WinsCount         int `json:"winsCount"`
	TotalPoints       int `json:"totalPoints"`
	Ranking           int `json:"ranking"`

	// Media
	ImageUrls    []string `json:"imageUrls,omitempty"`
	VideoUrls    []string `json:"videoUrls,omitempty"`
	FacebookUrl  string   `json:"facebookUrl,omitempty"`
	InstagramUrl string   `json:"instagramUrl,omitempty"`
	TwitterUrl   string   `json:"twitterUrl,omitempty"`

	// Additional
	Tags         []string   `json:"tags,omitempty"`
	Rules        string     `json:"rules,omitempty"`
	Vision       string     `json:"vision,omitempty"`
	FoundedDate  *time.Time `json:"foundedDate,omitempty"`
	Achievements []string   `json:"achievements,omitempty"`

	CreatedAt time.Time `json:"createdAt"`
	UpdatedAt time.Time `json:"updatedAt"`
}

// ClubListResponse represents a simplified club response for lists
type ClubListResponse struct {
	ID           string    `json:"id"`
	Name         string    `json:"name"`
	Description  string    `json:"description"`
	Disciplines  []string  `json:"disciplines"`
	LogoUrl      string    `json:"logoUrl,omitempty"`
	City         string    `json:"city,omitempty"`
	Country      string    `json:"country,omitempty"`
	IsVerified   bool      `json:"isVerified"`
	MembersCount int       `json:"membersCount"`
	Ranking      int       `json:"ranking"`
	CreatedAt    time.Time `json:"createdAt"`
}

// ClubMemberResponse represents a club member response
type ClubMemberResponse struct {
	ID       string            `json:"id"`
	UserID   string            `json:"userId"`
	ClubID   string            `json:"clubId"`
	Position string            `json:"position"`
	Status   string            `json:"status"`
	JoinedAt time.Time         `json:"joinedAt"`
	User     *UserListResponse `json:"user,omitempty"` // Populated user data
}

// ClubStatsResponse represents club statistics
type ClubStatsResponse struct {
	TotalMembers      int     `json:"totalMembers"`
	TotalAthletes     int     `json:"totalAthletes"`
	TotalCompetitions int     `json:"totalCompetitions"`
	TotalWins         int     `json:"totalWins"`
	WinRate           float64 `json:"winRate"`
	AveragePoints     float64 `json:"averagePoints"`
	Ranking           int     `json:"ranking"`
}
