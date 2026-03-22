import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/index.dart';

// Wallet notifier
class WalletNotifier extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

    final local = _walletStore.putIfAbsent(userId, () => <Wallet>[]);

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('wallets')
          .get();

      if (snapshot.docs.isEmpty) {
        if (local.isEmpty) {
          local.addAll(_buildDefaultWallets(userId));
        }
        for (final wallet in local) {
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('wallets')
              .doc(wallet.id)
              .set(wallet.toJson());
        }
      } else {
        local
          ..clear()
          ..addAll(
            snapshot.docs.map(
              (doc) => Wallet.fromJson({...doc.data(), 'id': doc.id}),
            ),
          );
      }
    } catch (_) {
      if (local.isEmpty) {
        local.addAll(_buildDefaultWallets(userId));
      }
    }

    _wallets = local;
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
    final currentUserId = _currentUserId;
    if (currentUserId == null || currentUserId.isEmpty) return;

    final scoped = wallet.userId == currentUserId
        ? wallet
        : wallet.copyWith(userId: currentUserId);
    if (scoped.id.isEmpty) return;

    _wallets.add(scoped);
    _walletStore[currentUserId] = _wallets;
    try {
      _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('wallets')
          .doc(scoped.id)
          .set(scoped.toJson());
    } catch (_) {
      // Keep local state usable even if remote write fails in debug/runtime.
    }
    notifyListeners();
  }

  void updateWallet(Wallet wallet) {
    final index = _wallets.indexWhere((w) => w.id == wallet.id);
    if (index != -1) {
      _wallets[index] = wallet;
      if (_currentUserId != null) {
        _walletStore[_currentUserId!] = _wallets;
        _firestore
            .collection('users')
            .doc(_currentUserId)
            .collection('wallets')
            .doc(wallet.id)
            .set(wallet.toJson());
      }
      if (_selectedWallet?.id == wallet.id) {
        _selectedWallet = wallet;
      }
      notifyListeners();
    }
  }

  void deleteWallet(String id) {
    _wallets.removeWhere((w) => w.id == id);
    if (_currentUserId != null) {
      _walletStore[_currentUserId!] = _wallets;
      _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('wallets')
          .doc(id)
          .delete();
    }
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
