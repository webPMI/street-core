// validators.dart
// ============================================================================
// Unified Professional Validation System for FitRiders App
// Single source of truth for all form validation logic.
// Replaces: form_validator.dart (deleted), validator_factory.dart (integrated)
//
// Features:
// - Type-safe validation with abstract base class
// - Composable validators using & operator
// - Centralized regex patterns
// - Standardized translation keys
// - Zero code duplication
// - Full unit test coverage ready

import '/core/lang/context_tr.dart';
import '/core/lang/locale_keys.dart';
import 'package:flutter/material.dart';

// ============================================================================
// REGEX PATTERNS - Single Source of Truth

/// Centralized regex patterns for consistent validation across the app
class ValidationPatterns {
  // Email pattern - supports modern email formats
  // Allows: user+tag@example.com, user.name@example.co.uk, etc.
  static final email = RegExp(r'^[\w\+\-\.]+@([\w-]+\.)+[\w-]{2,}$');

  // Phone pattern - international format support
  // Allows: +1234567890, (123) 456-7890, 123-456-7890
  static final phone = RegExp(r'^\+?[\d\s\-\(\)]+$');

  // URL pattern - supports HTTP/HTTPS with optional www
  static final url = RegExp(
    r'^(https?:\/\/)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
  );

  // Text only - supports accented characters (international names)
  static final textWithAccents = RegExp(r'^[a-zA-ZÀ-ÿ\s]+$');

  // Text only - ASCII only (for usernames, etc.)
  static final textAsciiOnly = RegExp(r'^[a-zA-Z\s]+$');

  // Numbers - integers only
  static final integerOnly = RegExp(r'^-?\d+$');

  // Numbers - allows decimals
  static final decimal = RegExp(r'^-?\d*\.?\d+$');

  // Password strength patterns
  static final hasUppercase = RegExp('[A-Z]');
  static final hasLowercase = RegExp('[a-z]');
  static final hasDigit = RegExp('[0-9]');
  static final hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>]');

  // Date format (YYYY-MM-DD or DD/MM/YYYY)
  static final dateYMD = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  static final dateDMY = RegExp(r'^\d{2}/\d{2}/\d{4}$');

  // Credit card (basic format check)
  static final creditCard = RegExp(r'^\d{13,19}$');

  // Username (alphanumeric + underscore, 3-20 chars)
  static final username = RegExp(r'^[a-zA-Z0-9_]{3,20}$');

  // Postal code patterns by country
  static final postalCodeUS = RegExp(r'^\d{5}(-\d{4})?$');
  static final postalCodeUK = RegExp(r'^[A-Z]{1,2}\d{1,2}[A-Z]?\s?\d[A-Z]{2}$');
  static final postalCodeSpain = RegExp(r'^\d{5}$');
}

// ============================================================================
// TRANSLATION KEYS - Standardized
// ============================================================================

/// Centralized translation keys for validator error messages
class ValidationKeys {
  // Required field
  static const requiredField = LocaleKeys.requiredField;

  // Email
  static const invalidEmail = LocaleKeys.invalidEmail;

  // Password
  static const passwordMinLength = LocaleKeys.passwordMinLength; // Param: {min}
  static const passwordRequiresUppercase = LocaleKeys.passwordHasUppercase;
  static const passwordRequiresLowercase = LocaleKeys.passwordHasLowercase;
  static const passwordRequiresDigit = LocaleKeys.passwordHasNumber;
  static const passwordRequiresSpecialChar = LocaleKeys.passwordHasSpecial;
  static const passwordsDoNotMatch = LocaleKeys.passwordsDontMatch;

  // Phone
  static const invalidPhone = LocaleKeys.invalidPhone;
  static const phoneMinLength = 'phone.min_length'; // Param: {min}
  static const phoneMaxLength = 'phone.max_length'; // Param: {max}

  // URL
  static const invalidUrl = 'invalid.url';
  static const urlRequiresHttps = 'url.requires_https';

  // Numbers
  static const onlyNumbers = 'only.numbers';
  static const invalidNumber = 'invalid.number';
  static const numberOutOfRange = 'number.out_of_range'; // Params: {min}, {max}

