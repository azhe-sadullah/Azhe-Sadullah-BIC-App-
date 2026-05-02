import 'package:flutter/material.dart';

class CookiesScreen extends StatelessWidget {
  const CookiesScreen({super.key});

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
          'Cookies Policy',
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
                  colors: [Color(0xFFF56040), Color(0xFFFCAF45)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cookie, color: Colors.white, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cookies Policy',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'How we use cookies and similar technologies',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              'What Are Cookies?',
              'Cookies are small text files that are placed on your device when you visit a website or use an application. They help us provide you with a better experience by remembering your preferences and understanding how you use our services.',
            ),

            _buildSection(
              '1. Types of Cookies We Use',
              '''Essential Cookies:
• Required for basic app functionality
• Authentication and security
• Cannot be disabled

Performance Cookies:
• Help us understand how users interact with BIC
• Collect anonymous usage statistics
• Help us improve app performance

Functional Cookies:
• Remember your preferences and settings
• Personalize your experience
• Store language and region preferences

Advertising Cookies:
• Deliver relevant advertisements
• Measure ad effectiveness
• Limit ad frequency''',
            ),

            _buildSection(
              '2. Similar Technologies',
              '''In addition to cookies, we use:

Local Storage:
• Stores data on your device
• Faster than cookies
• Used for app preferences

Device Identifiers:
• Unique identifiers for your device
• Used for analytics and security

Pixels and Beacons:
• Small images that track interactions
• Used in emails and notifications''',
            ),

            _buildSection(
              '3. How We Use Cookies',
              '''We use cookies and similar technologies to:

• Keep you signed in to your account
• Remember your preferences and settings
• Understand how you use our app
• Improve our services and features
• Provide personalized content
• Measure the effectiveness of our marketing
• Ensure security and prevent fraud''',
            ),

            _buildSection(
              '4. Third-Party Cookies',
              '''Some cookies are placed by third-party services:

Analytics Partners:
• Google Analytics
• Firebase Analytics

Social Media:
• Facebook SDK
• Apple Sign In

Advertising:
• Google Ads
• Facebook Ads

These third parties have their own privacy policies governing the use of cookies.''',
            ),

            _buildSection(
              '5. Managing Cookies',
              '''You can control cookies through:

App Settings:
• Manage preferences in BIC settings
• Toggle specific cookie categories

Device Settings:
• Adjust privacy settings on your device
• Clear app data and cache

Note: Disabling certain cookies may affect app functionality.''',
            ),

            _buildSection(
              '6. Cookie Duration',
              '''Session Cookies:
• Deleted when you close the app
• Used for temporary data

Persistent Cookies:
• Remain until expiration or deletion
• Used for preferences and authentication

Typical retention periods:
• Authentication: 30 days
• Preferences: 1 year
• Analytics: 2 years''',
            ),

            _buildSection(
              '7. Your Choices',
              '''You have several options:

Accept All: Allow all cookies for full functionality
Essential Only: Only necessary cookies
Customize: Choose specific categories
Reject All: Block non-essential cookies

You can change your preferences at any time in app settings.''',
            ),

            _buildSection(
              '8. Updates to This Policy',
              'We may update this Cookies Policy periodically. We will notify you of significant changes through the app or via email.',
            ),

            _buildSection(
              '9. Contact Us',
              '''For questions about our use of cookies:

Email: cookies@bic-app.com
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
            style: TextStyle(fontSize: 14, height: 1.6, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}
