// 1. Estado (FormState)

import '../../services/api_response.dart';

class MyFormState {
  const MyFormState({
    this.isLoading = false,
    this.errorMessage,
    this.message,
    this.response,
  });
  final bool isLoading;
  final String? errorMessage;
  final String? message;
  final ApiResponse? response;

  MyFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? message,
    ApiResponse? response,
  }) {
    return MyFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      message: message,
      response: response,
    );
  }
}
