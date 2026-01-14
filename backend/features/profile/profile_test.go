package profile

import (
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// ============================================================================
// POST MODEL TESTS
// ============================================================================

func TestPost_Model(t *testing.T) {
	t.Run("creates post with required fields", func(t *testing.T) {
		now := time.Now()
		post := &Post{
			ID:        primitive.NewObjectID(),
			UserID:    primitive.NewObjectID(),
			UserName:  "testuser",
			Caption:   "Test post caption",
			MediaType: MediaTypeImage,
			MediaURLs: []string{"http://example.com/img.jpg"},
			CreatedAt: now,
			UpdatedAt: now,
		}

		assert.False(t, post.ID.IsZero())
		assert.False(t, post.UserID.IsZero())
		assert.Equal(t, "Test post caption", post.Caption)
		assert.Equal(t, MediaTypeImage, post.MediaType)
		assert.Len(t, post.MediaURLs, 1)
	})

	t.Run("post with multiple media", func(t *testing.T) {
		post := &Post{
			ID:        primitive.NewObjectID(),
			UserID:    primitive.NewObjectID(),
			Caption:   "Post with carousel",
			MediaType: MediaTypeCarousel,
			MediaURLs: []string{
				"http://example.com/img1.jpg",
				"http://example.com/img2.jpg",
				"http://example.com/img3.jpg",
			},
		}

		assert.Len(t, post.MediaURLs, 3)
		assert.Equal(t, MediaTypeCarousel, post.MediaType)
	})

	t.Run("post with engagement stats", func(t *testing.T) {
		post := &Post{
			ID:            primitive.NewObjectID(),
			LikesCount:    150,
			CommentsCount: 25,
			SharesCount:   10,
			ViewsCount:    1000,
		}

		assert.Equal(t, 150, post.LikesCount)
		assert.Equal(t, 25, post.CommentsCount)
		assert.Equal(t, 10, post.SharesCount)
		assert.Equal(t, 1000, post.ViewsCount)
	})

	t.Run("post with video", func(t *testing.T) {
		post := &Post{
			ID:           primitive.NewObjectID(),
			MediaType:    MediaTypeVideo,
			MediaURLs:    []string{"http://example.com/video.mp4"},
			ThumbnailURL: "http://example.com/thumb.jpg",
		}

		assert.Equal(t, MediaTypeVideo, post.MediaType)
		assert.NotEmpty(t, post.ThumbnailURL)
	})

	t.Run("post visibility levels", func(t *testing.T) {
		publicPost := &Post{Visibility: VisibilityPublic}
		followersPost := &Post{Visibility: VisibilityFollowers}
		privatePost := &Post{Visibility: VisibilityPrivate}

		assert.Equal(t, VisibilityPublic, publicPost.Visibility)
		assert.Equal(t, VisibilityFollowers, followersPost.Visibility)
		assert.Equal(t, VisibilityPrivate, privatePost.Visibility)
	})
}

// ============================================================================
// COMMENT MODEL TESTS
// ============================================================================

func TestComment_Model(t *testing.T) {
	t.Run("creates comment with required fields", func(t *testing.T) {
		now := time.Now()
		comment := &Comment{
			ID:        primitive.NewObjectID(),
			PostID:    primitive.NewObjectID(),
			UserID:    primitive.NewObjectID(),
			UserName:  "testuser",
			Text:      "Great post!",
			CreatedAt: now,
			UpdatedAt: now,
		}

		assert.False(t, comment.ID.IsZero())
		assert.False(t, comment.PostID.IsZero())
		assert.False(t, comment.UserID.IsZero())
		assert.Equal(t, "Great post!", comment.Text)
	})

	t.Run("reply comment with parent", func(t *testing.T) {
		parentID := primitive.NewObjectID()
		comment := &Comment{
			ID:              primitive.NewObjectID(),
			PostID:          primitive.NewObjectID(),
			UserID:          primitive.NewObjectID(),
			ParentCommentID: &parentID,
			Text:            "Reply to comment",
		}

		assert.NotNil(t, comment.ParentCommentID)
		assert.Equal(t, parentID, *comment.ParentCommentID)
	})

	t.Run("comment with likes", func(t *testing.T) {
		comment := &Comment{
			ID:         primitive.NewObjectID(),
			LikesCount: 10,
		}

		assert.Equal(t, 10, comment.LikesCount)
	})

	t.Run("edited comment", func(t *testing.T) {
		comment := &Comment{
			ID:       primitive.NewObjectID(),
			Text:     "Edited text",
			IsEdited: true,
		}

		assert.True(t, comment.IsEdited)
	})

	t.Run("comment with replies", func(t *testing.T) {
		comment := &Comment{
			ID:           primitive.NewObjectID(),
			RepliesCount: 5,
		}

		assert.Equal(t, 5, comment.RepliesCount)
	})
}

// ============================================================================
// LIKE MODEL TESTS
// ============================================================================

func TestLike_Model(t *testing.T) {
	t.Run("creates like for post", func(t *testing.T) {
		now := time.Now()
		like := &Like{
			ID:        primitive.NewObjectID(),
			PostID:    primitive.NewObjectID(),
			UserID:    primitive.NewObjectID(),
			UserName:  "testuser",
			CreatedAt: now,
		}

		assert.False(t, like.ID.IsZero())
		assert.False(t, like.PostID.IsZero())
		assert.False(t, like.UserID.IsZero())
		assert.Equal(t, "testuser", like.UserName)
	})

	t.Run("like with user avatar", func(t *testing.T) {
		like := &Like{
			ID:         primitive.NewObjectID(),
			PostID:     primitive.NewObjectID(),
			UserID:     primitive.NewObjectID(),
			UserName:   "testuser",
			UserAvatar: "http://example.com/avatar.jpg",
		}

		assert.NotEmpty(t, like.UserAvatar)
	})
}

// ============================================================================
// FOLLOW MODEL TESTS
// ============================================================================

func TestFollow_Model(t *testing.T) {
	t.Run("creates follow relationship", func(t *testing.T) {
		now := time.Now()
		follow := &Follow{
			ID:          primitive.NewObjectID(),
			FollowerID:  primitive.NewObjectID(),
			FollowingID: primitive.NewObjectID(),
			Status:      FollowStatusAccepted,
			CreatedAt:   now,
		}

		assert.False(t, follow.ID.IsZero())
		assert.False(t, follow.FollowerID.IsZero())
		assert.False(t, follow.FollowingID.IsZero())
		assert.Equal(t, FollowStatusAccepted, follow.Status)
	})

	t.Run("pending follow request", func(t *testing.T) {
		follow := &Follow{
			ID:          primitive.NewObjectID(),
			FollowerID:  primitive.NewObjectID(),
			FollowingID: primitive.NewObjectID(),
			Status:      FollowStatusPending,
		}

		assert.Equal(t, FollowStatusPending, follow.Status)
	})

	t.Run("accept follow request", func(t *testing.T) {
		follow := &Follow{
			ID:          primitive.NewObjectID(),
			FollowerID:  primitive.NewObjectID(),
			FollowingID: primitive.NewObjectID(),
			Status:      FollowStatusPending,
		}

		follow.Accept()

		assert.Equal(t, FollowStatusAccepted, follow.Status)
		assert.NotNil(t, follow.AcceptedAt)
	})
}

// ============================================================================
// STORY MODEL TESTS
// ============================================================================

func TestStory_Model(t *testing.T) {
	t.Run("creates story with required fields", func(t *testing.T) {
		now := time.Now()
		expiresAt := now.Add(24 * time.Hour)
		story := &Story{
			ID:        primitive.NewObjectID(),
			UserID:    primitive.NewObjectID(),
			MediaURL:  "http://example.com/story.jpg",
			MediaType: StoryMediaTypeImage,
			ExpiresAt: expiresAt,
			CreatedAt: now,
		}

		assert.False(t, story.ID.IsZero())
		assert.Equal(t, "http://example.com/story.jpg", story.MediaURL)
		assert.Equal(t, StoryMediaTypeImage, story.MediaType)
		assert.True(t, story.ExpiresAt.After(now))
	})

	t.Run("story with views", func(t *testing.T) {
		viewerID := primitive.NewObjectID()
		story := &Story{
			ID:         primitive.NewObjectID(),
			ViewsCount: 100,
			Viewers: []StoryView{
				{ID: primitive.NewObjectID(), UserID: viewerID},
			},
		}

		assert.Equal(t, 100, story.ViewsCount)
		assert.Len(t, story.Viewers, 1)
	})

	t.Run("video story", func(t *testing.T) {
		story := &Story{
			ID:           primitive.NewObjectID(),
			MediaURL:     "http://example.com/story.mp4",
			MediaType:    StoryMediaTypeVideo,
			ThumbnailURL: "http://example.com/thumb.jpg",
		}

		assert.Equal(t, StoryMediaTypeVideo, story.MediaType)
		assert.NotEmpty(t, story.ThumbnailURL)
	})
}

// ============================================================================
// SAVED POST MODEL TESTS
// ============================================================================

func TestSavedPost_Model(t *testing.T) {
	t.Run("creates saved post", func(t *testing.T) {
		now := time.Now()
		savedPost := &SavedPost{
			ID:        primitive.NewObjectID(),
			UserID:    primitive.NewObjectID(),
			PostID:    primitive.NewObjectID(),
			CreatedAt: now,
		}

		assert.False(t, savedPost.ID.IsZero())
		assert.False(t, savedPost.UserID.IsZero())
		assert.False(t, savedPost.PostID.IsZero())
		assert.False(t, savedPost.CreatedAt.IsZero())
	})

	t.Run("validates required fields", func(t *testing.T) {
		savedPost := &SavedPost{}
		err := savedPost.Validate()
		assert.Error(t, err)

		savedPost.PostID = primitive.NewObjectID()
		err = savedPost.Validate()
		assert.Error(t, err)

		savedPost.UserID = primitive.NewObjectID()
		err = savedPost.Validate()
		assert.NoError(t, err)
	})
}

// ============================================================================
// MEDIA TYPE TESTS
// ============================================================================

func TestMediaType_Constants(t *testing.T) {
	t.Run("valid media types", func(t *testing.T) {
		assert.Equal(t, MediaType("image"), MediaTypeImage)
		assert.Equal(t, MediaType("video"), MediaTypeVideo)
		assert.Equal(t, MediaType("carousel"), MediaTypeCarousel)
	})
}

func TestPostVisibility_Constants(t *testing.T) {
	t.Run("valid visibility levels", func(t *testing.T) {
		assert.Equal(t, PostVisibility("public"), VisibilityPublic)
		assert.Equal(t, PostVisibility("followers"), VisibilityFollowers)
		assert.Equal(t, PostVisibility("private"), VisibilityPrivate)
	})
}

// ============================================================================
// EDGE CASES
// ============================================================================

func TestProfile_EdgeCases(t *testing.T) {
	t.Run("post with empty caption", func(t *testing.T) {
		post := &Post{
			ID:        primitive.NewObjectID(),
			UserID:    primitive.NewObjectID(),
			Caption:   "",
			MediaType: MediaTypeImage,
			MediaURLs: []string{"http://example.com/img.jpg"},
		}

		assert.Empty(t, post.Caption)
		assert.NotEmpty(t, post.MediaURLs)
	})

	t.Run("comment without parent is top-level", func(t *testing.T) {
		comment := &Comment{
			ID:              primitive.NewObjectID(),
			PostID:          primitive.NewObjectID(),
			UserID:          primitive.NewObjectID(),
			ParentCommentID: nil,
			Text:            "Top level comment",
		}

		assert.Nil(t, comment.ParentCommentID)
	})

	t.Run("story expiration check", func(t *testing.T) {
		now := time.Now()

		// Active story
		activeStory := &Story{
			ID:        primitive.NewObjectID(),
			ExpiresAt: now.Add(12 * time.Hour),
		}
		assert.True(t, activeStory.ExpiresAt.After(now))

		// Expired story
		expiredStory := &Story{
			ID:        primitive.NewObjectID(),
			ExpiresAt: now.Add(-1 * time.Hour),
		}
		assert.True(t, expiredStory.ExpiresAt.Before(now))
	})

	t.Run("deleted comment", func(t *testing.T) {
		now := time.Now()
		comment := &Comment{
			ID:        primitive.NewObjectID(),
			IsDeleted: true,
			DeletedAt: &now,
		}

		assert.True(t, comment.IsDeleted)
		assert.NotNil(t, comment.DeletedAt)
	})
}

// ============================================================================
// POST CREATION REQUEST TESTS
// ============================================================================

func TestCreatePostRequest(t *testing.T) {
	t.Run("valid post request", func(t *testing.T) {
		req := &CreatePostRequest{
			Caption:    "My awesome post",
			MediaType:  MediaTypeImage,
			MediaURLs:  []string{"http://example.com/img.jpg"},
			Visibility: VisibilityPublic,
		}

		assert.NotEmpty(t, req.Caption)
		assert.NotEmpty(t, req.MediaURLs)
	})
}

// ============================================================================
// BENCHMARKS
// ============================================================================

func BenchmarkPost_Creation(b *testing.B) {
	now := time.Now()
	userID := primitive.NewObjectID()

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = &Post{
			ID:        primitive.NewObjectID(),
			UserID:    userID,
			Caption:   "Benchmark post content",
			MediaType: MediaTypeImage,
			MediaURLs: []string{"http://example.com/img.jpg"},
			CreatedAt: now,
			UpdatedAt: now,
		}
	}
}

