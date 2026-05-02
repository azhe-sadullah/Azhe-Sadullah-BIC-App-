import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF405DE6), Color(0xFF5851DB)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield, color: Colors.white, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Privacy Policy',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Your privacy matters to us',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              'Introduction',
              'At BIC (Business Intermediation Center), we take your privacy seriously. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.',
            ),

            _buildSection(
              '1. Information We Collect',
              '''We collect information that you provide directly to us:

Personal Information:
• Name and username
• Email address
• Phone number
• Profile picture
• Country and location

Account Information:
• Login credentials
• Account preferences
• Communication preferences

Content Information:
• Posts and comments
• Messages and interactions
• Photos and media you share''',
            ),

            _buildSection(
              '2. Automatic Data Collection',
              '''When you use BIC, we automatically collect:

• Device information (model, OS, unique identifiers)
• Log data (access times, pages viewed, app crashes)
• Location data (with your permission)
• Usage patterns and preferences
• Network information''',
            ),

            _buildSection(
              '3. How We Use Your Information',
              '''We use collected information to:

• Provide and maintain our services
• Personalize your experience
• Process transactions and send notifications
• Improve our app and develop new features
• Communicate with you about updates and promotions
• Ensure security and prevent fraud
• Comply with legal obligations''',
            ),

            _buildSection(
              '4. Information Sharing',
              '''We may share your information with:

• Service providers who assist our operations
• Business partners for joint services
• Legal authorities when required by law
• Other users (only information you choose to make public)

We do NOT sell your personal information to third parties.''',
            ),

            _buildSection(
              '5. Data Security',
              '''We implement industry-standard security measures:

• Encryption of data in transit and at rest
• Secure authentication protocols
• Regular security audits
• Access controls and monitoring
• Incident response procedures

While we strive to protect your data, no method of transmission over the Internet is 100% secure.''',
            ),

            _buildSection(
              '6. Your Rights',
              '''You have the right to:

• Access your personal data
• Correct inaccurate information
• Delete your account and data
• Export your data
• Opt-out of marketing communications
• Restrict certain processing activities
• Lodge a complaint with authorities''',
            ),

            _buildSection(
              '7. Data Retention',
              'We retain your personal data for as long as your account is active or as needed to provide services. You can request deletion of your data at any time through account settings or by contacting us.',
            ),

            _buildSection(
              '8. Children\'s Privacy',
              'BIC is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If we learn we have collected such information, we will delete it immediately.',
            ),

            _buildSection(
              '9. International Data Transfers',
              'Your information may be transferred to and processed in countries other than your country of residence. We ensure appropriate safeguards are in place for such transfers.',
            ),

            _buildSection(
              '10. Changes to This Policy',
              'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new policy on this page and updating the "Last Updated" date.',
            ),

            _buildSection(
              '11. Contact Us',
              '''For questions about this Privacy Policy or our data practices:

Email: privacy@bic-app.com
Data Protection Officer: dpo@bic-app.com
Address: Business Intermediation Center''',
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(fontSize: 14, height: 1.6, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}
