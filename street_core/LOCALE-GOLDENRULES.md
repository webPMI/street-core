# Locale Golden Rules - Translation Keys Best Practices

## 📋 Overview

This document establishes the **mandatory standards** for internationalization (i18n) in the Street Core application. All developers and AI agents MUST follow these rules to ensure consistency, maintainability, and type safety.

---

## 🎯 Core Principles

### 1. **ALWAYS Use LocaleKeys Constants**

❌ **NEVER DO THIS:**
```dart
MyText('hello.world')
context.tr('welcome.message')
SnackBarHelper.showSuccess(context, 'success.saved')
```

✅ **ALWAYS DO THIS:**
```dart
MyText(LocaleKeys.helloWorld)
context.tr(LocaleKeys.welcomeMessage)
SnackBarHelper.showSuccess(context, LocaleKeys.successSaved)
```

**Why?** Type safety, IDE autocomplete, compile-time error detection, and easier refactoring.

### 2. **ALWAYS Check for Existing Keys Before Adding New Ones**

⚠️ **CRITICAL RULE:** Before adding a new key to `LocaleKeys.dart`, **ALWAYS search** to ensure it doesn't already exist!

```dart
// Step 1: Search in LocaleKeys.dart (Ctrl+F / Cmd+F)
// Search for: "deletePost", "delete", "post"

// Step 2: If found, reuse it
MyText(LocaleKeys.deletePost)  // ✅ Reusing existing key

// Step 3: Only add if truly doesn't exist
static const String deletePost = 'delete.post';  // Only if not found
```

### 3. **Use //TODO LocaleKeys for Pending Translations**

When you find a hardcoded string that needs a LocaleKey but the key doesn't exist yet:

```dart
// ✅ CORRECT - Mark for later
MyText(
  //TODO LocaleKeys
  'pending.translation.key',
)
```

### 4. **ALWAYS Remove //TODO Comments After Fixing**

⚠️ **CRITICAL:** Once you've added the LocaleKey and replaced the hardcoded string, **DELETE the //TODO comment**:

```dart
// ❌ WRONG - TODO still present after fix
MyText(
  //TODO LocaleKeys
  LocaleKeys.myKey,  // Fixed but TODO not removed!
)

// ✅ CORRECT - TODO removed after fix
MyText(LocaleKeys.myKey)
```

---

## 🔑 LocaleKeys Naming Conventions

### Format: `camelCase` for constant names, `dot.notation` for translation keys

```dart
// ✅ CORRECT
static const String myProfilePage = 'my.profile.page';
static const String errorLoadingData = 'error.loading.data';
static const String successfullySaved = 'successfully.saved';

// ❌ WRONG
static const String my_profile_page = 'my_profile_page';  // Don't use snake_case
static const String ErrorLoadingData = 'ErrorLoadingData';  // Don't use PascalCase
static const String myprofilepage = 'myprofilepage';  // Don't omit dots
```

### Grouping Strategy

Organize keys by **feature/domain**, not alphabetically:

```dart
class LocaleKeys {
  // App Basic
  static const String appTitle = 'app.title';
  static const String appName = 'app.name';
  
  // Common Actions
  static const String save = 'save';
  static const String cancel = 'cancel';
  static const String delete = 'delete';
  
  // Profile Group
  static const String profile = 'profile';
  static const String editProfile = 'edit.profile';
  static const String viewProfile = 'view.profile';
  
  // Posts & Social
  static const String post = 'post';
  static const String createPost = 'create.post';
  static const String deletePost = 'delete.post';
}
```

---

## 🚫 Avoiding Duplicates & Strict Ordering

### Rule 1: ONE key, ONE definition
Before adding a new key, **ALWAYS search** across the entire file to ensure it doesn't already exist.

### Rule 2: Strict Logical Ordering
Keys MUST be added to their corresponding **Feature Group** and kept in a logical order (alphabetical within the group is preferred, but related keys like `delete` and `deleteConfirmation` should stay together).

❌ **WRONG - Adding at the end of the file:**
```dart
  // ... line 700 ...
  static const String newUserKey = 'new.user.key'; // DON'T JUST APPEND
}
```

✅ **ALWAYS DO THIS:**
1. Find the relevant group (e.g., `// Profile Group`).
2. Insert the key in the correct place within that group.
3. If no group exists, create a new one with a clear header comment.

### Rule 3: Check, Order, No Repeats
We cannot afford to repeat errors of duplicate or misplaced keys. 
1. **CHECK**: Search for the key name AND the string value.
2. **ORDER**: Place it in the correct feature group.
3. **VERIFY**: Ensure no other key in the file uses the same translation string unless explicitly intended.

