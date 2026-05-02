import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../landing/landing_page.dart';
import '../view_model/theme/theme_view_model.dart';
import '../view_model/language/language_provider.dart';
import 'settings/account_info_screen.dart';
import 'settings/privacy_settings_screen.dart';
import 'settings/security_settings_screen.dart';
import 'settings/notification_settings_screen.dart';
import 'settings/help_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  bool _isLoggingOut = false;

  Future<void> _logout() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'دەرچوون',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'دڵنیایت لە دەرچوون؟',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'پاشگەزبوونەوە',
              style: GoogleFonts.poppins(),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(
              'دەرچوون',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await _authService.logout();

      if (!mounted) return;

      // Navigate to landing page and clear all previous routes
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const Landing()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoggingOut = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('هەڵە لە دەرچوون: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = context.watch<LanguageProvider>().strings;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5),
        elevation: 0,
        title: Text(
          lang.settings,
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoggingOut
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(lang.logout),
                ],
              ),
            )
          : ListView(
              children: [
                _buildSectionHeader(lang.account, isDark),
                _buildSettingsTile(
                  icon: Ionicons.person_outline,
                  title: lang.accountInfo,
                  subtitle: lang.accountInfoSub,
                  isDark: isDark,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AccountInfoScreen())),
                ),

                const SizedBox(height: 16),

                _buildSectionHeader(lang.privacySecurity, isDark),
                _buildSettingsTile(
                  icon: Ionicons.lock_closed_outline,
                  title: lang.privacy,
                  subtitle: lang.privacySub,
                  isDark: isDark,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacySettingsScreen())),
                ),
                _buildSettingsTile(
                  icon: Ionicons.shield_checkmark_outline,
                  title: lang.security,
                  subtitle: lang.securitySub,
                  isDark: isDark,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SecuritySettingsScreen())),
                ),

                const SizedBox(height: 16),

                _buildSectionHeader(lang.notifications, isDark),
                _buildSettingsTile(
                  icon: Ionicons.notifications_outline,
                  title: lang.notifications,
                  subtitle: lang.notifSub,
                  isDark: isDark,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationSettingsScreen())),
                ),

                const SizedBox(height: 16),

                _buildSectionHeader(lang.appearance, isDark),
                _buildSettingsTile(
                  icon: isDark ? Ionicons.moon_outline : Ionicons.sunny_outline,
                  title: lang.theme,
                  subtitle: isDark ? lang.themeDark : lang.themeLight,
                  isDark: isDark,
                  onTap: () => Provider.of<ThemeProvider>(context, listen: false).toggleTheme(),
                ),
                _buildLanguageTile(isDark),

                const SizedBox(height: 16),

                _buildSectionHeader(lang.about, isDark),
                _buildSettingsTile(
                  icon: Ionicons.information_circle_outline,
                  title: lang.aboutBic,
                  subtitle: lang.version,
                  isDark: isDark,
                  onTap: () => showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('BIC'),
                      content: const Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Version 1.0.0'),
                          SizedBox(height: 8),
                          Text('Business Intermediation Center'),
                          SizedBox(height: 8),
                          Text('© 2026 BIC.'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildSettingsTile(
                  icon: Ionicons.help_circle_outline,
                  title: lang.helpSupport,
                  subtitle: lang.helpSub,
                  isDark: isDark,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpScreen())),
                ),

                const SizedBox(height: 32),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton(
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Ionicons.log_out_outline),
                        const SizedBox(width: 8),
                        Text(lang.logout, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildLanguageTile(bool isDark) {
    return Consumer<LanguageProvider>(
      builder: (context, langProvider, _) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Ionicons.language_outline, size: 24, color: Color(0xFF3897F0)),
            ),
            title: Text(
              langProvider.isKurdish ? 'زمان' : 'Language',
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              langProvider.isKurdish ? 'English / کوردی' : 'English / Kurdish',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
            ),
            trailing: Switch(
              value: langProvider.isKurdish,
              onChanged: (_) => langProvider.toggleLanguage(),
              activeThumbColor: const Color(0xFF3897F0),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.grey[400] : Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 24,
            color: const Color(0xFF3897F0),
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}
