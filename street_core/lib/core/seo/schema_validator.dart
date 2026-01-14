/// Schema.org Validator
///
/// Validates structured data schemas for completeness and correctness
/// before adding them to pages.
library;

/// Validation result for schema validation
class SchemaValidationResult {

  const SchemaValidationResult({
    required this.isValid,
    required this.schemaType,
    this.errors = const [],
    this.warnings = const [],
  });
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final String schemaType;

  @override
  String toString() {
    if (isValid) {
      return 'Schema "$schemaType" is valid${warnings.isNotEmpty ? ' with ${warnings.length} warning(s)' : ''}';
    }
    return 'Schema "$schemaType" is invalid: ${errors.join(", ")}';
  }
}

/// Schema validator for JSON-LD structured data
class SchemaValidator {
  /// Validate any schema based on its @type
  static SchemaValidationResult validate(Map<String, dynamic> schema) {
    final type = schema['@type'] as String?;

    if (type == null) {
      return const SchemaValidationResult(
        isValid: false,
        schemaType: 'Unknown',
        errors: ['Missing required @type property'],
      );
    }

    // Validate @context
    final context = schema['@context'];
    final warnings = <String>[];
    if (context == null) {
      warnings.add('Missing @context (should be "https://schema.org")');
    } else if (context != 'https://schema.org') {
      warnings.add('@context should be "https://schema.org"');
    }

    // Validate based on type
    switch (type) {
      case 'Organization':
      case 'SportsOrganization':
        return _validateOrganization(schema, type, warnings);
      case 'Person':
        return _validatePerson(schema, warnings);
      case 'SportsEvent':
        return _validateEvent(schema, warnings);
      case 'Product':
        return _validateProduct(schema, warnings);
      case 'Article':
        return _validateArticle(schema, warnings);
      case 'BreadcrumbList':
        return _validateBreadcrumb(schema, warnings);
      case 'FAQPage':
        return _validateFAQ(schema, warnings);
      case 'WebPage':
        return _validateWebPage(schema, warnings);
      case 'LocalBusiness':
        return _validateLocalBusiness(schema, warnings);
      default:
        return SchemaValidationResult(
          isValid: true,
          schemaType: type,
          warnings: [
            ...warnings,
            'Unknown schema type "$type" - basic validation only',
          ],
        );
    }
  }

