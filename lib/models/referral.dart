class ReferralData {
  final String myReferralCode;
  final int totalReferrals;
  final double totalEarnings;
  final double pendingEarnings;
  final double paidEarnings;
  final List<ReferralItem> referrals;

  const ReferralData({
    required this.myReferralCode,
    required this.totalReferrals,
    required this.totalEarnings,
    required this.pendingEarnings,
    required this.paidEarnings,
    required this.referrals,
  });

  factory ReferralData.fromJson(Map<String, dynamic> json) {
    return ReferralData(
      myReferralCode: json['my_referral_code'] ?? '',
      totalReferrals: json['total_referrals'] ?? 0,
      totalEarnings: (json['total_earnings'] ?? 0.0).toDouble(),
      pendingEarnings: (json['pending_earnings'] ?? 0.0).toDouble(),
      paidEarnings: (json['paid_earnings'] ?? 0.0).toDouble(),
      referrals: (json['referrals'] as List<dynamic>? ?? [])
          .map((item) => ReferralItem.fromJson(item))
          .toList(),
    );
  }
}

class ReferralItem {
  final int id;
  final ReferredUser referredUser;
  final double rewardAmount;
  final bool isPaid;
  final DateTime createdAt;
  final DateTime? paidAt;

  const ReferralItem({
    required this.id,
    required this.referredUser,
    required this.rewardAmount,
    required this.isPaid,
    required this.createdAt,
    this.paidAt,
  });

  factory ReferralItem.fromJson(Map<String, dynamic> json) {
    return ReferralItem(
      id: json['id'] ?? 0,
      referredUser: ReferredUser.fromJson(json['referred_user'] ?? {}),
      rewardAmount: (json['reward_amount'] ?? 0.0).toDouble(),
      isPaid: json['is_paid'] ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      paidAt: json['paid_at'] != null 
          ? DateTime.tryParse(json['paid_at']) 
          : null,
    );
  }
}

class ReferredUser {
  final String name;
  final String surname;
  final String email;

  const ReferredUser({
    required this.name,
    required this.surname,
    required this.email,
  });

  factory ReferredUser.fromJson(Map<String, dynamic> json) {
    return ReferredUser(
      name: json['name'] ?? '',
      surname: json['surname'] ?? '',
      email: json['email'] ?? '',
    );
  }

  String get fullName => '$name $surname';
}

class ReferralCodeResponse {
  final String referralCode;
  final String message;

  const ReferralCodeResponse({
    required this.referralCode,
    required this.message,
  });

  factory ReferralCodeResponse.fromJson(Map<String, dynamic> json) {
    return ReferralCodeResponse(
      referralCode: json['referral_code'] ?? '',
      message: json['message'] ?? '',
    );
  }
}
