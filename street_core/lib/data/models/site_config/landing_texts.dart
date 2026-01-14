/// Landing Page Texts Models
///
/// Contains all models for landing page content.

/// Feature Item Model
class FeatureItem {
  FeatureItem({this.icon, this.title, this.description});

  factory FeatureItem.fromJson(Map<String, dynamic> json) {
    return FeatureItem(
      icon: json['icon'],
      title: json['title'],
      description: json['description'],
    );
  }

  final String? icon;
  final String? title;
  final String? description;

  Map<String, dynamic> toJson() => {
        if (icon != null) 'icon': icon,
        if (title != null) 'title': title,
        if (description != null) 'description': description,
      };
}

/// Testimonial Model
class Testimonial {
  Testimonial({this.name, this.role, this.text, this.avatar, this.rating});

  factory Testimonial.fromJson(Map<String, dynamic> json) {
    return Testimonial(
      name: json['name'],
      role: json['role'],
      text: json['text'],
      avatar: json['avatar'],
      rating: json['rating'],
    );
  }

  final String? name;
  final String? role;
  final String? text;
  final String? avatar;
  final int? rating;

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (role != null) 'role': role,
        if (text != null) 'text': text,
        if (avatar != null) 'avatar': avatar,
        if (rating != null) 'rating': rating,
      };
}

/// Landing Page Texts Model
///
/// Contains all text content for the landing page.
class LandingTexts {
  LandingTexts({
    this.heroTitle,
    this.heroSubtitle,
    this.heroButtonText,
    this.heroButtonUrl,
    this.heroImageUrl,
    this.aboutTitle,
    this.aboutText,
    this.features,
    this.testimonials,
    this.ctaTitle,
    this.ctaText,
    this.ctaButtonText,
  });

  factory LandingTexts.fromJson(Map<String, dynamic> json) {
    return LandingTexts(
      heroTitle: json['heroTitle'],
      heroSubtitle: json['heroSubtitle'],
      heroButtonText: json['heroButtonText'],
      heroButtonUrl: json['heroButtonUrl'],
      heroImageUrl: json['heroImageUrl'],
      aboutTitle: json['aboutTitle'],
      aboutText: json['aboutText'],
      features: json['features'] != null
          ? (json['features'] as List)
              .map((e) => FeatureItem.fromJson(e))
              .toList()
          : null,
      testimonials: json['testimonials'] != null
          ? (json['testimonials'] as List)
              .map((e) => Testimonial.fromJson(e))
              .toList()
          : null,
      ctaTitle: json['ctaTitle'],
      ctaText: json['ctaText'],
      ctaButtonText: json['ctaButtonText'],
    );
  }

  factory LandingTexts.empty() => LandingTexts();

  final String? heroTitle;
  final String? heroSubtitle;
  final String? heroButtonText;
  final String? heroButtonUrl;
  final String? heroImageUrl;
  final String? aboutTitle;
  final String? aboutText;
  final List<FeatureItem>? features;
  final List<Testimonial>? testimonials;
  final String? ctaTitle;
  final String? ctaText;
  final String? ctaButtonText;

  Map<String, dynamic> toJson() => {
        if (heroTitle != null) 'heroTitle': heroTitle,
        if (heroSubtitle != null) 'heroSubtitle': heroSubtitle,
        if (heroButtonText != null) 'heroButtonText': heroButtonText,
        if (heroButtonUrl != null) 'heroButtonUrl': heroButtonUrl,
        if (heroImageUrl != null) 'heroImageUrl': heroImageUrl,
        if (aboutTitle != null) 'aboutTitle': aboutTitle,
        if (aboutText != null) 'aboutText': aboutText,
        if (features != null)
          'features': features!.map((e) => e.toJson()).toList(),
        if (testimonials != null)
          'testimonials': testimonials!.map((e) => e.toJson()).toList(),
        if (ctaTitle != null) 'ctaTitle': ctaTitle,
        if (ctaText != null) 'ctaText': ctaText,
        if (ctaButtonText != null) 'ctaButtonText': ctaButtonText,
      };
}
