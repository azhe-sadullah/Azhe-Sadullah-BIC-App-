import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loading_overlay/loading_overlay.dart';
import '../view_model/auth/register_view_model.dart';
import '../widgets/indicators.dart';
import 'phone_otp_screen.dart';

class EmailOtpScreen extends StatefulWidget {
  final RegisterViewModel viewModel;

  const EmailOtpScreen({super.key, required this.viewModel});

  @override
  State<EmailOtpScreen> createState() => _EmailOtpScreenState();
}

class _EmailOtpScreenState extends State<EmailOtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool   _loading   = false;
  String _errorText = '';
  int    _countdown = 60;
  bool   _canResend = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes)  { f.dispose(); }
    super.dispose();
  }

  void _startCountdown() {
    setState(() { _countdown = 60; _canResend = false; });
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _countdown--;
        if (_countdown <= 0) _canResend = true;
      });
      return _countdown > 0;
    });
  }

  String get _code => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_code.length < 6) {
      setState(() => _errorText = 'تکایە کۆدی ٦ پیتی داخڵ بکە');
      return;
    }
    setState(() { _loading = true; _errorText = ''; });

    final valid = widget.viewModel.verifyEmailCode(_code);
    if (!valid) {
      setState(() {
        _loading   = false;
        _errorText = 'کۆدی هەڵەیە یان کاتی تەواو بووە';
      });
      for (final c in _controllers) { c.clear(); }
      _focusNodes[0].requestFocus();
      return;
    }

    // Code correct → create Firebase account + send phone OTP
    await widget.viewModel.createAccountAndSendPhoneOtp(
      context,
      (verificationId) {
        if (!mounted) return;
        setState(() => _loading = false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PhoneOtpScreen(
              viewModel:      widget.viewModel,
              verificationId: verificationId,
            ),
          ),
        );
      },
    );

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _resend() async {
    if (!_canResend) return;
    setState(() => _loading = true);
    final fallbackCode = await widget.viewModel.resendEmailCode(context);
    if (!mounted) return;
    setState(() => _loading = false);
    if (fallbackCode != null) {
      await widget.viewModel.showTestCodeDialog(context, fallbackCode);
    }
    _startCountdown();
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.viewModel.email ?? '';

    return LoadingOverlay(
      progressIndicator: circularProgress(context),
      isLoading: _loading,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3897F0).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.email_outlined, color: Color(0xFF3897F0), size: 40),
                ),
                const SizedBox(height: 24),
                const Text('تاییدکردنی ئیمەیڵ',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black)),
                const SizedBox(height: 12),
                Text('کۆدی ٦ پیتی نێردرا بۆ',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.grey[600])),
                Text(email,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF3897F0))),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (i) => _otpBox(i)),
                ),
                const SizedBox(height: 16),
                if (_errorText.isNotEmpty)
                  Text(_errorText,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                      textAlign: TextAlign.center),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _verify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3897F0),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('تاییدکردن',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('کۆدت نەگەیشت؟  ',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    GestureDetector(
                      onTap: _canResend ? _resend : null,
                      child: Text(
                        _canResend ? 'دووبارە بنێرە' : 'دووبارە بنێرە (${_countdown}s)',
                        style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold,
                          color: _canResend ? const Color(0xFF3897F0) : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _otpBox(int index) {
    return SizedBox(
      width: 48, height: 56,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3897F0), width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: _errorText.isNotEmpty ? Colors.red : Colors.grey[300]!,
            ),
          ),
        ),
        onChanged: (val) {
          setState(() => _errorText = '');
          if (val.isNotEmpty && index < 5) _focusNodes[index + 1].requestFocus();
          if (val.isEmpty && index > 0) _focusNodes[index - 1].requestFocus();
          if (_code.length == 6) _verify();
        },
        onTap: () => _controllers[index].selection = TextSelection.fromPosition(
            TextPosition(offset: _controllers[index].text.length)),
      ),
    );
  }
}
