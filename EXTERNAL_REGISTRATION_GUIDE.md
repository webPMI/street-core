# External Registration Feature - Developer Guide

## Quick Start

The external registration feature is automatically integrated into the competition detail page. No additional changes needed to use it.

### How It Works Automatically

1. **Backend returns external registration data**
   ```json
   {
     "id": "comp-123",
     "registrationType": "external",
     "externalRegistrationUrl": "https://eventbrite.com/events/123456",
     "externalProvider": "Eventbrite"
   }
   ```

2. **Competition model parses it**
   ```dart
   final competition = Competition.fromJson(json);
   assert(competition.isExternalRegistration == true);
   ```

3. **Register button shows warning instead of registration form**
   - User sees prominent amber/orange warning banner
   - Banner displays provider name
   - "Continue to Eventbrite" button appears
   - Clicking shows exit confirmation dialog
   - Clicking "Continue" opens browser

4. **For internal registrations, normal flow continues**
   - `registrationType: "internal"` or missing field
   - Shows standard green "Register" button
   - Opens internal registration sheet
   - Everything works as before

## File Structure

```
street_core/lib/features/competitions/
├── models/
│   └── competition.dart                    # Added: registrationType, externalRegistrationUrl, externalProvider
├── services/
│   └── competitions_service.dart           # Added: getExternalRegistrationUrl() method
├── widgets/
│   └── external_registration_warning.dart  # NEW: Warning banner widget
├── pages/
│   ├── compe_detail/
│   │   └── competition_detail_page.dart    # Uses CompetRegisterButton (no changes needed)
│   └── compe_register/
│       └── compe_register_button.dart      # Updated: Checks for external registration
```

## Component Responsibilities

### Competition Model
- **Parse external registration data from API**
- **Provide helper methods:**
  - `isExternalRegistration` - Check if external
  - `isInternalRegistration` - Check if internal
  - `getExternalRegistrationUrl()` - Get URL safely

### Competitions Service
- **Provide `getExternalRegistrationUrl(competition)`**
- Encapsulates business logic for accessing external URL

### ExternalRegistrationWarning Widget
- **Display prominent warning banner**
- **Handle URL launching**
- **Show exit confirmation dialog**
- **Manage errors gracefully**

### CompetRegisterButton
- **Check registration type**
- **Show appropriate UI:**
  - External: Show warning banner
  - Internal: Show register/unregister button
- **Manage user authentication state**

## Component Integration Diagram

```
CompetitionDetailPage
  ├─ Fetches competition data
  └─ FloatingActionButton: CompetRegisterButton
       ├─ Checks isExternalRegistration
       ├─ If external: Shows ExternalRegistrationWarning
       │  ├─ User clicks "Continue to [Provider]"
       │  ├─ Shows exit confirmation dialog
       │  └─ Launches URL in browser
       └─ If internal: Shows Register/Unregister button
          └─ Normal registration flow
```

## Testing the Feature

### Test Case 1: External Registration Flow
```dart
// Setup: Create competition with external registration
final competition = Competition(
  id: 'comp-1',
  registrationType: 'external',
  externalRegistrationUrl: 'https://eventbrite.com/events/123',
  externalProvider: 'Eventbrite',
  // ... other fields
);

// Test: Check helper methods
expect(competition.isExternalRegistration, true);
expect(competition.isInternalRegistration, false);
expect(competition.getExternalRegistrationUrl(), 'https://eventbrite.com/events/123');

// Test: Widget shows warning
final button = CompetRegisterButton(competition: competition);
// Should display ExternalRegistrationWarning instead of FAB button
```

### Test Case 2: Internal Registration Flow
```dart
// Setup: Create competition with internal registration
final competition = Competition(
  id: 'comp-2',
  // registrationType omitted or 'internal'
  // ... other fields
);

// Test: Check helper methods
expect(competition.isInternalRegistration, true);
expect(competition.getExternalRegistrationUrl(), null);

// Test: Widget shows button
final button = CompetRegisterButton(competition: competition);
// Should display FAB with green color and "Register" label
```

### Test Case 3: Error Handling
```dart
// Test: Missing URL
final competition = Competition(
  registrationType: 'external',
  externalRegistrationUrl: null,
  // ...
);
// Clicking button shows: "External registration URL not available"

// Test: Invalid URL
final competition = Competition(
  registrationType: 'external',
  externalRegistrationUrl: 'not a valid url!!!',
  // ...
);
// Clicking button shows: "Invalid registration URL"
```

## Backend API Contract

### Request/Response Format

**Expected response for external registration:**
```json
{
  "status": "success",
  "data": {
    "id": "comp-123",
    "title": "Street Skating Championship 2024",
    "registrationType": "external",
    "externalRegistrationUrl": "https://eventbrite.com/events/123456789",
    "externalProvider": "Eventbrite",
    ...other fields...
  }
}
```

**Alternative nested format (also supported):**
```json
{
  "status": "success",
  "data": {
    "id": "comp-123",
    "title": "Street Skating Championship 2024",
    "registration": {
      "registrationType": "external",
      "externalRegistrationUrl": "https://eventbrite.com/events/123456789",
      "externalProvider": "Eventbrite"
    },
    ...other fields...
  }
}
```

