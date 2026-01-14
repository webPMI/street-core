# Competitions Module - Architecture & Protocols

**Version**: 1.0
**Last Updated**: 2026-01-06
**Architecture**: Hexagonal (Clean Architecture with DDD)

---

## 📐 Architecture Rules

### 1. Hexagonal Architecture (Vertical Slicing)

This module follows **Clean Architecture** principles with strict separation of concerns:

```
competitions/
├── domain/                    # CORE - Business logic (NO dependencies)
│   ├── entities/             # Domain models with business rules
│   ├── repositories/         # Repository interfaces (contracts)
│   └── services/             # Domain services (authorization, validation)
│
├── application/              # USE CASES - Application logic
│   └── usecases/
│       ├── emergency/        # Emergency operations (CRITICAL)
│       ├── heat/             # Heat management
│       ├── score/            # Scoring operations
│       └── ...               # Other features
│
└── infrastructure/           # ADAPTERS - External integrations
    ├── http/
    │   ├── handlers/         # HTTP controllers
    │   ├── routes/           # Route definitions
    │   └── middlewares/      # Request interceptors
    ├── persistence/
    │   └── mongodb/          # MongoDB repositories
    └── realtime/             # SSE broadcaster
```

### 2. Dependency Rules (CRITICAL)

**Direction**: Infrastructure → Application → Domain

```
✅ ALLOWED:
- Infrastructure imports Application
- Infrastructure imports Domain
- Application imports Domain

❌ FORBIDDEN:
- Domain imports Application
- Domain imports Infrastructure
- Application imports Infrastructure
```

**Example**:
```go
// ✅ GOOD
package handlers
import "backend/features/competitions/application/usecases"
import "backend/features/competitions/domain/entities"

// ❌ BAD
package domain
import "backend/features/competitions/infrastructure/http/handlers"
```

### 3. Transaction Pattern (Emergency Operations)

**ALL emergency use cases MUST follow this pattern:**

```go
func (uc *EmergencyUseCase) Execute(ctx context.Context, req Request) error {
    // 1. START TRANSACTION
    session, err := uc.mongoClient.StartSession()
    if err != nil {
        return fmt.Errorf("failed to start session: %w", err)
    }
    defer session.EndSession(ctx)

    // 2. EXECUTE WITH SESSION
    err = mongo.WithSession(ctx, session, func(sc mongo.SessionContext) error {
        if err := session.StartTransaction(); err != nil {
            return err
        }

        // 3. LOAD ENTITIES
        competition, _ := uc.competitionRepo.FindByID(sc, req.CompetitionID)
        heat, _ := uc.heatRepo.FindByID(sc, req.HeatID)

        // 4. AUTHORIZE (EmergencyAuthorizationService)
        if err := uc.authService.Authorize(sc, req.UserID, req.UserRole,
            entities.EmergencyActionTypeScoreReset, heat); err != nil {
            return err
        }

        // 5. CAPTURE STATE BEFORE
        stateBefore := captureStateBefore(heat, scores)

        // 6. APPLY DOMAIN LOGIC
        // ... business logic ...

        // 7. CAPTURE STATE AFTER
        stateAfter := captureStateAfter(heat, scores)

        // 8. CREATE AUDIT RECORD
        action := entities.NewEmergencyAction(
            req.CompetitionID, req.HeatID, req.UserID,
            entities.EmergencyActionTypeScoreReset,
            stateBefore, stateAfter, req.Reason,
        )
        uc.emergencyActionRepo.Save(sc, action)

        // 9. SAVE CHANGES
        uc.heatRepo.Update(sc, heat)
        uc.scoreRepo.UpdateBatch(sc, scores)

        // 10. COMMIT
        return session.CommitTransaction(sc)
    })

    if err != nil {
        return err
    }

    // 11. BROADCAST (outside transaction - non-blocking)
    uc.broadcaster.NotifyScoreReset(ctx, req.CompetitionID, req.HeatID, req.AthleteID)

    return nil
}
```