func BenchmarkComment_Creation(b *testing.B) {
	now := time.Now()
	postID := primitive.NewObjectID()
	userID := primitive.NewObjectID()

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = &Comment{
			ID:        primitive.NewObjectID(),
			PostID:    postID,
			UserID:    userID,
			Text:      "Benchmark comment",
			CreatedAt: now,
		}
	}
}

// ============================================================================
// POST VALIDATION TESTS
// ============================================================================

func TestPost_Validate(t *testing.T) {
	t.Run("valid post", func(t *testing.T) {
		post := &Post{
			UserID:    primitive.NewObjectID(),
			MediaURLs: []string{"http://example.com/img.jpg"},
			Caption:   "Test caption",
		}
		err := post.Validate()
		assert.NoError(t, err)
	})

	t.Run("missing userID", func(t *testing.T) {
		post := &Post{
			MediaURLs: []string{"http://example.com/img.jpg"},
		}
		err := post.Validate()
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "userId")
	})

	t.Run("missing media URLs", func(t *testing.T) {
		post := &Post{
			UserID:    primitive.NewObjectID(),
			MediaURLs: []string{},
		}
		err := post.Validate()
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "media URL")
	})

	t.Run("too many media URLs", func(t *testing.T) {
		urls := make([]string, 11)
		for i := range urls {
			urls[i] = "http://example.com/img.jpg"
		}
		post := &Post{
			UserID:    primitive.NewObjectID(),
			MediaURLs: urls,
		}
		err := post.Validate()
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "maximum 10")
	})

	t.Run("caption too long", func(t *testing.T) {
		longCaption := make([]byte, 2201)
		for i := range longCaption {
			longCaption[i] = 'a'
		}
		post := &Post{
			UserID:    primitive.NewObjectID(),
			MediaURLs: []string{"http://example.com/img.jpg"},
			Caption:   string(longCaption),
		}
		err := post.Validate()
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "2200 characters")
	})
}

