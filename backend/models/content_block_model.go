package models

// ContentBlock type constants
const (
	ContentBlockTypeText     = "text"
	ContentBlockTypeHeading  = "heading"
	ContentBlockTypeImage    = "image"
	ContentBlockTypeVideo    = "video"
	ContentBlockTypeDocument = "document"
	ContentBlockTypeCode     = "code"
	ContentBlockTypeQuote    = "quote"
	ContentBlockTypeList     = "list"
	ContentBlockTypeEmbed    = "embed"
	ContentBlockTypeAudio    = "audio"
	ContentBlockTypeDivider  = "divider"
	ContentBlockTypeCallout  = "callout"
)

// List type constants
const (
	ListTypeOrdered   = "ordered"
	ListTypeUnordered = "unordered"
)

// Callout type constants
const (
	CalloutTypeInfo    = "info"
	CalloutTypeWarning = "warning"
	CalloutTypeSuccess = "success"
	CalloutTypeError   = "error"
)

// Alignment constants
const (
	AlignmentLeft   = "left"
	AlignmentCenter = "center"
	AlignmentRight  = "right"
)

// Width constants
const (
	WidthFull   = "full"
	WidthLarge  = "large"
	WidthMedium = "medium"
	WidthSmall  = "small"
)

// ContentBlock represents a flexible content block in a lesson
// Can be text, image, video, code, etc.
type ContentBlock struct {
	ID    string `json:"id" bson:"id" validate:"required"`                   // Unique ID within lesson
	Type  string `json:"type" bson:"type" validate:"required"`               // text, heading, image, video, etc.
	Order int    `json:"order" bson:"order" validate:"required,gte=0"`       // Display order

	// Text content (for text, heading, quote, callout)
	Content string `json:"content,omitempty" bson:"content,omitempty"`

	// Heading level (h1-h6)
	Level int `json:"level,omitempty" bson:"level,omitempty" validate:"omitempty,gte=1,lte=6"`

	// URL (for image, video, document, audio, embed)
	Url string `json:"url,omitempty" bson:"url,omitempty" validate:"omitempty,url"`

	// Caption/Alt text
	Caption string `json:"caption,omitempty" bson:"caption,omitempty"`

	// Code-specific
	Language string `json:"language,omitempty" bson:"language,omitempty"` // For code blocks (go, javascript, python, etc.)

	// List-specific
	Items    []string `json:"items,omitempty" bson:"items,omitempty"`                                         // For list blocks
	ListType string   `json:"listType,omitempty" bson:"listType,omitempty" validate:"omitempty,oneof=ordered unordered"` // ordered, unordered

	// Embed-specific
	EmbedType string `json:"embedType,omitempty" bson:"embedType,omitempty"` // youtube, vimeo, codepen, jsfiddle, etc.
	EmbedId   string `json:"embedId,omitempty" bson:"embedId,omitempty"`

	// Callout-specific
	CalloutType string `json:"calloutType,omitempty" bson:"calloutType,omitempty" validate:"omitempty,oneof=info warning success error"` // info, warning, success, error

	// Styling
	Alignment string `json:"alignment,omitempty" bson:"alignment,omitempty" validate:"omitempty,oneof=left center right"` // left, center, right
	Style     string `json:"style,omitempty" bson:"style,omitempty"` // Custom CSS class or style identifier

	// Metadata
	Width string `json:"width,omitempty" bson:"width,omitempty" validate:"omitempty,oneof=full large medium small"` // full, large, medium, small
}

// Resource represents a downloadable file attached to a lesson
type Resource struct {
	ID            string `json:"id" bson:"id" validate:"required"`
	Title         string `json:"title" bson:"title" validate:"required,min=1,max=255"`        // Display title for the resource
	Name          string `json:"name" bson:"name" validate:"required,min=1,max=255"`          // Original filename
	Description   string `json:"description,omitempty" bson:"description,omitempty"`
	Type          string `json:"type" bson:"type" validate:"required,oneof=pdf doc docx ppt pptx xls xlsx zip image video audio"`
	Url           string `json:"url" bson:"url" validate:"required,url"`
	FileSize      int64  `json:"fileSize" bson:"fileSize"`      // Bytes
	DownloadCount int    `json:"downloadCount" bson:"downloadCount"`
}

// AddContentBlockRequest represents the request to add a content block
type AddContentBlockRequest struct {
	Type        string   `json:"type" binding:"required"`
	Order       int      `json:"order" binding:"required,gte=0"`
	Content     string   `json:"content,omitempty"`
	Level       int      `json:"level,omitempty" binding:"omitempty,gte=1,lte=6"`
	Url         string   `json:"url,omitempty" binding:"omitempty,url"`
	Caption     string   `json:"caption,omitempty"`
	Language    string   `json:"language,omitempty"`
	Items       []string `json:"items,omitempty"`
	ListType    string   `json:"listType,omitempty" binding:"omitempty,oneof=ordered unordered"`
	EmbedType   string   `json:"embedType,omitempty"`
	EmbedId     string   `json:"embedId,omitempty"`
	CalloutType string   `json:"calloutType,omitempty" binding:"omitempty,oneof=info warning success error"`
	Alignment   string   `json:"alignment,omitempty" binding:"omitempty,oneof=left center right"`
	Width       string   `json:"width,omitempty" binding:"omitempty,oneof=full large medium small"`
}

// UpdateContentBlockRequest represents the request to update a content block
type UpdateContentBlockRequest struct {
	Type        *string   `json:"type,omitempty"`
	Order       *int      `json:"order,omitempty" binding:"omitempty,gte=0"`
	Content     *string   `json:"content,omitempty"`
	Level       *int      `json:"level,omitempty" binding:"omitempty,gte=1,lte=6"`
	Url         *string   `json:"url,omitempty" binding:"omitempty,url"`
	Caption     *string   `json:"caption,omitempty"`
	Language    *string   `json:"language,omitempty"`
	Items       *[]string `json:"items,omitempty"`
	ListType    *string   `json:"listType,omitempty" binding:"omitempty,oneof=ordered unordered"`
	EmbedType   *string   `json:"embedType,omitempty"`
	EmbedId     *string   `json:"embedId,omitempty"`
	CalloutType *string   `json:"calloutType,omitempty" binding:"omitempty,oneof=info warning success error"`
	Alignment   *string   `json:"alignment,omitempty" binding:"omitempty,oneof=left center right"`
	Width       *string   `json:"width,omitempty" binding:"omitempty,oneof=full large medium small"`
}

// ReorderContentBlocksRequest represents the request to reorder content blocks
type ReorderContentBlocksRequest struct {
	BlockOrders []BlockOrder `json:"blockOrders" binding:"required,min=1"`
}

// BlockOrder represents a block ID and its new order
type BlockOrder struct {
	BlockID string `json:"blockId" binding:"required"`
	Order   int    `json:"order" binding:"required,gte=0"`
}
