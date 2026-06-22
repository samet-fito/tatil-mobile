import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// E-bilet ve otel voucher — görüntüleme / indirme.
class TravelDocumentService {
  static Future<void> showDocumentOptions(
    BuildContext context, {
    required String title,
    required String fileName,
    required String htmlBody,
    required String webViewerUrl,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.open_in_browser),
                title: const Text('Web\'de görüntüle'),
                subtitle: const Text('Tarayıcıda aç'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _openWeb(webViewerUrl);
                },
              ),
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text('Cihaza indir'),
                subtitle: const Text('HTML belge olarak kaydet ve paylaş'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _downloadAndShare(
                    context,
                    fileName: fileName,
                    html: _wrapHtml(title, htmlBody),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String buildEticketHtml({
    required String reservationId,
    required String passengerName,
    required String airline,
    required String departure,
    required String returnDate,
    required int adults,
    required int children,
  }) {
    return '''
      <p><strong>Rezervasyon:</strong> $reservationId</p>
      <p><strong>Yolcu:</strong> $passengerName</p>
      <p><strong>Havayolu:</strong> $airline</p>
      <p><strong>Gidiş:</strong> $departure</p>
      <p><strong>Dönüş:</strong> $returnDate</p>
      <p><strong>Yolcu sayısı:</strong> $adults yetişkin${children > 0 ? ', $children çocuk' : ''}</p>
      <hr/>
      <p>Bu belge Vizegoo e-bilet onayınızdır. Havalimanında kimlik ile birlikte ibraz edin.</p>
    ''';
  }

  static String buildVoucherHtml({
    required String reservationId,
    required String passengerName,
    required String hotelName,
    required String checkIn,
    required String checkOut,
    required int nights,
  }) {
    return '''
      <p><strong>Rezervasyon:</strong> $reservationId</p>
      <p><strong>Misafir:</strong> $passengerName</p>
      <p><strong>Otel:</strong> $hotelName</p>
      <p><strong>Giriş:</strong> $checkIn</p>
      <p><strong>Çıkış:</strong> $checkOut</p>
      <p><strong>Gece:</strong> $nights</p>
      <hr/>
      <p>Bu voucher otel check-in için geçerlidir. Rezervasyon numaranızı resepsiyonda gösterin.</p>
    ''';
  }

  static String eticketViewerUrl(String reservationId) =>
      'https://vizegoo.app/doc/eticket/$reservationId';

  static String voucherViewerUrl(String reservationId) =>
      'https://vizegoo.app/doc/voucher/$reservationId';

  static String _wrapHtml(String title, String body) => '''
<!DOCTYPE html>
<html lang="tr">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <title>$title</title>
  <style>
    body { font-family: -apple-system, sans-serif; padding: 24px; color: #222; line-height: 1.5; }
    h1 { color: #FF6600; font-size: 22px; }
  </style>
</head>
<body>
  <h1>$title</h1>
  $body
</body>
</html>
''';

  static Future<void> _openWeb(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static Future<void> _downloadAndShare(
    BuildContext context, {
    required String fileName,
    required String html,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(html);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: fileName,
        text: 'Vizegoo seyahat belgeniz',
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Belge kaydedilemedi, lütfen tekrar deneyin.')),
        );
      }
    }
  }
}