// ============================================================================
// POST SETDEFAULTS TESTS
// ============================================================================

func TestPost_SetDefaults(t *testing.T) {
	t.Run("sets all default values", func(t *testing.T) {
		post := &Post{
			UserID:    primitive.NewObjectID(),
			MediaURLs: []string{"http://example.com/img.jpg"},
		}

		post.SetDefaults()

		assert.False(t, post.CreatedAt.IsZero())
		assert.False(t, post.UpdatedAt.IsZero())
		assert.True(t, post.IsActive)
		assert.False(t, post.IsArchived)
		assert.False(t, post.IsDeleted)
		assert.Equal(t, 0, post.LikesCount)
		assert.Equal(t, 0, post.CommentsCount)
		assert.Equal(t, VisibilityPublic, post.Visibility)
		assert.NotNil(t, post.Tags)
		assert.NotNil(t, post.Mentions)
	})

	t.Run("preserves existing visibility", func(t *testing.T) {
		post := &Post{
			UserID:     primitive.NewObjectID(),
			Visibility: VisibilityPrivate,
		}

		post.SetDefaults()

		assert.Equal(t, VisibilityPrivate, post.Visibility)
	})
}

// ============================================================================
// POST COUNTER TESTS
// ============================================================================

func TestPost_CounterMethods(t *testing.T) {
	t.Run("increment likes", func(t *testing.T) {
		post := &Post{LikesCount: 0}
		post.IncrementLikes()
		assert.Equal(t, 1, post.LikesCount)
		post.IncrementLikes()
		assert.Equal(t, 2, post.LikesCount)
	})

	t.Run("decrement likes", func(t *testing.T) {
		post := &Post{LikesCount: 5}
		post.DecrementLikes()
		assert.Equal(t, 4, post.LikesCount)
	})

	t.Run("decrement likes stops at zero", func(t *testing.T) {
		post := &Post{LikesCount: 0}
		post.DecrementLikes()
		assert.Equal(t, 0, post.LikesCount)
	})

	t.Run("increment comments", func(t *testing.T) {
		post := &Post{CommentsCount: 0}
		post.IncrementComments()
		assert.Equal(t, 1, post.CommentsCount)
	})

	t.Run("decrement comments stops at zero", func(t *testing.T) {
		post := &Post{CommentsCount: 0}
		post.DecrementComments()
		assert.Equal(t, 0, post.CommentsCount)
	})

	t.Run("increment views", func(t *testing.T) {
		post := &Post{ViewsCount: 0}
		post.IncrementViews()
		assert.Equal(t, 1, post.ViewsCount)
	})
}

