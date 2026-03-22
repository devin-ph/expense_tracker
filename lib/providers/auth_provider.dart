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
      } else {
        _currentUser = null;
      }
    } catch (e) {
      _currentUser = null;
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

      // Load user profile from Firestore
      await _loadUserProfile(result.user!.uid);

      // If profile not found in Firestore, sign out and show error
      if (_currentUser == null) {
        await _firebaseAuth.signOut();
        _error = 'Tài khoản không tồn tại';
        throw Exception(_error);
      }

      _error = null;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
      throw Exception(_error);
    } catch (e) {
      _error = e.toString();
      throw Exception(_error);
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

      try {
        await _firestore
            .collection('users')
            .doc(result.user!.uid)
            .set(newUser.toJson());
      } catch (e) {
        // Keep auth and Firestore consistent: if profile creation fails,
        // remove the just-created auth account and surface the error.
        await result.user?.delete();
        _currentUser = null;
        throw Exception(
          'Đăng ký thất bại: không thể lưu dữ liệu người dùng trên Firebase.',
        );
      }

      _currentUser = newUser;
      _error = null;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
      throw Exception(_error);
    } catch (e) {
      _error = e.toString();
      throw Exception(_error);
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
      if (!kIsWeb &&
          defaultTargetPlatform != TargetPlatform.android &&
          defaultTargetPlatform != TargetPlatform.iOS &&
          defaultTargetPlatform != TargetPlatform.macOS) {
        throw Exception('Google Sign-in chưa hỗ trợ trên nền tảng này');
      }

      final googleProvider = firebase_auth.GoogleAuthProvider();
      final userCredential = kIsWeb
          ? await _firebaseAuth.signInWithPopup(googleProvider)
          : await _firebaseAuth.signInWithProvider(googleProvider);

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Đăng nhập Google thất bại');
      }

      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) {
        final newUser = User(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? 'Google User',
          email: firebaseUser.email ?? '',
          photoUrl: firebaseUser.photoURL,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set(newUser.toJson());

        _currentUser = newUser;
      } else {
        _currentUser = User.fromJson({
          ...userDoc.data()!,
          'id': firebaseUser.uid,
        });
      }

      _error = null;
    } on firebase_auth.FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'popup-closed-by-user':
          _error = 'Bạn đã đóng cửa sổ đăng nhập Google';
          break;
        case 'account-exists-with-different-credential':
          _error = 'Email đã tồn tại với phương thức đăng nhập khác';
          break;
        default:
          _error = _getErrorMessage(e.code);
      }
      throw Exception(_error);
    } catch (e) {
      _error = e.toString();
      throw Exception(_error);
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
      case 'auth-domain-config-required':
        return 'Thiếu cấu hình auth domain cho Google đăng nhập. Vui lòng kiểm tra Firebase web config.';
      case 'unauthorized-domain':
        return 'Domain hiện tại chưa được cho phép trong Firebase Authentication > Settings > Authorized domains.';
      case 'operation-not-allowed':
        return 'Phương thức đăng nhập này chưa được bật trong Firebase Authentication.';
      case 'configuration-not-found':
        return 'Thiếu cấu hình Google Sign-In trên Firebase. Vào Firebase Authentication > Sign-in method và bật Google, chọn Project support email rồi lưu.';
      default:
        return 'Lỗi xác thực: $code';
    }
  }
}
