# StreetCore - Urban Sports Platform
(inline aggressive skates, bmx, skate, scooter, )
## Project Overview

**Version**: 0.1
**Architecture**: Monolith by Features

## What This Project Does

StreetCore is an **urban sports competition aggregator** platform with:
- **Competition Discovery**: See ALL competitions (internal + external)
- User authentication & profiles
- Competition management (full lifecycle)
- External competition registration (via links)
- Multi-language support (ES primary)
- 8 visual themes

### 🎯 Core Mission

**StreetCore aggregates ALL urban sports competitions**, whether managed in-app or externally.

**Competition Types**:
1. **Internal**: Full management in StreetCore (registration, scoring, results)
2. **External**: Competition info displayed, registration via external link to official site

**Why?** Centralize discovery → More visibility → More participation → Stronger community

## Current Priorities

All modules complete. Future enhancements:
1. **Performance** - Redis caching, query optimization
2. **Infrastructure** - Secrets management (Vault)
3. **Scaling** - Horizontal scaling preparation

## Architecture Principles

### Monolith by Features (Backend & Frontend)

**Core Principle**: 1 Feature = 1 Folder. Everything related to a feature lives together.

```
features/
├── auth/           # All auth code here
├── competitions/   # All competitions code here
├── clubs/          # All clubs code here
└── [feature]/      # Everything in one place
```

**Dependency Flow**:
```
Handler/Page → Service → Repository/API
     ↓            ↓           ↓
   (HTTP)    (Business)   (Data)
```

**Enfoque Híbrido** (ver ADR-005):
- **Flat (simple)**: auth, clubs, events, profile, schools, chat, athlete, calendar
- **Hexagonal (complejo)**: competitions, market

