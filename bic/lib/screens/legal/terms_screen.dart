import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

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
          'Terms of Service',
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
                  colors: [Color(0xFF833AB4), Color(0xFFC13584)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.gavel, color: Colors.white, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Terms of Service',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Last updated: January 2025',
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
              'Welcome to BIC',
              'By accessing or using the BIC (Business Intermediation Center) application, you agree to be bound by these Terms of Service. Please read them carefully before using our services.',
            ),

            _buildSection(
              '1. Acceptance of Terms',
              'By creating an account or using BIC, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service and our Privacy Policy. If you do not agree to these terms, please do not use our services.',
            ),

            _buildSection(
              '2. Eligibility',
              'You must be at least 13 years old to use BIC. By using our services, you represent and warrant that you meet this age requirement and have the legal capacity to enter into these terms.',
            ),

            _buildSection(
              '3. Account Registration',
              '''When you create an account, you agree to:
• Provide accurate and complete information
• Maintain the security of your account credentials
• Notify us immediately of any unauthorized access
• Be responsible for all activities under your account
• Not create accounts for others without permission''',
            ),

            _buildSection(
              '4. User Content',
              '''You retain ownership of content you post on BIC. By posting content, you grant us a non-exclusive, royalty-free license to use, display, and distribute your content within our platform.

You agree not to post content that:
• Violates any laws or regulations
• Infringes on intellectual property rights
• Contains hate speech or harassment
• Is misleading or fraudulent
• Contains malware or harmful code''',
            ),

            _buildSection(
              '5. Prohibited Activities',
              '''Users are prohibited from:
• Impersonating others or creating fake accounts
• Spamming or sending unsolicited messages
• Attempting to hack or disrupt our services
• Scraping or collecting user data without consent
• Using automated tools without authorization
• Engaging in any illegal activities''',
            ),

            _buildSection(
              '6. Intellectual Property',
              'BIC and its original content, features, and functionality are owned by BIC Team and are protected by international copyright, trademark, and other intellectual property laws.',
            ),

            _buildSection(
              '7. Termination',
              'We reserve the right to terminate or suspend your account at any time, without prior notice, for conduct that we believe violates these Terms of Service or is harmful to other users, us, or third parties.',
            ),

            _buildSection(
              '8. Disclaimer of Warranties',
              'BIC is provided "as is" without any warranties of any kind. We do not guarantee that our services will be uninterrupted, secure, or error-free.',
            ),

            _buildSection(
              '9. Limitation of Liability',
              'To the maximum extent permitted by law, BIC shall not be liable for any indirect, incidental, special, consequential, or punitive damages arising from your use of our services.',
            ),

            _buildSection(
              '10. Changes to Terms',
              'We may modify these Terms of Service at any time. We will notify users of significant changes. Your continued use of BIC after changes constitutes acceptance of the modified terms.',
            ),

            _buildSection(
              '11. Contact Us',
              '''If you have any questions about these Terms of Service, please contact us at:

Email: legal@bic-app.com
Address: Business Intermediation Center
Support: support@bic-app.com''',
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
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