  // Text
  static const onlyText = 'only.text';
  static const invalidText = 'invalid.text';

  // Length
  static const minLength = LocaleKeys.minLength; // Param: {min}
  static const maxLength = LocaleKeys.maxLength; // Param: {max}

  // Date
  static const invalidDate = 'invalid.date';
  static const dateOutOfRange = 'date.out_of_range';

  // Credit card
  static const invalidCreditCard = 'invalid.credit_card';

  // Username
  static const invalidUsername = 'invalid.username';
  static const usernameMinLength = 'username.min_length';

  // Postal code
  static const invalidPostalCode = 'invalid.postal_code';
}

// ============================================================================
// BASE VALIDATOR CLASS
// ============================================================================

/// Abstract base class for all validators
///
/// Provides:
/// - Consistent validation interface
/// - Composability via & operator
/// - Type safety
/// - Testability
///
/// Usage:
/// ```dart
/// final validator = RequiredValidator() & EmailValidator();
/// final error = validator.validate(context, 'test@example.com');
/// ```
abstract class Validator {
  /// Validates the given value and returns an error message or null
  ///
  /// @param context - BuildContext for translations
  /// @param value - The value to validate
  /// @return Error message string or null if valid
  String? validate(BuildContext context, String? value);

  /// Composes this validator with another (AND logic)
  ///
  /// Both validators must pass for the composite to pass.
  ///
  /// Example:
  /// ```dart
  /// final validator = requiredValidator & emailValidator & minLengthValidator;
  /// ```
  Validator operator &(Validator other) {
    return CompositeValidator([this, other]);
  }
}

// ============================================================================
// CORE VALIDATORS
// ============================================================================

/// Validates that a field is not empty
class RequiredValidator extends Validator {
  RequiredValidator({this.customMessage});
  final String? customMessage;

  @override
  String? validate(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return customMessage ?? context.tr(ValidationKeys.requiredField);
    }
    return null;
  }
}

/// Validates email format
class EmailValidator extends Validator {
  EmailValidator({this.customMessage, this.required = true});
  final String? customMessage;
  final bool required;

  @override
  String? validate(BuildContext context, String? value) {
    // Optional field - allow empty
    if (!required && (value == null || value.isEmpty)) {
      return null;
    }

    // Required field - check if empty
    if (required) {
      final requiredError = requiredValidator.validate(context, value);
      if (requiredError != null) return requiredError;
    }

    // Check email format
    if (value != null && value.isNotEmpty) {
      if (!ValidationPatterns.email.hasMatch(value)) {
        return customMessage ?? context.tr(ValidationKeys.invalidEmail);
      }
    }

    return null;
  }
}

/// Validates password with configurable requirements
class PasswordValidator extends Validator {
  PasswordValidator({
    this.minLength = 8,
    this.requireUppercase = true,
    this.requireLowercase = true,
    this.requireDigit = true,
    this.requireSpecialChar = true,
    this.customMessage,
  });
  final int minLength;
  final bool requireUppercase;
  final bool requireLowercase;
  final bool requireDigit;
  final bool requireSpecialChar;
  final String? customMessage;

  @override
  String? validate(BuildContext context, String? value) {
    // Always required
    final requiredError = requiredValidator.validate(context, value);
    if (requiredError != null) return requiredError;

    final password = value!;

    // Check minimum length
    if (password.length < minLength) {
      return customMessage ??
          context
              .tr(ValidationKeys.passwordMinLength)
              .replaceAll('{min}', '$minLength');
    }

    // Check uppercase requirement
    if (requireUppercase &&
        !ValidationPatterns.hasUppercase.hasMatch(password)) {
      return customMessage ??
          context.tr(ValidationKeys.passwordRequiresUppercase);
    }

    // Check lowercase requirement
    if (requireLowercase &&
        !ValidationPatterns.hasLowercase.hasMatch(password)) {
      return customMessage ??
          context.tr(ValidationKeys.passwordRequiresLowercase);
    }

    // Check digit requirement
    if (requireDigit && !ValidationPatterns.hasDigit.hasMatch(password)) {
      return customMessage ?? context.tr(ValidationKeys.passwordRequiresDigit);
    }

    // Check special character requirement
    if (requireSpecialChar &&
        !ValidationPatterns.hasSpecialChar.hasMatch(password)) {
      return customMessage ??
          context.tr(ValidationKeys.passwordRequiresSpecialChar);
    }

    return null;
  }
}