// ============================================================================
// POST SOFT DELETE TESTS
// ============================================================================

func TestPost_SoftDelete(t *testing.T) {
	t.Run("marks post as deleted", func(t *testing.T) {
		post := &Post{
			ID:       primitive.NewObjectID(),
			IsActive: true,
		}

		post.SoftDelete()

		assert.True(t, post.IsDeleted)
		assert.False(t, post.IsActive)
		assert.NotNil(t, post.DeletedAt)
	})
}

// ============================================================================
// HASHTAG EXTRACTION TESTS
// ============================================================================

func TestExtractHashtags(t *testing.T) {
	t.Run("extracts single hashtag", func(t *testing.T) {
		text := "Check out this #skating video"
		tags := ExtractHashtags(text)
		assert.Len(t, tags, 1)
		assert.Contains(t, tags, "skating")
	})

	t.Run("extracts multiple hashtags", func(t *testing.T) {
		text := "#skating #inline #aggressive #park"
		tags := ExtractHashtags(text)
		assert.Len(t, tags, 4)
		assert.Contains(t, tags, "skating")
		assert.Contains(t, tags, "inline")
		assert.Contains(t, tags, "aggressive")
		assert.Contains(t, tags, "park")
	})

	t.Run("removes duplicates", func(t *testing.T) {
		text := "#skating is fun #skating"
		tags := ExtractHashtags(text)
		assert.Len(t, tags, 1)
	})

	t.Run("handles text without hashtags", func(t *testing.T) {
		text := "Just a normal text without hashtags"
		tags := ExtractHashtags(text)
		assert.Empty(t, tags)
	})

	t.Run("extracts hashtag at beginning", func(t *testing.T) {
		text := "#first hashtag test"
		tags := ExtractHashtags(text)
		assert.Len(t, tags, 1)
		assert.Equal(t, "first", tags[0])
	})

	t.Run("handles empty string", func(t *testing.T) {
		tags := ExtractHashtags("")
		assert.Empty(t, tags)
	})
}