**Key Points**:
- ✅ **MongoDB transactions** for atomicity
- ✅ **Authorization BEFORE applying changes**
- ✅ **Audit trail** with StateBefore/StateAfter (for UNDO)
- ✅ **SSE broadcast** after successful commit
- ✅ **NO deletion** - use soft delete (Status: "archived")

---

## 🚨 Emergency Protocols

### Emergency Authorization Matrix

| Action Type | Organizer | Head Judge | Judge | Speaker | Admin |
|------------|-----------|------------|-------|---------|-------|
| **Score Reset** | ✅ | ✅ | ❌ | ❌ | ✅ |
| **Score Swap** | ✅ | ✅ | ❌ | ❌ | ✅ |
| **Score Override** | ✅ | ✅ | ❌ | ❌ | ✅ |
| **Score Unlock** | ✅ | ✅ | ❌ | ❌ | ✅ |
| **Bypass Judge Requirement** | ✅ | ❌ | ❌ | ❌ | ✅ |
| **Freeze/Rollback Heat** | ✅ | ✅ | ❌ | ❌ | ✅ |

**Implementation**: `domain/services/emergency_authorization_service.go`

### Emergency Action Types

```go
const (
    EmergencyActionTypeScoreReset       = "SCORE_RESET"
    EmergencyActionTypeScoreSwap        = "SCORE_SWAP"
    EmergencyActionTypeScoreOverride    = "SCORE_OVERRIDE"
    EmergencyActionTypeScoreUnlock      = "SCORE_UNLOCK"
    EmergencyActionTypeBypassJudge      = "BYPASS_JUDGE_REQUIREMENT"
    EmergencyActionTypeFreezeHeat       = "FREEZE_HEAT"
    EmergencyActionTypeRollbackHeat     = "ROLLBACK_HEAT"
    EmergencyActionTypeTiebreakResolve  = "TIEBREAK_RESOLVE"
    EmergencyActionTypeScoreReview      = "SCORE_UNDER_REVIEW"
    EmergencyActionTypeAthleteRemoval   = "ATHLETE_REMOVAL"
)
```

### Audit Trail (CRITICAL for UNDO)

Every emergency action creates an audit record:

```go
type EmergencyAction struct {
    ID            primitive.ObjectID
    CompetitionID primitive.ObjectID
    HeatID        *primitive.ObjectID // Optional for competition-wide actions

    ActionType    string              // SCORE_RESET, SCORE_SWAP, etc.
    PerformedBy   primitive.ObjectID  // User who authorized
    PerformedAt   time.Time

    StateBefore   map[string]interface{} // JSON snapshot BEFORE
    StateAfter    map[string]interface{} // JSON snapshot AFTER

    Reason        string              // Min 10 chars
    IsApplied     bool                // Applied = true, Rolled back = false
    AppliedAt     *time.Time
}
```

**StateBefore/StateAfter enables UNDO functionality** (future feature).

---

## 📡 Real-Time Events (SSE)

### Connection Endpoint

```
GET /api/v1/competitions/:id/events
Authorization: Bearer <jwt_token>
```

### Event Types & Payloads

#### 1. Emergency Broadcast (`emergency`)

**Priority**: CRITICAL, WARNING, INFO

```json
{
  "type": "emergency",
  "priority": "CRITICAL",
  "competitionId": "673d1f2e8b5c4a1d2e3f4a5b",
  "heatId": "673d1f2e8b5c4a1d2e3f4a5c",
  "message": "Judge tablet malfunction - Heat paused",
  "timestamp": "2026-01-06T10:30:00Z",
  "data": {
    "subject": "JUDGE_TABLET_FAILURE",
    "targetRole": "speaker",
    "actionNeeded": true
  }
}
```

#### 2. Score Reset (`score_reset`)

**Trigger**: `ResetSingleAthleteScoreUseCase`