**Critical Rules**:
- Feature isolation (features don't import from each other unless necessary)
- Shared code in core/pkg only
- Elegir estructura según complejidad (ver criterios en ADR-005)

## 🔴 GOLDEN RULES - NON-NEGOTIABLE

### 1. ALL List Endpoints MUST Have Pagination

**Backend**: Every endpoint that returns a list MUST implement pagination with limits.

```go
// ✅ REQUIRED pattern
pagination, err := middlewares.ParsePagination(c)
results, total, err := service.List(ctx, pagination.Page, pagination.Limit, filters)

// ❌ FORBIDDEN
allResults := service.GetAll(ctx) // NO LIMITS = FUTURE DISASTER
```

**Limits**:
- Standard: 20/page, max 100
- Heavy queries: 10/page, max 50
- Admin: 50/page, max 200

**Why?** Prevents performance collapse as data grows.

### 2. Competition Aggregation Philosophy

**StreetCore shows ALL competitions**, not just those managed in-app.

**Implementation Requirements**:

**Backend Model**:
```go
type Competition struct {
    RegistrationType string // "internal" | "external"
    ExternalURL      string // For external competitions
    // ... other fields
}
```

**Frontend Logic**:
```dart
if (competition.registrationType == 'internal') {
    // In-app registration
    showRegistrationForm();
} else {
    // Redirect to external site
    launchURL(competition.externalURL);
}
```

**Content Display**:
- Internal: Full details, in-app registration, scoring, results
- External: Info (date, location, discipline) + "Register Here" button → external link

**Goal**: Be the go-to place to discover ALL urban sports competitions, building network effects.

### Backend Structure (Go)
```
backend/
├── main.go
├── config/               # Configuration
├── pkg/                  # Shared utilities
├── features/             # Business features
│   │
│   │ FLAT (Simple) ─────────────────────
│   ├── auth/
│   │   ├── model.go      # Entities
│   │   ├── dto.go        # Request/Response
│   │   ├── repository.go # Data access
│   │   ├── service.go    # Business logic
│   │   ├── handler.go    # HTTP handlers
│   │   └── routes.go     # Route definitions
│   ├── clubs/            # Flat
│   ├── events/           # Flat
│   ├── profile/          # Flat
│   │
│   │ HEXAGONAL (Complex) ───────────────
│   ├── competitions/
│   │   ├── domain/entities/
│   │   ├── domain/repositories/
│   │   ├── application/usecases/
│   │   ├── infrastructure/http/handlers/
│   │   └── infrastructure/persistence/mongodb/
│   └── market/           # Hexagonal
│
├── admin/                # Admin module
├── routes/               # Main router
└── tests/                # Centralized tests
```

### Frontend Structure (Flutter)
```
lib/
├── main.dart
├── config/               # App configuration
├── core/                 # Shared utilities
│   ├── di/               # Dependency injection
│   ├── theme/            # 8 visual themes
│   ├── router/           # Navigation
│   ├── services/         # API service (base)
│   ├── widgets/          # Shared widgets
│   └── lang/             # i18n
├── features/             # Business features (Monolith by Features)
│   ├── auth/
│   │   ├── models/       # User, AuthTokens
│   │   ├── services/     # AuthService, AuthRepository
│   │   ├── bloc/         # AuthCubit + States
│   │   ├── pages/        # LoginPage, RegisterPage
│   │   └── widgets/      # Feature-specific widgets
│   ├── profile/          # User profiles, posts, social
│   ├── competitions/     # Competitions, judges, scoring
│   └── public/           # Core public pages (home, legal, contact, auth)
├── admin/                # Admin module (separate)
└── dev/                  # Dev utilities
```

### Public Pages Architecture

Each feature module that has public pages exports them through a centralized routing system:

```
core/router/
├── app_routes.dart         # Route path constants
├── navigation_config.dart  # PublicPage enum + NavigationConfig
├── public_routes.dart      # Aggregates all public routes
└── private_routes.dart     # Aggregates all private routes

features/
├── clubs/clubs_routes.dart           # publicClubRoutes, privateClubRoutes
├── competitions/competition_routes.dart  # publicCompetitionRoutes, privateCompetitionRoutes
├── events/events_routes.dart         # publicEventRoutes
├── athletes/athletes_routes.dart     # publicAthleteRoutes
└── market/market_routes.dart         # publicMarketRoutes
```

All public pages use `PublicLayout` with `activePage` parameter for navigation highlighting.

## Technology Stack

### Backend
- **Language**: Go 1.24+
- **Framework**: Gin (HTTP router)
- **Database**: MongoDB 7.0+
- **Auth**: JWT with token rotation (RFC 6749)
- **Translations/i18n**: Follow naming conventions in `docs/modules/i18n/CORE_TRANSLATIONS.md`. Use `context.tr(LocaleKeys.key)`. Update module-specific `TRANSLATIONS.md` fragments.
- **Error Codes**: Backend must return semantic codes (check `docs/modules/[module]/TRANSLATIONS.md`).
- **API Requests**: Always use `ApiService.useFetch` via `BaseRepository` methods.
- **Query Parameters**: Use the native `queryParameters` argument in `useFetch` or standardized `fetchPaginatedList` in `BaseRepository`. 

### Frontend
- **Framework**: Flutter 3.9.2 / Dart 3.9.2
- **State Management**: flutter_bloc/Cubit
- **Routing**: go_router
- **HTTP**: dio (with interceptors)
- **Storage**: shared_preferences + flutter_secure_storage

**Key Packages**:
- `flutter_bloc: ^9.1.1` - State management
- `go_router: ^17.0.1` - Navigation
- `dio: ^5.9.0` - HTTP client
- `equatable: ^2.0.7` - Value equality
- `get_it: ^9.2.0` - Dependency injection



### Creating a New Feature

**Backend** (5 files per feature):
1. `model.go` - Define entities
2. `dto.go` - Request/Response structs
3. `repository.go` - Database operations
4. `service.go` - Business logic
5. `handler.go` + `routes.go` - HTTP layer

**Frontend** (5 folders per feature):
1. `models/` - Dart classes with fromJson/toJson
2. `services/` - API calls + business logic
3. `bloc/` - Cubit + States
4. `pages/` - Screen widgets
5. `widgets/` - Feature-specific widgets


## Agent Contracts System

**Purpose**: Define roles, boundaries, and collaboration rules for AI agents working on this codebase.

**Location**: `backend/docs/architecture/contracts/`

### How It Works

1. **Before assigning work**: Master agent reads relevant contract
2. **Agent receives task**: Operates within contract boundaries
3. **Agent produces output**: Follows required format (initial summary max 1-2 pages)
4. **Master validates**: Checks token budget, format, proposal tone
5. **Approval gate**: Agent requests permission for deep-dive work

### Available Agents

| Agent | Role | Token Budget |
|-------|------|--------------|
| master-agent | Orchestrator, enforces contracts | 15k |
| architect-agent | Architecture, design patterns, ADRs | 12k |
| backend-agent | Go code quality, patterns | 10k |
| flutter-agent | UI, widgets, BLoC/Cubit | 10k |
| database-agent | MongoDB indexes, performance | 8k |
| security-agent | OWASP, vulnerabilities | 8k |
| devops-agent | CI/CD, tests, deployment | 8k |

### Core Rules

- **Agents PROPOSE, Master DECIDES** - No agent has unilateral authority
- **Token budgets are hard limits** - Agents escalate if exceeded
- **Initial summaries required** - No deep dives without approval
- **No authority language** - Agents can't use "CRITICAL", "Deploy now", etc.
- **No phases/timelines** - Only Master/user defines when things happen

### Contract Files

Each agent has a YAML contract defining:
- `role` - Core responsibility
- `boundaries` - What agent must/must not do
- `output_format` - Required deliverable structure
- `approval_required_for` - Actions needing Master approval
- `collaboration` - How agent works with others

See `backend/docs/architecture/contracts/README.md` for details.

## Important Files & Locations

### Backend Entry Points
- `backend/main.go` - Application entry point
- `backend/routes/router_config.go` - Route configuration
- `backend/config/mongo.go` - Database configuration
- `./.env` - Environment variables (DO NOT COMMIT)

### Frontend Entry Points
- `stret_core/lib/main.dart` - App entry point
- `stret_core/lib/core/router/app_routes.dart` - Navigation setup
- `stret_core/lib/core/theme/` - Theme configuration
- `stret_core/lib/core/lang/` - Internationalization

### Configuration Files
- `.claude/settings.local.json` - Claude Code permissions
- `.claude/.mcp.json` - MCP server configuration (project-level)
- `~/.claude.json` - User-level MCP servers
- `.env.example` - Template for environment variables

### Documentation
- `docs/architecture/adr/` - Architecture Decision Records
- `docs/architecture/contracts/` - Agent roles and boundaries
- `docs/guides/` - Development guides
- `docs/TODO.md` - Current status and roadmap
- `README.md` - Project overview


## Common Gotchas & Important Notes

### Backend
1. **Keep features isolated** - Minimize cross-feature imports
2. **Use context.Context for all DB operations** - For proper cancellation
3. **JWT tokens have 15min lifetime** - Refresh tokens are 7 days
4. **Account lockout after 5 failed attempts** - 15 minute cooldown
5. **Use bcrypt cost 12 for passwords** - Security standard

### Frontend
7. **All BLoCs must emit new state instances** - For proper change detection
8. **Use Equatable for models** - For value comparison
9. **Secure storage for tokens** - Use flutter_secure_storage
10. **Theming uses family fonts** - OpenSans, Oswald, Roboto
11. **Services handle both API and logic** - No separate repository layer

### General
12. **MongoDB uses TTL indexes** - Automatic cleanup of expired tokens
13. **Backend runs on port 3000** - Frontend on port 8080, MongoDB on 27017
14. **Frontend supports 8 themes** - Nature, Ocean, Sporty, Professional, etc.
15. **Primary language is Spanish** - ES translations required


**Last Updated**: 2026-01-09