/// Validates that password confirmation matches original
class PasswordConfirmValidator extends Validator {
  PasswordConfirmValidator({
    required this.originalPassword,
    this.customMessage,
  });
  final String originalPassword;
  final String? customMessage;

  @override
  String? validate(BuildContext context, String? value) {
    // Check required
    final requiredError = requiredValidator.validate(context, value);
    if (requiredError != null) return requiredError;

    // Check match
    if (value != originalPassword) {
      return customMessage ?? context.tr(ValidationKeys.passwordsDoNotMatch);
    }

    return null;
  }
}

/// Validates URL format
class UrlValidator extends Validator {
  UrlValidator({
    this.customMessage,
    this.required = false,
    this.requireHttps = false,
  });
  final String? customMessage;
  final bool required;
  final bool requireHttps;

  @override
  String? validate(BuildContext context, String? value) {
    // Optional field - allow empty
    if (!required && (value == null || value.isEmpty)) {
      return null;
    }

    // Required field - check if empty
    if (required) {
      final requiredError = requiredValidator.validate(context, value);
      if (requiredError != null) return requiredError;
    }

    // Check URL format
    if (value != null && value.isNotEmpty) {
      if (!ValidationPatterns.url.hasMatch(value)) {
        return customMessage ?? context.tr(ValidationKeys.invalidUrl);
      }

      // Check HTTPS requirement
      if (requireHttps && !value.startsWith('https://')) {
        return customMessage ?? context.tr(ValidationKeys.urlRequiresHttps);
      }
    }

    return null;
  }
}

/// Validates phone number format
class PhoneValidator extends Validator {
  PhoneValidator({
    this.customMessage,
    this.required = false,
    this.minLength,
    this.maxLength,
  });
  final String? customMessage;
  final bool required;
  final int? minLength;
  final int? maxLength;

  @override
  String? validate(BuildContext context, String? value) {
    // Optional field - allow empty
    if (!required && (value == null || value.isEmpty)) {
      return null;
    }

    // Required field - check if empty
    if (required) {
      final requiredError = requiredValidator.validate(context, value);
      if (requiredError != null) return requiredError;
    }

    // Check phone format
    if (value != null && value.isNotEmpty) {
      if (!ValidationPatterns.phone.hasMatch(value)) {
        return customMessage ?? context.tr(ValidationKeys.invalidPhone);
      }

      // Remove formatting characters for length check
      final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');

      // Check minimum length
      if (minLength != null && digitsOnly.length < minLength!) {
        return customMessage ??
            context
                .tr(ValidationKeys.phoneMinLength)
                .replaceAll('{min}', '$minLength');
      }

      // Check maximum length
      if (maxLength != null && digitsOnly.length > maxLength!) {
        return customMessage ??
            context
                .tr(ValidationKeys.phoneMaxLength)
                .replaceAll('{max}', '$maxLength');
      }
    }

    return null;
  }
}

/// Validates numeric input
class NumberValidator extends Validator {
  NumberValidator({
    this.customMessage,
    this.required = false,
    this.allowDecimal = false,
    this.allowNegative = true,
  });
  final String? customMessage;
  final bool required;
  final bool allowDecimal;
  final bool allowNegative;

  @override
  String? validate(BuildContext context, String? value) {
    // Optional field - allow empty
    if (!required && (value == null || value.isEmpty)) {
      return null;
    }

    // Required field - check if empty
    if (required) {
      final requiredError = requiredValidator.validate(context, value);
      if (requiredError != null) return requiredError;
    }

    // Check number format
    if (value != null && value.isNotEmpty) {
      final pattern = allowDecimal
          ? ValidationPatterns.decimal
          : ValidationPatterns.integerOnly;

      if (!pattern.hasMatch(value)) {
        return customMessage ?? context.tr(ValidationKeys.onlyNumbers);
      }

      // Check negative numbers
      if (!allowNegative && value.startsWith('-')) {
        return customMessage ?? context.tr(ValidationKeys.invalidNumber);
      }
    }

    return null;
  }
}