```json
{
  "type": "score_reset",
  "priority": "CRITICAL",
  "competitionId": "673d1f2e8b5c4a1d2e3f4a5b",
  "heatId": "673d1f2e8b5c4a1d2e3f4a5c",
  "message": "Score reset for athlete - Re-run authorized",
  "timestamp": "2026-01-06T10:35:00Z",
  "data": {
    "athleteId": "673d1f2e8b5c4a1d2e3f4a5d",
    "action": "SCORE_RESET"
  }
}
```

**Speaker Action**: Reload athlete scores for `heatId` + `athleteId`

#### 3. Score Swap (`score_swap`)

**Trigger**: `SwapAthleteScoresUseCase`

```json
{
  "type": "score_swap",
  "priority": "CRITICAL",
  "competitionId": "673d1f2e8b5c4a1d2e3f4a5b",
  "heatId": "673d1f2e8b5c4a1d2e3f4a5c",
  "message": "Scores swapped between two athletes",
  "timestamp": "2026-01-06T10:40:00Z",
  "data": {
    "athlete1Id": "673d1f2e8b5c4a1d2e3f4a5d",
    "athlete2Id": "673d1f2e8b5c4a1d2e3f4a5e",
    "reason": "Athletes registered in wrong order",
    "action": "SCORE_SWAP"
  }
}
```

**Speaker Action**: Reload scores for BOTH athletes

#### 4. Score Override (`score_override`)

**Trigger**: `AdminOverrideScoreUseCase`

```json
{
  "type": "score_override",
  "priority": "CRITICAL",
  "competitionId": "673d1f2e8b5c4a1d2e3f4a5b",
  "heatId": "673d1f2e8b5c4a1d2e3f4a5c",
  "message": "Admin override: Score changed from 85.50 to 88.00",
  "timestamp": "2026-01-06T10:45:00Z",
  "data": {
    "scoreId": "673d1f2e8b5c4a1d2e3f4a5f",
    "athleteId": "673d1f2e8b5c4a1d2e3f4a5d",
    "originalScore": 85.50,
    "newScore": 88.00,
    "reason": "Judge tablet malfunction",
    "action": "SCORE_OVERRIDE"
  }
}
```

**Speaker Action**: Reload single score by `scoreId`

**Important**: Original judge score is preserved in `OriginalJudgeScore` field for protests.

#### 5. Score Under Review (`score_under_review`)

**Trigger**: `SetScoreUnderReviewUseCase`

```json
{
  "type": "score_under_review",
  "priority": "WARNING",
  "competitionId": "673d1f2e8b5c4a1d2e3f4a5b",
  "message": "Score under protest review",
  "timestamp": "2026-01-06T10:50:00Z",
  "data": {
    "scoreId": "673d1f2e8b5c4a1d2e3f4a5f",
    "action": "UNDER_REVIEW"
  }
}
```

**Speaker Action**: Display "UNDER REVIEW" badge on score

#### 6. Heat Order Change (`heat_order_change`)

**Trigger**: `NotifyHeatOrderChange()`

```json
{
  "type": "heat_order_change",
  "priority": "WARNING",
  "competitionId": "673d1f2e8b5c4a1d2e3f4a5b",
  "heatId": "673d1f2e8b5c4a1d2e3f4a5c",
  "message": "Heat order has been modified",
  "timestamp": "2026-01-06T10:55:00Z",
  "data": {
    "newOrder": ["athlete1_id", "athlete2_id", "athlete3_id"],
    "action": "HEAT_ORDER_CHANGE"
  }
}
```

**Speaker Action**: Reorder athletes in UI based on `newOrder` array

#### 7. Athlete Removed (`athlete_removed`)

**Trigger**: `NotifyAthleteRemoved()`

```json
{
  "type": "athlete_removed",
  "priority": "CRITICAL",
  "competitionId": "673d1f2e8b5c4a1d2e3f4a5b",
  "heatId": "673d1f2e8b5c4a1d2e3f4a5c",
  "message": "Athlete removed from heat",
  "timestamp": "2026-01-06T11:00:00Z",
  "data": {
    "athleteId": "673d1f2e8b5c4a1d2e3f4a5d",
    "reason": "Injury during warm-up",
    "action": "ATHLETE_REMOVED"
  }
}
```

