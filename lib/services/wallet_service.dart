import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletService extends ChangeNotifier {
  WalletService._();

  static final WalletService instance = WalletService._();
  static const String _balanceKey = 'wallet_balance';

  double _balance = 0;
  bool _loaded = false;
  bool _loading = false;

  double get balance => _balance;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    if (_loaded || _loading) return;
    _loading = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      _balance = prefs.getDouble(_balanceKey) ?? 0;
      _loaded = true;
      notifyListeners();
    } finally {
      _loading = false;
    }
  }

  Future<double> topUp(double amount) async {
    if (amount <= 0) {
      return balance;
    }
    await load();
    _balance += amount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_balanceKey, _balance);
    notifyListeners();
    return _balance;
  }

  Future<double> spend(double amount) async {
    if (amount <= 0) {
      return balance;
    }
    await load();
    if (amount > _balance) {
      throw StateError('Insufficient wallet balance');
    }
    _balance -= amount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_balanceKey, _balance);
    notifyListeners();
    return _balance;
  }
}
