import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bic/screens/mainscreen.dart';
import 'package:bic/services/firestore_service.dart';
import 'package:bic/services/email_service.dart';
import 'package:bic/services/notification_service.dart';
import 'package:bic/models/user_model.dart';

class RegisterViewModel extends ChangeNotifier {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<FormState>     formKey     = GlobalKey<FormState>();

  bool validate = false;
  bool loading  = false;

  String? username;
  String? email;
  String? password;
  String? cPassword;
  String? phoneNumber; // Full: e.g. "+9647501234567"
  String  country = '+964';

  FocusNode usernameFN = FocusNode();
  FocusNode emailFN    = FocusNode();
  FocusNode countryFN  = FocusNode();
  FocusNode passFN     = FocusNode();
  FocusNode cPassFN    = FocusNode();

  String?   _emailCode;
  DateTime? _emailCodeExpiry;

  final FirebaseAuth     _auth             = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  void setEmail(String? val)       { email     = val; notifyListeners(); }
  void setPassword(String? val)    { password  = val; notifyListeners(); }
  void setName(String? val)        { username  = val; notifyListeners(); }
  void setConfirmPass(String? val) { cPassword = val; notifyListeners(); }
  void setCountry(String? val)     { country   = val ?? '+964'; notifyListeners(); }

  void setPhone(String localNumber, String countryCode) {
    country = countryCode;
    // Remove leading 0 from local number (e.g. "07501234567" → "7501234567")
    final local = localNumber.startsWith('0') ? localNumber.substring(1) : localNumber;
    phoneNumber = countryCode + local;
    notifyListeners();
  }

  Future<bool> startRegistration(BuildContext context) async {
    final form = formKey.currentState!;
    form.save();

    if (!form.validate()) {
      validate = true;
      notifyListeners();
      _snack('تکایە هەڵەکانی سووری چاک بکەرەوە', context);
      return false;
    }

    if (phoneNumber == null || phoneNumber!.length < 8) {
      _snack('تکایە ژمارەی تەلەفۆنی دروست داخڵ بکە', context);
      return false;
    }

    if (password != cPassword) {
      _snack('وشەی نهێنیەکان یەک نین', context);
      return false;
    }

    loading = true;
    notifyListeners();

    try {
      final available = await _firestoreService.isUsernameAvailable(username!)
          .timeout(const Duration(seconds: 15), onTimeout: () {
        throw TimeoutException('کاتی پشکنینی ناوی بەکارهێنەر تەواو بوو');
      });
      if (!available) {
        loading = false;
        notifyListeners();
        if (!context.mounted) return false;
        _snack('ئەم ناوەی بەکارهێنەر پێشتر بەکارهاتووە', context);
        return false;
      }

      _emailCode       = EmailService.generateCode();
      _emailCodeExpiry = DateTime.now().add(const Duration(minutes: 1));

      final sent = await EmailService.sendVerificationCode(
        toEmail:  email!,
        code:     _emailCode!,
        userName: username!,
      ).timeout(const Duration(seconds: 15), onTimeout: () => false);

      loading = false;
      notifyListeners();

      if (!context.mounted) return false;

      if (!sent) {
        await _showTestCodeDialog(context, _emailCode!);
        if (!context.mounted) return false;
      }
      return true; // caller navigates to EmailOtpScreen
    } catch (e) {
      loading = false;
      notifyListeners();
      if (!context.mounted) return false;
      _snack('هەڵەیەک ڕوویدا: $e', context);
      return false;
    }
  }

