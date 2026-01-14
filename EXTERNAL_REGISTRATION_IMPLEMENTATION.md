# External Registration Feature - Implementation Summary

## Overview

Implemented external registration support for competitions based on the architect's design. Users are now clearly warned when a competition uses third-party registration, with a prominent banner and exit confirmation dialog.

## Files Modified/Created

### 1. Competition Model
**File:** `C:\src\street-core\street_core\lib\features\competitions\models\competition.dart`

**Changes:**
- Added three new fields to the `Competition` class:
  - `registrationType`: String? - Indicates registration type ("internal", "external", or null)
  - `externalRegistrationUrl`: String? - URL to the external registration platform
  - `externalProvider`: String? - Name of the provider (e.g., "Eventbrite", "Ticketmaster")

- Added three helper methods:
  - `isExternalRegistration`: Getter that returns true if registrationType == "external"
  - `isInternalRegistration`: Getter that returns true for internal/null registration
  - `getExternalRegistrationUrl()`: Method to safely retrieve the external URL

- Updated `fromJson()` to parse the new fields from API responses
- Updated `toJson()` to serialize the new fields when sending to backend

### 2. Competitions Service
**File:** `C:\src\street-core\street_core\lib\features\competitions\services\competitions_service.dart`

**Changes:**
- Added `getExternalRegistrationUrl(Competition competition)` method
  - Returns the URL only if the competition uses external registration
  - Returns null otherwise for safety

### 3. External Registration Warning Widget (NEW)
**File:** `C:\src\street-core\street_core\lib\features\competitions\widgets\external_registration_warning.dart`

**Features:**
- Prominent warning banner with amber/orange colors
- Displays provider name when available
- Shows clear "Continue to [Provider]" button
- Exit confirmation dialog before opening external URL
- Safe URL launching with validation
- Error handling for invalid or missing URLs
- Responsive layout that works on all screen sizes

**User Flow:**
1. User views competition detail page
2. If external registration is enabled, the warning widget appears instead of the register button
3. User reads the warning and provider information
4. User clicks "Continue to [Provider]" button
5. Confirmation dialog appears: "You will leave StreetCore and go to [Provider]. Continue?"
6. If confirmed, URL launches in external browser
7. If cancelled, user stays on the StreetCore app

**Key Implementation Details:**
- Uses `url_launcher` package (already in pubspec.yaml)
- Uses `LaunchMode.externalApplication` to open in browser
- Validates URLs with `Uri.tryParse()`
- Shows snackbar errors for invalid/missing URLs
- Uses theme colors with custom warning color extension
- Follows Material Design 3 principles

### 4. Register Button Update
**File:** `C:\src\street-core\street_core\lib\features\competitions\pages\compe_register\compe_register_button.dart`

**Changes:**
- Added import for `ExternalRegistrationWarning`
- Updated `build()` method to check if competition uses external registration
- When `_canRegister() && isExternalRegistration`, shows warning banner instead of register button
- Maintains all existing logic for internal registrations

**Logic Flow:**
```
if (!_hasChecked) return SizedBox.shrink()
if (_canRegister() && isExternalRegistration) return ExternalRegistrationWarning()
if (_canRegister()) return RegisterButton()
if (_canUnregister()) return UnregisterButton()
return SizedBox.shrink()
```

## Design System Integration

### Colors Used
- Warning banner background: `#FFE0B2` (light orange)
- Warning banner border: `#F57C00` (orange)
- Warning text color: `#331B00` (dark brown)
- Theme-aware: Uses `colorScheme.warning` and `colorScheme.warningContainer`

### Icons
- Warning icon: `Icons.warning_amber`
- Provider link icon: `Icons.language`
- External link icon: `Icons.open_in_new`

### Typography
- Uses existing `MyText` widget for consistency
- Respects app's font family settings (OpenSans, Oswald, Roboto)
- Follows Material Design text hierarchy

## Backend Requirements

To use this feature, backend should return:

```json
{
  "id": "comp-123",
  "title": "Competition Name",
  "registrationType": "external",
  "externalRegistrationUrl": "https://eventbrite.com/events/123456",
  "externalProvider": "Eventbrite",
  ...
}
```

Or with nested registration object:

```json
{
  "id": "comp-123",
  "registration": {
    "registrationType": "external",
    "externalRegistrationUrl": "https://eventbrite.com/events/123456",
    "externalProvider": "Eventbrite"
  }
}
```

## Usage Examples

### Checking Registration Type in Code
```dart
final competition = await service.fetchCompetitionById('comp-123');

if (competition.isExternalRegistration) {
  // Show external registration UI
}

if (competition.isInternalRegistration) {
  // Show internal registration UI
}

// Get the external URL
final url = competition.getExternalRegistrationUrl();
```

### In Competition Detail Page
The `CompetRegisterButton` automatically handles the registration type:
- External competitions show the warning banner with action button
- Internal competitions show the standard register/unregister buttons

## Testing Scenarios

### Scenario 1: External Registration
1. Competition with `registrationType: "external"`
2. User views detail page
3. See warning banner with provider name
4. Click "Continue to [Provider]"
5. See confirmation dialog
6. Click "Continue" → Opens browser
7. Click "Cancel" → Stays on app

### Scenario 2: Internal Registration
1. Competition with `registrationType: "internal"` or no field
2. User views detail page
3. See standard green "Register" button (if eligible)
4. Click button → Internal registration sheet appears

### Scenario 3: Missing External URL
1. Competition with `registrationType: "external"` but no URL
2. User clicks button
3. See error snackbar: "External registration URL not available"

### Scenario 4: Invalid External URL
1. Competition with malformed URL
2. User clicks button
3. See error snackbar: "Invalid registration URL"

## Security Considerations

1. **URL Validation**: Uses `Uri.tryParse()` to validate URLs before launching
2. **Safe Launching**: Uses `LaunchMode.externalApplication` to open in browser, not in-app
3. **Error Handling**: Gracefully handles missing/invalid URLs
4. **User Confirmation**: Explicit dialog before leaving the platform
5. **No Sensitive Data**: Never passes authentication tokens to external URLs

## Accessibility

- Warning banner uses semantic colors for color-blind users
- Icons have text labels alongside them
- Confirmation dialog clearly states what will happen
- Uses Material Design 3 principles for consistent experience
- Text is selectable with MyText widget

## Monolith by Features Compliance

- All code contained in `features/competitions/` module
- External registration is a feature-specific widget
- Service method added to `CompetitionsService`
- Model fields are properly serialized/deserialized
- No cross-feature imports (only core utilities)

## Future Enhancements

1. Analytics tracking when users click external registration links
2. Retry mechanism if external site is unreachable
3. Cache external registration state locally
4. Support for deep linking back to app after registration
5. Display registration status from external platforms (if API available)

## Dependencies

All required packages already in `pubspec.yaml`:
- `flutter`: Flutter framework
- `flutter_bloc`: State management
- `url_launcher: ^6.3.2`: Opening external URLs
- `equatable: ^2.0.7`: Model equality

No new dependencies needed!

## Migration Notes

### For Existing Competitions
- If `registrationType` field is missing, default behavior is `isInternalRegistration == true`
- Existing internal registrations continue to work without changes
- No breaking changes to the API contract

### API Response Backward Compatibility
The implementation checks both:
1. Root level fields: `registrationType`, `externalRegistrationUrl`, `externalProvider`
2. Nested `registration` object for the same fields

This ensures compatibility with different API response formats.