// ============================================================================
// MENTION EXTRACTION TESTS
// ============================================================================

func TestExtractMentions(t *testing.T) {
	t.Run("extracts single mention", func(t *testing.T) {
		text := "Thanks @johndoe for the help"
		mentions := ExtractMentions(text)
		assert.Len(t, mentions, 1)
		assert.Contains(t, mentions, "johndoe")
	})

	t.Run("extracts multiple mentions", func(t *testing.T) {
		text := "@user1 @user2 @user3 are awesome"
		mentions := ExtractMentions(text)
		assert.Len(t, mentions, 3)
	})

	t.Run("removes duplicates", func(t *testing.T) {
		text := "@johndoe mentioned @johndoe again"
		mentions := ExtractMentions(text)
		assert.Len(t, mentions, 1)
	})

	t.Run("handles text without mentions", func(t *testing.T) {
		text := "Just a normal text"
		mentions := ExtractMentions(text)
		assert.Empty(t, mentions)
	})

	t.Run("handles empty string", func(t *testing.T) {
		mentions := ExtractMentions("")
		assert.Empty(t, mentions)
	})
}

// ============================================================================
// POST TAG EXTRACTION FROM CAPTION
// ============================================================================

func TestPost_ExtractAndSetTagsFromCaption(t *testing.T) {
	t.Run("extracts tags from caption", func(t *testing.T) {
		post := &Post{
			Caption: "Amazing #skating session at the #park",
			Tags:    []string{},
		}

		post.ExtractAndSetTagsFromCaption()

		assert.Len(t, post.Tags, 2)
		assert.Contains(t, post.Tags, "skating")
		assert.Contains(t, post.Tags, "park")
	})

	t.Run("merges with existing tags", func(t *testing.T) {
		post := &Post{
			Caption: "New #skating video",
			Tags:    []string{"inline"},
		}

		post.ExtractAndSetTagsFromCaption()

		assert.Len(t, post.Tags, 2)
		assert.Contains(t, post.Tags, "inline")
		assert.Contains(t, post.Tags, "skating")
	})

	t.Run("avoids duplicates", func(t *testing.T) {
		post := &Post{
			Caption: "#skating is great",
			Tags:    []string{"skating"},
		}

		post.ExtractAndSetTagsFromCaption()

		assert.Len(t, post.Tags, 1)
	})

	t.Run("handles empty caption", func(t *testing.T) {
		post := &Post{
			Caption: "",
			Tags:    []string{},
		}

		post.ExtractAndSetTagsFromCaption()

		assert.Empty(t, post.Tags)
	})
}