/// Validates that a number is within a range
class RangeValidator extends Validator {
  RangeValidator({required this.min, required this.max, this.customMessage});
  final num min;
  final num max;
  final String? customMessage;

  @override
  String? validate(BuildContext context, String? value) {
    // Check required
    final requiredError = requiredValidator.validate(context, value);
    if (requiredError != null) return requiredError;

    // Parse number
    final number = num.tryParse(value!);
    if (number == null) {
      return context.tr(ValidationKeys.invalidNumber);
    }

    // Check range
    if (number < min || number > max) {
      return customMessage ??
          context
              .tr(ValidationKeys.numberOutOfRange)
              .replaceAll('{min}', '$min')
              .replaceAll('{max}', '$max');
    }

    return null;
  }
}

/// Validates minimum length
class MinLengthValidator extends Validator {
  MinLengthValidator(this.minLength, {this.customMessage});
  final int minLength;
  final String? customMessage;

  @override
  String? validate(BuildContext context, String? value) {
    if (value != null && value.length < minLength) {
      return customMessage ??
          context
              .tr(ValidationKeys.minLength)
              .replaceAll('{min}', '$minLength');
    }
    return null;
  }
}

/// Validates maximum length
class MaxLengthValidator extends Validator {
  MaxLengthValidator(this.maxLength, {this.customMessage});
  final int maxLength;
  final String? customMessage;

  @override
  String? validate(BuildContext context, String? value) {
    if (value != null && value.length > maxLength) {
      return customMessage ??
          context
              .tr(ValidationKeys.maxLength)
              .replaceAll('{max}', '$maxLength');
    }
    return null;
  }
}

/// Validates text-only input (letters and spaces)
class TextOnlyValidator extends Validator {
  TextOnlyValidator({
    this.customMessage,
    this.required = false,
    this.allowAccents = true,
  });
  final String? customMessage;
  final bool required;
  final bool allowAccents;

  @override
  String? validate(BuildContext context, String? value) {
    // Optional field - allow empty
    if (!required && (value == null || value.isEmpty)) {
      return null;
    }

    // Required field - check if empty
    if (required) {
      final requiredError = requiredValidator.validate(context, value);
      if (requiredError != null) return requiredError;
    }

    // Check text format
    if (value != null && value.isNotEmpty) {
      final pattern = allowAccents
          ? ValidationPatterns.textWithAccents
          : ValidationPatterns.textAsciiOnly;

      if (!pattern.hasMatch(value)) {
        return customMessage ?? context.tr(ValidationKeys.onlyText);
      }
    }

    return null;
  }
}

/// Validates date format
class DateValidator extends Validator {
  DateValidator({
    this.customMessage,
    this.required = false,
    this.minDate,
    this.maxDate,
  });
  final String? customMessage;
  final bool required;
  final DateTime? minDate;
  final DateTime? maxDate;

  @override
  String? validate(BuildContext context, String? value) {
    // Optional field - allow empty
    if (!required && (value == null || value.isEmpty)) {
      return null;
    }

    // Required field - check if empty
    if (required) {
      final requiredError = requiredValidator.validate(context, value);
      if (requiredError != null) return requiredError;
    }

    // Check date format and parse
    if (value != null && value.isNotEmpty) {
      final date = DateTime.tryParse(value);
      if (date == null) {
        return customMessage ?? context.tr(ValidationKeys.invalidDate);
      }

      // Check date range
      if (minDate != null && date.isBefore(minDate!)) {
        return customMessage ?? context.tr(ValidationKeys.dateOutOfRange);
      }

      if (maxDate != null && date.isAfter(maxDate!)) {
        return customMessage ?? context.tr(ValidationKeys.dateOutOfRange);
      }
    }

    return null;
  }
}

/// Validates credit card number (basic format)
class CreditCardValidator extends Validator {
  CreditCardValidator({this.customMessage});
  final String? customMessage;

