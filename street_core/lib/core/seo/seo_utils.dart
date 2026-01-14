import 'dart:math' as math;

/// SEO Utilities
///
/// Helper functions for SEO optimization including validators,
/// generators, and checkers.

class SeoUtils {
  /// Validate title length (optimal: 50-60 characters)
  static SeoValidationResult validateTitle(String title) {
    final length = title.length;

    if (length == 0) {
      return SeoValidationResult(
        isValid: false,
        score: 0,
        message: 'Title is empty (critical)',
        recommendation: 'Add a descriptive title (50-60 characters)',
      );
    }

    if (length < 30) {
      return SeoValidationResult(
        isValid: false,
        score: 40,
        message: 'Title is too short ($length chars)',
        recommendation: 'Expand title to 50-60 characters',
      );
    }

    if (length > 70) {
      return SeoValidationResult(
        isValid: false,
        score: 60,
        message: 'Title is too long ($length chars, will be truncated)',
        recommendation: 'Shorten title to 50-60 characters',
      );
    }

    if (length >= 50 && length <= 60) {
      return SeoValidationResult(
        isValid: true,
        score: 100,
        message: 'Title length is optimal ($length chars)',
      );
    }

    return SeoValidationResult(
      isValid: true,
      score: 80,
      message: 'Title length is acceptable ($length chars)',
      recommendation: 'Optimal length is 50-60 characters',
    );
  }

  /// Validate meta description (optimal: 150-160 characters)
  static SeoValidationResult validateDescription(String description) {
    final length = description.length;

    if (length == 0) {
      return SeoValidationResult(
        isValid: false,
        score: 0,
        message: 'Description is empty (critical)',
        recommendation: 'Add a compelling description (150-160 characters)',
      );
    }

    if (length < 120) {
      return SeoValidationResult(
        isValid: false,
        score: 50,
        message: 'Description is too short ($length chars)',
        recommendation: 'Expand description to 150-160 characters',
      );
    }

    if (length > 160) {
      return SeoValidationResult(
        isValid: false,
        score: 70,
        message: 'Description is too long ($length chars, will be truncated)',
        recommendation: 'Shorten description to 150-160 characters',
      );
    }

    if (length >= 150 && length <= 160) {
      return SeoValidationResult(
        isValid: true,
        score: 100,
        message: 'Description length is optimal ($length chars)',
      );
    }

    return SeoValidationResult(
      isValid: true,
      score: 85,
      message: 'Description length is acceptable ($length chars)',
      recommendation: 'Optimal length is 150-160 characters',
    );
  }

  /// Validate alt text for images (optimal: under 125 characters)
  static SeoValidationResult validateAltText(String altText) {
    final length = altText.length;

    if (length == 0) {
      return SeoValidationResult(
        isValid: false,
        score: 0,
        message: 'Alt text is empty (critical for accessibility)',
        recommendation: 'Add descriptive alt text',
      );
    }

    if (length > 125) {
      return SeoValidationResult(
        isValid: false,
        score: 60,
        message: 'Alt text is too long ($length chars)',
        recommendation: 'Keep alt text under 125 characters',
      );
    }

    return SeoValidationResult(
      isValid: true,
      score: 100,
      message: 'Alt text is good ($length chars)',
    );
  }

  /// Generate optimized title with app name
  static String generateTitle(String pageTitle, {bool includeAppName = true}) {
    if (!includeAppName) return pageTitle;

    // Check if title already includes app name
    if (pageTitle.contains('FitRiders Pro')) {
      return pageTitle;
    }

    final fullTitle = '$pageTitle | FitRiders Pro';

    // Validate length
    if (fullTitle.length > 70) {
      // Truncate page title to fit
      const maxPageTitleLength = 70 - ' | FitRiders Pro'.length;
      final truncated = '${pageTitle.substring(0, maxPageTitleLength - 3)}...';
      return '$truncated | FitRiders Pro';
    }

    return fullTitle;
  }

  /// Truncate description to SEO-friendly length
  static String truncateDescription(String description, {int maxLength = 160}) {
    if (description.length <= maxLength) return description;

    // Find last space before maxLength to avoid cutting words
    final truncateAt = description.lastIndexOf(' ', maxLength - 3);

    if (truncateAt == -1 || truncateAt < maxLength - 20) {
      // If no space found or too far back, just cut at maxLength
      return '${description.substring(0, maxLength - 3)}...';
    }

    return '${description.substring(0, truncateAt)}...';
  }