---

## 📁 File Import Paths

### Rule: Use CORRECT relative paths based on file location

```dart
// ❌ WRONG - Incorrect number of "../"
// File: lib/features/profile/posts/pages/posts_feed_page.dart
import '../../../core/lang/locale_keys.dart';  // TOO FEW

// ✅ CORRECT
import '../../../../core/lang/locale_keys.dart';  // CORRECT (4 levels up)
```

### Quick Reference:

| File Location | Path to `core/lang/locale_keys.dart` |
|--------------|--------------------------------------|
| `lib/features/public/` | `../../core/lang/locale_keys.dart` |
| `lib/features/dashboard/` | `../../core/lang/locale_keys.dart` |
| `lib/features/profile/pages/` | `../../../core/lang/locale_keys.dart` |
| `lib/features/profile/posts/pages/` | `../../../../core/lang/locale_keys.dart` |
| `lib/features/profile/widgets/` | `../../../core/lang/locale_keys.dart` |

**Tip:** Count the directory levels from your file to `lib/`, then add the path to `core/lang/locale_keys.dart`.

---

## 🛠️ Widget Usage Patterns

### MyText Widget

`MyText` automatically translates keys using `context.tr()`:

```dart
// ✅ CORRECT - MyText handles translation
MyText(LocaleKeys.welcomeMessage)

// ❌ WRONG - Don't double-translate
MyText(context.tr(LocaleKeys.welcomeMessage))
```

### MyButton Widget

```dart
// ✅ CORRECT
MyButton(
  text: LocaleKeys.saveChanges,
  onPressed: _handleSave,
)
```

### MyForm Widget

```dart
// ✅ CORRECT
MyForm(
  title: LocaleKeys.editProfile,
  buttonText: LocaleKeys.save,
  formItems: [...],
  onSubmit: _handleSubmit,
)
```

### context.tr() Direct Usage

Use `context.tr()` when you need the translated string directly:

```dart
// ✅ CORRECT - For tooltips, hints, validators
tooltip: context.tr(LocaleKeys.clickToEdit),
hintText: context.tr(LocaleKeys.enterYourName),

// ✅ CORRECT - For SnackBars and Dialogs
SnackBarHelper.showSuccess(context, LocaleKeys.dataSaved);
```

---

## 📝 FormItemConfig Pattern

### Rule: Use LocaleKeys for labels and hints

```dart
// ✅ CORRECT
FormItemConfig(
  id: 'email',
  type: FormFieldType.email,
  label: LocaleKeys.email,
  hintText: LocaleKeys.enterYourEmail,
  isRequired: true,
)

// ❌ WRONG
FormItemConfig(
  id: 'email',
  type: FormFieldType.email,
  label: 'email',  // Hardcoded
  hintText: 'enter_your_email',  // Hardcoded
  isRequired: true,
)
```

---

## 🔍 Common Mistakes & Solutions

### Mistake 1: Using hardcoded strings

```dart
// ❌ WRONG
MyText('delete.post')

// ✅ CORRECT
MyText(LocaleKeys.deletePost)
```

### Mistake 2: Inconsistent key naming

```dart
// ❌ WRONG - Mixed conventions
static const String enter_your_name = 'enter.your.name';
static const String EnterYourEmail = 'enter.your.email';

// ✅ CORRECT - Consistent camelCase
static const String enterYourName = 'enter.your.name';
static const String enterYourEmail = 'enter.your.email';
```

### Mistake 3: Creating duplicate keys

```dart
// ❌ WRONG - Duplicate definitions
static const String deletePost = 'delete.post';  // Line 189
// ... 400 lines later ...
static const String deletePost = 'delete.post';  // Line 605 - DUPLICATE!

// ✅ CORRECT - Search first, reuse existing
// Just use the existing LocaleKeys.deletePost
```

### Mistake 4: Wrong import paths

```dart
// ❌ WRONG
import '../../../core/lang/locale_keys.dart';  // File is 4 levels deep

// ✅ CORRECT
import '../../../../core/lang/locale_keys.dart';  // Correct for 4 levels
```

---

## 🎨 Key Naming Patterns

### Actions
- `create`, `edit`, `delete`, `save`, `cancel`, `submit`, `update`
- `createPost`, `editProfile`, `deleteComment`

### States
- `loading`, `error`, `success`, `empty`
- `errorLoadingData`, `successfullySaved`, `noDataAvailable`

