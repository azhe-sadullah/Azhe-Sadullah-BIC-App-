import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../view_model/language/language_provider.dart';

class RateAppScreen extends StatefulWidget {
  const RateAppScreen({super.key});

  @override
  State<RateAppScreen> createState() => _RateAppScreenState();
}

class _RateAppScreenState extends State<RateAppScreen> {
  int _stars = 0;
  final _feedbackCtrl = TextEditingController();
  bool _submitting = false;
  bool _alreadyRated = false;
  bool _submitted = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkExisting();
  }

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkExisting() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) { setState(() => _checking = false); return; }
    final doc = await FirebaseFirestore.instance.collection('appFeedback').doc(uid).get();
    setState(() {
      if (doc.exists) { _alreadyRated = true; _stars = (doc.data()?['stars'] as num?)?.toInt() ?? 5; }
      _checking = false;
    });
  }

  Future<void> _submit() async {
    if (_stars == 0) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _submitting = true);
    final ref = FirebaseFirestore.instance.collection('appFeedback').doc(uid);
    final existing = await ref.get();
    final data = <String, dynamic>{
      'userId': uid, 'stars': _stars,
      'feedback': _feedbackCtrl.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (!existing.exists) data['createdAt'] = FieldValue.serverTimestamp();
    await ref.set(data, SetOptions(merge: true));
    setState(() { _submitting = false; _submitted = true; });
  }

  String _starLabel(dynamic lang, int s) {
    switch (s) {
      case 1: return lang.ratingLabel1;
      case 2: return lang.ratingLabel2;
      case 3: return lang.ratingLabel3;
      case 4: return lang.ratingLabel4;
      case 5: return lang.ratingLabel5;
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().strings;
    return Scaffold(
      appBar: AppBar(title: Text(lang.rateAppTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), centerTitle: true),
      body: _checking
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                const SizedBox(height: 16),
                Container(
                  width: 88, height: 88,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF1a1a2e), Color(0xFF0f3460)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [BoxShadow(color: const Color(0xFF0f3460).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: Center(child: Text('BIC', style: GoogleFonts.montserrat(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 4))),
                ),
                const SizedBox(height: 20),
                Text('BIC', style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 4)),
                const SizedBox(height: 6),
                Text(lang.rateAppSub, style: TextStyle(fontSize: 13, color: Colors.grey[600]), textAlign: TextAlign.center),
                const SizedBox(height: 36),

                if (_submitted || _alreadyRated) ...[
                  const Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    _alreadyRated && !_submitted ? lang.rateAppAlready : lang.rateAppThanks,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  _StarDisplay(stars: _stars),
                ] else ...[
                  Text(lang.rateAppStarHint, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final active = i < _stars;
                      return GestureDetector(
                        onTap: () => setState(() => _stars = i + 1),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: active ? 0.8 : 1.0, end: active ? 1.0 : 0.8),
                          duration: const Duration(milliseconds: 200),
                          builder: (ctx, scale, _) => Transform.scale(
                            scale: scale,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(
                                active ? Icons.star_rounded : Icons.star_outline_rounded,
                                color: active ? Colors.amber : Colors.grey[400],
                                size: 46,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  if (_stars > 0) ...[
                    const SizedBox(height: 8),
                    Text(_starLabel(lang, _stars), style: TextStyle(fontSize: 13, color: Colors.amber[700], fontWeight: FontWeight.w600)),
                  ],
                  const SizedBox(height: 24),
                  TextField(
                    controller: _feedbackCtrl,
                    maxLines: 4, maxLength: 300,
                    decoration: InputDecoration(
                      hintText: lang.rateAppFeedbackHint,
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _stars == 0 || _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0f3460), foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _submitting
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(lang.rateAppSubmit, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],

                const SizedBox(height: 32),
                OutlinedButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(lang.rateAppPlayStore)),
                  ),
                  icon: const Icon(Icons.star_rounded, color: Colors.amber),
                  label: Text(lang.rateAppPlayStore, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ]),
            ),
    );
  }
}

class _StarDisplay extends StatelessWidget {
  final int stars;
  const _StarDisplay({required this.stars});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) => Icon(
        i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
        color: Colors.amber, size: 32,
      )),
    );
  }
}
