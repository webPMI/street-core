/// Contact Information Model
///
/// Contains contact details for the organization.
class ContactInfo {
  ContactInfo({
    this.email,
    this.phone,
    this.whatsapp,
    this.address,
    this.city,
    this.country,
    this.postalCode,
    this.businessHours,
    this.mapLatitude,
    this.mapLongitude,
    this.mapEmbedUrl,
  });

  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    return ContactInfo(
      email: json['email'],
      phone: json['phone'],
      whatsapp: json['whatsapp'],
      address: json['address'],
      city: json['city'],
      country: json['country'],
      postalCode: json['postalCode'],
      businessHours: json['businessHours'],
      mapLatitude: json['mapLatitude'],
      mapLongitude: json['mapLongitude'],
      mapEmbedUrl: json['mapEmbedUrl'],
    );
  }

  factory ContactInfo.empty() => ContactInfo();

  final String? email;
  final String? phone;
  final String? whatsapp;
  final String? address;
  final String? city;
  final String? country;
  final String? postalCode;
  final String? businessHours;
  final String? mapLatitude;
  final String? mapLongitude;
  final String? mapEmbedUrl;

  // Convenience getters with default empty string
  String get safeEmail => email ?? '';
  String get safePhone => phone ?? '';
  String get safeWhatsApp => whatsapp ?? '';
  String get safeAddress => address ?? '';
  String get safeCity => city ?? '';
  String get safeCountry => country ?? '';
  String get safePostalCode => postalCode ?? '';
  String get safeBusinessHours => businessHours ?? '';
  String get safeMapEmbedUrl => mapEmbedUrl ?? '';

  Map<String, dynamic> toJson() => {
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (whatsapp != null) 'whatsapp': whatsapp,
        if (address != null) 'address': address,
        if (city != null) 'city': city,
        if (country != null) 'country': country,
        if (postalCode != null) 'postalCode': postalCode,
        if (businessHours != null) 'businessHours': businessHours,
        if (mapLatitude != null) 'mapLatitude': mapLatitude,
        if (mapLongitude != null) 'mapLongitude': mapLongitude,
        if (mapEmbedUrl != null) 'mapEmbedUrl': mapEmbedUrl,
      };

  ContactInfo copyWith({
    String? email,
    String? phone,
    String? whatsapp,
    String? address,
    String? city,
    String? country,
    String? postalCode,
    String? businessHours,
    String? mapLatitude,
    String? mapLongitude,
    String? mapEmbedUrl,
  }) {
    return ContactInfo(
      email: email ?? this.email,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      businessHours: businessHours ?? this.businessHours,
      mapLatitude: mapLatitude ?? this.mapLatitude,
      mapLongitude: mapLongitude ?? this.mapLongitude,
      mapEmbedUrl: mapEmbedUrl ?? this.mapEmbedUrl,
    );
  }
}
