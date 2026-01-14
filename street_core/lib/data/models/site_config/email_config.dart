/// Email Configuration Model
///
/// Contains email addresses and templates configuration.
class EmailConfig {
  EmailConfig({
    this.supportEmail,
    this.salesEmail,
    this.notificationsEmail,
    this.noReplyEmail,
    this.welcomeSubject,
    this.welcomeTemplate,
    this.resetSubject,
    this.resetTemplate,
  });

  factory EmailConfig.fromJson(Map<String, dynamic> json) {
    return EmailConfig(
      supportEmail: json['supportEmail'],
      salesEmail: json['salesEmail'],
      notificationsEmail: json['notificationsEmail'],
      noReplyEmail: json['noReplyEmail'],
      welcomeSubject: json['welcomeSubject'],
      welcomeTemplate: json['welcomeTemplate'],
      resetSubject: json['resetSubject'],
      resetTemplate: json['resetTemplate'],
    );
  }

  factory EmailConfig.empty() => EmailConfig();

  final String? supportEmail;
  final String? salesEmail;
  final String? notificationsEmail;
  final String? noReplyEmail;
  final String? welcomeSubject;
  final String? welcomeTemplate;
  final String? resetSubject;
  final String? resetTemplate;

  Map<String, dynamic> toJson() => {
        if (supportEmail != null) 'supportEmail': supportEmail,
        if (salesEmail != null) 'salesEmail': salesEmail,
        if (notificationsEmail != null) 'notificationsEmail': notificationsEmail,
        if (noReplyEmail != null) 'noReplyEmail': noReplyEmail,
        if (welcomeSubject != null) 'welcomeSubject': welcomeSubject,
        if (welcomeTemplate != null) 'welcomeTemplate': welcomeTemplate,
        if (resetSubject != null) 'resetSubject': resetSubject,
        if (resetTemplate != null) 'resetTemplate': resetTemplate,
      };
}
