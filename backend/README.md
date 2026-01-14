# Street Core Backend

A production-ready Go REST API backend for the FitRiders social fitness platform. Built with clean architecture, comprehensive security features, and scalable design patterns.

## Features

- **Authentication & Authorization**
  - JWT-based authentication with token versioning
  - OAuth 2.0 support (Google, Facebook)
  - Two-Factor Authentication (TOTP)
  - Role-based access control (RBAC)
  - Token revocation and refresh token rotation

- **Security**
  - Rate limiting (per-endpoint configurable)
  - CSRF protection
  - Input sanitization (XSS prevention)
  - Security headers (HSTS, CSP, X-Frame-Options)
  - Password strength validation
  - Brute force protection

- **Social Features**
  - User profiles with avatars
  - Posts with media (images, videos, carousels)
  - Comments and replies
  - Likes and reactions
  - Follow/follower system
  - Stories (24h expiration)
  - Saved posts
  - Privacy settings

- **Infrastructure**
  - MongoDB with generic repository pattern
  - Structured logging (file + MongoDB)
  - Prometheus metrics
  - Health checks
  - Graceful shutdown

## Tech Stack

| Category | Technology |
|----------|------------|
| Language | Go 1.25+ |
| Framework | Gin |
| Database | MongoDB |
| Authentication | JWT, OAuth 2.0 |
| Email | SendGrid / SMTP |
| Metrics | Prometheus |

## Quick Start

### Prerequisites

- Go 1.25 or higher
- MongoDB 6.0+
- Make (optional, for using Makefile commands)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/your-org/street-core.git
cd street-core/backend
```

2. Copy environment file:
```bash
cp .env.example .env
```

3. Configure environment variables (see [Configuration](#configuration))

4. Install dependencies:
```bash
go mod download
```

5. Run the server:
```bash
go run main.go
# or with make
make run
```

The server will start on `http://localhost:3000` (or configured port).

## Configuration

### Required Environment Variables

```env
# Server
ENV=development
PORT=3000

# JWT (REQUIRED - generate with: openssl rand -hex 32)
JWT_SECRET=your-secure-secret-key

# MongoDB (REQUIRED)
MONGO_URI=mongodb://localhost:27017
DB_NAME=fitriders
```

### Optional Environment Variables

```env
# JWT Expiration
JWT_EXP_HOURS=1
REFRESH_TOKEN_EXP_DAYS=7

# OAuth (for social login)
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
GOOGLE_REDIRECT_URI=
FACEBOOK_APP_ID=
FACEBOOK_APP_SECRET=
FACEBOOK_REDIRECT_URI=

# Security
ALLOWED_ORIGINS=http://localhost:3000
ENABLE_HSTS=true
HSTS_MAX_AGE=31536000

# Rate Limiting
RATE_LIMIT_ENABLED=true
RATE_LIMIT_GENERAL_RATE=1000
RATE_LIMIT_AUTH_RATE=10

# Logging
LOG_LEVEL=info
LOG_FORMAT=pretty
LOG_TO_FILE=false
LOG_TO_MONGO=true

# Email (SendGrid)
SENDGRID_API_KEY=
EMAIL_FROM=noreply@yourapp.com

# 2FA
TWO_FACTOR_ENCRYPTION_KEY=your-32-byte-encryption-key
```

## Project Structure

```
backend/
├── main.go                 # Application entry point
├── app/                    # DI container & DTOs
│   ├── container.go        # Dependency injection
│   └── dto/                # Request/Response DTOs
├── config/                 # Configuration management
├── features/               # Feature modules
│   ├── auth/               # Authentication
│   └── profile/            # User profiles & social
├── handlers/               # HTTP handlers
├── middlewares/            # HTTP middlewares
├── models/                 # Data models
├── pkg/                    # Shared packages
│   ├── repository/         # Generic repository
│   ├── email/              # Email service
│   ├── errors/             # Error handling
│   └── ...
├── routes/                 # Route definitions
├── services/               # Business logic
├── tests/                  # Centralized tests
│   ├── helpers/            # Test utilities
│   ├── mocks/              # Mock implementations
│   └── integration/        # Integration tests
└── utils/                  # Utility functions
```

## Logging \u0026 Translation Standards

### Logging with Tags

The backend uses `utils.AppLogger` with tag support for structured, filterable logging:

```go
import "backend/utils"

// Basic logging
utils.InfoWithTag("Auth", "User logged in", map[string]interface{}{
    "user_id": userID,
    "ip": clientIP,
})

// Error logging
utils.ErrorWithTag("Competition", "Failed to create competition", map[string]interface{}{
    "error": err.Error(),
    "user_id": userID,
})
```

