/// Auth Feature - Barrel Export
/// Import this file to access all auth components.
library;

import '../../data/models/user_model.dart';

// Models
export 'models/auth_tokens.dart';
export 'models/auth_exceptions.dart';

// Services
export 'services/auth_service.dart';

// BLoC / State Management
export 'bloc/auth_cubit.dart';
export 'bloc/auth_state.dart';
export 'bloc/user_cubit.dart';
export 'bloc/user_state.dart';
// Type alias for backward compatibility
// Use 'User' as alias for 'UserModel' throughout the codebase

typedef User = UserModel;
