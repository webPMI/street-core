/// Prize Pool Model - Competition prize distribution.
/// Following Monolith-by-Features architecture (ADR-005).

import 'package:equatable/equatable.dart';

// =============================================================================
// PRIZE POOL
// =============================================================================

class PrizePool extends Equatable {
  const PrizePool({
    required this.totalAmount,
    required this.currency,
    this.firstPlace,
    this.secondPlace,
    this.thirdPlace,
    this.otherPrizes,
    this.nonMonetaryPrizes,
  });

  factory PrizePool.fromJson(Map<String, dynamic> json) {
    return PrizePool(
      totalAmount: (json['totalAmount'] as num).toDouble(),
      currency: json['currency'] as String,
      firstPlace: json['firstPlace'] != null
          ? (json['firstPlace'] as num).toDouble()
          : null,
      secondPlace: json['secondPlace'] != null
          ? (json['secondPlace'] as num).toDouble()
          : null,
      thirdPlace: json['thirdPlace'] != null
          ? (json['thirdPlace'] as num).toDouble()
          : null,
      otherPrizes: (json['otherPrizes'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(int.parse(k), (v as num).toDouble()),
      ),
      nonMonetaryPrizes: (json['nonMonetaryPrizes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

  final double totalAmount;
  final String currency;
  final double? firstPlace;
  final double? secondPlace;
  final double? thirdPlace;
  final Map<int, double>? otherPrizes;
  final List<String>? nonMonetaryPrizes;

  Map<String, dynamic> toJson() {
    return {
      'totalAmount': totalAmount,
      'currency': currency,
      'firstPlace': firstPlace,
      'secondPlace': secondPlace,
      'thirdPlace': thirdPlace,
      'otherPrizes': otherPrizes?.map((k, v) => MapEntry(k.toString(), v)),
      'nonMonetaryPrizes': nonMonetaryPrizes,
    };
  }

  @override
  List<Object?> get props =>
      [totalAmount, currency, firstPlace, secondPlace, thirdPlace];
}
