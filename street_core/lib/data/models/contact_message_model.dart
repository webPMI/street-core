/// Model for contact messages sent through the contact form
class ContactMessage {

  ContactMessage({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.subject,
    this.message,
    this.category,
    this.status,
    this.isReadFlag = false,
    this.createdAt,
    this.updatedAt,
    this.readAt,
    this.repliedAt,
    this.repliedBy,
    this.replyMessage,
    this.adminNotes,
    this.assignedTo,
  });

  factory ContactMessage.fromJson(Map<String, dynamic> json) {
    return ContactMessage(
      id: json['id'] ?? json['_id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      subject: json['subject'],
      message: json['message'],
      category: json['category'] ?? 'general',
      status: json['status'] ?? 'new',
      isReadFlag: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      readAt:
          json['readAt'] != null ? DateTime.tryParse(json['readAt']) : null,
      repliedAt: json['repliedAt'] != null
          ? DateTime.tryParse(json['repliedAt'])
          : null,
      repliedBy: json['repliedBy'],
      replyMessage: json['replyMessage'],
      adminNotes: json['adminNotes'],
      assignedTo: json['assignedTo'],
    );
  }
  final String? id;
  final String? name;
  final String? email;
  final String? phone;
  final String? subject;
  final String? message;
  final String? category; // 'general', 'support', 'sales', 'feedback', 'other'
  final String? status; // 'new', 'read', 'replied', 'archived'
  final bool isReadFlag;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? readAt;
  final DateTime? repliedAt;
  final String? repliedBy;
  final String? replyMessage;
  final String? adminNotes;
  final String? assignedTo;

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (subject != null) 'subject': subject,
        if (message != null) 'message': message,
        if (category != null) 'category': category,
        if (status != null) 'status': status,
        'isRead': isReadFlag,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
        if (readAt != null) 'readAt': readAt!.toIso8601String(),
        if (repliedAt != null) 'repliedAt': repliedAt!.toIso8601String(),
        if (repliedBy != null) 'repliedBy': repliedBy,
        if (replyMessage != null) 'replyMessage': replyMessage,
        if (adminNotes != null) 'adminNotes': adminNotes,
        if (assignedTo != null) 'assignedTo': assignedTo,
      };

  /// For form submission (only send required fields)
  Map<String, dynamic> toSubmitJson() => {
        'name': name,
        'email': email,
        if (phone != null && phone!.isNotEmpty) 'phone': phone,
        'subject': subject,
        'message': message,
        if (category != null) 'category': category,
      };

  bool get isNew => status == 'new';
  bool get isRead =>
      isReadFlag ||
      status == 'read' ||
      status == 'replied' ||
      status == 'archived';
  bool get isReplied => status == 'replied';
  bool get isArchived => status == 'archived';

  ContactMessage copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? subject,
    String? message,
    String? category,
    String? status,
    bool? isReadFlag,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? readAt,
    DateTime? repliedAt,
    String? repliedBy,
    String? replyMessage,
    String? adminNotes,
    String? assignedTo,
  }) {
    return ContactMessage(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      subject: subject ?? this.subject,
      message: message ?? this.message,
      category: category ?? this.category,
      status: status ?? this.status,
      isReadFlag: isReadFlag ?? this.isReadFlag,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      readAt: readAt ?? this.readAt,
      repliedAt: repliedAt ?? this.repliedAt,
      repliedBy: repliedBy ?? this.repliedBy,
      replyMessage: replyMessage ?? this.replyMessage,
      adminNotes: adminNotes ?? this.adminNotes,
      assignedTo: assignedTo ?? this.assignedTo,
    );
  }
}

/// Stats model for contact messages
class ContactMessageStats {

  ContactMessageStats({
    this.totalCount = 0,
    this.unreadCount = 0,
    this.newCount = 0,
    this.repliedCount = 0,
  });

  factory ContactMessageStats.fromJson(Map<String, dynamic> json) {
    return ContactMessageStats(
      totalCount: json['totalCount'] ?? 0,
      unreadCount: json['unreadCount'] ?? 0,
      newCount: json['newCount'] ?? 0,
      repliedCount: json['repliedCount'] ?? 0,
    );
  }
  final int totalCount;
  final int unreadCount;
  final int newCount;
  final int repliedCount;
}
