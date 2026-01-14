package main

import (
	"context"
	"fmt"
	"os"
	"strings"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

// ANSI color codes
const (
	colorReset  = "\033[0m"
	colorRed    = "\033[31m"
	colorGreen  = "\033[32m"
	colorYellow = "\033[33m"
	colorBlue   = "\033[34m"
)

func main() {
	fmt.Println(colorBlue + "================================" + colorReset)
	fmt.Println(colorBlue + "S3 Connection Test" + colorReset)
	fmt.Println(colorBlue + "================================" + colorReset)
	fmt.Println()

	// Read configuration from environment
	bucket := os.Getenv("MEDIA_S3_BUCKET")
	region := os.Getenv("MEDIA_S3_REGION")
	accessKey := os.Getenv("MEDIA_S3_ACCESS_KEY")
	secretKey := os.Getenv("MEDIA_S3_SECRET_KEY")
	endpoint := os.Getenv("MEDIA_S3_ENDPOINT")

	// Validate required variables
	if bucket == "" || region == "" || accessKey == "" || secretKey == "" {
		printError("Missing required environment variables")
		fmt.Println(colorYellow + "Required variables:" + colorReset)
		fmt.Println("  - MEDIA_S3_BUCKET")
		fmt.Println("  - MEDIA_S3_REGION")
		fmt.Println("  - MEDIA_S3_ACCESS_KEY")
		fmt.Println("  - MEDIA_S3_SECRET_KEY")
		fmt.Println()
		fmt.Println(colorYellow + "Optional:" + colorReset)
		fmt.Println("  - MEDIA_S3_ENDPOINT (for MinIO or custom S3)")
		os.Exit(1)
	}

	// Print configuration
	printInfo("Configuration:")
	fmt.Printf("  Bucket:     %s\n", bucket)
	fmt.Printf("  Region:     %s\n", region)
	fmt.Printf("  Access Key: %s***\n", accessKey[:min(10, len(accessKey))])
	fmt.Printf("  Endpoint:   %s\n", getEndpointDisplay(endpoint))
	fmt.Println()

	// Test 1: Create S3 client
	printTest("Creating S3 client...")
	client, err := createS3Client(region, accessKey, secretKey, endpoint)
	if err != nil {
		printError(fmt.Sprintf("Failed to create S3 client: %v", err))
		os.Exit(1)
	}
	printSuccess("S3 client created")

	// Test 2: List buckets
	printTest("Listing buckets...")
	ctx := context.Background()
	listResult, err := client.ListBuckets(ctx, &s3.ListBucketsInput{})
	if err != nil {
		printError(fmt.Sprintf("Failed to list buckets: %v", err))
		printInfo("Make sure your credentials have s3:ListAllMyBuckets permission")
		os.Exit(1)
	}
	printSuccess(fmt.Sprintf("Found %d bucket(s)", len(listResult.Buckets)))

	// Check if our bucket exists
	bucketExists := false
	for _, b := range listResult.Buckets {
		if *b.Name == bucket {
			bucketExists = true
			break
		}
	}

	if bucketExists {
		printSuccess(fmt.Sprintf("Bucket '%s' exists", bucket))
	} else {
		printWarning(fmt.Sprintf("Bucket '%s' not found in list", bucket))
		printInfo("Available buckets:")
		for _, b := range listResult.Buckets {
			fmt.Printf("  - %s\n", *b.Name)
		}
	}

	// Test 3: Check bucket location
	printTest("Checking bucket location...")
	locationResult, err := client.GetBucketLocation(ctx, &s3.GetBucketLocationInput{
		Bucket: aws.String(bucket),
	})
	if err != nil {
		printError(fmt.Sprintf("Failed to get bucket location: %v", err))
		printInfo("Make sure the bucket exists and you have access")
		os.Exit(1)
	}

	bucketRegion := string(locationResult.LocationConstraint)
	if bucketRegion == "" {
		bucketRegion = "us-east-1" // Default region
	}

	if bucketRegion != region {
		printWarning(fmt.Sprintf("Bucket region (%s) doesn't match configured region (%s)", bucketRegion, region))
		printInfo("Update MEDIA_S3_REGION in .env to match")
	} else {
		printSuccess(fmt.Sprintf("Bucket region: %s", bucketRegion))
	}

	// Test 4: Upload test file
	printTest("Uploading test file...")
	testKey := fmt.Sprintf("_test/%d.txt", time.Now().Unix())
	testContent := "StreetCore S3 Connection Test"

	_, err = client.PutObject(ctx, &s3.PutObjectInput{
		Bucket:      aws.String(bucket),
		Key:         aws.String(testKey),
		Body:        strings.NewReader(testContent),
		ContentType: aws.String("text/plain"),
	})
	if err != nil {
		printError(fmt.Sprintf("Failed to upload test file: %v", err))
		printInfo("Make sure you have s3:PutObject permission")
		os.Exit(1)
	}
	printSuccess(fmt.Sprintf("Test file uploaded: %s", testKey))

	// Test 5: Download test file
	printTest("Downloading test file...")
	getResult, err := client.GetObject(ctx, &s3.GetObjectInput{
		Bucket: aws.String(bucket),
		Key:    aws.String(testKey),
	})
	if err != nil {
		printError(fmt.Sprintf("Failed to download test file: %v", err))
		printInfo("Make sure you have s3:GetObject permission")
		os.Exit(1)
	}
	defer getResult.Body.Close()
	printSuccess("Test file downloaded successfully")

	// Test 6: Delete test file
	printTest("Deleting test file...")
	_, err = client.DeleteObject(ctx, &s3.DeleteObjectInput{
		Bucket: aws.String(bucket),
		Key:    aws.String(testKey),
	})
	if err != nil {
		printError(fmt.Sprintf("Failed to delete test file: %v", err))
		printInfo("Make sure you have s3:DeleteObject permission")
		os.Exit(1)
	}
	printSuccess("Test file deleted successfully")

	// Test 7: List objects (optional)
	printTest("Listing objects in bucket...")
	listObjectsResult, err := client.ListObjectsV2(ctx, &s3.ListObjectsV2Input{
		Bucket:  aws.String(bucket),
		MaxKeys: aws.Int32(10),
	})
	if err != nil {
		printError(fmt.Sprintf("Failed to list objects: %v", err))
		printInfo("Make sure you have s3:ListBucket permission")
	} else {
		printSuccess(fmt.Sprintf("Found %d object(s) in bucket", *listObjectsResult.KeyCount))
		if *listObjectsResult.KeyCount > 0 {
			printInfo("Sample objects:")
			for i, obj := range listObjectsResult.Contents {
				if i >= 5 {
					break
				}
				fmt.Printf("  - %s (%d bytes)\n", *obj.Key, obj.Size)
			}
		}
	}

	// Summary
	fmt.Println()
	fmt.Println(colorGreen + "================================" + colorReset)
	fmt.Println(colorGreen + "✓ All tests passed!" + colorReset)
	fmt.Println(colorGreen + "================================" + colorReset)
	fmt.Println()
	printInfo("S3 storage is ready to use")
	printInfo("Update .env with:")
	fmt.Println("  FEATURE_S3_STORAGE=true")
	fmt.Println("  or")
	fmt.Println("  FEATURE_HYBRID_STORAGE=true")
}

func createS3Client(region, accessKey, secretKey, endpoint string) (*s3.Client, error) {
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
		return nil, err
	}

	// Create S3 client
	client := s3.NewFromConfig(cfg, func(o *s3.Options) {
		if endpoint != "" {
			o.UsePathStyle = true // Required for MinIO
		}
	})

	return client, nil
}

func getEndpointDisplay(endpoint string) string {
	if endpoint == "" {
		return "Default (AWS S3)"
	}
	return endpoint
}

func printTest(msg string) {
	fmt.Printf("%s[TEST]%s %s\n", colorBlue, colorReset, msg)
}

func printSuccess(msg string) {
	fmt.Printf("%s✓ %s%s\n", colorGreen, msg, colorReset)
}

func printError(msg string) {
	fmt.Printf("%s✗ %s%s\n", colorRed, msg, colorReset)
}

func printWarning(msg string) {
	fmt.Printf("%s⚠ %s%s\n", colorYellow, msg, colorReset)
}

func printInfo(msg string) {
	fmt.Printf("%sℹ %s%s\n", colorBlue, msg, colorReset)
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
