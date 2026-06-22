import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../services/loyalty_points_service.dart';
import '../services/referral_service.dart';
import '../theme/app_theme.dart';
import '../theme/tatil_theme.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  String _myCode = '...';
  bool _redeemed = false;
  bool _loading = true;
  final _inputCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final code = await ReferralService.myCode();
    final redeemed = await ReferralService.hasRedeemedReferral();
    if (mounted) {
      setState(() {
        _myCode = code;
        _redeemed = redeemed;
        _loading = false;
      });
    }
  }

  Future<void> _share() async {
    final msg = await ReferralService.shareMessage();
    await Share.share(msg.trim(), subject: 'Vizegoo davet kodum');
  }

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: _myCode));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Davet kodu kopyalandı'),
          backgroundColor: AppTheme.teal,
        ),
      );
    }
  }

  Future<void> _redeem() async {
    final result = await ReferralService.redeemCode(_inputCtrl.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? AppTheme.teal : AppTheme.orange,
      ),
    );
    if (result.success) {
      setState(() => _redeemed = true);
      _inputCtrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TatilTheme.bgSoft,
      appBar: AppBar(
        title: const Text('Arkadaşını Davet Et'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CupertinoActivityIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.teal.withValues(alpha: 0.9),
                        AppTheme.accent.withValues(alpha: 0.85),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Davet kodunuz',
                        style: TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _myCode,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Arkadaşınız kodu kullanınca ikiniz de ${ReferralService.bonusPoints} puan kazanın',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _copyCode,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white54),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Kopyala'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _share,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppTheme.teal,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text(
                                'Paylaş',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (!_redeemed) ...[
                  const Text(
                    'Davet kodunuz var mı?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _inputCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'VGXXXXX',
                      filled: true,
                      fillColor: AppTheme.bgSecondary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _redeem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Kodu kullan',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ] else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(CupertinoIcons.check_mark_circled_solid,
                            color: AppTheme.teal),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Davet kodu kullanıldı — puanlarınız hesabınıza eklendi.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                Text(
                  'Her ${LoyaltyPointsService.pointsPerTenTL} TL harcamada 1 puan kazanırsınız. '
                  'Davet bonusu tek seferliktir.',
                  style: TatilTheme.hint.copyWith(fontSize: 11, height: 1.45),
                ),
              ],
            ),
    );
  }
}
