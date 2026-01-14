package social

import "backend/models"

// ============================================================================
// SOCIAL MODULE MESSAGES
// ============================================================================
// Este archivo extiende models/messages.go con claves específicas del módulo

// Re-export de claves centrales para conveniencia
const (
	// Posts
	PostSaved         = models.PostSaved
	PostUnsaved       = models.PostUnsaved
	PostAlreadySaved  = models.PostAlreadySaved
	SavedPostNotFound = models.SavedPostNotFound
)

// Claves específicas del módulo Social
const (
	// Post management
	PostCreated     = "social.post.created"
	PostUpdated     = "social.post.updated"
	PostDeleted     = "social.post.deleted"
	PostNotFound    = "social.post.not.found"
	PostPublished   = "social.post.published"
	PostUnpublished = "social.post.unpublished"
	PostReported    = "social.post.reported"
	PostHidden      = "social.post.hidden"

	// Comments
	CommentCreated  = "social.comment.created"
	CommentUpdated  = "social.comment.updated"
	CommentDeleted  = "social.comment.deleted"
	CommentNotFound = "social.comment.not.found"
	CommentReported = "social.comment.reported"
	CommentTooLong  = "social.comment.too.long"
	CommentTooShort = "social.comment.too.short"

	// Likes
	PostLiked      = "social.post.liked"
	PostUnliked    = "social.post.unliked"
	CommentLiked   = "social.comment.liked"
	CommentUnliked = "social.comment.unliked"
	AlreadyLiked   = "social.already.liked"
	NotLiked       = "social.not.liked"

	// Follows
	UserFollowed     = "social.user.followed"
	UserUnfollowed   = "social.user.unfollowed"
	AlreadyFollowing = "social.already.following"
	NotFollowing     = "social.not.following"
	CannotFollowSelf = "social.cannot.follow.self"

	// Feed
	FeedRetrieved  = "social.feed.retrieved"
	FeedEmpty      = "social.feed.empty"
	FeedLoadFailed = "social.feed.load.failed"

	// Notifications
	NotificationSent     = "social.notification.sent"
	NotificationRead     = "social.notification.read"
	NotificationDeleted  = "social.notification.deleted"
	NotificationsCleared = "social.notifications.cleared"

	// Shares
	PostShared  = "social.post.shared"
	ShareFailed = "social.share.failed"

	// Moderation
	ContentFlagged  = "social.content.flagged"
	ContentApproved = "social.content.approved"
	ContentRejected = "social.content.rejected"
	UserMuted       = "social.user.muted"
	UserUnmuted     = "social.user.unmuted"
	UserBanned      = "social.user.banned"
	UserUnbanned    = "social.user.unbanned"

	// Privacy
	PostVisibilityChanged    = "social.post.visibility.changed"
	ProfilePrivate           = "social.profile.private"
	ProfilePublic            = "social.profile.public"
	CannotViewPrivateContent = "social.cannot.view.private.content"
)