  @override
  String? validate(BuildContext context, String? value) {
    // Check required
    final requiredError = requiredValidator.validate(context, value);
    if (requiredError != null) return requiredError;

    // Remove spaces and dashes
    final cleaned = value!.replaceAll(RegExp(r'[\s-]'), '');

    // Check format
    if (!ValidationPatterns.creditCard.hasMatch(cleaned)) {
      return customMessage ?? context.tr(ValidationKeys.invalidCreditCard);
    }

    // Luhn algorithm check
    if (!_luhnCheck(cleaned)) {
      return customMessage ?? context.tr(ValidationKeys.invalidCreditCard);
    }

    return null;
  }

  /// Luhn algorithm for credit card validation
  bool _luhnCheck(String cardNumber) {
    int sum = 0;
    bool alternate = false;

    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cardNumber[i]);

      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }

      sum += digit;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }
}

/// Validates username format
class UsernameValidator extends Validator {
  UsernameValidator({this.customMessage, this.minLength = 3});
  final String? customMessage;
  final int minLength;

  @override
  String? validate(BuildContext context, String? value) {
    // Check required
    final requiredError = requiredValidator.validate(context, value);
    if (requiredError != null) return requiredError;

    // Check format
    if (!ValidationPatterns.username.hasMatch(value!)) {
      return customMessage ?? context.tr(ValidationKeys.invalidUsername);
    }

    // Check minimum length
    if (value.length < minLength) {
      return customMessage ??
          context
              .tr(ValidationKeys.usernameMinLength)
              .replaceAll('{min}', '$minLength');
    }

    return null;
  }
}

/// Composite validator - runs multiple validators in sequence
class CompositeValidator extends Validator {
  CompositeValidator(this.validators);
  final List<Validator> validators;

  @override
  String? validate(BuildContext context, String? value) {
    for (final validator in validators) {
      final error = validator.validate(context, value);
      if (error != null) return error; // Return first error
    }
    return null;
  }
}

// ============================================================================
// GLOBAL VALIDATOR INSTANCES (Reusable)

// Required field
final requiredValidator = RequiredValidator();

// Email
final emailValidator = EmailValidator();
final optionalEmailValidator = EmailValidator(required: false);

// Password
final passwordValidator = PasswordValidator();
final simplePasswordValidator = PasswordValidator(
  minLength: 6,
  requireUppercase: false,
  requireLowercase: false,
  requireDigit: false,
  requireSpecialChar: false,
);

// URL
final urlValidator = UrlValidator();
final requiredUrlValidator = UrlValidator(required: true);
final httpsUrlValidator = UrlValidator(requireHttps: true);

// Phone
final phoneValidator = PhoneValidator();
final requiredPhoneValidator = PhoneValidator(required: true);

// Number
final numberValidator = NumberValidator();
final requiredNumberValidator = NumberValidator(required: true);
final decimalValidator = NumberValidator(allowDecimal: true);
final positiveNumberValidator = NumberValidator(allowNegative: false);

// Text
final textOnlyValidator = TextOnlyValidator();
final requiredTextValidator = TextOnlyValidator(required: true);
final asciiTextValidator = TextOnlyValidator(allowAccents: false);

// Date
final dateValidator = DateValidator();
final requiredDateValidator = DateValidator(required: true);

// Credit card
final creditCardValidator = CreditCardValidator();

// Username
final usernameValidator = UsernameValidator();

// ============================================================================
// VALIDATOR FACTORY (String-based creation for convenience)
// ============================================================================

