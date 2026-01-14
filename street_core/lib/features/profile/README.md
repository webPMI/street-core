# Profile Module - ADR-005 Compliant

**Location**: `lib/features/profile/`
**Pattern**: Monolith-by-Features
**Status**: 100% Production Ready

## Structure

```
features/profile/
├── bloc/                    # State management (Cubits + States)
│   ├── user_cubit.dart
│   ├── user_profile_cubit.dart
│   ├── user_posts_cubit.dart
│   ├── follow_cubit.dart
│   └── [states]
│
├── pages/                   # UI Screens
│   ├── profile_page.dart
│   ├── profile_edit_page.dart
│   ├── user_profile_page.dart
│   ├── followers_page.dart
│   ├── following_page.dart
│   ├── saved_posts_page.dart
│   └── change_password_page.dart
│
├── posts/                   # Posts sub-feature
│   ├── bloc/               # Posts-specific cubits
│   ├── pages/              # Posts-specific pages
│   ├── widgets/            # Posts-specific widgets
│   └── posts_routes.dart   # Posts routing
│
├── widgets/                 # Shared profile widgets
│   ├── profile_header.dart
│   ├── profile_stats.dart
│   ├── avatar_upload_widget.dart
│   └── [11 more widgets]
│
├── repositories/            # Data layer (API calls)
│   ├── profile_repository.dart
│   ├── post_repository.dart
│   ├── follow_repository.dart
│   ├── story_repository.dart
│   └── privacy_repository.dart (copy, shared with Settings)
│
├── services/                # Business logic layer
│   ├── profile_service.dart
│   ├── post_service.dart
│   ├── follow_service.dart
│   ├── story_service.dart
│   └── privacy_service.dart
│
├── models/                  # Data models
│   ├── privacy_settings_model.dart
│   └── story_model.dart
│
├── di/                      # Dependency injection
│   └── profile_injection.dart
│
├── profile_routes.dart      # Main routing
└── README.md                # This file
```

## Dependency Flow

```
Page → Cubit → Service → Repository → API
```

Example:
```
profile_page.dart
  → UserProfileCubit
    → ProfileService
      → ProfileRepository
        → Backend API
```

## Key Features

- User profiles (view, edit)
- Posts (create, view)
- Stories (create, view)
- Follow/Unfollow system
- Privacy settings
- Media uploads

## Usage

### Import the DI module

```dart
import 'package:street_core/features/profile/di/profile_injection.dart';

void main() {
  final getIt = GetIt.instance;
  setupProfileModule(getIt); // Registers all dependencies
}
```

### Use in a page

```dart
import 'package:street_core/features/profile/bloc/user_profile_cubit.dart';
import 'package:street_core/features/profile/pages/profile_page.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<UserProfileCubit>(),
      child: ProfilePage(),
    );
  }
}
```



## Shared Dependencies

Some repositories are shared across modules and live in `data/repositories/`:

- `UserRepository` - Shared with Auth
- `MediaUploadRepository` - Shared with all modules
- `PrivacyRepository` - Shared with Settings (copy exists here for reference)

## Testing

Tests should mirror the structure:

```
test/
├── unit/profile/
│   ├── repositories/
│   ├── services/
│   └── cubits/
└── widget/profile/
    ├── pages/
    └── widgets/
```

## Contributing

When adding new features to Profile:

1. Add to the appropriate subfolder (pages, widgets, services, etc.)
2. Keep everything in `features/profile/`
3. Update `di/profile_injection.dart` to register new dependencies
4. Write tests in `test/unit/profile/` or `test/widget/profile/`

## Related Documentation

- ADR-005: Monolith-by-Features pattern
- `docs/modules/profile/CONTEXT.md` - Module overview
- `docs/CORE.md` - Architecture principles

---

Last Updated: 2024-12-24 00:50 UTC-5
