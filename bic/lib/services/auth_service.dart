import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';
import 'notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        await _saveUserId(result.user!.uid);
        return {'success': true, 'user': result.user};
      } else {
        return {'success': false, 'message': 'Login failed'};
      }
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getErrorMessage(e.code)};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String country,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      bool isAvailable = await _firestoreService.isUsernameAvailable(username);
      if (!isAvailable) {
        return {'success': false, 'message': 'Username is already taken'};
      }

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        await result.user!.updateDisplayName(username);

        UserModel newUser = UserModel(
          id: result.user!.uid,
          username: username,
          email: email,
          fullName: '',
          avatar: '',
          bio: 'Welcome to BIC!',
          postsCount: 0,
          followersCount: 0,
          followingCount: 0,
          isVerified: false,
          followers: [],
          following: [],
          bookmarks: [],
          createdAt: DateTime.now(),
        );

        await _firestoreService.createUser(newUser);
        await _saveUserId(result.user!.uid);

        return {'success': true, 'user': result.user};
      } else {
        return {'success': false, 'message': 'Registration failed'};
      }
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getErrorMessage(e.code)};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {'success': true, 'message': 'Password reset email sent'};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getErrorMessage(e.code)};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  Future<void> logout() async {
    await NotificationService().clearTokenOnLogout();
    await _auth.signOut();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('userData');
  }

  Future<UserModel?> getUserData(String uid) async {
    try {
      final user = await _firestoreService.getUser(uid);
      return user;
    } catch (e) {
      if (_auth.currentUser != null && _auth.currentUser!.uid == uid) {
        return UserModel(
          id: _auth.currentUser!.uid,
          username: _auth.currentUser!.displayName ?? '',
          email: _auth.currentUser!.email ?? '',
        );
      }
      return null;
    }
  }

  Future<UserModel?> getCurrentUserData() async {
    if (_auth.currentUser == null) return null;
    return await getUserData(_auth.currentUser!.uid);
  }

  Future<bool> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestoreService.updateUser(uid, data);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _saveUserId(String uid) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', uid);
  }

  Future<String?> getSavedUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn(
        serverClientId: '750851867031-e4haveuceos7h2cuv6t200ts2hdtilfh.apps.googleusercontent.com',
      ).signIn();
      if (googleUser == null) return {'success': false, 'message': 'چوونەژوورەوە پاشگەزبووەوە'};

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      if (result.user == null) return {'success': false, 'message': 'چوونەژوورەوە سەرکەوتوو نەبوو'};

      await _saveUserId(result.user!.uid);

      final existing = await _firestoreService.getUser(result.user!.uid).catchError((_) => null);
      if (existing == null) {
        final displayName = result.user!.displayName ?? googleUser.email.split('@').first;
        final newUser = UserModel(
          id: result.user!.uid,
          username: displayName,
          email: result.user!.email ?? '',
          fullName: result.user!.displayName ?? '',
          avatar: result.user!.photoURL ?? '',
          bio: 'Welcome to BIC!',
          postsCount: 0,
          followersCount: 0,
          followingCount: 0,
          isVerified: false,
          followers: [],
          following: [],
          bookmarks: [],
          createdAt: DateTime.now(),
        );
        await _firestoreService.createUser(newUser);
      }

      return {'success': true, 'user': result.user};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getErrorMessage(e.code)};
    } catch (e) {
      return {'success': false, 'message': 'هەڵەیەک ڕوویدا: $e'};
    }
  }

  Future<Map<String, dynamic>> signInWithFacebook() async {
    try {
      final loginResult = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );
      if (loginResult.status != LoginStatus.success) {
        return {'success': false, 'message': 'Facebook: ${loginResult.message ?? loginResult.status.toString()}'};
      }

      final credential = FacebookAuthProvider.credential(loginResult.accessToken!.tokenString);
      final result = await _auth.signInWithCredential(credential);
      if (result.user == null) return {'success': false, 'message': 'چوونەژوورەوە سەرکەوتوو نەبوو'};

      await _saveUserId(result.user!.uid);

      final existing = await _firestoreService.getUser(result.user!.uid).catchError((_) => null);
      if (existing == null) {
        final userData = await FacebookAuth.instance.getUserData();
        final newUser = UserModel(
          id: result.user!.uid,
          username: (userData['name'] as String? ?? result.user!.email ?? result.user!.uid).replaceAll(' ', '_'),
          email: result.user!.email ?? '',
          fullName: userData['name'] as String? ?? '',
          avatar: result.user!.photoURL ?? '',
          bio: 'Welcome to BIC!',
          postsCount: 0,
          followersCount: 0,
          followingCount: 0,
          isVerified: false,
          followers: [],
          following: [],
          bookmarks: [],
          createdAt: DateTime.now(),
        );
        await _firestoreService.createUser(newUser);
      }

      return {'success': true, 'user': result.user};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getErrorMessage(e.code)};
    } catch (e) {
      return {'success': false, 'message': 'هەڵەیەک ڕوویدا: $e'};
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'هیچ هەژمارێک بەم ئیمەیڵە نەدۆزرایەوە';
      case 'wrong-password':
        return 'وشەی نهێنی هەڵەیە';
      case 'email-already-in-use':
        return 'ئەم ئیمەیڵە پێشتر تۆمارکراوە';
      case 'invalid-email':
        return 'ئیمەیڵ دروست نییە';
      case 'weak-password':
        return 'وشەی نهێنی زۆر لاوازە (لانیکەم 6 پیت پێویستە)';
      case 'user-disabled':
        return 'ئەم هەژمارە ناچالاککراوە';
      case 'too-many-requests':
        return 'هەوڵی زۆر. تکایە دواتر هەوڵ بدەرەوە';
      case 'operation-not-allowed':
        return 'چوونەژوورەوە بە ئیمەیڵ/وشەی نهێنی چالاک نەکراوە';
      case 'invalid-credential':
        return 'ئیمەیڵ یان وشەی نهێنی هەڵەیە. تکایە دووبارە هەوڵ بدەرەوە';
      default:
        return 'هەڵەیەک ڕوویدا. تکایە دووبارە هەوڵ بدەرەوە';
    }
  }
}
