import 'dart:math';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';

class EmailService {
  static const String _gmailUser = 'bicapp2026@gmail.com';
  static const String _gmailAppPassword = 'lhxdkwhqanxzlnch';

  /// کۆدی ٦ پیتی ئەخولقێنێت
  static String generateCode() {
    return (100000 + Random.secure().nextInt(900000)).toString();
  }

  /// ئیمەیڵ بە کۆدی تاییدکردن دەنێرێت لە ڕێگەی Gmail SMTP
  static Future<bool> sendVerificationCode({
    required String toEmail,
    required String code,
    required String userName,
  }) async {
    try {
      final smtpServer = gmail(_gmailUser, _gmailAppPassword);

      final message = Message()
        ..from = Address(_gmailUser, 'BIC')
        ..recipients.add(toEmail)
        ..subject = 'کۆدی تاییدکردنت - BIC'
        ..html = '''
<div dir="rtl" style="font-family: Arial, sans-serif; max-width: 500px; margin: 0 auto; padding: 30px; background: #f9f9f9; border-radius: 12px;">
  <h2 style="color: #3897F0; text-align: center;">BIC — Business Intermediation Center</h2>
  <p style="font-size: 16px; color: #333;">
    سڵاو <strong>$userName</strong>،
  </p>
  <p style="font-size: 15px; color: #555;">
    کۆدی تاییدکردنت بۆ ئەکاونتی BIC:
  </p>
  <div style="text-align: center; margin: 30px 0;">
    <span style="font-size: 42px; font-weight: bold; letter-spacing: 12px; color: #3897F0; background: #fff; padding: 16px 24px; border-radius: 12px; border: 2px solid #3897F0;">
      $code
    </span>
  </div>
  <p style="font-size: 13px; color: #999; text-align: center;">
    ئەم کۆدە تەنها ١٠ خولەک کار دەکات.<br>
    ئەگەر تۆ داوای تۆمارکردن نەکردووی، ئەم ئیمەیڵەی پشتگوێ بخە.
  </p>
</div>
        ''';

      await send(message, smtpServer);
      return true;
    } catch (e) {
      return false;
    }
  }
}
