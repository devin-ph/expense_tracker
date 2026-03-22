import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/index.dart';

// Authentication state notifier
class AuthNotifier extends ChangeNotifier {
  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  // Listen to auth state changes
  AuthNotifier() {
    _firebaseAuth.authStateChanges().listen((firebase_auth.User? user) async {
      if (user != null) {
        // Load user profile from Firestore
        await _loadUserProfile(user.uid);
      } else {
        _currentUser = null;
      }
      notifyListeners();
    });
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await _loadUserProfile(user.uid);
      } else {
        _currentUser = null;
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = User.fromJson({...doc.data()!, 'id': uid});
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _loadUserProfile(result.user!.uid);
      _error = null;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signup(String email, String password, String name) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      final newUser = User(
        id: result.user!.uid,
        name: name,
        email: email,
        photoUrl: null,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .set(newUser.toJson());

      _currentUser = newUser;
      _error = null;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
      _currentUser = null;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<void> loginWithGoogle() async {
    _isLoading = true;
    notifyListeners();
    try {
      // Note: Google Sign-in requires additional Google Sign-in plugin
      // For now, this is a placeholder
      // You need to implement google_sign_in package
      throw Exception('Google Sign-in chưa được cấu hình');
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserProfile({String? name, String? photoUrl}) async {
    if (_currentUser == null) {
      _error = 'Không có người dùng đang đăng nhập';
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();
    try {
      final updated = _currentUser!.copyWith(name: name, photoUrl: photoUrl);

      // Update in Firestore
      await _firestore.collection('users').doc(_currentUser!.id).update({
        if (name != null) 'name': name,
        if (photoUrl != null) 'photoUrl': photoUrl,
      });

      _currentUser = updated;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Email không tồn tại';
      case 'wrong-password':
        return 'Mật khẩu không chính xác';
      case 'email-already-in-use':
        return 'Email đã được sử dụng';
      case 'weak-password':
        return 'Mật khẩu quá yếu';
      case 'invalid-email':
        return 'Email không hợp lệ';
      case 'user-disabled':
        return 'Người dùng đã bị vô hiệu hóa';
      default:
        return 'Lỗi xác thực: $code';
    }
  }
}
