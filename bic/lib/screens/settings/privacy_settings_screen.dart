import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _privateAccount = false;
  bool _showActivityStatus = true;
  bool _allowComments = true;
  bool _allowMentions = true;
  bool _allowTagging = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ڕێکخستنەکانی تایبەتێتی',
          style: GoogleFonts.tajawal(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _buildSection(
            title: 'دۆخی هەژمار',
            children: [
              _buildSwitchTile(
                title: 'هەژماری تایبەت',
                subtitle: 'تەنها فۆڵۆوەرەکانت پۆستەکانت دەبینن',
                value: _privateAccount,
                onChanged: (value) {
                  setState(() {
                    _privateAccount = value;
                  });
                },
                icon: Icons.lock_outline,
              ),
            ],
          ),
          _buildSection(
            title: 'چالاکی',
            children: [
              _buildSwitchTile(
                title: 'پیشاندانی دۆخی چالاکی',
                subtitle: 'خەڵک دەزانن کاتێک ئۆنلاینیت',
                value: _showActivityStatus,
                onChanged: (value) {
                  setState(() {
                    _showActivityStatus = value;
                  });
                },
                icon: Icons.circle_outlined,
              ),
            ],
          ),
          _buildSection(
            title: 'کارلێککردن',
            children: [
              _buildSwitchTile(
                title: 'ڕێگە بە کۆمێنتەکان',
                subtitle: 'هەموو کەس دەتوانێت کۆمێنت بکات',
                value: _allowComments,
                onChanged: (value) {
                  setState(() {
                    _allowComments = value;
                  });
                },
                icon: Icons.comment_outlined,
              ),
              _buildSwitchTile(
                title: 'ڕێگە بە mention',
                subtitle: 'خەڵک دەتوانن mention ت بکەن',
                value: _allowMentions,
                onChanged: (value) {
                  setState(() {
                    _allowMentions = value;
                  });
                },
                icon: Icons.alternate_email,
              ),
              _buildSwitchTile(
                title: 'ڕێگە بە tagging',
                subtitle: 'خەڵک دەتوانن tag ت بکەن لە پۆستەکانیاندا',
                value: _allowTagging,
                onChanged: (value) {
                  setState(() {
                    _allowTagging = value;
                  });
                },
                icon: Icons.label_outline,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'ئەم ڕێکخستنانە فیچەری داهاتوون و لە ڤێرژنی داهاتوودا چالاک دەکرێن',
              style: GoogleFonts.tajawal(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: GoogleFonts.tajawal(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF3897F0).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF3897F0),
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.tajawal(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.tajawal(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: const Color(0xFF3897F0).withValues(alpha: 0.5),
        activeThumbColor: const Color(0xFF3897F0),
      ),
    );
  }
}
