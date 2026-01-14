import 'package:street_core/core/lang/locale_keys.dart';

import '/core/services/api_service.dart';
import 'form_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Form Cubit with Dependency Injection
///
/// Manages form submission state with proper DI and error handling
class MyFormCubit extends Cubit<MyFormState> {
  MyFormCubit({
    required this.apiService,
    required this.route,
    required this.method,
  }) : super(const MyFormState());
  final ApiService apiService; // ✅ Injected
  final String route;
  final String method;

  /// Submit form data to API
  ///
  /// Emits states: loading -> success/error
  /// Widget should listen to states and handle UI feedback
  Future<void> submitForm(Map<String, dynamic> data) async {
    // Clear previous messages and start loading
    emit(state.copyWith(isLoading: true));

    try {
      // Call API
      final response = await apiService.useFetch(
        route,
        method: method,
        body: data,
      );

      // Handle response
      if (!isClosed) {
        if (response.status == 'success') {
          emit(
            state.copyWith(
              isLoading: false,
              message: response.message,
              response: response,
            ),
          );
        } else {
          // Business logic error from API
          emit(
            state.copyWith(isLoading: false, errorMessage: response.message),
          );
        }
      }
    } catch (e) {
      // Network or unexpected error
      if (!isClosed) {
        emit(state.copyWith(isLoading: false, errorMessage: 'error_network'));
      }
    }
  }

  /// Clear error and success messages
  void clearMessages() {
    if (!isClosed) {
      emit(state.copyWith());
    }
  }

  /// Send form data with callback
  ///
  /// Alternative to submitForm() that uses callbacks instead of state emission
  /// Useful when you need custom logic after success/error
  Future<void> sendForm({
    required Map<String, dynamic> dataToSend,
    required Function(dynamic response) onSuccess,
    Function(String error)? onError,
  }) async {
    // Emit loading state
    emit(state.copyWith(isLoading: true));

    try {
      // Call API
      final response = await apiService.useFetch(
        route,
        method: method,
        body: dataToSend,
      );

      // Handle response
      if (!isClosed) {
        if (response.status == 'success') {
          // Success: emit state and call callback
          emit(
            state.copyWith(
              isLoading: false,
              message: response.message,
              response: response,
            ),
          );
          onSuccess(response);
        } else {
          // Business logic error from API
          final errorMsg = response.message;
          emit(state.copyWith(isLoading: false, errorMessage: errorMsg));
          if (onError != null) {
            onError(errorMsg);
          }
        }
      }
    } catch (e) {
      // Network or unexpected error
      if (!isClosed) {
        const errorMsg = LocaleKeys.errorNetwork;
        emit(state.copyWith(isLoading: false, errorMessage: errorMsg));
        if (onError != null) {
          onError(errorMsg);
        }
      }
    }
  }
}
