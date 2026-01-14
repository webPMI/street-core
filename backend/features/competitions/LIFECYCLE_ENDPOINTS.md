# Competition Lifecycle Endpoints

This document describes the newly implemented competition lifecycle management endpoints.

## Overview

Three new endpoints have been implemented to manage the competition lifecycle:
1. **Start Competition** - Transition from `upcoming` to `live`
2. **End Competition** - Transition from `live` to `completed`
3. **Publish Results** - Make leaderboard public

## Endpoints

### 1. Start Competition
**POST** `/api/v2/competitions/:id/start`

**Authorization**: Owner or Admin only

**Description**: Starts a competition by changing its status from `upcoming` to `live`.

**Validations**:
- Competition must exist
- User must be owner or admin
- Current status must be `upcoming`
- Must have minimum required participants

**Response**:
```json
{
  "status": "success",
  "message": "Competition started successfully",
  "data": {
    "id": "competition_id",
    "status": "live",
    "isLive": true,
    ...
  }
}
```

**Error Codes**:
- `400` - Invalid status or insufficient participants
- `401` - Unauthorized
- `403` - Not owner or admin
- `404` - Competition not found

---

### 2. End Competition
**POST** `/api/v2/competitions/:id/end`

**Authorization**: Owner or Admin only

**Description**: Ends a competition by changing its status from `live` to `completed`.

**Validations**:
- Competition must exist
- User must be owner or admin
- Current status must be `live`

**Response**:
```json
{
  "status": "success",
  "message": "Competition ended successfully",
  "data": {
    "id": "competition_id",
    "status": "completed",
    "isLive": false,
    ...
  }
}
```

**Error Codes**:
- `400` - Invalid status
- `401` - Unauthorized
- `403` - Not owner or admin
- `404` - Competition not found

---

### 3. Publish Results
**POST** `/api/v2/competitions/:id/publish-results`

**Authorization**: Owner or Admin only

**Description**: Publishes competition results, making the leaderboard public.

**Validations**:
- Competition must exist
- User must be owner or admin
- Status must be `completed` or `live`

**Response**:
```json
{
  "status": "success",
  "message": "Results published successfully",
  "data": {
    "id": "competition_id",
    "isResultsPublished": true,
    "resultsPublishedAt": "2025-12-29T12:00:00Z",
    ...
  }
}
```

**Error Codes**:
- `400` - Invalid status
- `401` - Unauthorized
- `403` - Not owner or admin
- `404` - Competition not found

## Implementation Details

### Files Created
1. `backend/features/competitions/application/usecases/start_competition.go`
2. `backend/features/competitions/application/usecases/end_competition.go`
3. `backend/features/competitions/application/usecases/publish_results.go`

### Files Modified
1. `backend/features/competitions/infrastructure/http/handlers/competition_handler.go`
   - Added `startCompetition`, `endCompetition`, `publishResults` fields
   - Added `Start()`, `End()`, `PublishResults()` handler methods

2. `backend/features/competitions/infrastructure/http/routes/competition_routes.go`
   - Added routes for lifecycle endpoints

3. `backend/features/competitions/config/wire.go`
   - Wired up new use cases in dependency injection

4. `backend/models/messages.go`
   - Added `CompetitionStartedSuccessfully` message key
   - Added `CompetitionEndedSuccessfully` message key

## Status Transitions

```
upcoming --[start]--> live --[end]--> completed
                       |
                       +--[publish-results]--> (results public)
```

## Domain Logic

The business logic is encapsulated in the `Competition` entity:
- `MarkAsLive()` - Sets status to `live` and `isLive` to `true`
- `MarkAsCompleted()` - Sets status to `completed` and `isLive` to `false`
- `PublishResults()` - Sets `isResultsPublished` to `true` and records timestamp

## Testing

To test these endpoints:

```bash
# Start competition
curl -X POST http://localhost:3000/api/v2/competitions/{id}/start \
  -H "Authorization: Bearer {token}" \
  -H "X-CSRF-Token: {csrf_token}"

# End competition
curl -X POST http://localhost:3000/api/v2/competitions/{id}/end \
  -H "Authorization: Bearer {token}" \
  -H "X-CSRF-Token: {csrf_token}"

# Publish results
curl -X POST http://localhost:3000/api/v2/competitions/{id}/publish-results \
  -H "Authorization: Bearer {token}" \
  -H "X-CSRF-Token: {csrf_token}"
```

## Notes

- All endpoints require CSRF protection
- All endpoints require authentication via JWT
- Authorization is checked via user role or ownership
- State transitions are validated before execution
- Timestamps are automatically updated on all operations

## Future Enhancements

Potential improvements for future iterations:
1. Add ability to pause/resume competitions
2. Add ability to cancel competitions
3. Add notifications when competition starts/ends
4. Add audit log for status changes
5. Add webhooks for lifecycle events