**Speaker Action**: Remove athlete from heat display

#### 8. Generic Competition Event (`BroadcastToCompetition`)

```json
{
  "type": "custom_event_type",
  "priority": "INFO",
  "competitionId": "673d1f2e8b5c4a1d2e3f4a5b",
  "message": "Custom message",
  "timestamp": "2026-01-06T11:05:00Z"
}
```

---

## 🔒 Security & Middleware

### Authentication Middleware

**ALL competition endpoints** require JWT authentication:

```go
auth := router.Group("/competitions")
auth.Use(middlewares.AuthMiddleware(authService, tokenRevocationService, userRepo))
```

### Emergency Endpoints Protection

**Two-layer security**:

1. **JWT Authentication** (middlewares.AuthMiddleware)
2. **Emergency Authorization** (EmergencyAuthorizationService)

**Example**:
```go
POST /api/v1/competitions/:id/emergency/reset-score
├─ [1] AuthMiddleware → Validates JWT, injects UserID + UserRole
└─ [2] EmergencyAuthorizationService → Checks role permissions for SCORE_RESET
```

**Emergency endpoints** (all protected):
- `POST /:id/emergency/reset-score`
- `POST /:id/emergency/swap-scores`
- `POST /:id/emergency/override-score`
- `POST /:id/emergency/unlock-score`
- `POST /:id/emergency/bypass-judge-requirement`
- `POST /:id/emergency/freeze-heat`
- `POST /:id/emergency/rollback-heat`
- `POST /:id/emergency/resolve-tiebreak`

### Role-Based Access

```go
// Organizer-only endpoint
auth.POST("/:id/start", middlewares.RequireRole("organizer"), handler.StartCompetition)

// Admin-only endpoint
auth.GET("/:id/events/subscribers", middlewares.RequireRole("admin"), sseHandler.GetSubscriberCount)
```

---

## 📦 Data Integrity Rules

### 1. NO Deletion - Soft Delete Only

**NEVER use `Delete()` on scores/heats/athletes.**

```go
// ❌ FORBIDDEN
scoreRepo.Delete(ctx, scoreID)

// ✅ REQUIRED
score.Status = entities.ScoreStatusArchivedByRerun
score.Notes = "Archived for re-run. Reason: " + reason
scoreRepo.Update(ctx, score)
```

**Status Values**:
- `"active"` - Current active score
- `"archived_by_rerun"` - Athlete re-ran, old score archived
- `"archived_by_reset"` - Heat reset, all scores archived

### 2. Score Preservation for Protests

**When admin overrides score**, original judge score MUST be preserved:

```go
func (s *Score) AdminOverrideScore(newTotalScore float64, newCriteriaScores map[string]float64) {
    if !s.IsOverridden {
        // PRESERVE original for protests
        s.OriginalJudgeScore = s.TotalScore
        s.OriginalCriteriaScores = s.CriteriaScores
    }
    s.IsOverridden = true
    s.TotalScore = newTotalScore
    s.CriteriaScores = newCriteriaScores
}
```

### 3. Locked Scores

Scores are automatically locked when:
- Heat status = "completed"
- Heat status = "published"

**Unlock requires**:
- Emergency authorization
- Audit trail creation

---

## 🧪 Testing Guidelines

### Unit Tests (Domain Layer)

Test domain logic in isolation:

```go
func TestEmergencyAction_Validate(t *testing.T) {
    action := entities.NewEmergencyAction(...)
    err := action.Validate()
    assert.NoError(t, err)
}
```

### Integration Tests (Use Cases)

Test with MongoDB in-memory or testcontainers:

```go
func TestResetSingleAthleteScore_Success(t *testing.T) {
    // Setup MongoDB transaction
    // Create test data
    // Execute use case
    // Assert audit trail created
    // Assert scores archived
    // Assert broadcast called
}
```

### E2E Tests (HTTP Handlers)

Test complete flow with authentication:

