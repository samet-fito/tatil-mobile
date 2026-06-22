import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../services/trip_reminder_service.dart';
import '../theme/app_theme.dart';
import '../theme/tatil_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _remindersEnabled = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await TripReminderService.remindersEnabled();
    if (mounted) {
      setState(() {
        _remindersEnabled = enabled;
        _loading = false;
      });
    }
  }

  Future<void> _toggle(bool value) async {
    await TripReminderService.setRemindersEnabled(value);
    if (mounted) setState(() => _remindersEnabled = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TatilTheme.bgSoft,
      appBar: AppBar(
        title: const Text('Bildirimler'),
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.bgSecondary,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.teal.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          CupertinoIcons.airplane,
                          color: AppTheme.teal,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Check-in hatırlatıcısı',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Kalkıştan 24 saat önce uygulama içi bildirim',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: _remindersEnabled,
                        activeColor: AppTheme.teal,
                        onChanged: _toggle,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Hatırlatıcılar cihazınızda planlanır. Uygulamayı açtığınızda vadesi gelen bildirimler gösterilir. Tam push bildirimi için sistem izinleri yakında eklenecek.',
                  style: TatilTheme.hint.copyWith(fontSize: 12, height: 1.45),
                ),
              ],
            ),
    );
  }
}
