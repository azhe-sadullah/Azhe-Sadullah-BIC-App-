library;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:bic/utils/constants.dart';
import 'package:ionicons/ionicons.dart';
import 'package:bic/screens/edit_profile_customer.dart';
import 'package:bic/screens/edit_profile_sailor.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bic/screens/analytics_screen.dart';
import 'package:bic/screens/business_card_screen.dart';
import 'package:bic/screens/settings/rate_app_screen.dart';

class ProfileScreen extends StatelessWidget {
  final bool isSailor;

  const ProfileScreen({super.key, this.isSailor = false});

  @override
  Widget build(BuildContext context) {
    // Determine Theme based on Role
    final mainColor = isSailor ? Constants.sailorPrimary : Constants.customerPrimary;
    final bgColor = isSailor ? Constants.sailorBackground : Constants.customerBackground;

    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                 _buildHeaderImage(mainColor),
                Positioned(
                  bottom: -50,
                  child: _buildAvatar(mainColor),
                ),
                Positioned(
                  top: 50,
                  left: 20,
                  child: InkWell(
                    onTap: () {
                       Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => isSailor ? EditProfileSailor() : EditProfileCustomer(),
                        ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                       child: Icon(Ionicons.settings_outline, color: Colors.black54),
                    ),
                  ),
                ),
                 Positioned(
                  top: 50,
                  right: 20,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                     child: Icon(Ionicons.options_outline, color: Colors.black54),
                  ),
                ),
              ],
            ),
            SizedBox(height: 60), // Space for Avatar
            Text(
              "Jane Doe Watson",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
             SizedBox(height: 4),
            Text(
              "Member since January 2026",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: mainColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: mainColor.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isSailor ? Icons.anchor : Icons.star, size: 14, color: mainColor),
                  SizedBox(width: 4),
                  Text(
                    isSailor ? "Sailor • Pro" : "Premium",
                    style: TextStyle(
                      color: mainColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
             SizedBox(height: 24),
            isSailor ? _buildSailorStats(mainColor) : _buildCustomerStats(mainColor),
             SizedBox(height: 24),
            isSailor 
            ? _buildActionCard(
                context,
                title: "Upcoming Schedule",
                subtitle: "You have 3 tasks for tomorrow.",
                icon: Ionicons.calendar,
                color: mainColor,
              )
            : _buildActionCard(
                context,
                title: "Invite Friend",
                subtitle: "Get \$15 Free for a limited time.",
                icon: Ionicons.people,
                color: mainColor,
              ),
             SizedBox(height: 20),
            _buildMenuSection(context, isSailor),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderImage(Color color) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        image: DecorationImage(
           // Placeholder 
          image: NetworkImage(isSailor 
            ? "https://images.unsplash.com/photo-1519681393784-d120267933ba?auto=format&fit=crop&w=800&q=80" // Night/Work
            : "https://images.unsplash.com/photo-1579621970563-ebec7560ff3e?auto=format&fit=crop&w=800&q=80" // Coins
          ),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.3), BlendMode.darken),
        ),
      ),
    );
  }

  Widget _buildAvatar(Color color) {
    return Stack(
      children: [
        Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(isSailor
              ? "https://i.pravatar.cc/300?img=11" // Male/Worker
              : "https://i.pravatar.cc/300?img=5" // Female/Customer
            ), 
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(Icons.camera_alt, color: Colors.white, size: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerStats(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem("7d", "Total Streak", CupertinoIcons.flame, Colors.orange),
          Container(height: 40, width: 1, color: Colors.grey.withValues(alpha: 0.3)),
          _buildStatItem("85", "Goals", Ionicons.flag, Colors.black87),
           Container(height: 40, width: 1, color: Colors.grey.withValues(alpha: 0.3)),
          _buildStatItem("\$112", "Total Saved", Ionicons.cash, Colors.green),
        ],
      ),
    );
  }

  Widget _buildSailorStats(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem("12", "Tasks Done", Ionicons.checkbox_outline, color),
          Container(height: 40, width: 1, color: Colors.grey.withValues(alpha: 0.3)),
          _buildStatItem("Active", "Status", Ionicons.radio_button_on, Colors.green),
          Container(height: 40, width: 1, color: Colors.grey.withValues(alpha: 0.3)),
          _buildStatItem("Active", "Status", Ionicons.radio_button_on, Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color iconColor) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 24),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, bool isSailor) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      padding: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: isSailor
        ? [
           _buildMenuItem("Analytics", Ionicons.bar_chart_outline, onTap: () {
             Navigator.push(context, MaterialPageRoute(
               builder: (_) => const AnalyticsScreen(),
             ));
           }),
           Divider(indent: 50),
           _buildMenuItem("QR Business Card", Ionicons.qr_code_outline, onTap: () {
             final uid = FirebaseAuth.instance.currentUser?.uid;
             if (uid == null) return;
             FirebaseFirestore.instance.collection('users').doc(uid).get().then((doc) {
               if (!context.mounted) return;
               final d = doc.data() ?? {};
               Navigator.push(context, MaterialPageRoute(
                 builder: (_) => BusinessCardScreen(
                   userId: uid,
                   username: d['username'] ?? '',
                   fullName: d['fullName'],
                   avatar: d['avatar'],
                   bio: d['bio'],
                 ),
               ));
             });
           }),
           Divider(indent: 50),
           _buildMenuItem("My Certifications", Ionicons.ribbon_outline),
           Divider(indent: 50),
           _buildMenuItem("Job History", Ionicons.time_outline),
           Divider(indent: 50),
           _buildMenuItem("Settings", Ionicons.settings_outline),
           Divider(indent: 50),
           _buildMenuItem("Support", Ionicons.headset_outline),
        ]
        : [
          _buildMenuItem("Analytics", Ionicons.bar_chart_outline, onTap: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => const AnalyticsScreen(),
            ));
          }),
          Divider(indent: 50),
          _buildMenuItem("About Us", Ionicons.person_outline),
          Divider(indent: 50),
          _buildMenuItem("Achievements", Ionicons.trophy_outline),
           Divider(indent: 50),
          _buildMenuItem("News & Resource", Ionicons.bulb_outline),
           Divider(indent: 50),
          _buildMenuItem("Settings", Ionicons.settings_outline),
           Divider(indent: 50),
          _buildMenuItem("Community", Ionicons.chatbubble_ellipses_outline),
           Divider(indent: 50),
          _buildMenuItem("Rate App", Ionicons.star_outline, onTap: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => const RateAppScreen(),
            ));
          }),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String title, IconData icon, {VoidCallback? onTap}) {
    return ListTile(
      leading: Container(
         padding: EdgeInsets.all(8),
         decoration: BoxDecoration(
           color: Colors.grey[100],
           shape: BoxShape.circle,
         ),
        child: Icon(icon, size: 20, color: Colors.black54),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap ?? () {},
    );
  }
}
