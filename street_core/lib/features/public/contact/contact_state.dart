abstract class ContactState {}

class ContactInitial extends ContactState {}

class ContactSubmitting extends ContactState {}

class ContactSubmitSuccess extends ContactState {

  ContactSubmitSuccess({required this.message, this.messageId});
  final String message;
  final String? messageId;
}

class ContactSubmitError extends ContactState {

  ContactSubmitError({required this.message});
  final String message;
}
