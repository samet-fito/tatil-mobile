import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../utils/price_format.dart' show PriceFormat;

/// 3D Secure ödeme doğrulama — önizlemede banka yönlendirmesi simülasyonu.
abstract final class Payment3DSecureSheet {
  static Future<bool> show(
    BuildContext context, {
    required int amountTL,
    required String merchantName,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => _Payment3DSecureBody(
        amountTL: amountTL,
        merchantName: merchantName,
      ),
    );
    return result == true;
  }
}

class _Payment3DSecureBody extends StatefulWidget {
  const _Payment3DSecureBody({
    required this.amountTL,
    required this.merchantName,
  });

  final int amountTL;
  final String merchantName;

  @override
  State<_Payment3DSecureBody> createState() => _Payment3DSecureBodyState();
}

enum _Phase { redirect, sms, processing, done }

class _Payment3DSecureBodyState extends State<_Payment3DSecureBody> {
  _Phase _phase = _Phase.redirect;
  final _smsCtrl = TextEditingController();
  String? _error;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _phase == _Phase.redirect) {
        setState(() => _phase = _Phase.sms);
      }
    });
  }

  @override
  void dispose() {
    _smsCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifySms() async {
    final code = _smsCtrl.text.trim();
    if (code.length < 4) {
      setState(() => _error = 'Doğrulama kodunu girin');
      return;
    }
    setState(() {
      _error = null;
      _phase = _Phase.processing;
    });
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() {
      _phase = _Phase.done;
      _success = true;
    });
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.12),
      decoration: const BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.teal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  CupertinoIcons.lock_shield,
                  color: AppTheme.teal,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '3D Secure Doğrulama',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Bankanız güvenli ödeme istiyor',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.bgTertiary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.merchantName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  PriceFormat.format(widget.amountTL),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.accent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_phase == _Phase.redirect) ...[
            const CupertinoActivityIndicator(radius: 14),
            const SizedBox(height: 16),
            const Text(
              'Bankanıza yönlendiriliyorsunuz…',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
          ] else if (_phase == _Phase.sms) ...[
            const Text(
              'Telefonunuza gelen SMS kodunu girin.\n(Demo: herhangi bir 6 haneli kod)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _smsCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 8,
                color: AppTheme.textPrimary,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                counterText: '',
                hintText: '••••••',
                filled: true,
                fillColor: AppTheme.bgTertiary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.teal, width: 2),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(fontSize: 12, color: Colors.red.shade700),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _verifySms,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Onayla',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ] else if (_phase == _Phase.processing) ...[
            const CupertinoActivityIndicator(radius: 14),
            const SizedBox(height: 16),
            const Text(
              'Ödeme işleniyor…',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
          ] else if (_phase == _Phase.done && _success) ...[
            Icon(CupertinoIcons.check_mark_circled_solid,
                size: 48, color: AppTheme.teal),
            const SizedBox(height: 8),
            const Text(
              'Ödeme onaylandı',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
          const SizedBox(height: 8),
          if (_phase != _Phase.processing && _phase != _Phase.done)
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal', style: TextStyle(color: AppTheme.textMuted)),
            ),
        ],
      ),
    );
  }
}