  /// Generate alt text from description
  static String generateAltText(String description, {int maxLength = 125}) {
    final cleaned = description.trim();

    if (cleaned.length <= maxLength) return cleaned;

    final truncateAt = cleaned.lastIndexOf(' ', maxLength - 3);

    if (truncateAt == -1 || truncateAt < maxLength - 20) {
      return '${cleaned.substring(0, maxLength - 3)}...';
    }

    return '${cleaned.substring(0, truncateAt)}...';
  }

  /// Generate slug from text (URL-friendly)
  static String generateSlug(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp('[áàäâ]'), 'a')
        .replaceAll(RegExp('[éèëê]'), 'e')
        .replaceAll(RegExp('[íìïî]'), 'i')
        .replaceAll(RegExp('[óòöô]'), 'o')
        .replaceAll(RegExp('[úùüû]'), 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp('-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  /// Check heading hierarchy on page
  static HeadingHierarchyResult checkHeadingHierarchy(
    List<HeadingInfo> headings,
  ) {
    if (headings.isEmpty) {
      return HeadingHierarchyResult(
        isValid: false,
        issues: ['No headings found on page'],
        score: 0,
      );
    }

    final issues = <String>[];
    var score = 100;

    // Check for H1
    final h1Count = headings.where((h) => h.level == 1).length;
    if (h1Count == 0) {
      issues.add('Missing H1 tag (critical)');
      score -= 30;
    } else if (h1Count > 1) {
      issues.add('Multiple H1 tags found ($h1Count). Should have only one.');
      score -= 20;
    }

    // Check hierarchy order
    for (var i = 0; i < headings.length - 1; i++) {
      final current = headings[i];
      final next = headings[i + 1];

      // Heading should not skip levels (e.g., H2 -> H4)
      if (next.level > current.level + 1) {
        issues.add(
          'Heading skips level: H${current.level} -> H${next.level} at position ${i + 1}',
        );
        score -= 10;
      }
    }

    // Check for empty headings
    final emptyHeadings =
        headings.where((h) => h.text.trim().isEmpty).length;
    if (emptyHeadings > 0) {
      issues.add('$emptyHeadings empty heading(s) found');
      score -= emptyHeadings * 5;
    }

    return HeadingHierarchyResult(
      isValid: issues.isEmpty,
      issues: issues,
      score: math.max(0, score),
      h1Count: h1Count,
      totalHeadings: headings.length,
    );
  }

  /// Calculate overall page SEO score
  static PageSeoScore calculatePageScore({
    required String title,
    required String description,
    required List<String> images,
    required List<HeadingInfo> headings,
    required bool hasStructuredData,
    required bool hasCanonicalUrl,
  }) {
    var totalScore = 0;
    const maxScore = 100;
    final issues = <String>[];
    final warnings = <String>[];

    // Title (20 points)
    final titleResult = validateTitle(title);
    totalScore += (titleResult.score * 0.20).round();
    if (!titleResult.isValid) {
      issues.add(titleResult.message);
    }

    // Description (20 points)
    final descResult = validateDescription(description);
    totalScore += (descResult.score * 0.20).round();
    if (!descResult.isValid) {
      issues.add(descResult.message);
    }

    // Headings (20 points)
    final headingResult = checkHeadingHierarchy(headings);
    totalScore += (headingResult.score * 0.20).round();
    issues.addAll(headingResult.issues);

    // Images with alt text (15 points)
    if (images.isEmpty) {
      warnings.add('No images found on page');
      totalScore += 15; // Not critical
    } else {
      final imagesWithoutAlt = images.where((img) => img.isEmpty).length;
      if (imagesWithoutAlt > 0) {
        warnings.add('$imagesWithoutAlt image(s) missing alt text');
        final imageScore =
            ((images.length - imagesWithoutAlt) / images.length * 15).round();
        totalScore += imageScore;
      } else {
        totalScore += 15;
      }
    }

    // Structured data (15 points)
    if (hasStructuredData) {
      totalScore += 15;
    } else {
      warnings.add('Missing structured data (JSON-LD)');
    }

    // Canonical URL (10 points)
    if (hasCanonicalUrl) {
      totalScore += 10;
    } else {
      issues.add('Missing canonical URL');
    }

    return PageSeoScore(
      score: math.min(totalScore, maxScore),
      grade: _getGrade(totalScore),
      issues: issues,
      warnings: warnings,
      metrics: {
        'title_length': title.length,
        'description_length': description.length,
        'h1_count': headings.where((h) => h.level == 1).length,
        'total_headings': headings.length,
        'images_count': images.length,
        'images_with_alt': images.where((img) => img.isNotEmpty).length,
        'has_structured_data': hasStructuredData,
        'has_canonical_url': hasCanonicalUrl,
      },
    );
  }

  static String _getGrade(int score) {
    if (score >= 90) return 'A';
    if (score >= 80) return 'B';
    if (score >= 70) return 'C';
    if (score >= 60) return 'D';
    return 'F';
  }

  /// Extract keywords from text
  static List<String> extractKeywords(String text, {int maxKeywords = 10}) {
    // Remove common stop words
    final stopWords = {
      'el',
      'la',
      'de',
      'que',
      'y',
      'en',
      'un',
      'ser',
      'se',
      'no',
      'por',
      'con',
      'para',
      'una',
      'su',
      'al',
      'lo',
      'como',
      'mas',
      'pero',
      'sus',
      'le',
      'ya',
      'o',
      'este',
      'si',
      'porque',
      'esta',
      'the',
      'is',
      'at',
      'which',
      'on',
      'a',
      'an',
      'as',
      'are',
      'was',
      'were',
      'been',
      'be',
      'have',
      'has',
      'had',
      'do',
      'does',
      'did',
      'will',
      'would',
      'should',
      'could',
      'may',
      'might',
    };

    final words = text.toLowerCase().split(RegExp(r'\W+'));
    final wordFrequency = <String, int>{};

    for (final word in words) {
      if (word.length > 3 && !stopWords.contains(word)) {
        wordFrequency[word] = (wordFrequency[word] ?? 0) + 1;
      }
    }

    // Sort by frequency and return top keywords
    final sortedWords = wordFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedWords
        .take(maxKeywords)
        .map((e) => e.key)
        .toList();
  }

  /// Validate URL structure for SEO
  static SeoValidationResult validateUrl(String url) {
    // Check length
    if (url.length > 100) {
      return SeoValidationResult(
        isValid: false,
        score: 60,
        message: 'URL is too long (${url.length} chars)',
        recommendation: 'Keep URLs under 100 characters',
      );
    }

    // Check for special characters
    if (RegExp(r'[^a-z0-9\-/._~:?#\[\]@!$&()*+,;=%]', caseSensitive: false)
        .hasMatch(url)) {
      return SeoValidationResult(
        isValid: false,
        score: 70,
        message: 'URL contains special characters',
        recommendation: 'Use only alphanumeric characters and hyphens',
      );
    }

    // Check for underscores (hyphens are preferred)
    if (url.contains('_')) {
      return SeoValidationResult(
        isValid: true,
        score: 85,
        message: 'URL contains underscores',
        recommendation: 'Use hyphens instead of underscores for better SEO',
      );
    }

    return SeoValidationResult(
      isValid: true,
      score: 100,
      message: 'URL structure is good',
    );
  }
}

/// SEO Validation Result
class SeoValidationResult {

  SeoValidationResult({
    required this.isValid,
    required this.score,
    required this.message,
    this.recommendation,
  });
  final bool isValid;
  final int score;
  final String message;
  final String? recommendation;

  @override
  String toString() {
    final buffer = StringBuffer('[Score: $score/100] $message');
    if (recommendation != null) {
      buffer.write(' - $recommendation');
    }
    return buffer.toString();
  }
}

/// Heading Information
class HeadingInfo {

  HeadingInfo({required this.level, required this.text});
  final int level; // 1-6 for H1-H6
  final String text;
}

/// Heading Hierarchy Result
class HeadingHierarchyResult {

  HeadingHierarchyResult({
    required this.isValid,
    required this.issues,
    required this.score,
    this.h1Count,
    this.totalHeadings,
  });
  final bool isValid;
  final List<String> issues;
  final int score;
  final int? h1Count;
  final int? totalHeadings;

  @override
  String toString() {
    final buffer = StringBuffer('[Score: $score/100] ');
    if (isValid) {
      buffer.write('Heading hierarchy is valid');
    } else {
      buffer.write('Issues found: ${issues.join(", ")}');
    }
    if (h1Count != null) {
      buffer.write(' (H1: $h1Count, Total: $totalHeadings)');
    }
    return buffer.toString();
  }
}

/// Page SEO Score
class PageSeoScore {

  PageSeoScore({
    required this.score,
    required this.grade,
    required this.issues,
    required this.warnings,
    required this.metrics,
  });
  final int score;
  final String grade;
  final List<String> issues;
  final List<String> warnings;
  final Map<String, dynamic> metrics;

  @override
  String toString() {
    return 'SEO Score: $score/100 (Grade: $grade)\n'
        'Issues: ${issues.isEmpty ? "None" : issues.join(", ")}\n'
        'Warnings: ${warnings.isEmpty ? "None" : warnings.join(", ")}';
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'grade': grade,
      'issues': issues,
      'warnings': warnings,
      'metrics': metrics,
    };
  }
}
