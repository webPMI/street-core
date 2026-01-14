import '/core/services/api_address.dart';

class UserModel {

  UserModel({
    required this.id,
    required this.firstName,
    required this.email,
    required this.role,
    this.phone,
    this.lastName,
    this.nickName,
    this.userName,
    this.isPremium = false,
    this.gender,
    this.imageUrl,
    this.avatarUrl,
    this.createdAt,
    this.updatedAt,
    this.bio,
    this.isActive = true,
    this.emailVerified = false,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.isVerified = false,
    this.isPrivate = false,
    this.twoFactorEnabled = false,
    this.twoFactorVerifiedAt,
    this.oauthProviders,
  });

  // 1. Deserialización: Crear modelo desde JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // 1. Extracción de nombres para construir 'name'
    final String firstName = json['firstName'] as String? ?? '';
    final String rawLastName = json['lastName'] as String? ?? '';

    // CONSTRUCCIÓN DEL CAMPO 'name': Combina firstName y lastName.
    final String fullName = '$firstName $rawLastName'.trim();

    // 2. Manejo de fechas
    DateTime? parsedCreatedAt;
    if (json['createdAt'] != null) {
      parsedCreatedAt = DateTime.tryParse(json['createdAt'] as String);
    }

    DateTime? parsedUpdatedAt;
    if (json['updatedAt'] != null) {
      parsedUpdatedAt = DateTime.tryParse(json['updatedAt'] as String);
    }

