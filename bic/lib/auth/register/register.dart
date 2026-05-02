import 'package:bic/auth/login/login.dart';
import 'package:bic/view_model/auth/register_view_model.dart';
import 'package:bic/services/auth_service.dart';
import 'package:bic/screens/mainscreen.dart';
import 'package:bic/screens/legal/terms_screen.dart';
import 'package:bic/screens/legal/privacy_screen.dart';
import 'package:bic/screens/legal/cookies_screen.dart';
import 'package:bic/screens/email_otp_screen.dart';
import 'package:bic/components/phone_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:provider/provider.dart';

import '../../components/password_text_field.dart';
import '../../components/text_form_builder.dart';
import '../../utils/validation.dart';
import '../../widgets/indicators.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final FocusNode _phoneFN = FocusNode();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _phoneFN.dispose();
    super.dispose();
  }

  Future<void> _submitRegistration(
      BuildContext context, RegisterViewModel viewModel) async {
    final ok = await viewModel.startRegistration(context);
    if (ok && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EmailOtpScreen(viewModel: viewModel),
        ),
      );
    }
  }

  void _openTerms() {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => const TermsScreen()),
    );
  }

  void _openPrivacy() {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => const PrivacyScreen()),
    );
  }

  void _openCookies() {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => const CookiesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    RegisterViewModel viewModel = Provider.of<RegisterViewModel>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LoadingOverlay(
      progressIndicator: circularProgress(context),
      isLoading: viewModel.loading,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      const SizedBox(height: 40),

                      // Logo
                      _buildLogo(isDark),

                      const SizedBox(height: 30),

                      // Description
                      Text(
                        'Sign up to connect with businesses\nand professionals.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Social signup buttons
                      _buildSocialButtons(isDark),

                      const SizedBox(height: 24),

                      // Divider
                      _buildDivider(isDark),

                      const SizedBox(height: 24),

                      // Form
                      _buildForm(viewModel, context, isDark),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomBar(isDark),
      ),
    );
  }

  Widget _buildLogo(bool isDark) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF833AB4),
                Color(0xFFC13584),
                Color(0xFFE1306C),
                Color(0xFFF56040),
                Color(0xFFFCAF45),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFC13584).withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              'assets/app_icon.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'BIC',
          style: GoogleFonts.montserrat(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            letterSpacing: 6,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  bool _socialLoading = false;

  Future<void> _handleSocialLogin(Future<Map<String, dynamic>> Function() signIn) async {
    setState(() => _socialLoading = true);
    try {
      final result = await signIn();
      if (!mounted) return;
      if (result['success'] == true) {
        Navigator.of(context).pushAndRemoveUntil(
          CupertinoPageRoute(builder: (_) => const TabScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'هەڵەیەک ڕوویدا', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _socialLoading = false);
    }
  }

  Widget _buildSocialButtons(bool isDark) {
    final authService = AuthService();
    return Column(
      children: [
        // Facebook button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () { if (!_socialLoading) _handleSocialLogin(authService.signInWithFacebook); },
            icon: const Icon(Ionicons.logo_facebook, color: Colors.white, size: 20),
            label: Text(
              'Continue with Facebook',
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1877F2),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Google button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () { if (!_socialLoading) _handleSocialLogin(authService.signInWithGoogle); },
            icon: Icon(Ionicons.logo_google, color: isDark ? Colors.white : Colors.black87, size: 20),
            label: Text(
              'Continue with Google',
              style: GoogleFonts.poppins(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              elevation: 0,
              side: BorderSide(color: isDark ? const Color(0xFF363636) : const Color(0xFFDBDBDB)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: isDark ? const Color(0xFF363636) : const Color(0xFFDBDBDB),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: isDark ? const Color(0xFF363636) : const Color(0xFFDBDBDB),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(RegisterViewModel viewModel, BuildContext context, bool isDark) {
    return Form(
      key: viewModel.formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        children: [
          // Full Name
          _buildTextField(
            viewModel: viewModel,
            hintText: 'Full Name',
            icon: Ionicons.person_outline,
            focusNode: viewModel.usernameFN,
            nextFocusNode: viewModel.emailFN,
            validateFunction: Validations.validateName,
            onSaved: (val) => viewModel.setName(val),
            isDark: isDark,
          ),

          const SizedBox(height: 14),

          // Email
          _buildTextField(
            viewModel: viewModel,
            hintText: 'Email',
            icon: Ionicons.mail_outline,
            focusNode: viewModel.emailFN,
            nextFocusNode: _phoneFN,
            validateFunction: Validations.validateEmail,
            onSaved: (val) => viewModel.setEmail(val),
            isDark: isDark,
          ),

          const SizedBox(height: 14),

          // Phone number with country code
          PhoneFieldWithCountryCode(
            enabled: !viewModel.loading,
            focusNode: _phoneFN,
            nextFocusNode: viewModel.passFN,
            onSaved: (phone, countryCode) {
              viewModel.setPhone(phone, countryCode);
            },
          ),

          const SizedBox(height: 14),

          // Password
          _buildPasswordField(
            viewModel: viewModel,
            hintText: 'Password',
            focusNode: viewModel.passFN,
            nextFocusNode: viewModel.cPassFN,
            onSaved: (val) => viewModel.setPassword(val),
            isDark: isDark,
          ),

          const SizedBox(height: 14),

          // Confirm Password
          _buildPasswordField(
            viewModel: viewModel,
            hintText: 'Confirm Password',
            focusNode: viewModel.cPassFN,
            onSaved: (val) => viewModel.setConfirmPass(val),
            onSubmit: () => _submitRegistration(context, viewModel),
            isDark: isDark,
          ),

          const SizedBox(height: 24),

          // Sign up button
          _buildSignUpButton(context, viewModel),

          const SizedBox(height: 20),

          // Terms text with clickable links
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                  height: 1.5,
                ),
                children: [
                  const TextSpan(text: 'By signing up, you agree to our '),
                  TextSpan(
                    text: 'Terms',
                    style: const TextStyle(
                      color: Color(0xFF3897F0),
                      fontWeight: FontWeight.w600,
                    ),
                    recognizer: TapGestureRecognizer()..onTap = _openTerms,
                  ),
                  const TextSpan(text: ', '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: const TextStyle(
                      color: Color(0xFF3897F0),
                      fontWeight: FontWeight.w600,
                    ),
                    recognizer: TapGestureRecognizer()..onTap = _openPrivacy,
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Cookies Policy',
                    style: const TextStyle(
                      color: Color(0xFF3897F0),
                      fontWeight: FontWeight.w600,
                    ),
                    recognizer: TapGestureRecognizer()..onTap = _openCookies,
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required RegisterViewModel viewModel,
    required String hintText,
    required IconData icon,
    required FocusNode focusNode,
    FocusNode? nextFocusNode,
    required String? Function(String?) validateFunction,
    required Function(String) onSaved,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262626) : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF363636) : const Color(0xFFDBDBDB),
        ),
      ),
      child: TextFormBuilder(
        enabled: !viewModel.loading,
        prefix: icon,
        hintText: hintText,
        textInputAction: nextFocusNode != null
            ? TextInputAction.next
            : TextInputAction.done,
        validateFunction: validateFunction,
        onSaved: onSaved,
        focusNode: focusNode,
        nextFocusNode: nextFocusNode,
      ),
    );
  }

  Widget _buildPasswordField({
    required RegisterViewModel viewModel,
    required String hintText,
    required FocusNode focusNode,
    FocusNode? nextFocusNode,
    required Function(String) onSaved,
    VoidCallback? onSubmit,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262626) : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF363636) : const Color(0xFFDBDBDB),
        ),
      ),
      child: PasswordFormBuilder(
        enabled: !viewModel.loading,
        prefix: Ionicons.lock_closed_outline,
        suffix: Ionicons.eye_outline,
        hintText: hintText,
        textInputAction: nextFocusNode != null
            ? TextInputAction.next
            : TextInputAction.done,
        validateFunction: Validations.validatePassword,
        submitAction: onSubmit,
        obscureText: true,
        onSaved: onSaved,
        focusNode: focusNode,
        nextFocusNode: nextFocusNode,
      ),
    );
  }

  Widget _buildSignUpButton(BuildContext context, RegisterViewModel viewModel) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () => _submitRegistration(context, viewModel),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3897F0),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Sign up',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF363636) : const Color(0xFFDBDBDB),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Have an account? ',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushReplacement(
                CupertinoPageRoute(builder: (_) => const Login()),
              );
            },
            child: Text(
              'Log in',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3897F0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