  /// Validate Organization schema
  static SchemaValidationResult _validateOrganization(
    Map<String, dynamic> schema,
    String type,
    List<String> warnings,
  ) {
    final errors = <String>[];

    // Required fields
    if (!_hasField(schema, 'name')) {
      errors.add('Missing required field: name');
    }

    // Recommended fields
    if (!_hasField(schema, 'url')) {
      warnings.add('Recommended field missing: url');
    }
    if (!_hasField(schema, 'logo')) {
      warnings.add('Recommended field missing: logo');
    }

    return SchemaValidationResult(
      isValid: errors.isEmpty,
      schemaType: type,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validate Person schema
  static SchemaValidationResult _validatePerson(
    Map<String, dynamic> schema,
    List<String> warnings,
  ) {
    final errors = <String>[];

    if (!_hasField(schema, 'name')) {
      errors.add('Missing required field: name');
    }

    return SchemaValidationResult(
      isValid: errors.isEmpty,
      schemaType: 'Person',
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validate SportsEvent schema
  static SchemaValidationResult _validateEvent(
    Map<String, dynamic> schema,
    List<String> warnings,
  ) {
    final errors = <String>[];

    if (!_hasField(schema, 'name')) {
      errors.add('Missing required field: name');
    }
    if (!_hasField(schema, 'startDate')) {
      errors.add('Missing required field: startDate');
    }

    // Validate date format
    final startDate = schema['startDate'];
    if (startDate != null && startDate is String) {
      if (!_isValidIsoDate(startDate)) {
        errors.add('startDate must be in ISO 8601 format');
      }
    }

    // Recommended fields
    if (!_hasField(schema, 'location')) {
      warnings.add('Recommended field missing: location');
    }
    if (!_hasField(schema, 'description')) {
      warnings.add('Recommended field missing: description');
    }

    return SchemaValidationResult(
      isValid: errors.isEmpty,
      schemaType: 'SportsEvent',
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validate Product schema
  static SchemaValidationResult _validateProduct(
    Map<String, dynamic> schema,
    List<String> warnings,
  ) {
    final errors = <String>[];

    if (!_hasField(schema, 'name')) {
      errors.add('Missing required field: name');
    }

    // Check offers
    final offers = schema['offers'];
    if (offers == null) {
      warnings.add('Recommended field missing: offers');
    } else if (offers is Map) {
      if (!_hasField(offers as Map<String, dynamic>, 'price')) {
        warnings.add('offers.price is recommended');
      }
      if (!_hasField(offers, 'priceCurrency')) {
        warnings.add('offers.priceCurrency is recommended');
      }
    }

    // Recommended fields
    if (!_hasField(schema, 'description')) {
      warnings.add('Recommended field missing: description');
    }
    if (!_hasField(schema, 'image')) {
      warnings.add('Recommended field missing: image');
    }

    return SchemaValidationResult(
      isValid: errors.isEmpty,
      schemaType: 'Product',
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validate Article schema
  static SchemaValidationResult _validateArticle(
    Map<String, dynamic> schema,
    List<String> warnings,
  ) {
    final errors = <String>[];

    if (!_hasField(schema, 'headline')) {
      errors.add('Missing required field: headline');
    } else {
      final headline = schema['headline'] as String;
      if (headline.length > 110) {
        warnings.add('headline should be under 110 characters');
      }
    }

    if (!_hasField(schema, 'author')) {
      errors.add('Missing required field: author');
    }
    if (!_hasField(schema, 'datePublished')) {
      errors.add('Missing required field: datePublished');
    }

    // Recommended fields
    if (!_hasField(schema, 'image')) {
      warnings.add('Recommended field missing: image');
    }
    if (!_hasField(schema, 'publisher')) {
      warnings.add('Recommended field missing: publisher');
    }

    return SchemaValidationResult(
      isValid: errors.isEmpty,
      schemaType: 'Article',
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validate BreadcrumbList schema
  static SchemaValidationResult _validateBreadcrumb(
    Map<String, dynamic> schema,
    List<String> warnings,
  ) {
    final errors = <String>[];

    final itemListElement = schema['itemListElement'];
    if (itemListElement == null) {
      errors.add('Missing required field: itemListElement');
    } else if (itemListElement is List) {
      if (itemListElement.isEmpty) {
        errors.add('itemListElement cannot be empty');
      } else {
        for (var i = 0; i < itemListElement.length; i++) {
          final item = itemListElement[i];
          if (item is Map) {
            if (!_hasField(item as Map<String, dynamic>, 'position')) {
              errors.add('itemListElement[$i] missing position');
            }
            if (!_hasField(item, 'name')) {
              errors.add('itemListElement[$i] missing name');
            }
          }
        }
      }
    }

    return SchemaValidationResult(
      isValid: errors.isEmpty,
      schemaType: 'BreadcrumbList',
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validate FAQPage schema
  static SchemaValidationResult _validateFAQ(
    Map<String, dynamic> schema,
    List<String> warnings,
  ) {
    final errors = <String>[];

    final mainEntity = schema['mainEntity'];
    if (mainEntity == null) {
      errors.add('Missing required field: mainEntity');
    } else if (mainEntity is List) {
      if (mainEntity.isEmpty) {
        errors.add('mainEntity cannot be empty');
      } else {
        for (var i = 0; i < mainEntity.length; i++) {
          final question = mainEntity[i];
          if (question is Map) {
            if (!_hasField(question as Map<String, dynamic>, 'name')) {
              errors.add('mainEntity[$i] missing name (question text)');
            }
            if (!_hasField(question, 'acceptedAnswer')) {
              errors.add('mainEntity[$i] missing acceptedAnswer');
            }
          }
        }
      }
    }

    return SchemaValidationResult(
      isValid: errors.isEmpty,
      schemaType: 'FAQPage',
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validate WebPage schema
  static SchemaValidationResult _validateWebPage(
    Map<String, dynamic> schema,
    List<String> warnings,
  ) {
    final errors = <String>[];

    if (!_hasField(schema, 'name')) {
      errors.add('Missing required field: name');
    }

    // Recommended fields
    if (!_hasField(schema, 'description')) {
      warnings.add('Recommended field missing: description');
    }
    if (!_hasField(schema, 'url')) {
      warnings.add('Recommended field missing: url');
    }

    return SchemaValidationResult(
      isValid: errors.isEmpty,
      schemaType: 'WebPage',
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validate LocalBusiness schema
  static SchemaValidationResult _validateLocalBusiness(
    Map<String, dynamic> schema,
    List<String> warnings,
  ) {
    final errors = <String>[];

    if (!_hasField(schema, 'name')) {
      errors.add('Missing required field: name');
    }
    if (!_hasField(schema, 'address')) {
      errors.add('Missing required field: address');
    }

    // Recommended fields
    if (!_hasField(schema, 'telephone')) {
      warnings.add('Recommended field missing: telephone');
    }
    if (!_hasField(schema, 'openingHoursSpecification')) {
      warnings.add('Recommended field missing: openingHoursSpecification');
    }

    return SchemaValidationResult(
      isValid: errors.isEmpty,
      schemaType: 'LocalBusiness',
      errors: errors,
      warnings: warnings,
    );
  }

  /// Check if a field exists and is not null/empty
  static bool _hasField(Map<String, dynamic> schema, String field) {
    final value = schema[field];
    if (value == null) return false;
    if (value is String && value.isEmpty) return false;
    if (value is List && value.isEmpty) return false;
    return true;
  }

  /// Check if a string is a valid ISO 8601 date
  static bool _isValidIsoDate(String date) {
    try {
      DateTime.parse(date);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Validate multiple schemas
  static List<SchemaValidationResult> validateAll(
    List<Map<String, dynamic>> schemas,
  ) {
    return schemas.map(validate).toList();
  }

  /// Check if all schemas are valid
  static bool areAllValid(List<Map<String, dynamic>> schemas) {
    return schemas.every((s) => validate(s).isValid);
  }
}