### UI Elements
- `title`, `description`, `label`, `hint`, `placeholder`
- `enterYourName`, `selectCategory`, `chooseFromGallery`

### Messages
- `confirmation`, `warning`, `info`
- `deletePostConfirmation`, `unsavedChangesWarning`

### Navigation
- `goBack`, `viewDetails`, `viewAll`, `backToHome`

---

## 📝 Widget Documentation

### Rule: Add brief comment above each widget function

Every widget function should have a **very brief** comment explaining its purpose:

```dart
// ✅ CORRECT - Brief, clear comment
/// Displays user posts in a scrollable feed
class PostsFeedPage extends StatelessWidget {
  // ...
}

/// Shows delete confirmation dialog
void _showDeleteDialog(BuildContext context) {
  // ...
}

/// Builds the loading state UI
Widget _buildLoadingState() {
  return Center(child: CircularProgressIndicator());
}

// ❌ WRONG - Too verbose
/// This widget is responsible for displaying a comprehensive list of all user-generated
/// posts in a vertically scrollable feed format with infinite scroll pagination support
class PostsFeedPage extends StatelessWidget {
  // ...
}

// ❌ WRONG - No comment
class PostsFeedPage extends StatelessWidget {
  // ...
}
```

**Format:**
- Use `///` for class/widget documentation
- Use `//` for private helper methods
- Keep it to **one line** whenever possible
- Focus on **what** it does, not **how**

---

## ✅ Checklist Before Committing

- [ ] All `MyText()` calls use `LocaleKeys.xxx`
- [ ] All `context.tr()` calls use `LocaleKeys.xxx`
- [ ] All `SnackBarHelper` messages use `LocaleKeys.xxx`
- [ ] All `FormItemConfig` labels/hints use `LocaleKeys.xxx`
- [ ] No hardcoded translation strings (e.g., `'my.key'`)
- [ ] No duplicate key definitions in `LocaleKeys.dart`
- [ ] Import paths are correct for file location
- [ ] New keys follow camelCase naming convention
- [ ] New keys are grouped logically in `LocaleKeys.dart`

---

## 🔧 Tools & Commands

### Search for hardcoded strings:
```bash
# Find potential hardcoded strings in Dart files
grep -r "MyText('[a-z]" lib/
grep -r "context.tr('[a-z]" lib/
```

### Find duplicate keys:
```bash
# In LocaleKeys.dart, search for:
static const String
# Then manually check for duplicates
```

### Verify imports:
```bash
# Check if LocaleKeys is imported
grep -l "LocaleKeys" lib/features/**/*.dart
```

---

## 📚 Examples

### Complete Example: Login Page

```dart
import 'package:flutter/material.dart';
import 'package:street_core/core/lang/locale_keys.dart';
import 'package:street_core/core/widgets/my_form.dart';
import 'package:street_core/core/widgets/my_text.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MyText(LocaleKeys.logIn),  // ✅
      ),
      body: MyForm(
        title: LocaleKeys.logIn,  // ✅
        buttonText: LocaleKeys.logIn,  // ✅
        formItems: [
          FormItemConfig.email(
            id: 'email',
            label: LocaleKeys.email,  // ✅
            hintText: LocaleKeys.enterYourEmail,  // ✅
          ),
          FormItemConfig.password(
            id: 'password',
            label: LocaleKeys.password,  // ✅
          ),
        ],
        onSubmit: (data) {
          // Handle login
          SnackBarHelper.showSuccess(
            context,
            LocaleKeys.loginSuccessful,  // ✅
          );
        },
      ),
    );
  }
}
```

---

## 🚀 Migration Strategy

When updating existing code:

1. **Search** for hardcoded strings: `'my.key'`
2. **Check** if LocaleKey exists in `LocaleKeys.dart`
3. **Add** missing key if needed (check for duplicates first!)
4. **Replace** hardcoded string with `LocaleKeys.xxx`
5. **Add** import if missing
6. **Test** that translation works
7. **Mark** with `//TODO LocaleKeys` if key is missing and needs to be added later

---

## 📞 Questions?

If you're unsure about:
- **Key naming**: Follow existing patterns in `LocaleKeys.dart`
- **Duplicates**: Search before adding
- **Import paths**: Count directory levels
- **Widget usage**: Check this document's examples

**Remember:** Consistency is key! When in doubt, look at existing code that follows these rules.

---

**Last Updated:** 2026-01-06  
**Version:** 1.0  
**Maintained by:** Street Core Team
