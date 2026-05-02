import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loading_overlay/loading_overlay.dart';
import '../view_model/auth/register_view_model.dart';
import '../widgets/indicators.dart';

class PhoneOtpScreen extends StatefulWidget {
  final RegisterViewModel viewModel;
  final String verificationId;

  const PhoneOtpScreen({super.key, required this.viewModel, required this.verificationId});

  @override
  State<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

class _PhoneOtpScreenState extends State<PhoneOtpScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _loading = false;
  String _errorText = '';
  int _resendCountdown = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  void _startCountdown() {
    setState(() { _resendCountdown = 60; _canResend = false; });
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _resendCountdown--;
        if (_resendCountdown <= 0) _canResend = true;
      });
      return _resendCountdown > 0;
    });
  }

  String get _enteredCode => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    final code = _enteredCode;
    if (code.length < 6) {
      setState(() => _errorText = 'تکایە کۆدی ٦ پیتی داخڵ بکە');
      return;
    }
    setState(() { _loading = true; _errorText = ''; });
    await widget.viewModel.verifyPhoneOtp(
      context,
      widget.verificationId,
      code,
      onError: (msg) {
        if (!mounted) return;
        setState(() { _loading = false; _errorText = msg; });
        for (final c in _controllers) { c.clear(); }
        _focusNodes[0].requestFocus();
      },
    );
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _resend() async {
    if (!_canResend) return;
    setState(() => _loading = true);
    await widget.viewModel.resendPhoneOtp(
      context,
      onCodeSent: (newVerificationId) => _startCountdown(),
    );
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final phone = widget.viewModel.phoneNumber ?? '';

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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.phone_android_outlined, color: Colors.green, size: 40),
                ),
                const SizedBox(height: 24),
                const Text('تاییدکردنی تەلەفۆن',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black)),
                const SizedBox(height: 12),
                Text('کۆدی ٦ پیتی نێردرا بۆ',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.grey[600])),
                Text(phone,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green)),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) => SizedBox(
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _errorText.isNotEmpty ? Colors.red : Colors.green, width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.green, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _errorText.isNotEmpty ? Colors.red : Colors.grey[300]!),
                        ),
                      ),
                      onChanged: (val) {
                        setState(() => _errorText = '');
                        if (val.isNotEmpty && index < 5) { _focusNodes[index + 1].requestFocus(); }
                        else if (val.isEmpty && index > 0) { _focusNodes[index - 1].requestFocus(); }
                        if (_enteredCode.length == 6) _verify();
                      },
                      onTap: () => _controllers[index].selection = TextSelection.fromPosition(
                          TextPosition(offset: _controllers[index].text.length)),
                    ),
                  )),
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
                      backgroundColor: Colors.green,
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
                        _canResend ? 'دووبارە بنێرە' : 'دووبارە بنێرە (${_resendCountdown}s)',
                        style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold,
                          color: _canResend ? Colors.green : Colors.grey,
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
}
