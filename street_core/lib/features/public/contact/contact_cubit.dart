import '../repositories/contact_message_repository.dart';
import 'contact_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ContactCubit extends Cubit<ContactState> {
  ContactCubit({ContactMessageRepository? repository})
    : _repository = repository ?? ContactMessageRepository(),
      super(ContactInitial());
  final ContactMessageRepository _repository;

  /// Submit contact form message
  Future<void> submitMessage({
    required String name,
    required String email,
    String? phone,
    required String subject,
    required String message,
    String? category,
  }) async {
    emit(ContactSubmitting());

    try {
      final response = await _repository.submitContactMessage(
        name: name,
        email: email,
        phone: phone,
        subject: subject,
        message: message,
        category: category,
      );

      if (response.status == 'success') {
        emit(
          ContactSubmitSuccess(
            message: response.message.isEmpty
                ? 'contact_message_submitted'
                : response.message,
            messageId: response.data,
          ),
        );
      } else {
        emit(
          ContactSubmitError(
            message: response.message.isEmpty
                ? 'contact_message_submit_error'
                : response.message,
          ),
        );
      }
    } catch (e) {
      emit(ContactSubmitError(message: 'contact_message_submit_error'));
    }
  }

  /// Reset to initial state
  void reset() {
    emit(ContactInitial());
  }
}
