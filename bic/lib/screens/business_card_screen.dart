import 'package:bic/view_model/language/language_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class BusinessCardScreen extends StatelessWidget {
  final String userId;
  final String username;
  final String? fullName;
  final String? avatar;
  final String? bio;

  const BusinessCardScreen({
    super.key,
    required this.userId,
    required this.username,
    this.fullName,
    this.avatar,
    this.bio,
  });

  String get _qrData => 'bic_profile:$userId';
  String get _profileLink => 'bic.app/@$username';

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();
    final lang = lp.strings;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: Text(lang.qrCardTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            // ── Business Card ────────────────────────────────
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0f3460).withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24, width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 36,
                            backgroundImage: avatar != null ? CachedNetworkImageProvider(avatar!) : null,
                            backgroundColor: Colors.white12,
                            child: avatar == null
                                ? Text(
                                    username.isNotEmpty ? username[0].toUpperCase() : 'B',
                                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (fullName?.isNotEmpty == true)
                                Text(fullName!,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                              Text('@$username',
                                  style: const TextStyle(fontSize: 13, color: Colors.white60)),
                              if (bio?.isNotEmpty == true) ...[
                                const SizedBox(height: 6),
                                Text(bio!,
                                    maxLines: 2, overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, color: Colors.white54)),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),
                    Container(height: 1, color: Colors.white12),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: QrImageView(
                            data: _qrData,
                            version: QrVersions.auto,
                            size: 160,
                            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF0f3460)),
                            dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square, color: Color(0xFF1a1a2e)),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.link_rounded, color: Colors.white54, size: 16),
                          const SizedBox(width: 6),
                          Text(_profileLink,
                              style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),
                    const Text('BIC — Business Intermediation Center',
                        style: TextStyle(fontSize: 10, color: Colors.white30)),
                  ],
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