```go
func TestEmergencyResetScore_Unauthorized(t *testing.T) {
    // Request without JWT → 401
    // Request with Judge role → 403
    // Request with Head Judge role → 200
}
```

---

## 📊 Performance Considerations

### SSE Hub Scalability

**Current**: In-memory state (single server)

**For multi-server deployments**, use Redis Pub/Sub:

```go
// Publish to Redis
redisClient.Publish(ctx, "competition:"+competitionID, eventJSON)

// Subscribe from Redis
pubsub := redisClient.Subscribe(ctx, "competition:"+competitionID)
for msg := range pubsub.Channel() {
    sseHub.Broadcast(competitionID, msg)
}
```

### Database Indexing

**Required indexes** (performance):

```javascript
// Scores collection
db.scores.createIndex({ competitionId: 1, heatId: 1, athleteId: 1 })
db.scores.createIndex({ status: 1 })

// Emergency actions collection
db.emergency_actions.createIndex({ competitionId: 1, createdAt: -1 })
db.emergency_actions.createIndex({ performedBy: 1, createdAt: -1 })

// Heats collection
db.heats.createIndex({ competitionId: 1, roundId: 1 })
```

---

## 🚀 Deployment Checklist

Before deploying to production:

- [ ] All emergency endpoints have JWT + role authorization
- [ ] MongoDB indexes created
- [ ] SSE Hub graceful shutdown implemented
- [ ] EmergencyAuthorizationService tested with all roles
- [ ] Audit trail storage validated (StateBefore/StateAfter)
- [ ] Score preservation for protests verified
- [ ] Soft delete pattern enforced (no hard deletes)
- [ ] Transaction rollback tested
- [ ] SSE reconnection tested (client-side)
- [ ] Load testing for concurrent SSE connections

---

## 📝 Code Review Checklist

When reviewing PRs for this module:

### Architecture Compliance
- [ ] No domain imports of infrastructure/application
- [ ] Use cases follow transaction pattern (10 steps)
- [ ] Repository interfaces in `domain/repositories/`

### Emergency Operations
- [ ] Authorization checked via `EmergencyAuthorizationService`
- [ ] Audit trail created with StateBefore/StateAfter
- [ ] SSE broadcast after successful commit
- [ ] Reason provided (min 10 chars)

### Data Integrity
- [ ] NO hard deletes (use soft delete)
- [ ] Score preservation for overrides
- [ ] MongoDB transactions used
- [ ] Rollback on error

### Security
- [ ] JWT authentication on endpoints
- [ ] Role-based authorization
- [ ] Input validation
- [ ] No sensitive data in logs

### Testing
- [ ] Unit tests for domain logic
- [ ] Integration tests for use cases
- [ ] E2E tests for handlers
- [ ] Edge cases covered

---

## 📚 Related Documentation

- `docs/modules/competitions/BLOQUE_1_EMERGENCY_AUDIT.md` - Emergency audit system
- `docs/modules/competitions/BLOQUE_2_EMERGENCY_USE_CASES.md` - Emergency operations
- `docs/modules/competitions/BLOQUE_3_SSE_IMPLEMENTATION.md` - Real-time events
- `infrastructure/realtime/example_sse_client.html` - JavaScript client example

---

## ⚠️ Breaking Changes Protocol

If you need to modify core interfaces or contracts:

1. **Document the change** in this README
2. **Update all implementations** (repositories, use cases, handlers)
3. **Update tests** (unit, integration, e2e)
4. **Migration script** if database schema changes
5. **Version bump** in this README header
6. **Notify team** before merging

---

## 🆘 Emergency Contacts

**Architecture Questions**: Check this README first
**Domain Logic Issues**: Review `domain/entities/` documentation
**Security Concerns**: Review `EmergencyAuthorizationService`
**SSE Issues**: Check `BLOQUE_3_SSE_IMPLEMENTATION.md`

---

**Last Review**: 2026-01-06
**Next Review**: Every major feature addition
**Maintained By**: Backend Team
