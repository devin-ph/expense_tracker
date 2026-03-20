import 'package:flutter/foundation.dart';
import '../models/index.dart';

// Wallet notifier
class WalletNotifier extends ChangeNotifier {
  List<Wallet> _wallets = [];
  Wallet? _selectedWallet;
  bool _isLoading = false;

  List<Wallet> get wallets => _wallets;
  Wallet? get selectedWallet => _selectedWallet;
  bool get isLoading => _isLoading;

  WalletNotifier() {
    _initialize();
  }

  void _initialize() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));

    // Create default wallet
    _wallets = [
      Wallet(
        id: '1',
        userId: 'user1',
        name: 'Ví chính',
        balance: 5000000,
        createdAt: DateTime.now(),
        isDefault: true,
      ),
      Wallet(
        id: '2',
        userId: 'user1',
        name: 'Ví tiết kiệm',
        balance: 2000000,
        createdAt: DateTime.now(),
      ),
    ];
    _selectedWallet = _wallets.first;

    _isLoading = false;
    notifyListeners();
  }

  void selectWallet(Wallet wallet) {
    _selectedWallet = wallet;
    notifyListeners();
  }

  void addWallet(Wallet wallet) {
    _wallets.add(wallet);
    notifyListeners();
  }

  void updateWallet(Wallet wallet) {
    final index = _wallets.indexWhere((w) => w.id == wallet.id);
    if (index != -1) {
      _wallets[index] = wallet;
      notifyListeners();
    }
  }

  void deleteWallet(String id) {
    _wallets.removeWhere((w) => w.id == id);
    if (_selectedWallet?.id == id && _wallets.isNotEmpty) {
      _selectedWallet = _wallets.first;
    }
    notifyListeners();
  }

  void updateWalletBalance(String walletId, double amount) {
    final index = _wallets.indexWhere((w) => w.id == walletId);
    if (index != -1) {
      _wallets[index] = _wallets[index].copyWith(balance: amount);
      if (_selectedWallet?.id == walletId) {
        _selectedWallet = _wallets[index];
      }
      notifyListeners();
    }
  }
}
