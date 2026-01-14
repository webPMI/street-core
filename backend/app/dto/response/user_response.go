package response

import "time"

// UserResponse represents a public user profile response
// Excludes sensitive fields like password, deleted status, etc.
type UserResponse struct {
	ID             string    `json:"id"`
	Email          string    `json:"email,omitempty"` // Only for owner/admin
	FirstName      string    `json:"firstName"`
	LastName       string    `json:"lastName"`
	UserName       string    `json:"userName"`
	Bio            string    `json:"bio,omitempty"`
	AvatarURL      string    `json:"avatarUrl,omitempty"`
	ImageUrl       string    `json:"imageUrl,omitempty"`
	IsPrivate      bool      `json:"isPrivate"`
	IsPremium      bool      `json:"isPremium"`
	FollowersCount int       `json:"followersCount"`
	FollowingCount int       `json:"followingCount"`
	Role           string    `json:"role,omitempty"` // Only for owner/admin
	CreatedAt      time.Time `json:"createdAt"`
}

// ProfileResponse represents a detailed user profile response
// Includes additional personal information for the profile owner
type ProfileResponse struct {
	ID             string    `json:"id"`
	Email          string    `json:"email"`
	EmailVerified  bool      `json:"emailVerified"`
	FirstName      string    `json:"firstName"`
	LastName       string    `json:"lastName"`
	UserName       string    `json:"userName"`
	Bio            string    `json:"bio,omitempty"`
	Phone          string    `json:"phone,omitempty"`
	Gender         string    `json:"gender,omitempty"`
	NickName       string    `json:"nickName,omitempty"`
	AvatarURL      string    `json:"avatarUrl,omitempty"`
	ImageUrl       string    `json:"imageUrl,omitempty"`
	IsPrivate      bool      `json:"isPrivate"`
	IsPremium      bool      `json:"isPremium"`
	FollowersCount int       `json:"followersCount"`
	FollowingCount int       `json:"followingCount"`
	Role           string    `json:"role"`
	OAuthProviders []string  `json:"oauthProviders,omitempty"`
	CreatedAt      time.Time `json:"createdAt"`
	UpdatedAt      time.Time `json:"updatedAt"`
}

// UserListResponse represents a simplified user response for lists
type UserListResponse struct {
	ID             string `json:"id"`
	FirstName      string `json:"firstName"`
	LastName       string `json:"lastName"`
	UserName       string `json:"userName"`
	AvatarURL      string `json:"avatarUrl,omitempty"`
	IsPremium      bool   `json:"isPremium"`
	FollowersCount int    `json:"followersCount"`
}

// UserStatsResponse represents user statistics
type UserStatsResponse struct {
	TotalPosts     int `json:"totalPosts"`
	TotalFollowers int `json:"totalFollowers"`
	TotalFollowing int `json:"totalFollowing"`
	TotalLikes     int `json:"totalLikes"`
	TotalComments  int `json:"totalComments"`
}

// PasswordChangeResponse represents the response after password change
type PasswordChangeResponse struct {
	Message   string    `json:"message"`
	ChangedAt time.Time `json:"changedAt"`
}

// EmailChangeResponse represents the response after email change
type EmailChangeResponse struct {
	Message   string    `json:"message"`
	NewEmail  string    `json:"newEmail"`
	UpdatedAt time.Time `json:"updatedAt"`
}