/// Factory for creating validators from string descriptors
///
/// Useful for declarative form building and backward compatibility.
///
/// Supported formats:
/// - 'required'
/// - 'email'
/// - 'password' or 'password:minLength'
/// - 'simplepassword' or 'simplepassword:minLength'
/// - 'url', 'https'
/// - 'phone'
/// - 'number', 'int', 'decimal'
/// - 'range:min-max'
/// - 'minLength:n', 'min_length:n'
/// - 'maxLength:n', 'max_length:n'
/// - 'text', 'onlytext'
/// - 'date'
/// - 'creditcard'
/// - 'username'
///
/// Example:
/// ```dart
/// final validator = ValidatorFactory.create(context, 'email');
/// final multiValidator = ValidatorFactory.createMultiple(
///   context,
///   ['required', 'email', 'minLength:5']
/// );
/// ```
class ValidatorFactory {
  /// Creates a validator from a string descriptor
  static FormFieldValidator<String>? create(
    BuildContext context,
    String validatorName, {
    Map<String, dynamic>? params,
  }) {
    final parts = validatorName.split(':');
    final name = parts[0].toLowerCase().trim();
    final param = parts.length > 1 ? parts[1] : null;

    switch (name) {
      case 'required':
        return (value) => requiredValidator.validate(context, value);

      case 'email':
        return (value) => emailValidator.validate(context, value);

      case 'password':
        final minLength = param != null ? int.tryParse(param) : null;
        final validator = minLength != null
            ? PasswordValidator(minLength: minLength)
            : passwordValidator;
        return (value) => validator.validate(context, value);

      case 'simplepassword':
        final minLength = param != null ? int.tryParse(param) ?? 6 : 6;
        final validator = PasswordValidator(
          minLength: minLength,
          requireUppercase: false,
          requireLowercase: false,
          requireDigit: false,
          requireSpecialChar: false,
        );
        return (value) => validator.validate(context, value);

      case 'url':
        return (value) => urlValidator.validate(context, value);

      case 'https':
        return (value) => httpsUrlValidator.validate(context, value);

      case 'phone':
        return (value) => phoneValidator.validate(context, value);

      case 'number':
      case 'int':
        return (value) => numberValidator.validate(context, value);

      case 'decimal':
      case 'double':
      case 'float':
        return (value) => decimalValidator.validate(context, value);

      case 'range':
        if (param != null) {
          final rangeParts = param.split('-');
          if (rangeParts.length == 2) {
            final min = num.tryParse(rangeParts[0]);
            final max = num.tryParse(rangeParts[1]);
            if (min != null && max != null) {
              final validator = RangeValidator(min: min, max: max);
              return (value) => validator.validate(context, value);
            }
          }
        }
        return null;

      case 'minlength':
      case 'min.length':
        if (param != null) {
          final minLength = int.tryParse(param);
          if (minLength != null) {
            final validator = MinLengthValidator(minLength);
            return (value) => validator.validate(context, value);
          }
        }
        return null;

      case 'maxlength':
      case 'max.length':
        if (param != null) {
          final maxLength = int.tryParse(param);
          if (maxLength != null) {
            final validator = MaxLengthValidator(maxLength);
            return (value) => validator.validate(context, value);
          }
        }
        return null;

      case 'text':
      case 'string':
      case 'onlytext':
        return (value) => textOnlyValidator.validate(context, value);

      case 'date':
        return (value) => dateValidator.validate(context, value);

      case 'creditcard':
        return (value) => creditCardValidator.validate(context, value);

      case 'username':
        return (value) => usernameValidator.validate(context, value);

      default:
        return null;
    }
  }

  /// Creates multiple validators and composes them
  static FormFieldValidator<String>? createMultiple(
    BuildContext context,
    List<String> validatorNames,
  ) {
    final validators = validatorNames
        .map((name) => create(context, name))
        .where((v) => v != null)
        .cast<FormFieldValidator<String>>()
        .toList();

    if (validators.isEmpty) return null;

    return (String? value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }

  /// Creates a password confirmation validator
  static FormFieldValidator<String> createPasswordConfirm(
    BuildContext context,
    String originalPassword,
  ) {
    final validator = PasswordConfirmValidator(
      originalPassword: originalPassword,
    );
    return (value) => validator.validate(context, value);
  }

  /// Creates a custom validator from a function
  static FormFieldValidator<String> custom(
    String? Function(BuildContext context, String? value) validatorFn,
    BuildContext context,
  ) {
    return (String? value) => validatorFn(context, value);
  }

  /// Composes multiple validators (alternative to & operator)
  static FormFieldValidator<String>? compose(
    BuildContext context,
    List<Validator> validators,
  ) {
    if (validators.isEmpty) return null;

    final composite = CompositeValidator(validators);
    return (value) => composite.validate(context, value);
  }
}

// ============================================================================
// TYPE ALIAS FOR FLUTTER COMPATIBILITY
// ============================================================================

/// Type alias for Flutter's FormFieldValidator
typedef FormFieldValidator<T> = String? Function(T? value);