// ============================================================================
// LIKE VALIDATION TESTS
// ============================================================================

func TestLike_Validate(t *testing.T) {
	t.Run("valid like", func(t *testing.T) {
		like := &Like{
			PostID: primitive.NewObjectID(),
			UserID: primitive.NewObjectID(),
		}
		err := like.Validate()
		assert.NoError(t, err)
	})

	t.Run("missing postID", func(t *testing.T) {
		like := &Like{
			UserID: primitive.NewObjectID(),
		}
		err := like.Validate()
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "postId")
	})

	t.Run("missing userID", func(t *testing.T) {
		like := &Like{
			PostID: primitive.NewObjectID(),
		}
		err := like.Validate()
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "userId")
	})
}

// ============================================================================
// STORY VALIDATION TESTS
// ============================================================================

func TestStory_Validate(t *testing.T) {
	t.Run("valid story", func(t *testing.T) {
		story := &Story{
			UserID:    primitive.NewObjectID(),
			MediaURL:  "http://example.com/story.jpg",
			MediaType: StoryMediaTypeImage,
		}
		err := story.Validate()
		assert.NoError(t, err)
	})

	t.Run("missing userID", func(t *testing.T) {
		story := &Story{
			MediaURL:  "http://example.com/story.jpg",
			MediaType: StoryMediaTypeImage,
		}
		err := story.Validate()
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "userId")
	})

	t.Run("missing mediaUrl", func(t *testing.T) {
		story := &Story{
			UserID:    primitive.NewObjectID(),
			MediaType: StoryMediaTypeImage,
		}
		err := story.Validate()
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "mediaUrl")
	})

	t.Run("invalid mediaType", func(t *testing.T) {
		story := &Story{
			UserID:    primitive.NewObjectID(),
			MediaURL:  "http://example.com/story.jpg",
			MediaType: "invalid",
		}
		err := story.Validate()
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "invalid media type")
	})

	t.Run("caption too long", func(t *testing.T) {
		longCaption := make([]byte, 201)
		for i := range longCaption {
			longCaption[i] = 'a'
		}
		story := &Story{
			UserID:    primitive.NewObjectID(),
			MediaURL:  "http://example.com/story.jpg",
			MediaType: StoryMediaTypeImage,
			Caption:   string(longCaption),
		}
		err := story.Validate()
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "caption too long")
	})
}

