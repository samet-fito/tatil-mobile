import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/help_support_sheet.dart';
import '../config/support_config.dart';
import '../config/app_experience.dart';
import '../theme/app_theme.dart';
import '../theme/tatil_theme.dart';
import '../services/auth_service.dart';
import '../services/admin_service.dart';
import '../theme/custom_page_route.dart';
import '../utils/app_navigation.dart';
import 'search_screen.dart';
import 'ai_assistant_screen.dart';
import 'medical_search_screen.dart';
import 'clinic_register_screen.dart';
import 'admin_screen.dart';
import 'my_reservations_screen.dart';
import 'pnr_checkin_screen.dart';
import 'loyalty_points_screen.dart';
import 'notification_settings_screen.dart';
import 'price_watch_screen.dart';
import 'referral_screen.dart';
import 'support_chat_screen.dart';
import '../services/loyalty_points_service.dart';
import '../services/trip_reminder_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    MainTabController.instance.attach((index) {
      if (mounted) setState(() => _currentIndex = index);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkTripReminder());
  }

  Future<void> _checkTripReminder() async {
    final reminder = await TripReminderService.consumeDueReminder();
    if (!mounted || reminder == null) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Check-in hatırlatıcısı'),
        content: Text(
          '${reminder.cityName} uçuşunuz için online check-in yapmayı unutmayın. '
          'Kalkış: ${reminder.departureDate.day}.${reminder.departureDate.month}.${reminder.departureDate.year}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tamam'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              pushAppRoute(context, const PnrCheckinScreen());
            },
            child: const Text('Check-in'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    MainTabController.instance.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TatilTheme.bgSoft,
      body: _currentIndex == 0 ? const SearchScreen() : const ProfileScreen(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              children: [
                Expanded(child: _navItem(0, CupertinoIcons.search, 'Keşfet')),
                Expanded(child: _navItem(1, CupertinoIcons.person, 'Profil')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final selected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            selected && index == 1 ? CupertinoIcons.person_fill : icon,
            color: selected ? TatilTheme.orange : TatilTheme.textMuted,
            size: 22,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: selected ? TatilTheme.orange : TatilTheme.textMuted,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isAdmin = false;
  bool _googleLoading = false;
  int _loyaltyPoints = 0;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _loadAdminAccess();
    _loadLoyaltyPoints();
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      if (mounted) {
        _loadAdminAccess();
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _loadLoyaltyPoints() async {
    final pts = await LoyaltyPointsService.balance();
    if (mounted) setState(() => _loyaltyPoints = pts);
  }

  Future<void> _loadAdminAccess() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final isAdmin = await AdminService.isAdmin();
    if (mounted) setState(() => _isAdmin = isAdmin);
  }

  Future<void> _openAdminPanel() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin paneli için giriş yapmanız gerekiyor'),
          backgroundColor: AppTheme.orange,
        ),
      );
      return;
    }
    final isAdmin = await AdminService.isAdmin();
    if (!mounted) return;
    if (isAdmin) {
      pushAppRoute(context, const AdminScreen());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erişim yetkiniz yok'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_googleLoading) return;
    setState(() => _googleLoading = true);
    try {
      final success = await AuthService.signInWithGoogle();
      if (!mounted) return;
      if (success) {
        await _loadAdminAccess();
      }
      setState(() => _googleLoading = false);
    } catch (_) {
      if (mounted) {
        setState(() => _googleLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google girişi tamamlanamadı. Lütfen tekrar deneyin.'),
            backgroundColor: AppTheme.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final isGuest = AuthService.isGuest && user == null;
    final name = isGuest
        ? 'Misafir'
        : (user?.userMetadata?['full_name'] ??
            user?.email?.split('@')[0] ??
            'Kullanıcı');
    final email = isGuest ? 'Giriş yapılmadı' : (user?.email ?? '');
    final avatarUrl = user?.userMetadata?['avatar_url'];

    return Scaffold(
      backgroundColor: TatilTheme.bgSoft,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text('Profil',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accent.withOpacity(0.15),
                      AppTheme.teal.withOpacity(0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.accent.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                            color: AppTheme.accent.withOpacity(0.3), width: 2),
                      ),
                      child: avatarUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: Image.network(avatarUrl, fit: BoxFit.cover),
                            )
                          : const Icon(CupertinoIcons.person_fill,
                              color: AppTheme.accent, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary)),
                          const SizedBox(height: 2),
                          Text(email,
                              style: const TextStyle(
                                  fontSize: 13, color: AppTheme.textMuted)),
                          if (!isGuest) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.teal.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: const Text('Üye',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.teal)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  await pushAppRoute(context, const LoyaltyPointsScreen());
                  if (mounted) _loadLoyaltyPoints();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.accent.withOpacity(0.12),
                        AppTheme.orange.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.accent.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          CupertinoIcons.gift,
                          color: AppTheme.accent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Vizegoo Puan',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              '$_loyaltyPoints puan · Her 10 TL = 1 puan',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        CupertinoIcons.chevron_right,
                        size: 16,
                        color: AppTheme.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (isGuest)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.orangeSoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.orange.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(CupertinoIcons.person_crop_circle_badge_checkmark,
                          color: AppTheme.orange, size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Misafir modu — rezervasyonlar cihazınızda saklanır.',
                          style: TextStyle(fontSize: 12, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
              if (!AppExperience.paymentsEnabled) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.orange.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    AppExperience.previewBannerText,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.35,
                      color: Color(0xFF9A3412),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (isGuest) ...[
                GestureDetector(
                  onTap: _googleLoading ? null : _signInWithGoogle,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: _googleLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Google ile Giriş Yap',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              const Text('Keşfet & hizmetler',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                      letterSpacing: 0.5)),
              const SizedBox(height: 10),
              _menuItem(
                context,
                CupertinoIcons.doc_text,
                'Rezervasyonlarım',
                'Seyahat kartı · rehber · belgeler',
                AppTheme.orange,
                () => pushAppRoute(context, const MyReservationsScreen()),
              ),
              _menuItem(
                context,
                CupertinoIcons.ticket,
                'PNR & Check-in',
                'Bilet sorgula · online check-in',
                AppTheme.teal,
                () => pushAppRoute(context, const PnrCheckinScreen()),
              ),
              _menuItem(
                context,
                CupertinoIcons.bell_fill,
                'Fiyat Alarmlarım',
                'Hedef fiyata düşünce haber ver',
                AppTheme.orange,
                () => pushAppRoute(context, const PriceWatchScreen()),
              ),
              _menuItem(
                context,
                CupertinoIcons.person_2,
                'Arkadaşını Davet Et',
                'Davet koduyla puan kazan',
                AppTheme.accent,
                () => pushAppRoute(context, const ReferralScreen()),
              ),
              _menuItem(
                context,
                CupertinoIcons.bell,
                'Bildirimler',
                'Check-in hatırlatıcıları',
                AppTheme.textMuted,
                () => pushAppRoute(context, const NotificationSettingsScreen()),
              ),
              _menuItem(
                context,
                CupertinoIcons.sparkles,
                'AI Asistan',
                'Tatil planında yardım al',
                AppTheme.orange,
                () => pushAppRoute(context, const AiAssistantScreen()),
              ),
              _menuItem(
                context,
                CupertinoIcons.heart,
                'Sağlık Turizmi',
                'Tedavi ve konaklama paketleri',
                AppTheme.teal,
                () => pushAppRoute(context, const MedicalSearchScreen()),
              ),
              const SizedBox(height: 20),
              const Text('Destek & iş ortaklığı',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                      letterSpacing: 0.5)),
              const SizedBox(height: 10),
              _menuItem(
                context,
                CupertinoIcons.headphones,
                'Canlı Destek',
                'Chat · ${SupportConfig.supportHours}',
                AppTheme.teal,
                () => pushAppRoute(context, const SupportChatScreen()),
              ),
              _menuItem(
                context,
                CupertinoIcons.question_circle,
                'Yardım & Destek',
                'SSS, WhatsApp ve e-posta',
                AppTheme.textMuted,
                () => showHelpSupportSheet(context),
              ),
              _menuItem(
                context,
                CupertinoIcons.building_2_fill,
                'Klinik Başvurusu',
                'Vizegoo partner olun',
                AppTheme.teal,
                () => pushAppRoute(context, const ClinicRegisterScreen()),
              ),
              if (_isAdmin)
                _menuItem(context, CupertinoIcons.shield, 'Admin Paneli', 'Sistem yönetimi', AppTheme.orange, _openAdminPanel),
              const SizedBox(height: 24),
              const Center(child: Text('Vizegoo v1.0.0', style: TextStyle(fontSize: 12, color: AppTheme.textMuted))),
              const SizedBox(height: 16),
              if (!isGuest)
                GestureDetector(
                  onTap: () async {
                    await AuthService.signOut();
                    if (context.mounted) {
                      await AuthService.continueAsGuest();
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (ctx) => const MainScreen()),
                        );
                      }
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.red.withOpacity(0.2)),
                    ),
                    child: const Center(
                      child: Text('Çıkış Yap',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.red)),
                    ),
                  ),
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuItem(BuildContext context, IconData icon, String label, String subtitle, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgSecondary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            ],
          )),
          const Icon(CupertinoIcons.chevron_right, size: 14, color: AppTheme.textMuted),
        ]),
      ),
    );
  }
}