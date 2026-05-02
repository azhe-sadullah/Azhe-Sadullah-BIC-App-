import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'یارمەتی',
          style: GoogleFonts.tajawal(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHelpSection(
            context,
            title: 'پرسیارە باوەکان',
            icon: Ionicons.help_circle_outline,
            items: [
              _HelpItem(
                question: 'چۆن پۆست دروست بکەم؟',
                answer:
                    'کلیک لە دوگمەی + لە خوارەوە بکە، وێنەیەک هەڵبژێرە، caption زیاد بکە و Share بکە.',
              ),
              _HelpItem(
                question: 'چۆن فۆڵۆوی کەسێک بکەم؟',
                answer:
                    'بڕۆ بۆ پرۆفایلی ئەو کەسە و کلیک لە دوگمەی "Follow" بکە.',
              ),
              _HelpItem(
                question: 'چۆن وشەی نهێنیم بگۆڕم؟',
                answer:
                    'بڕۆ بۆ Settings > Security > Change Password و هەنگاوەکان جێبەجێ بکە.',
              ),
              _HelpItem(
                question: 'چۆن هەژمارەکەم بسڕمەوە؟',
                answer:
                    'ئەم فیچەرە لە ڤێرژنی داهاتوودا بەردەست دەبێت. لەم کاتەدا پەیوەندی بە پشتگیری بکە.',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildContactSection(context),
          const SizedBox(height: 24),
          _buildAboutSection(),
        ],
      ),
    );
  }

  Widget _buildHelpSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<_HelpItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF3897F0)),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.tajawal(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...items.map(
          (item) => _buildExpansionTile(context, item),
        ),
      ],
    );
  }

  Widget _buildExpansionTile(BuildContext context, _HelpItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: ExpansionTile(
        title: Text(
          item.question,
          style: GoogleFonts.tajawal(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              item.answer,
              style: GoogleFonts.tajawal(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFF3897F0).withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Ionicons.mail_outline,
              size: 48,
              color: Color(0xFF3897F0),
            ),
            const SizedBox(height: 16),
            Text(
              'پێویستت بە یارمەتییە؟',
              style: GoogleFonts.tajawal(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'پەیوەندی بە تیمی پشتگیری بکە',
              style: GoogleFonts.tajawal(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                _showContactDialog(context);
              },
              icon: const Icon(Ionicons.send),
              label: Text(
                'پەیوەندی پێوە بکە',
                style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3897F0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Column(
      children: [
        Text(
          'BIC - Business Intermediation Center',
          style: GoogleFonts.tajawal(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Version 1.0.0',
          style: GoogleFonts.tajawal(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '© 2026 BIC App. All rights reserved.',
          style: GoogleFonts.tajawal(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'پەیوەندی بە پشتگیری',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'دەتوانیت لە ڕێگەی ئەم کەناڵانەوە پەیوەندی بکەیت:',
              style: GoogleFonts.tajawal(fontSize: 14),
            ),
            const SizedBox(height: 16),
            _buildContactMethod(
              icon: Icons.email,
              label: 'support@bic-app.com',
            ),
            const SizedBox(height: 8),
            _buildContactMethod(
              icon: Icons.phone,
              label: '+964 xxx xxx xxxx',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('داخستن', style: GoogleFonts.tajawal()),
          ),
        ],
      ),
    );
  }

  Widget _buildContactMethod({
    required IconData icon,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF3897F0)),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.tajawal(fontSize: 14),
        ),
      ],
    );
  }
}

class _HelpItem {
  final String question;
  final String answer;

  _HelpItem({
    required this.question,
    required this.answer,
  });
}
