package storage

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"io"
	"strings"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

// S3Storage implements Storage interface using AWS S3 or S3-compatible storage (MinIO)
type S3Storage struct {
	client    *s3.Client
	bucket    string
	region    string
	cdnDomain string // Optional CDN domain for public URLs
	endpoint  string // For MinIO or custom S3 endpoints
}

// NewS3Storage creates a new S3 storage instance
func NewS3Storage(bucket, region, accessKey, secretKey, endpoint, cdnDomain string) (*S3Storage, error) {
	// Build AWS config
	var cfg aws.Config
	var err error

	if endpoint != "" {
		// Custom endpoint (MinIO, DigitalOcean Spaces, etc.)
		customResolver := aws.EndpointResolverWithOptionsFunc(
			func(service, region string, options ...interface{}) (aws.Endpoint, error) {
				return aws.Endpoint{
					URL:               endpoint,
					HostnameImmutable: true,
				}, nil
			},
		)

		cfg, err = config.LoadDefaultConfig(context.Background(),
			config.WithRegion(region),
			config.WithEndpointResolverWithOptions(customResolver),
			config.WithCredentialsProvider(credentials.NewStaticCredentialsProvider(accessKey, secretKey, "")),
		)
	} else {
		// Standard AWS S3
		cfg, err = config.LoadDefaultConfig(context.Background(),
			config.WithRegion(region),
			config.WithCredentialsProvider(credentials.NewStaticCredentialsProvider(accessKey, secretKey, "")),
		)
	}

	if err != nil {
		return nil, fmt.Errorf("failed to load AWS config: %w", err)
	}

	// Create S3 client
	client := s3.NewFromConfig(cfg, func(o *s3.Options) {
		if endpoint != "" {
			o.UsePathStyle = true // Required for MinIO
		}
	})

	return &S3Storage{
		client:    client,
		bucket:    bucket,
		region:    region,
		cdnDomain: strings.TrimSuffix(cdnDomain, "/"),
		endpoint:  endpoint,
	}, nil
}

// Save stores a file to S3
func (s *S3Storage) Save(ctx context.Context, file io.Reader, path string, metadata Metadata) (*SaveResult, error) {
	// Calculate hash while reading
	hash := sha256.New()
	teeReader := io.TeeReader(file, hash)

	// Read entire file into memory (needed for S3 upload)
	// TODO: For large files, use multipart upload
	data, err := io.ReadAll(teeReader)
	if err != nil {
		return nil, fmt.Errorf("failed to read file: %w", err)
	}

	// Ensure path doesn't start with /
	path = strings.TrimPrefix(path, "/")

	// Build S3 input
	input := &s3.PutObjectInput{
		Bucket:      aws.String(s.bucket),
		Key:         aws.String(path),
		Body:        strings.NewReader(string(data)),
		ContentType: aws.String(metadata.ContentType),
	}

	// Add custom metadata
	if len(metadata.Custom) > 0 {
		input.Metadata = metadata.Custom
	}

	// Upload to S3
	_, err = s.client.PutObject(ctx, input)
	if err != nil {
		return nil, fmt.Errorf("failed to upload to S3: %w", err)
	}

	// Calculate hash
	hashString := hex.EncodeToString(hash.Sum(nil))

	// Build public URL
	publicURL := s.GetPublicURL(path)

	return &SaveResult{
		Path:      path,
		PublicURL: publicURL,
		Size:      int64(len(data)),
		Hash:      hashString,
	}, nil
}

// Get retrieves a file from S3
func (s *S3Storage) Get(ctx context.Context, path string) (io.ReadCloser, error) {
	// Ensure path doesn't start with /
	path = strings.TrimPrefix(path, "/")

	// Get object from S3
	result, err := s.client.GetObject(ctx, &s3.GetObjectInput{
		Bucket: aws.String(s.bucket),
		Key:    aws.String(path),
	})
	if err != nil {
		return nil, fmt.Errorf("failed to get object from S3: %w", err)
	}

	return result.Body, nil
}

// Delete removes a file from S3
func (s *S3Storage) Delete(ctx context.Context, path string) error {
	// Ensure path doesn't start with /
	path = strings.TrimPrefix(path, "/")

	// Delete object from S3
	_, err := s.client.DeleteObject(ctx, &s3.DeleteObjectInput{
		Bucket: aws.String(s.bucket),
		Key:    aws.String(path),
	})
	if err != nil {
		return fmt.Errorf("failed to delete object from S3: %w", err)
	}

	return nil
}

// Exists checks if a file exists in S3
func (s *S3Storage) Exists(ctx context.Context, path string) (bool, error) {
	// Ensure path doesn't start with /
	path = strings.TrimPrefix(path, "/")

	// Head object to check existence
	_, err := s.client.HeadObject(ctx, &s3.HeadObjectInput{
		Bucket: aws.String(s.bucket),
		Key:    aws.String(path),
	})
	if err != nil {
		// Check if error is "not found"
		if strings.Contains(err.Error(), "NotFound") || strings.Contains(err.Error(), "404") {
			return false, nil
		}
		return false, fmt.Errorf("failed to check object: %w", err)
	}

	return true, nil
}

// GetPublicURL returns the public URL for a file
func (s *S3Storage) GetPublicURL(path string) string {
	// Ensure path doesn't start with /
	path = strings.TrimPrefix(path, "/")

	// Use CDN domain if configured
	if s.cdnDomain != "" {
		return fmt.Sprintf("%s/%s", s.cdnDomain, path)
	}

	// Use custom endpoint if configured (MinIO)
	if s.endpoint != "" {
		return fmt.Sprintf("%s/%s/%s", s.endpoint, s.bucket, path)
	}

	// Default AWS S3 URL
	return fmt.Sprintf("https://%s.s3.%s.amazonaws.com/%s", s.bucket, s.region, path)
}

// GetStorageType returns the storage type
func (s *S3Storage) GetStorageType() string {
	if s.endpoint != "" {
		return "s3-compatible"
	}
	return "s3"
}
