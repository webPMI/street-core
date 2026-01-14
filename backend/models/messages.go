package models

// messages.go
// Claves simples de mensajes i18n para el backend
// Flutter traduce estas claves automáticamente con LocaleCubit

const (
	// Success Messages - Auth
	LoginSuccessful          = "login.successful"
	RegisterSuccessful       = "register.successful"
	LogoutSuccessful         = "logout.successful"
	PasswordResetSent        = "password.reset.sent"
	PasswordResetSuccessful  = "password.reset.successful"
	TokenValidatedSuccessful = "token.validated.successful"

	// Success Messages - Users
	ProfileUpdatedSuccessfully  = "profile.updated.successfully"
	AccountDeletedSuccessfully  = "account.deleted.successfully"
	UserUpdatedSuccessfully     = "user.updated.successfully"
	UserDeletedSuccessfully     = "user.deleted.successfully"
	PasswordChangedSuccessfully = "password.changed.successfully"

	// Success Messages - Events
	EventCreatedSuccessfully      = "event.created.successfully"
	EventUpdatedSuccessfully      = "event.updated.successfully"
	EventDeletedSuccessfully      = "event.deleted.successfully"
	EventRegisteredSuccessfully   = "event.registered.successfully"
	EventUnregisteredSuccessfully = "event.unregistered.successfully"

	// Success Messages - Products
	ProductCreatedSuccessfully = "product.created.successfully"
	ProductUpdatedSuccessfully = "product.updated.successfully"
	ProductDeletedSuccessfully = "product.deleted.successfully"

	// Success Messages - Clubs
	ClubCreatedSuccessfully        = "club.created.successfully"
	ClubUpdatedSuccessfully        = "club.updated.successfully"
	ClubDeletedSuccessfully        = "club.deleted.successfully"
	ClubJoinedSuccessfully         = "club.joined.successfully"
	ClubLeftSuccessfully           = "club.left.successfully"
	MemberAddedSuccessfully        = "member.added.successfully"
	MemberUpdatedSuccessfully      = "member.updated.successfully"
	MemberRemovedSuccessfully      = "member.removed.successfully"
	MembershipApprovedSuccessfully = "membership.approved.successfully"

	// Success Messages - Athletes
	AthleteCreatedSuccessfully = "athlete.created.successfully"
	AthleteUpdatedSuccessfully = "athlete.updated.successfully"
	AthleteDeletedSuccessfully = "athlete.deleted.successfully"

	// Success Messages - Competitions
	CompetitionCreatedSuccessfully      = "competition.created.successfully"
	CompetitionUpdatedSuccessfully      = "competition.updated.successfully"
	CompetitionDeletedSuccessfully      = "competition.deleted.successfully"
	CompetitionStartedSuccessfully      = "competition.started.successfully"
	CompetitionEndedSuccessfully        = "competition.ended.successfully"
	CompetitionRegisteredSuccessfully   = "competition.registered.successfully"
	CompetitionUnregisteredSuccessfully = "competition.unregistered.successfully"
	ScoreSubmittedSuccessfully          = "score.submitted.successfully"
	ScoreUpdatedSuccessfully            = "score.updated.successfully"
	ResultsPublishedSuccessfully        = "results.published.successfully"
	CategoryCreatedSuccessfully         = "category.created.successfully"
	CategoryUpdatedSuccessfully         = "category.updated.successfully"
	CategoryDeletedSuccessfully         = "category.deleted.successfully"
	ParticipantAddedSuccessfully        = "participant.added.successfully"
	ParticipantRemovedSuccessfully      = "participant.removed.successfully"
	JudgeInvitedSuccessfully            = "judge.invited.successfully"
	InvitationAcceptedSuccessfully      = "invitation.accepted.successfully"
	InvitationRejectedSuccessfully      = "invitation.rejected.successfully"
	InvitationCancelledSuccessfully     = "invitation.cancelled.successfully"

	// Success Messages - Emergency Operations
	EmergencyScoreResetSuccessfully    = "emergency.score.reset.successfully"
	EmergencyScoreOverrideSuccessfully = "emergency.score.override.successfully"
	EmergencyScoresSwappedSuccessfully = "emergency.scores.swapped.successfully"

	// Success Messages - Posts
	PostSaved   = "post.saved"
	PostUnsaved = "post.unsaved"

	// Success Messages - Other
	PolicyUpdatedSuccessfully = "policy.updated.successfully"

	// Error Messages - Auth
	InvalidCredentials      = "invalid.credentials"
	EmailAlreadyExists      = "email.already.exists"
	WeakPassword            = "weak.password"
	TokenExpired            = "token.expired"
	InvalidToken            = "invalid.token"
	Unauthorized            = "unauthorized"
	IncorrectPassword       = "incorrect.password"
	NewPasswordTooWeak      = "new.password.too.weak"
	PasswordChangeFailure   = "password.change.failure"
	AccountLocked           = "account.locked"
	TokenRevoked            = "token.revoked"
	UsernameAlreadyExists   = "username.already.exists"
	InvalidUserID           = "invalid.user.id"
	JSONParsingFailed       = "json.parsing.failed"
	InvalidInput            = "invalid.input"
	InvalidResetToken       = "invalid.reset.token"
	ResetTokenExpired       = "reset.token.expired"
	ResetTokenAlreadyUsed   = "reset.token.already.used"
	EmailNotFound           = "email.not.found"
	PasswordResetEmailError = "password.reset.email.error"

	// Error Messages - OAuth
	OAuthNotConfigured = "oauth.not.configured"
	OAuthProviderError = "oauth.provider.error"
	OAuthStateMismatch = "oauth.state.mismatch"

	// Error Messages - Validation
	InvalidEmail  = "invalid.email"
	RequiredField = "required.field"
	InvalidPhone  = "invalid.phone"
	InvalidDate   = "invalid.date"

	// Error Messages - Resources
	ResourceNotFound    = "resource.not.found"
	UserNotFound        = "user.not.found"
	EventNotFound       = "event.not.found"
	ProductNotFound     = "product.not.found"
	ClubNotFound        = "club.not.found"
	AthleteNotFound     = "athlete.not.found"
	CompetitionNotFound = "competition.not.found"
	CategoryNotFound    = "category.not.found"
	InvitationNotFound  = "invitation.not.found"
	ScoreNotFound       = "score.not.found"
	MemberNotFound      = "member.not.found"
	SavedPostNotFound   = "saved.post.not.found"

	// Error Messages - Posts
	PostAlreadySaved = "post.already.saved"

	// Error Messages - Permissions
	PermissionDenied        = "permission.denied"
	AdminOnly               = "admin.only"
	InsufficientPermissions = "insufficient.permissions"

	// Error Messages - System
	ServerError   = "server.error"
	DatabaseError = "database.error"
	NetworkError  = "network.error"
	RouteNotFound = "route.not.found"

	// Error Messages - Business Logic
	AlreadyRegistered          = "already.registered"
	AlreadyMember              = "already.member"
	RegistrationClosed         = "registration.closed"
	MaxParticipantsReached     = "max.participants.reached"
	MaxJudgesReached           = "max.judges.reached"
	CannotLeaveClub            = "cannot.leave.club" // Owner cannot leave
	InvalidStatus              = "invalid.status"
	InvitationExpired          = "invitation.expired"
	InvitationAlreadyResponded = "invitation.already.responded"
	AlreadyInvited             = "already.invited"
	AlreadyJudge               = "already.judge"
	DuplicateScore             = "duplicate.score"
	NotAuthorizedJudge         = "not.authorized.judge"

	// Communication Messages (Chat, Contact)
	ConversationCreated      = "conversation.created"
	ConversationNotFound     = "conversation.not.found"
	MessageSent              = "message.sent"
	MessageNotFound          = "message.not.found"
	MessageRetrieved         = "message.retrieved"
	MessagesRetrieved        = "messages.retrieved"
	MessageUpdated           = "message.updated"
	MessageDeleted           = "message.deleted"
	ConversationMarkedAsRead = "conversation.marked.as.read"
	UnauthorizedConversation = "unauthorized.conversation"
	InvalidParticipants      = "invalid.participants"
	CannotMessageSelf        = "cannot.message.self"

	// Privacy Messages
	PrivacySettingsRetrieved = "privacy.settings.retrieved"
	PrivacySettingsUpdated   = "privacy.settings.updated"
	UserBlocked              = "user.blocked"
	UserUnblocked            = "user.unblocked"
	BlockedUsersRetrieved    = "blocked.users.retrieved"
	CannotBlockYourself      = "cannot.block.yourself"
	PrivacySettingsNotFound  = "privacy.settings.not.found"

	// Success Messages - Subscriptions & Payments
	SubscriptionCreatedSuccessfully  = "subscription.created.successfully"
	SubscriptionUpdatedSuccessfully  = "subscription.updated.successfully"
	SubscriptionCanceledSuccessfully = "subscription.canceled.successfully"
	SubscriptionResumedSuccessfully  = "subscription.resumed.successfully"
	PlanChangedSuccessfully          = "plan.changed.successfully"
	PaymentSuccessful                = "payment.successful"
	PaymentProcessedSuccessfully     = "payment.processed.successfully"
	RefundProcessedSuccessfully      = "refund.processed.successfully"
	InvoiceGeneratedSuccessfully     = "invoice.generated.successfully"
	PaymentMethodUpdatedSuccessfully = "payment.method.updated.successfully"
	BillingInfoUpdatedSuccessfully   = "billing.info.updated.successfully"

	// Error Messages - Subscriptions & Payments
	SubscriptionNotFound        = "subscription.not.found"
	PlanNotFound                = "plan.not.found"
	PaymentNotFound             = "payment.not.found"
	InvoiceNotFound             = "invoice.not.found"
	InvalidPlan                 = "invalid.plan"
	InvalidPaymentMethod        = "invalid.payment.method"
	PaymentFailed               = "payment.failed"
	PaymentCanceled             = "payment.canceled"
	InsufficientFunds           = "insufficient.funds"
	CardDeclined                = "card.declined"
	CardExpired                 = "card.expired"
	InvalidCard                 = "invalid.card"
	SubscriptionAlreadyActive   = "subscription.already.active"
	SubscriptionAlreadyCanceled = "subscription.already.canceled"
	CannotCancelSubscription    = "cannot.cancel.subscription"
	CannotChangePlan            = "cannot.change.plan"
	TrialExpired                = "trial.expired"
	SubscriptionPastDue         = "subscription.past.due"
	RefundFailed                = "refund.failed"
	InvalidRefundAmount         = "invalid.refund.amount"
	RefundPeriodExpired         = "refund.period.expired"
	StripeError                 = "stripe.error"
	WebhookVerificationFailed   = "webhook.verification.failed"
	InvalidSubscriptionStatus   = "invalid.subscription.status"
	BillingAddressRequired      = "billing.address.required"
	PaymentMethodRequired       = "payment.method.required"
	PlanNotAvailable            = "plan.not.available"
	UpgradeRequired             = "upgrade.required"
	DowngradeNotAllowed         = "downgrade.not.allowed"
	FeatureNotAvailableInPlan   = "feature.not.available.in.plan"

	// Info Messages - Subscriptions & Payments
	SubscriptionWillCancelAtPeriodEnd = "subscription.will.cancel.at.period.end"
	SubscriptionRenewsOn              = "subscription.renews.on"
	TrialEndsOn                       = "trial.ends.on"
	PaymentRetryScheduled             = "payment.retry.scheduled"
	InvoiceSent                       = "invoice.sent"

	// Success Messages - Site Config & Other
	UserRetrieved          = "user.retrieved"
	UserCreated            = "user.created"
	UserDeleted            = "user.deleted"
	ProfileUpdated         = "profile.updated"
	PasswordChanged        = "password.changed"
	ConfigRetrieved        = "config.retrieved"
	ContactInfoRetrieved   = "contact.info.retrieved"
	SocialMediaRetrieved   = "social.media.retrieved"
	LegalTextsRetrieved    = "legal.texts.retrieved"
	CompanyInfoRetrieved   = "company.info.retrieved"
	SEOConfigRetrieved     = "seo.config.retrieved"
	LandingTextsRetrieved  = "landing.texts.retrieved"
	AppConfigRetrieved     = "app.config.retrieved"
	ConsentConfigRetrieved = "consent.config.retrieved"
	BasicConfigRetrieved   = "basic.config.retrieved"

	// Additional Error Messages
	DuplicateResource     = "duplicate.resource"
	TokenCreationFailed   = "token.creation.failed"
	TokenRevocationFailed = "token.revocation.failed"
	ValidationFailed      = "validation.failed"
	ValueTooShort         = "value.too.short"
	ValueTooLong          = "value.too.long"
	ValueTooSmall         = "value.too.small"
	ValueTooLarge         = "value.too.large"
	InvalidURL            = "invalid.url"
	InvalidUUID           = "invalid.uuid"
	InvalidValue          = "invalid.value"
	InvalidPage           = "invalid.page"
	InvalidLimit          = "invalid.limit"
	InvalidHTTPURL        = "invalid.http.url"
	InvalidPhoneFormat    = "invalid.phone.format"
	InvalidLatitude       = "invalid.latitude"
	InvalidLongitude      = "invalid.longitude"
	ValidationError       = "validation.error"
	RateLimitExceeded     = "rate.limit.exceeded"
	InvalidID             = "invalid.id"
	MissingID             = "missing.id"
	MustBeNumeric         = "must.be.numeric"
	MustBeAlphanumeric    = "must.be.alphanumeric"
	InvalidYear           = "invalid.year"
)