// ============================================================================
// STORY HELPER METHODS TESTS
// ============================================================================

func TestStory_IsExpired(t *testing.T) {
	t.Run("expired story", func(t *testing.T) {
		story := &Story{
			ExpiresAt: time.Now().Add(-1 * time.Hour),
		}
		assert.True(t, story.IsExpired())
	})

	t.Run("active story", func(t *testing.T) {
		story := &Story{
			ExpiresAt: time.Now().Add(12 * time.Hour),
		}
		assert.False(t, story.IsExpired())
	})
}

func TestStory_IncrementViews(t *testing.T) {
	story := &Story{ViewsCount: 0}
	story.IncrementViews()
	assert.Equal(t, 1, story.ViewsCount)
	story.IncrementViews()
	assert.Equal(t, 2, story.ViewsCount)
}

func TestStory_SetDefaults(t *testing.T) {
	story := &Story{
		UserID:   primitive.NewObjectID(),
		MediaURL: "http://example.com/story.jpg",
	}

	story.SetDefaults()

	assert.False(t, story.CreatedAt.IsZero())
	assert.True(t, story.ExpiresAt.After(time.Now()))
	assert.True(t, story.IsActive)
	assert.False(t, story.IsDeleted)
	assert.Equal(t, 0, story.ViewsCount)
	assert.Equal(t, StoryVisibilityFollowers, story.Visibility)
}

// ============================================================================
// FOLLOW VALIDATION TESTS
// ============================================================================

func TestFollow_Validate(t *testing.T) {
	t.Run("valid follow", func(t *testing.T) {
		follow := &Follow{
			FollowerID:  primitive.NewObjectID(),
			FollowingID: primitive.NewObjectID(),
		}
		err := follow.Validate()
		assert.NoError(t, err)
	})

	t.Run("missing followerID", func(t *testing.T) {
		follow := &Follow{
			FollowingID: primitive.NewObjectID(),
		}
		err := follow.Validate()
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "followerId")
	})

	t.Run("cannot follow yourself", func(t *testing.T) {
		userID := primitive.NewObjectID()
		follow := &Follow{
			FollowerID:  userID,
			FollowingID: userID,
		}
		err := follow.Validate()
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "follow yourself")
	})
}

func TestFollow_SetDefaults(t *testing.T) {
	follow := &Follow{
		FollowerID:  primitive.NewObjectID(),
		FollowingID: primitive.NewObjectID(),
	}

	follow.SetDefaults()

	assert.False(t, follow.CreatedAt.IsZero())
	assert.Equal(t, FollowStatusAccepted, follow.Status)
}

// ============================================================================
// SAVED POST VALIDATION TESTS
// ============================================================================

func TestSavedPost_SetDefaults(t *testing.T) {
	savedPost := &SavedPost{
		PostID: primitive.NewObjectID(),
		UserID: primitive.NewObjectID(),
	}

	savedPost.SetDefaults()

	assert.False(t, savedPost.CreatedAt.IsZero())
}

// ============================================================================
// ADDITIONAL BENCHMARKS
// ============================================================================

func BenchmarkExtractHashtags(b *testing.B) {
	text := "#skating #inline #aggressive #park #street Check out this amazing #trick"
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		ExtractHashtags(text)
	}
}

func BenchmarkExtractMentions(b *testing.B) {
	text := "Thanks @user1 @user2 @user3 for the awesome session with @user4"
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		ExtractMentions(text)
	}
}

func BenchmarkPost_Validate(b *testing.B) {
	post := &Post{
		UserID:    primitive.NewObjectID(),
		MediaURLs: []string{"http://example.com/img.jpg"},
		Caption:   "Test caption",
	}
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		post.Validate()
	}
}

func BenchmarkPost_SetDefaults(b *testing.B) {
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		post := &Post{
			UserID:    primitive.NewObjectID(),
			MediaURLs: []string{"http://example.com/img.jpg"},
		}
		post.SetDefaults()
	}
}
