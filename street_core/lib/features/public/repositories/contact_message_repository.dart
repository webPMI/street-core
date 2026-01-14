import '../../../core/services/api_response.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/api_uris.dart';
import '../../../data/models/contact_message_model.dart';

/// Repository for public contact message operations
///
/// This repository handles the public contact form submission.
/// For admin operations, see AdminContactMessageRepository in admin/data/
class ContactMessageRepository {
  ContactMessageRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();
  final ApiService _apiService;

  /// Submit a contact message from the public contact form
  ///
  /// Returns [ApiResponse] with the created message ID on success
  /// Rate limited: 5 requests per hour per IP
  Future<ApiResponse<String>> submitContactMessage({
    required String name,
    required String email,
    String? phone,
    required String subject,
    required String message,
    String? category,
  }) async {
    final data = {
      'name': name,
      'email': email,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      'subject': subject,
      'message': message,
      if (category != null) 'category': category,
    };

    final response = await _apiService.useFetch<String>(
      ApiUris.submitContactMessage,
      method: 'POST',
      requiredToken: false,
      body: data, // FIXED: was dataToSend
      fromJsonT: (data) {
        if (data is Map<String, dynamic>) {
          return data['id']?.toString() ?? '';
        }
        return '';
      },
    );

    return response;
  }

  /// Submit a contact message from a ContactMessage model
  Future<ApiResponse<String>> submitMessage(ContactMessage message) async {
    return submitContactMessage(
      name: message.name ?? '',
      email: message.email ?? '',
      phone: message.phone,
      subject: message.subject ?? '',
      message: message.message ?? '',
      category: message.category,
    );
  }
}
