package request

// UpdateUserRequest represents the user profile update request payload
// Only includes fields that can be updated by the user
type UpdateUserRequest struct {
	FirstName *string `json:"firstName,omitempty" binding:"omitempty,min=2,max=50"`
	LastName  *string `json:"lastName,omitempty" binding:"omitempty,max=50"`
	Bio       *string `json:"bio,omitempty" binding:"omitempty,max=500"`
	UserName  *string `json:"userName,omitempty" binding:"omitempty,min=3,max=30"`
	Phone     *string `json:"phone,omitempty" binding:"omitempty,min=10,max=15"`
	Gender    *string `json:"gender,omitempty" binding:"omitempty,oneof=male female other"`
	NickName  *string `json:"nickName,omitempty" binding:"omitempty,min=3,max=30"`
	ImageUrl  *string `json:"imageUrl,omitempty" binding:"omitempty,url,max=500"`
	AvatarURL *string `json:"avatarUrl,omitempty" binding:"omitempty,url,max=500"`
	IsPrivate *bool   `json:"isPrivate,omitempty"`
}

// UpdatePasswordRequest represents the password change request payload
type UpdatePasswordRequest struct {
	CurrentPassword string `json:"currentPassword" binding:"required"`
	NewPassword     string `json:"newPassword" binding:"required,min=8"`
}

// UpdateEmailRequest represents the email change request payload
type UpdateEmailRequest struct {
	NewEmail        string `json:"newEmail" binding:"required,email"`
	CurrentPassword string `json:"currentPassword" binding:"required"`
}

// UpdateRoleRequest represents the admin role update request payload
type UpdateRoleRequest struct {
	Role string `json:"role" binding:"required,oneof=admin editor user"`
}

// UpdatePremiumRequest represents the premium status update request payload
type UpdatePremiumRequest struct {
	IsPremium bool `json:"isPremium" binding:"required"`
}
