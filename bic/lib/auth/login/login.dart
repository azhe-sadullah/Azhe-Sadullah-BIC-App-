import 'package:bic/auth/register/register.dart';
import 'package:bic/view_model/auth/login_view_model.dart';
import 'package:bic/services/auth_service.dart';
import 'package:bic/screens/mainscreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:provider/provider.dart';

import '../../components/password_text_field.dart';
import '../../components/text_form_builder.dart';
import '../../utils/validation.dart';
import '../../widgets/indicators.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    LoginViewModel viewModel = Provider.of<LoginViewModel>(context);
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
                      const SizedBox(height: 60),

                      // Instagram-style Logo
                      _buildLogo(isDark),

                      const SizedBox(height: 50),

                      // Form
                      _buildForm(context, viewModel, isDark),

                      const SizedBox(height: 20),

                      // Divider with OR
                      _buildDivider(isDark),

                      const SizedBox(height: 20),

                      // Social Login
                      _buildSocialLogin(isDark),

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
        // Gradient logo container
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
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
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/app_icon.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'BIC',
          style: GoogleFonts.montserrat(
            fontSize: 42,
            fontWeight: FontWeight.w900,
            letterSpacing: 6,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context, LoginViewModel viewModel, bool isDark) {
    return Form(
      key: viewModel.formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        children: [
          // Email field
          _buildTextField(
            viewModel: viewModel,
            hintText: 'Email',
            icon: Ionicons.mail_outline,
            focusNode: viewModel.emailFN,
            nextFocusNode: viewModel.passFN,
            validateFunction: Validations.validateEmail,
            onSaved: (val) => viewModel.setEmail(val),
            isDark: isDark,
          ),

          const SizedBox(height: 16),

          // Password field
          _buildPasswordField(
            viewModel: viewModel,
            hintText: 'Password',
            focusNode: viewModel.passFN,
            onSaved: (val) => viewModel.setPassword(val),
            onSubmit: () => viewModel.login(context),
            isDark: isDark,
          ),

          const SizedBox(height: 24),

          // Login button
          _buildLoginButton(context, viewModel),

          const SizedBox(height: 20),

          // Forgot password
          TextButton(
            onPressed: () => viewModel.forgotPassword(context),
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(fontSize: 13),
                children: [
                  TextSpan(
                    text: 'Forgot your login details? ',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const TextSpan(
                    text: 'Get help logging in.',
                    style: TextStyle(
                      color: Color(0xFF3897F0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required LoginViewModel viewModel,
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
    required LoginViewModel viewModel,
    required String hintText,
    required FocusNode focusNode,
    required Function(String) onSaved,
    required VoidCallback onSubmit,
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
        textInputAction: TextInputAction.done,
        validateFunction: Validations.validatePassword,
        submitAction: onSubmit,
        obscureText: true,
        onSaved: onSaved,
        focusNode: focusNode,
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context, LoginViewModel viewModel) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () => viewModel.login(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3897F0),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Log in',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
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

  Widget _buildSocialLogin(bool isDark) {
    final authService = AuthService();
    return Column(
      children: [
        // Facebook login
        _buildSocialButton(
          icon: Ionicons.logo_facebook,
          text: 'Continue with Facebook',
          color: const Color(0xFF3B5998),
          onTap: () { if (!_socialLoading) _handleSocialLogin(authService.signInWithFacebook); },
        ),
        const SizedBox(height: 12),
        // Google login
        _buildSocialButton(
          icon: Ionicons.logo_google,
          text: 'Continue with Google',
          color: isDark ? Colors.white : Colors.black87,
          textColor: isDark ? Colors.black : Colors.black87,
          isOutlined: true,
          onTap: () { if (!_socialLoading) _handleSocialLogin(authService.signInWithGoogle); },
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String text,
    required Color color,
    Color? textColor,
    bool isOutlined = false,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: isOutlined
          ? OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, color: color, size: 20),
              label: Text(
                text,
                style: GoogleFonts.poppins(
                  color: textColor ?? color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey[400]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          : ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, color: Colors.white, size: 20),
              label: Text(
                text,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
            "Don't have an account? ",
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushReplacement(
                CupertinoPageRoute(builder: (_) => Register()),
              );
            },
            child: Text(
              'Sign up',
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
