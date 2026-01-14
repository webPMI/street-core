# Media Upload Cubit

State management for media upload operations with progress tracking, validation, and error handling.

## Features

- Progress tracking during uploads
- Built-in validation before upload
- Automatic retry logic (via MediaUploadService)
- Error handling with localized error codes
- Support for single and multiple file uploads
- Cross-platform (web, mobile, desktop)

## Usage

### 1. Basic Setup with BlocProvider

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:street_core/core/media/bloc/media_bloc.dart';
import 'package:street_core/core/di/injection.dart';

class MyUploadPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<MediaUploadCubit>(),
      child: MyUploadView(),
    );
  }
}
```

### 2. Upload Avatar

```dart
class MyUploadView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MediaUploadCubit, MediaUploadState>(
      listener: (context, state) {
        if (state is MediaUploadSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Avatar uploaded: ${state.response.url}')),
          );
        } else if (state is MediaUploadError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr(state.errorCode)),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is MediaUploadLoading) {
          return Column(
            children: [
              CircularProgressIndicator(value: state.progress),
              Text('${(state.progress * 100).toInt()}%'),
            ],
          );
        }

        return ElevatedButton(
          onPressed: () async {
            final file = await pickImageFile();
            if (file != null) {
              context.read<MediaUploadCubit>().uploadAvatar(file);
            }
          },
          child: Text('Upload Avatar'),
        );
      },
    );
  }
}
```

### 3. Upload Multiple Images

```dart
ElevatedButton(
  onPressed: () async {
    final picker = ImagePicker();
    final xfiles = await picker.pickMultiImage();

    if (xfiles.isNotEmpty) {
      context.read<MediaUploadCubit>().uploadMultiple(xfiles);
    }
  },
  child: Text('Upload Multiple'),
);

// Listen to state
BlocListener<MediaUploadCubit, MediaUploadState>(
  listener: (context, state) {
    if (state is MediaUploadMultipleSuccess) {
      print('Uploaded ${state.responses.length} files');
      for (final response in state.responses) {
        print('URL: ${response.url}');
      }
    }
  },
  child: ...,
);
```

### 4. Cancel Upload

```dart
IconButton(
  icon: Icon(Icons.cancel),
  onPressed: () {
    context.read<MediaUploadCubit>().cancelUpload();
  },
);
```

### 5. Reset State

```dart
// Reset to initial state (useful after success/error)
context.read<MediaUploadCubit>().reset();
```

## States

### MediaUploadInitial
- No upload in progress
- Default state

### MediaUploadLoading
- Upload in progress
- Properties:
  - `progress` (double): 0.0 to 1.0
  - `fileName` (String?): Name of file being uploaded

### MediaUploadSuccess
- Single file uploaded successfully
- Properties:
  - `response` (MediaUploadResponse): Contains URL and filename

### MediaUploadMultipleSuccess
- Multiple files uploaded successfully
- Properties:
  - `responses` (List<MediaUploadResponse>): List of uploaded files

### MediaUploadError
- Upload failed
- Properties:
  - `errorCode` (String): Translation key (e.g., 'error.upload.failed')
  - `errorMessage` (String): Fallback error message

### MediaUploadCancelled
- Upload cancelled by user

## Error Codes

All error codes are localized in `lib/core/lang/translations/es/upload_es.dart`:

- `error.upload.failed`: General upload failure
- `error.avatar.too_large`: Avatar exceeds 5MB
- `error.image.too_large`: Image exceeds 10MB
- `error.video.too_large`: Video exceeds 500MB
- `error.file.too_small`: File under 1KB
- `error.invalid.file_type`: Invalid file extension
- `error.invalid_mime_type`: Invalid MIME type
- `error.no.files.selected`: No files selected
- `error.too.many.files`: Too many files (max 10)
- `error.total.size.exceeded`: Total size exceeds limit

## Integration with FileUploadWidget

The `FileUploadWidget` can be used alongside `MediaUploadCubit`:

```dart
BlocProvider(
  create: (context) => getIt<MediaUploadCubit>(),
  child: Column(
    children: [
      FileUploadWidget(
        maxFiles: 5,
        onFilesSelected: (files) {
          // Files selected, now upload them
          if (files.isNotEmpty) {
            context.read<MediaUploadCubit>().uploadImage(files.first);
          }
        },
      ),
      BlocBuilder<MediaUploadCubit, MediaUploadState>(
        builder: (context, state) {
          if (state is MediaUploadLoading) {
            return LinearProgressIndicator(value: state.progress);
          }
          return SizedBox.shrink();
        },
      ),
    ],
  ),
);
```

## Retry Logic

The `MediaUploadService` (used internally by the Cubit) includes automatic retry logic:

- **Max retries**: 3 attempts
- **Backoff strategy**: Exponential (2^attempt seconds)
  - Attempt 1: Immediate
  - Attempt 2: Wait 2 seconds
  - Attempt 3: Wait 4 seconds
- **Applies to**: All upload operations (avatar, image, multiple)

## Future Enhancements

### Dio Integration (Planned)

When Dio is integrated, the Cubit will support:

1. **Real-time progress tracking**:
   ```dart
   MediaUploadLoading(
     progress: 0.45, // 45% uploaded
     fileName: 'photo.jpg',
   )
   ```

2. **Upload cancellation**:
   ```dart
   context.read<MediaUploadCubit>().cancelUpload();
   // Actually cancels the HTTP request
   ```

3. **Streaming uploads** for large files (>50MB)

## Dependency Injection

The `MediaUploadCubit` is registered as a **Factory** (not Singleton) in DI:

```dart
// lib/core/media/di/media_injection.dart
getIt.registerFactory<MediaUploadCubit>(
  () => MediaUploadCubit(getIt<MediaUploadService>()),
);
```

This means:
- Each `BlocProvider` gets a fresh instance
- No state leakage between screens
- Proper cleanup when widget is disposed

## Testing

Example test:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

class MockMediaUploadService extends Mock implements MediaUploadService {}

void main() {
  group('MediaUploadCubit', () {
    late MediaUploadService service;
    late MediaUploadCubit cubit;

    setUp(() {
      service = MockMediaUploadService();
      cubit = MediaUploadCubit(service);
    });

    tearDown(() {
      cubit.close();
    });

    blocTest<MediaUploadCubit, MediaUploadState>(
      'emits [Loading, Success] when upload succeeds',
      build: () {
        when(() => service.uploadAvatar(any()))
            .thenAnswer((_) async => MediaUploadResponse(
                  url: 'https://example.com/avatar.jpg',
                  filename: 'avatar.jpg',
                ));
        return cubit;
      },
      act: (cubit) => cubit.uploadAvatar(File('test.jpg')),
      expect: () => [
        isA<MediaUploadLoading>(),
        isA<MediaUploadSuccess>(),
      ],
    );
  });
}
```

## See Also

- `FileUploadWidget`: UI component for file selection
- `MediaValidator`: File validation logic
- `MediaUploadService`: Low-level upload operations
- `ApiMediaService`: HTTP layer for media operations
