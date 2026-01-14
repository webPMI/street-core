# StreetCore - Urban Sports Platform

**Version**: 0.1
**Architecture**: Monolith by Features (Backend & Frontend)

---

## Quick Start

### For New Developers
1. **[Quick Start Guide](docs/guides/quick-start.md)** - Get up and running in 15 minutes
2. **[TODO & Status](docs/TODO.md)** - Current project status and tasks

### For AI Assistants
1. **[CLAUDE.md](CLAUDE.md)** - Complete project context for AI assistants
---

## Architecture

### Core Principle: 1 Feature = 1 Folder

Everything related to a feature lives together. No abstract layers, direct dependencies, simple and fast development.

```
Handler/Page → Service → Repository/API
     ↓            ↓           ↓
   (HTTP)    (Business)   (Data)
```

### Backend Structure (Go)

```
backend/
├── main.go                   # Entry point
├── config/                   # Configuration
├── pkg/                      # Shared utilities
├── features/                 # Business features
│   ├── auth/
│   │   ├── model.go          # Entities
│   │   ├── dto.go            # Request/Response DTOs
│   │   ├── repository.go     # Database operations
│   │   ├── service.go        # Business logic
│   │   ├── handler.go        # HTTP handlers
│   │   └── routes.go         # Route definitions
│   ├── competitions/
│   ├── profile/
└── routes/                   # Main router
```

### Frontend Structure (Flutter)

```
lib/
├── main.dart                 # Entry point
├── config/                   # App configuration
├── core/                     # Shared utilities
│   ├── di/                   # Dependency injection
│   ├── theme/                # 8 visual themes
│   ├── router/               # Navigation (go_router)
│   ├── services/             # Base API service
│   ├── widgets/              # Shared widgets
│   └── lang/                 # i18n (ES primary, EN secondary)
├── features/                 # Business features
│   ├── auth/                 # Authentication
│   │   ├── models/
│   │   ├── services/
│   │   ├── bloc/
│   │   ├── pages/
│   │   └── widgets/
│   ├── profile/              # User profiles, posts, social
│   ├── competitions/         # Competitions, judges, scoring
│   ├── dashboard/            # User dashboard
│   └── public/               # Public pages (home, legal, contact)
└── dev/                      # Development utilities2 modules)

---

## Technology Stack

### Backend
| Technology | Purpose |
|-----------|---------|
| Go 1.24+ | Language |
| Gin | HTTP Framework |
| MongoDB 7.0+ | Database |
| JWT | Authentication |
| Port: 3000 | Server |

### Frontend
| Technology | Purpose |
|-----------|---------|
| Flutter 3.9.2 | Framework |
| Dart 3.9.2 | Language |
| BLoC/Cubit | State Management |
| go_router | Navigation |
| Dio | HTTP Client |
| GetIt | Dependency Injection |
| Port: 8080 | Dev Server |

---

## Getting Started

### Prerequisites

```bash
# Backend
- Go 1.24+
- MongoDB 7.0+

# Frontend
- Flutter 3.9.2+
- Dart 3.9.2+
```
### Guides
- **[Quick Start](docs/guides/quick-start.md)** - Get started
- **[TODO & Tasks](docs/TODO.md)** - Current tasks and technical debt

### For AI Agents
- **[CLAUDE.md](CLAUDE.md)** - Complete AI context
---

## Development Workflow

### Creating a New Feature

**Backend**:
1. Create `features/[name]/` folder
2. Add `model.go`, `dto.go`, `repository.go`, `service.go`, `handler.go`, `routes.go`
3. Register routes in main router

**Frontend**:
1. Create `features/[name]/` folder
2. Add `models/`, `services/`, `bloc/`, `pages/`, `widgets/`
3. Register in DI container


## Security

### Implemented
- Bcrypt password hashing (cost 12)

### Planned


**Last Updated**: 2025-12-30