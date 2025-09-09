import 'package:korset_app/models/tariff.dart';

class UserTariff {
  final int id;
  final int userId;
  final int tariffId;
  final double paidAmount;
  final DateTime purchasedAt;
  final DateTime expiresAt;
  final String status;
  final String transactionReference;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Tariff tariff;

  UserTariff({
    required this.id,
    required this.userId,
    required this.tariffId,
    required this.paidAmount,
    required this.purchasedAt,
    required this.expiresAt,
    required this.status,
    required this.transactionReference,
    required this.createdAt,
    required this.updatedAt,
    required this.tariff,
  });

  factory UserTariff.fromJson(Map<String, dynamic> json) {
    return UserTariff(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      tariffId: json['tariff_id'] ?? 0,
      paidAmount:
          double.tryParse(json['paid_amount']?.toString() ?? '0') ?? 0.0,
      purchasedAt:
          DateTime.tryParse(json['purchased_at'] ?? '') ?? DateTime.now(),
      expiresAt: DateTime.tryParse(json['expires_at'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? '',
      transactionReference: json['transaction_reference'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      tariff: Tariff.fromJson(json['tariff'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'tariff_id': tariffId,
      'paid_amount': paidAmount.toString(),
      'purchased_at': purchasedAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'status': status,
      'transaction_reference': transactionReference,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'tariff': tariff.toJson(),
    };
  }

  bool get isActive => status == 'active';
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration get timeRemaining {
    if (isExpired) return Duration.zero;
    return expiresAt.difference(DateTime.now());
  }

  String get timeRemainingFormatted {
    if (isExpired) return 'Истек';

    final remaining = timeRemaining;
    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;

    if (days > 0) {
      return '$days д. $hours ч.';
    } else if (hours > 0) {
      return '$hours ч. $minutes м.';
    } else {
      return '$minutes м.';
    }
  }
}

class MyTariffsResponse {
  final bool success;
  final List<UserTariff> data;
  final int activeCount;

  MyTariffsResponse({
    required this.success,
    required this.data,
    required this.activeCount,
  });

  factory MyTariffsResponse.fromJson(Map<String, dynamic> json) {
    return MyTariffsResponse(
      success: json['success'] ?? false,
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => UserTariff.fromJson(item))
              .toList() ??
          [],
      activeCount: json['active_count'] ?? 0,
    );
  }
}
