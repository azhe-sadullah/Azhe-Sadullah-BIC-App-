import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bic/screens/mainscreen.dart';
import 'package:bic/services/auth_service.dart';
import 'package:bic/services/notification_service.dart';
import 'package:bic/utils/validation.dart';

class LoginViewModel extends ChangeNotifier {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool validate = false;
  bool loading = false;
  String? email, password;
  FocusNode emailFN = FocusNode();
  FocusNode passFN = FocusNode();
  final AuthService _authService = AuthService();

  Future<void> login(BuildContext context) async {
    FormState form = formKey.currentState!;
    form.save();
    if (!form.validate()) {
      validate = true;
      notifyListeners();
      showInSnackBar('تکایە هەڵەکانی سوور چاک بکە پێش ناردن', context);
    } else {
      loading = true;
      notifyListeners();

      try {
        Map<String, dynamic> result = await _authService.login(email!, password!)
            .timeout(const Duration(seconds: 20), onTimeout: () {
          return {'success': false, 'message': 'کاتی پەیوەندی تەواو بوو. تکایە ئینترنەتەکەت بپشکنە'};
        });

        loading = false;
        notifyListeners();

        if (!context.mounted) return;

        if (result['success']) {
          await NotificationService().refreshTokenAfterLogin();
          if (!context.mounted) return;
          Navigator.of(context).pushReplacement(
            CupertinoPageRoute(builder: (_) => const TabScreen()),
          );
        } else {
          showInSnackBar(result['message'], context);
        }
      } catch (e) {
        loading = false;
        notifyListeners();
        if (!context.mounted) return;
        showInSnackBar('هەڵەیەک ڕوویدا: $e', context);
      }
    }
  }

  Future<void> forgotPassword(BuildContext context) async {
    loading = true;
    notifyListeners();
    FormState form = formKey.currentState!;
    form.save();

    if (Validations.validateEmail(email) != null) {
      showInSnackBar('تکایە ئیمەیڵێکی دروست بنووسە بۆ گەڕاندنەوەی وشەی نهێنی', context);
      loading = false;
      notifyListeners();
      return;
    }

    try {
      Map<String, dynamic> result = await _authService.forgotPassword(email!)
          .timeout(const Duration(seconds: 20), onTimeout: () {
        return {'success': false, 'message': 'کاتی پەیوەندی تەواو بوو. تکایە ئینترنەتەکەت بپشکنە'};
      });
      loading = false;
      notifyListeners();

      if (!context.mounted) return;

      if (result['success']) {
        showInSnackBar('تکایە ئیمەیڵەکەت بپشکنە بۆ ڕێنماییەکانی گەڕاندنەوەی وشەی نهێنی', context);
      } else {
        showInSnackBar(result['message'], context);
      }
    } catch (e) {
      loading = false;
      notifyListeners();
      if (!context.mounted) return;
      showInSnackBar(e.toString(), context);
    }
  }

  void setEmail(String val) {
    email = val;
    notifyListeners();
  }

  void setPassword(String val) {
    password = val;
    notifyListeners();
  }

  void showInSnackBar(String value, context) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }
}
