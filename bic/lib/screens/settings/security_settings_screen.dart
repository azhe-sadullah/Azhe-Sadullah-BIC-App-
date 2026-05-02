import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _twoFactorAuth = false;
  bool _loginAlerts = true;
  bool _saveLoginInfo = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ڕێکخستنەکانی ئاسایش',
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
            title: 'دڵنیایی هەژمار',
            children: [
              _buildSwitchTile(
                title: 'پشتڕاستکردنەوەی دوو هێنایی',
                subtitle: 'زیادکردنی لایەرێکی تری ئاسایش',
                value: _twoFactorAuth,
                onChanged: (value) {
                  if (value) {
                    _showComingSoonDialog('پشتڕاستکردنەوەی دوو هێنایی');
                  } else {
                    setState(() => _twoFactorAuth = false);
                  }
                },
                icon: Icons.security_outlined,
              ),
              _buildSwitchTile(
                title: 'ئاگادارکردنەوەی چوونەژوورەوە',
                subtitle: 'ئاگادارکردنەوە بۆ چوونەژوورەوە لە ئامێرێکی نوێ',
                value: _loginAlerts,
                onChanged: (value) {
                  if (value) {
                    _showComingSoonDialog('ئاگادارکردنەوەی چوونەژوورەوە');
                  } else {
                    setState(() => _loginAlerts = false);
                  }
                },
                icon: Icons.notifications_active_outlined,
              ),
            ],
          ),
          _buildSection(
            title: 'داتا و زانیاری',
            children: [
              _buildSwitchTile(
                title: 'پاراستنی زانیاری login',
                subtitle: 'خۆکار login بوون لە ئامێرەکەتدا',
                value: _saveLoginInfo,
                onChanged: (value) {
                  setState(() {
                    _saveLoginInfo = value;
                  });
                },
                icon: Icons.save_outlined,
              ),
            ],
          ),
          _buildSection(
            title: 'دەسەڵات',
            children: [
              _buildActionTile(
                title: 'بینینی ئامێرە login کراوەکان',
                subtitle: 'بەڕێوەبردنی ئامێرە login کراوەکان',
                icon: Icons.devices_outlined,
                onTap: () {
                  _showComingSoonDialog('بینینی ئامێرە login کراوەکان');
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'هەندێک لەم فیچەرانە لە ڤێرژنی داهاتوودا چالاک دەکرێن',
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

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
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
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showComingSoonDialog(String featureTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          featureTitle,
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'ئەم فیچەرە لە ڤێرژنی داهاتوودا بەردەست دەبێت',
          style: GoogleFonts.tajawal(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _twoFactorAuth = false;
                _loginAlerts = false;
              });
            },
            child: Text('باشە', style: GoogleFonts.tajawal()),
          ),
        ],
      ),
    );
  }
}
