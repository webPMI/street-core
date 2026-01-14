package request

// CreateClubRequest represents the club creation request payload
type CreateClubRequest struct {
	Name        string   `json:"name" binding:"required,min=3,max=255"`
	Description string   `json:"description" binding:"required,min=10,max=2000"`
	Disciplines []string `json:"disciplines" binding:"required,min=1"`
	LogoUrl     string   `json:"logoUrl,omitempty" binding:"omitempty,url,max=500"`
	BannerUrl   string   `json:"bannerUrl,omitempty" binding:"omitempty,url,max=500"`

	// Location
	Address   string   `json:"address,omitempty"`
	City      string   `json:"city,omitempty" binding:"omitempty,max=100"`
	Country   string   `json:"country,omitempty" binding:"omitempty,max=100"`
	Latitude  *float64 `json:"latitude,omitempty"`
	Longitude *float64 `json:"longitude,omitempty"`

	// Contact
	Email   string `json:"email,omitempty" binding:"omitempty,email,max=255"`
	Phone   string `json:"phone,omitempty" binding:"omitempty,max=50"`
	Website string `json:"website,omitempty" binding:"omitempty,url,max=500"`

	// Settings
	IsPublic         bool   `json:"isPublic"`
	RequiresApproval bool   `json:"requiresApproval"`
	MembershipFee    *int   `json:"membershipFee,omitempty"`
	Currency         string `json:"currency,omitempty" binding:"omitempty,max=10"`

	// Media
	FacebookUrl  string `json:"facebookUrl,omitempty" binding:"omitempty,url,max=500"`
	InstagramUrl string `json:"instagramUrl,omitempty" binding:"omitempty,url,max=500"`
	TwitterUrl   string `json:"twitterUrl,omitempty" binding:"omitempty,url,max=500"`

	// Additional
	Tags        []string `json:"tags,omitempty"`
	Rules       string   `json:"rules,omitempty"`
	Vision      string   `json:"vision,omitempty"`
	FoundedDate *string  `json:"foundedDate,omitempty"` // ISO 8601 format
}

// UpdateClubRequest represents the club update request payload
type UpdateClubRequest struct {
	Name        *string   `json:"name,omitempty" binding:"omitempty,min=3,max=255"`
	Description *string   `json:"description,omitempty" binding:"omitempty,min=10,max=2000"`
	Disciplines []string  `json:"disciplines,omitempty"`
	LogoUrl     *string   `json:"logoUrl,omitempty" binding:"omitempty,url,max=500"`
	BannerUrl   *string   `json:"bannerUrl,omitempty" binding:"omitempty,url,max=500"`

	// Location
	Address   *string  `json:"address,omitempty"`
	City      *string  `json:"city,omitempty" binding:"omitempty,max=100"`
	Country   *string  `json:"country,omitempty" binding:"omitempty,max=100"`
	Latitude  *float64 `json:"latitude,omitempty"`
	Longitude *float64 `json:"longitude,omitempty"`

	// Contact
	Email   *string `json:"email,omitempty" binding:"omitempty,email,max=255"`
	Phone   *string `json:"phone,omitempty" binding:"omitempty,max=50"`
	Website *string `json:"website,omitempty" binding:"omitempty,url,max=500"`

	// Settings
	IsPublic         *bool   `json:"isPublic,omitempty"`
	RequiresApproval *bool   `json:"requiresApproval,omitempty"`
	MembershipFee    *int    `json:"membershipFee,omitempty"`
	Currency         *string `json:"currency,omitempty" binding:"omitempty,max=10"`

	// Media
	FacebookUrl  *string `json:"facebookUrl,omitempty" binding:"omitempty,url,max=500"`
	InstagramUrl *string `json:"instagramUrl,omitempty" binding:"omitempty,url,max=500"`
	TwitterUrl   *string `json:"twitterUrl,omitempty" binding:"omitempty,url,max=500"`

	// Additional
	Tags   []string `json:"tags,omitempty"`
	Rules  *string  `json:"rules,omitempty"`
	Vision *string  `json:"vision,omitempty"`
}

// JoinClubRequest represents the club join request payload
type JoinClubRequest struct {
	Message string `json:"message,omitempty" binding:"omitempty,max=500"`
}

// UpdateMemberRequest represents the member update request payload (for admins)
type UpdateMemberRequest struct {
	Position string `json:"position,omitempty" binding:"omitempty,oneof=owner admin moderator member"`
	Status   string `json:"status,omitempty" binding:"omitempty,oneof=active pending rejected banned"`
}