  Future<void> _showTestCodeDialog(BuildContext context, String code) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.developer_mode, color: Colors.orange),
            SizedBox(width: 8),
            Text('حاڵەتی تاقیکردنەوە',
                style: TextStyle(fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'کۆدی تاییدکردنت ئەمەیە — لە ئەپپەکەدا داخڵ بکە:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF3897F0).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF3897F0), width: 2),
              ),
              child: Text(
                code,
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 12,
                  color: Color(0xFF3897F0),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'ئەم کۆدە کۆپی بکەرەوە، بەدواوەوە دەمانخەینە ناو خانەکانی تاییدکردن',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('باشە، تێگەیشتم',
                style: TextStyle(color: Color(0xFF3897F0), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  bool verifyEmailCode(String enteredCode) {
    if (_emailCode == null || _emailCodeExpiry == null) return false;
    if (DateTime.now().isAfter(_emailCodeExpiry!)) return false;
    return enteredCode.trim() == _emailCode;
  }

  Future<String?> resendEmailCode(BuildContext context) async {
    _emailCode       = EmailService.generateCode();
    _emailCodeExpiry = DateTime.now().add(const Duration(minutes: 1));

    final sent = await EmailService.sendVerificationCode(
      toEmail:  email!,
      code:     _emailCode!,
      userName: username!,
    );

    if (!context.mounted) return null;
    if (sent) {
      _snack('کۆدی نوێ نێردرا بۆ ئیمەیڵەکەت ✅', context);
      return null;
    }
    return _emailCode; // caller will show dialog after turning off loading
  }

  Future<void> showTestCodeDialog(BuildContext context, String code) =>
      _showTestCodeDialog(context, code);

  Future<void> createAccountAndSendPhoneOtp(
    BuildContext context,
    void Function(String verificationId) onCodeSent,
  ) async {
    loading = true;
    notifyListeners();

    try {
      bool available = true;
      try {
        available = await _firestoreService.isUsernameAvailable(username!);
      } catch (_) {}


      if (!available) {
        loading = false;
        notifyListeners();
        if (!context.mounted) return;
        _snack('ئەم ناوەی بەکارهێنەر پێشتر بەکارهاتووە', context);
        return;
      }

      final result = await _auth.createUserWithEmailAndPassword(
        email:    email!,
        password: password!,
      ).timeout(const Duration(seconds: 20), onTimeout: () {
        throw TimeoutException('کاتی پەیوەندی تەواو بوو. تکایە ئینترنەتەکەت بپشکنە');
      });

      if (result.user == null) {
        loading = false;
        notifyListeners();
        if (!context.mounted) return;
        _snack('تۆمارکردن سەرکەوتوو نەبوو', context);
        return;
      }

      await result.user!.updateDisplayName(username);

      if (!context.mounted) return;

      await _sendPhoneOtp(
        context,
        onCodeSent,
        onPhoneAuthFailed: () async {
          if (!context.mounted) return;
          await _completeRegistration(context);
        },
      );
    } on FirebaseAuthException catch (e) {
      loading = false;
      notifyListeners();
      if (!context.mounted) return;
      _snack(_authError(e.code), context);
    } catch (e) {
      loading = false;
      notifyListeners();
      if (!context.mounted) return;
      _snack('هەڵەیەک ڕوویدا: $e', context);
    }
  }

  Future<void> _sendPhoneOtp(
    BuildContext context,
    void Function(String verificationId) onCodeSent, {
    Future<void> Function()? onPhoneAuthFailed,
  }) async {
    if (phoneNumber == null || phoneNumber!.length < 10) {
      if (onPhoneAuthFailed != null) await onPhoneAuthFailed();
      return;
    }

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber!,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await _auth.currentUser!.linkWithCredential(credential);
          } catch (_) {}
          if (!context.mounted) return;
          await _completeRegistration(context);
        },
        verificationFailed: (FirebaseAuthException e) {
          loading = false;
          notifyListeners();
          if (onPhoneAuthFailed != null) {
            onPhoneAuthFailed();
          } else {
            if (!context.mounted) return;
            _snack('هەڵەی تاییدکردنی تەلەفۆن: ${e.message}', context);
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          loading = false;
          notifyListeners();
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (_) {
      loading = false;
      notifyListeners();
      if (onPhoneAuthFailed != null && context.mounted) {
        await onPhoneAuthFailed();
      }
    }
  }

  Future<void> verifyPhoneOtp(
    BuildContext context,
    String verificationId,
    String smsCode, {
    required void Function(String msg) onError,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode:        smsCode,
      );

      try {
        await _auth.currentUser!.linkWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code != 'provider-already-linked' &&
            e.code != 'credential-already-in-use') {
          onError('کۆدی هەڵەیە. تکایە دووبارە هەوڵ بدەرەوە');
          return;
        }
      }

      if (!context.mounted) return;
      await _completeRegistration(context);
    } catch (e) {
      onError('کۆدی هەڵەیە. تکایە دووبارە هەوڵ بدەرەوە');
    }
  }

  Future<void> resendPhoneOtp(
    BuildContext context, {
    required void Function(String verificationId) onCodeSent,
  }) async {
    await _sendPhoneOtp(context, onCodeSent);
  }

  Future<void> _completeRegistration(BuildContext context) async {
    loading = true;
    notifyListeners();

    try {
      final uid = _auth.currentUser!.uid;

      final newUser = UserModel(
        id:             uid,
        username:       username!,
        email:          email!,
        fullName:       '',
        avatar:         '',
        bio:            'Welcome to BIC!',
        postsCount:     0,
        followersCount: 0,
        followingCount: 0,
        isVerified:     false,
        followers:      [],
        following:      [],
        bookmarks:      [],
        createdAt:      DateTime.now(),
      );

      await _firestoreService.createUser(newUser)
          .timeout(const Duration(seconds: 15), onTimeout: () {
        throw TimeoutException('کاتی پەیوەندی تەواو بوو. تکایە ئینترنەتەکەت بپشکنە');
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', uid);

      await NotificationService().refreshTokenAfterLogin();

      loading = false;
      notifyListeners();

      if (!context.mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        CupertinoPageRoute(builder: (_) => const TabScreen()),
        (route) => false,
      );
    } catch (e) {
      loading = false;
      notifyListeners();
      if (!context.mounted) return;
      _snack('هەڵەیەک ڕوویدا: $e', context);
    }
  }

  void _snack(String msg, BuildContext context) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  String _authError(String code) {
    switch (code) {
      case 'email-already-in-use':  return 'ئەم ئیمەیڵە پێشتر تۆمارکراوە';
      case 'invalid-email':         return 'ئیمەیڵ دروست نییە';
      case 'weak-password':         return 'وشەی نهێنی زۆر لاوازە (لانیکەم ٦ پیت)';
      case 'operation-not-allowed': return 'تۆمارکردن چالاک نەکراوە';
      default:                      return 'هەڵەیەک ڕوویدا. تکایە دووبارە هەوڵ بدەرەوە';
    }
  }

  void showInSnackBar(String value, BuildContext context) =>
      _snack(value, context);
}
