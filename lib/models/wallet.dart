import 'package:flutter/foundation.dart';

class Wallet {
  final double currentBalance;
  final String totalDeposits;
  final String totalWithdrawals;
  final String totalTransactions;
  final String lastTransaction;

  Wallet({
    required this.currentBalance,
    required this.totalDeposits,
    required this.totalWithdrawals,
    required this.totalTransactions,
    required this.lastTransaction,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    try {
      debugPrint('Wallet.fromJson: Парсим данные: $json');

      // Безопасно парсим current_balance
      double balance = 0.0;
      final balanceValue = json['current_balance'];
      if (balanceValue != null) {
        if (balanceValue is num) {
          balance = balanceValue.toDouble();
        } else if (balanceValue is String) {
          balance = double.tryParse(balanceValue) ?? 0.0;
        }
      }

      final wallet = Wallet(
        currentBalance: balance,
        totalDeposits: json['total_deposits']?.toString() ?? '',
        totalWithdrawals: json['total_withdrawals']?.toString() ?? '',
        totalTransactions: json['total_transactions']?.toString() ?? '',
        lastTransaction: json['last_transaction']?.toString() ?? '',
      );

      debugPrint(
          'Wallet.fromJson: Успешно создан кошелек с балансом: ${wallet.currentBalance}');
      return wallet;
    } catch (e) {
      debugPrint('Wallet.fromJson: Ошибка парсинга: $e');
      debugPrint('Wallet.fromJson: Данные JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'current_balance': currentBalance,
      'total_deposits': totalDeposits,
      'total_withdrawals': totalWithdrawals,
      'total_transactions': totalTransactions,
      'last_transaction': lastTransaction,
    };
  }
}