    // 3. Helper para convertir cadena vacía a null
    String? stringOrNull(String? value) {
      if (value == null) return null;
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    // Parse oauthProviders list
    List<String>? oauthProvidersList;
    if (json['oauthProviders'] != null) {
      oauthProvidersList = (json['oauthProviders'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList();
    }

    // Parse twoFactorVerifiedAt
    DateTime? parsedTwoFactorVerifiedAt;
    if (json['twoFactorVerifiedAt'] != null) {
      parsedTwoFactorVerifiedAt = DateTime.tryParse(json['twoFactorVerifiedAt'] as String);
    }

    return UserModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      firstName: fullName,
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'client',

      // 💡 Aplicación de la regla: Convertir "" a null para campos opcionales
      phone: stringOrNull(json['phone']?.toString()),
      lastName: stringOrNull(rawLastName),
      nickName: stringOrNull(json['nickName'] as String?),
      userName: stringOrNull(json['userName'] as String?),

      isPremium: json['isPremium'] as bool? ?? false,

      gender: stringOrNull(json['gender'] as String?),
      // Backend has both imageUrl and avatarUrl - use whichever is available
      // Convert relative URLs to absolute URLs for proper image loading
      imageUrl: mediaUrlOrNull(
          json['imageUrl'] as String? ?? json['avatarUrl'] as String?),
      avatarUrl: mediaUrlOrNull(json['avatarUrl'] as String?),
      bio: stringOrNull(json['bio'] as String?),

      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,

      // Account status
      isActive: json['isActive'] as bool? ?? true,
      emailVerified: json['emailVerified'] as bool? ?? false,

      // Social features
      followersCount: json['followersCount'] as int? ?? 0,
      followingCount: json['followingCount'] as int? ?? 0,
      postsCount: json['postsCount'] as int? ?? 0,
      isVerified: json['isVerified'] as bool? ?? false,
      isPrivate: json['isPrivate'] as bool? ?? false,

      // Two-Factor Authentication
      twoFactorEnabled: json['twoFactorEnabled'] as bool? ?? false,
      twoFactorVerifiedAt: parsedTwoFactorVerifiedAt,

      // OAuth providers
      oauthProviders: oauthProvidersList,
    );
  }
  final String id;
  // Usamos 'name' para el nombre completo, construido a partir de firstName y lastName
  final String firstName;
  final String email;
  final String role; // Rol del usuario (ej: 'admin', 'client')

  // Campos opcionales (Nullable)
  final String? phone;
  final String? lastName;
  final String? nickName;
  final String? userName; // Username único del usuario
  final bool isPremium;
  final String? gender;
  final String? imageUrl;
  final String? avatarUrl; // URL alternativa del avatar (compatibilidad backend)
  final DateTime? createdAt; // Fecha de creación de la cuenta
  final DateTime? updatedAt; // Fecha de última actualización
  final String? bio; // Biografía corta

  // Account status
  final bool isActive;
  final bool emailVerified;

  // Social features
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final bool isVerified;
  final bool isPrivate;

  // Two-Factor Authentication
  final bool twoFactorEnabled;
  final DateTime? twoFactorVerifiedAt;

  // OAuth providers
  final List<String>? oauthProviders;

  // --- MÉTODOS AÑADIDOS ---

  // 2. Serialización: Convertir modelo a JSON (para enviar a la API)
  Map<String, dynamic> toJson() {
    // Derive firstName for backend which likely expects it split
    String derivedFirstName = firstName;
    if (lastName != null &&
        lastName!.isNotEmpty &&
        firstName.toLowerCase().endsWith(lastName!.toLowerCase())) {
      // Remove last name from the end of the full name to get first name
      // Use case-insensitive check and length to handle basic trimming
      // But preserving original casing from name for the substring extraction
      final withoutLast = firstName.substring(
        0,
        firstName.length - lastName!.length,
      );
      derivedFirstName = withoutLast.trim();
    }

    // Fallback: if name logic fails but we have a space (simple split)
    if (derivedFirstName == firstName &&
        firstName.contains(' ') &&
        lastName != null &&
        lastName!.isNotEmpty) {
      // logic above might fail if cases don't match exactly or spaces differ.
      // This is a second resilient attempt, or we can just send firstName if we stored it.
      // Since we don't store it, we do our best.
    }

    return {
      'id': id,
      'firstName': derivedFirstName, // Backend expects 'firstName'
      'email': email,
      'role': role,
      'phone': phone,
      'lastName': lastName,
      'nickName': nickName,
      'userName': userName,
      'isPremium': isPremium,
      'gender': gender,
      'imageUrl': imageUrl,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isActive': isActive,
      'emailVerified': emailVerified,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
      'isVerified': isVerified,
      'isPrivate': isPrivate,
      'twoFactorEnabled': twoFactorEnabled,
      'twoFactorVerifiedAt': twoFactorVerifiedAt?.toIso8601String(),
      'oauthProviders': oauthProviders,
    };
  }

  // 3. Método copyWith (ESENCIAL para BLoC/Cubit)
  UserModel copyWith({
    String? id,
    String? firstName,
    String? email,
    String? role,
    String? phone,
    String? lastName,
    String? nickName,
    String? userName,
    bool? isPremium,
    String? gender,
    String? imageUrl,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? bio,
    bool? isActive,
    bool? emailVerified,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    bool? isVerified,
    bool? isPrivate,
    bool? twoFactorEnabled,
    DateTime? twoFactorVerifiedAt,
    List<String>? oauthProviders,
  }) {
    return UserModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      lastName: lastName ?? this.lastName,
      nickName: nickName ?? this.nickName,
      userName: userName ?? this.userName,
      isPremium: isPremium ?? this.isPremium,
      gender: gender ?? this.gender,
      imageUrl: imageUrl ?? this.imageUrl,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      bio: bio ?? this.bio,
      isActive: isActive ?? this.isActive,
      emailVerified: emailVerified ?? this.emailVerified,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      isVerified: isVerified ?? this.isVerified,
      isPrivate: isPrivate ?? this.isPrivate,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      twoFactorVerifiedAt: twoFactorVerifiedAt ?? this.twoFactorVerifiedAt,
      oauthProviders: oauthProviders ?? this.oauthProviders,
    );
  }
}

// Typedef for convenience
typedef User = UserModel;