### Field Specifications

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `registrationType` | String | No | "internal", "external", or omit for internal |
| `externalRegistrationUrl` | String | If external | Valid HTTPS URL to registration site |
| `externalProvider` | String | If external | Name of provider (e.g., "Eventbrite") |

## Error Scenarios

### Scenario 1: URL Not Available
**Cause:** `externalRegistrationUrl` is null or empty
**User sees:** "External registration URL not available"
**Recovery:** Admin must update competition with valid URL

### Scenario 2: Invalid URL Format
**Cause:** URL fails `Uri.tryParse()` validation
**User sees:** "Invalid registration URL"
**Recovery:** Admin must provide valid HTTPS URL

### Scenario 3: Network Error
**Cause:** Device cannot reach external site
**User sees:** Browser's native error page
**Recovery:** User can retry or check connection

## Design System Usage

### Colors
- **Warning Background:** `ColorScheme.warningContainer` (#FFE0B2)
- **Warning Border:** `ColorScheme.warning` (#F57C00)
- **Warning Text:** `Color(0xFF331B00)` (dark brown)
- **Button:** Uses `ColorScheme.warning` for action button

### Icons
- **Warning Icon:** `Icons.warning_amber` (24dp)
- **Provider Icon:** `Icons.language` (18dp)
- **External Link:** `Icons.open_in_new`

### Typography
- Uses `MyText` widget for consistency
- Respects app theming (fonts, sizes)
- Accessible contrast ratios (WCAG AA)

## Localization

The feature uses existing locale keys. To add translations:

```dart
// In locale file (e.g., es.json):
{
  "warning": "Advertencia",
  "cancel": "Cancelar",
  // External registration strings can use custom strings in widget
}
```

Current hardcoded strings (to be externalized if needed):
- "External Registration" (banner title)
- "This competition uses a third-party registration site..."
- "You will leave StreetCore and go to [Provider]. Continue?"
- "Platform: [Provider]"
- "External registration URL not available"
- "Invalid registration URL"

## Future Enhancements

### Analytics
```dart
// Track external registration clicks
analytics.logEvent(
  name: 'external_registration_clicked',
  parameters: {
    'competition_id': competition.id,
    'provider': competition.externalProvider,
  },
);
```

### Deep Linking
```dart
// Return to app after registration
final returnUrl = Uri.base.toString();
final externalUrl = Uri.parse(competition.externalRegistrationUrl!)
    .replace(queryParameters: {
      ...Uri.parse(competition.externalRegistrationUrl!).queryParameters,
      'return_url': returnUrl,
    });
await launchUrl(externalUrl);
```

### Provider Icons
```dart
// Display provider logo instead of text
final providerLogo = _getProviderIcon(competition.externalProvider);
// Icons for: Eventbrite, Ticketmaster, Eventboo, etc.
```

### Registration Status Sync
```dart
// Check registration status on external platform
final externalStatus = await _checkExternalRegistration(
  url: competition.externalRegistrationUrl,
  userId: currentUser.id,
);
```

## Performance Considerations

1. **No extra API calls:** Feature uses only competition data already fetched
2. **Lazy URL launching:** URL only validated when user clicks button
3. **Efficient widget building:** Uses getter methods, no expensive computations
4. **Memory efficient:** Warning widget is stateless, no state overhead

## Security Best Practices

1. **URL Validation:** All URLs validated with `Uri.tryParse()` before use
2. **External Launch:** Uses `LaunchMode.externalApplication` (browser only)
3. **No Token Passing:** Never includes auth tokens in external URLs
4. **User Consent:** Explicit dialog before leaving platform
5. **Error Isolation:** Errors don't crash app, show user-friendly messages

## Accessibility Compliance

- **Color:** Not reliant on color alone (text + icons)
- **Icons:** All icons have text labels
- **Text:** Clear, simple language
- **Contrast:** Meets WCAG AA standard
- **Touch targets:** Buttons minimum 48x48dp
- **Semantic:** Uses Material Design conventions

## Debugging Tips

### Check registration type
```dart
final competition = // ...
print('Type: ${competition.registrationType}');
print('Is external: ${competition.isExternalRegistration}');
print('URL: ${competition.externalRegistrationUrl}');
```

### Test URL parsing
```dart
final url = 'https://eventbrite.com/events/123';
final uri = Uri.tryParse(url);
print('Valid: ${uri != null}');
print('URI: $uri');
```

### Monitor button state
```dart
// In CompetRegisterButton._hasChecked breakpoint
// Check _canRegister() and widget.competition.isExternalRegistration
```

## Common Issues & Solutions

### Issue: Warning banner not showing
**Solution:** Check that `registrationType == 'external'` in API response

### Issue: Button shows register instead of warning
**Solution:** Verify `isExternalRegistration` getter returns true

### Issue: URL not launching
**Solution:**
1. Check URL is valid with `Uri.tryParse()`
2. Check HTTPS (required by url_launcher)
3. Check device has browser installed

### Issue: Dialog text is cut off
**Solution:** Ensure device has enough space; test on various screen sizes

## References

- **Flutter url_launcher:** https://pub.dev/packages/url_launcher
- **Material Design:** https://m3.material.io/
- **WCAG Accessibility:** https://www.w3.org/WAI/WCAG21/quickref/

---

**Last Updated:** 2026-01-12
**Version:** 1.0
**Author:** Claude Code / Flutter Agent
