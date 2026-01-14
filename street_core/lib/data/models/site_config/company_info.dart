/// Company Information Model
///
/// Contains basic company/organization details.
class CompanyInfo {
  CompanyInfo({
    this.name,
    this.legalName,
    this.slogan,
    this.shortDescription,
    this.longDescription,
    this.logoUrl,
    this.logoDarkUrl,
    this.faviconUrl,
    this.foundedYear,
    this.taxId,
  });

  factory CompanyInfo.fromJson(Map<String, dynamic> json) {
    return CompanyInfo(
      name: json['name'],
      legalName: json['legalName'],
      slogan: json['slogan'],
      shortDescription: json['shortDescription'],
      longDescription: json['longDescription'],
      logoUrl: json['logoUrl'],
      logoDarkUrl: json['logoDarkUrl'],
      faviconUrl: json['faviconUrl'],
      foundedYear: json['foundedYear'],
      taxId: json['taxId'],
    );
  }

  factory CompanyInfo.empty() => CompanyInfo();

  final String? name;
  final String? legalName;
  final String? slogan;
  final String? shortDescription;
  final String? longDescription;
  final String? logoUrl;
  final String? logoDarkUrl;
  final String? faviconUrl;
  final String? foundedYear;
  final String? taxId;

  // Convenience getters
  String get safeName => name ?? '';
  String get safeSlogan => slogan ?? '';

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (legalName != null) 'legalName': legalName,
        if (slogan != null) 'slogan': slogan,
        if (shortDescription != null) 'shortDescription': shortDescription,
        if (longDescription != null) 'longDescription': longDescription,
        if (logoUrl != null) 'logoUrl': logoUrl,
        if (logoDarkUrl != null) 'logoDarkUrl': logoDarkUrl,
        if (faviconUrl != null) 'faviconUrl': faviconUrl,
        if (foundedYear != null) 'foundedYear': foundedYear,
        if (taxId != null) 'taxId': taxId,
      };
}
