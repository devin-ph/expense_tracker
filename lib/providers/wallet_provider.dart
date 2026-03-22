import 'package:flutter/foundation.dart';
import '../models/index.dart';

// Wallet notifier
class WalletNotifier extends ChangeNotifier {
  List<Wallet> _wallets = [];
  Wallet? _selectedWallet;
  bool _isLoading = false;
  String? _currentUserId;

  final Map<String, List<Wallet>> _walletStore = {};
  final Map<String, String> _selectedWalletIdStore = {};

  List<Wallet> get wallets => _wallets;
  Wallet? get selectedWallet => _selectedWallet;
  bool get isLoading => _isLoading;

  Future<void> syncForUser(String? userId) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));

    _currentUserId = userId;
    if (userId == null || userId.isEmpty) {
      _wallets = [];
      _selectedWallet = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    _wallets = _walletStore.putIfAbsent(
      userId,
      () => _buildDefaultWallets(userId),
    );
    final selectedWalletId = _selectedWalletIdStore[userId];
    if (selectedWalletId != null) {
      final index = _wallets.indexWhere((w) => w.id == selectedWalletId);
      _selectedWallet = index == -1 ? null : _wallets[index];
    }
    _selectedWallet ??= _wallets.isNotEmpty ? _wallets.first : null;
    if (_selectedWallet != null) {
      _selectedWalletIdStore[userId] = _selectedWallet!.id;
    }

    _isLoading = false;
    notifyListeners();
  }

  List<Wallet> _buildDefaultWallets(String userId) {
    final now = DateTime.now();
    return [
      Wallet(
        id: '${userId}_wallet_1',
        userId: userId,
        name: 'Ví chính',
        balance: 5000000,
        createdAt: now,
        isDefault: true,
      ),
      Wallet(
        id: '${userId}_wallet_2',
        userId: userId,
        name: 'Ví tiết kiệm',
        balance: 2000000,
        createdAt: now,
      ),
    ];
  }

  void selectWallet(Wallet wallet) {
    _selectedWallet = wallet;
    if (_currentUserId != null) {
      _selectedWalletIdStore[_currentUserId!] = wallet.id;
    }
    notifyListeners();
  }

  void addWallet(Wallet wallet) {
    if (_currentUserId == null) return;
    final scoped = wallet.userId == _currentUserId
        ? wallet
        : wallet.copyWith(userId: _currentUserId);
    _wallets.add(scoped);
    notifyListeners();
  }

  void updateWallet(Wallet wallet) {
    final index = _wallets.indexWhere((w) => w.id == wallet.id);
    if (index != -1) {
      _wallets[index] = wallet;
      if (_selectedWallet?.id == wallet.id) {
        _selectedWallet = wallet;
      }
      notifyListeners();
    }
  }

  void deleteWallet(String id) {
    _wallets.removeWhere((w) => w.id == id);
    if (_selectedWallet?.id == id && _wallets.isNotEmpty) {
      _selectedWallet = _wallets.first;
      if (_currentUserId != null) {
        _selectedWalletIdStore[_currentUserId!] = _selectedWallet!.id;
      }
    } else if (_wallets.isEmpty) {
      _selectedWallet = null;
      if (_currentUserId != null) {
        _selectedWalletIdStore.remove(_currentUserId);
      }
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