**Available Methods:**
- `DebugWithTag(tag, message, fields)` - Debug information
- `InfoWithTag(tag, message, fields)` - General information
- `WarnWithTag(tag, message, fields)` - Warnings
- `ErrorWithTag(tag, message, fields)` - Errors
- `FatalWithTag(tag, message, fields)` - Fatal errors (exits program)

**Tag Naming Convention:**
- Use PascalCase: `Auth`, `Competition`, `UserService`
- Be descriptive but concise
- Match module/feature names

### Translation Keys

Translation keys are centralized in `models/messages.go` with module-specific extensions:

**Central Keys** (`models/messages.go`):
```go
const (
    LoginSuccessful = "login.successful"
    UserNotFound = "user.not.found"
    ServerError = "server.error"
)
```

**Module Keys** (e.g., `features/auth/auth_messages.go`):
```go
package auth

import "backend/models"

// Re-export central keys
const (
    LoginSuccessful = models.LoginSuccessful
)

// Module-specific keys
const (
    TokenGenerated = "auth.token.generated"
    SessionExpired = "auth.session.expired"
)
```

**Usage in API Responses:**
```go
import (
    "backend/models"
    "backend/features/auth"
)

// Success response
c.JSON(200, gin.H{
    "message": auth.LoginSuccessful,
    "data": user,
})

// Error response
c.JSON(404, gin.H{
    "message": models.UserNotFound,
})
```

**Module Message Files:**
- `features/auth/auth_messages.go` - Authentication keys
- `features/competitions/domain/competition_messages.go` - Competition keys
- `features/social/social_messages.go` - Social feature keys

**Key Naming Convention:**
- Format: `module.entity.action` or `module.entity.error`
- Examples: `auth.token.expired`, `competition.heat.started`
- Use dot notation for hierarchy
- Keep keys lowercase with dots


## API Endpoints

### Authentication

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/auth/register` | Register new user |
| POST | `/api/v1/auth/login` | Login |
| POST | `/api/v1/auth/logout` | Logout |
| POST | `/api/v1/auth/refresh` | Refresh token |
| POST | `/api/v1/auth/forgot-password` | Request password reset |
| POST | `/api/v1/auth/reset-password` | Reset password |
| GET | `/api/v1/auth/oauth/google` | Google OAuth |
| GET | `/api/v1/auth/oauth/facebook` | Facebook OAuth |

### Users & Profiles

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/users/me` | Get current user |
| PUT | `/api/v1/users/me` | Update profile |
| GET | `/api/v1/users/:id` | Get user by ID |
| GET | `/api/v1/users/:id/followers` | Get followers |
| GET | `/api/v1/users/:id/following` | Get following |

### Posts

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/posts` | List posts |
| POST | `/api/v1/posts` | Create post |
| GET | `/api/v1/posts/:id` | Get post |
| PUT | `/api/v1/posts/:id` | Update post |
| DELETE | `/api/v1/posts/:id` | Delete post |
| POST | `/api/v1/posts/:id/like` | Like post |
| DELETE | `/api/v1/posts/:id/like` | Unlike post |

### Health & Metrics

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check |
| GET | `/metrics` | Prometheus metrics |

## Testing

### Run All Tests

```bash
make test
# or
go test -v ./...
```

### Run Unit Tests Only

```bash
make test-unit
```

### Run Integration Tests

```bash
make test-integration
```

### Run with Coverage

```bash
make test-coverage
```

Coverage report will be generated at `coverage/coverage.html`.

### Run Benchmarks

```bash
make test-bench
```

## Development

### Code Formatting

```bash
make fmt
```

### Linting

```bash
make lint
```

### Pre-commit Checks

```bash
make pre-commit
```

### Build

```bash
make build
```

Binary will be created at `bin/street-core`.

## Security Considerations

### Production Checklist

- [ ] Set `ENV=production`
- [ ] Generate secure `JWT_SECRET` (min 32 bytes)
- [ ] Enable HTTPS/TLS
- [ ] Configure proper `ALLOWED_ORIGINS`
- [ ] Enable rate limiting
- [ ] Set secure CSP headers
- [ ] Configure MongoDB authentication
- [ ] Use separate encryption keys for 2FA
- [ ] Enable audit logging

### Rate Limits (Default)

| Endpoint Type | Limit |
|---------------|-------|
| General API | 1000/hour |
| Authentication | 10/minute |
| Password Reset | 3/5 minutes |
| File Upload | 10/minute |
| Post Creation | 20/hour |

## Deployment

### Docker

```bash
# Build image
make docker-build

# Run container
make docker-run
```

### Docker Compose

```bash
# Start all services
make docker-compose-up

# Stop all services
make docker-compose-down
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Run tests and linting (`make pre-commit`)
4. Commit your changes
5. Push to the branch
6. Open a Pull Request

## License

This project is proprietary software. All rights reserved.

## Support

For issues and questions, please open an issue on GitHub.
