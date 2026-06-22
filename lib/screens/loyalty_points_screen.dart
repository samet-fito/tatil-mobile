import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../services/loyalty_points_service.dart';
import '../theme/app_theme.dart';
import '../theme/tatil_theme.dart';

class LoyaltyPointsScreen extends StatefulWidget {
  const LoyaltyPointsScreen({super.key});

  @override
  State<LoyaltyPointsScreen> createState() => _LoyaltyPointsScreenState();
}

class _LoyaltyPointsScreenState extends State<LoyaltyPointsScreen> {
  int _balance = 0;
  List<LoyaltyTransaction> _history = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final balance = await LoyaltyPointsService.balance();
    final history = await LoyaltyPointsService.history();
    if (mounted) {
      setState(() {
        _balance = balance;
        _history = history;
        _loading = false;
      });
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TatilTheme.bgSoft,
      appBar: AppBar(
        title: const Text('Vizegoo Puan'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CupertinoActivityIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.accent.withOpacity(0.9),
                          AppTheme.orange.withOpacity(0.85),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Toplam puanınız',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_balance',
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '≈ ${LoyaltyPointsService.tlValueOfPoints(_balance)} TL indirim değeri',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.bgSecondary,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nasıl kazanılır?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Her 10 TL harcamada 1 Vizegoo Puan kazanırsınız. Puanlarınızı gelecekteki rezervasyonlarda indirim olarak kullanabileceksiniz.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.45,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Son işlemler',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_history.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.bgSecondary,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: const Text(
                        'Henüz puan kazanmadınız. İlk rezervasyonunuzda puan birikmeye başlar.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    )
                  else
                    ..._history.map((tx) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.bgSecondary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.teal.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                CupertinoIcons.plus,
                                size: 16,
                                color: AppTheme.teal,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx.label,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    _fmtDate(tx.createdAt),
                                    style: TatilTheme.hint.copyWith(fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '+${tx.points}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.teal,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
