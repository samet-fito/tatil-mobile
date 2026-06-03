import 'clinic_register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'search_screen.dart';
import 'login_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: _currentIndex == 0 ? const SearchScreen() : const ProfileScreen(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgSecondary,
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppTheme.accent,
          unselectedItemColor: AppTheme.textMuted,
          selectedLabelStyle: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.search),
              activeIcon: Icon(CupertinoIcons.search),
              label: 'Kesfet',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.person),
              activeIcon: Icon(CupertinoIcons.person_fill),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final isGuest = AuthService.isGuest;
    final name = isGuest
        ? 'Misafir'
        : (user?.userMetadata?['full_name'] ??
            user?.email?.split('@')[0] ??
            'Kullanici');
    final email = isGuest ? 'Giris yapilmadi' : (user?.email ?? '');
    final avatarUrl = user?.userMetadata?['avatar_url'];

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Başlık
              const Text(
                'Profil',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),

              // Kullanıcı kartı
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
                      width: 60,
                      height: 60,
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
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: const TextStyle(
                                fontSize: 13, color: AppTheme.textMuted),
                          ),
                          if (!isGuest) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.teal.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: const Text(
                                'Uye',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.teal,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Misafir ise giriş yap
              if (isGuest) ...[
                GestureDetector(
                  onTap: () async {
                    await AuthService.signInWithGoogle();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text(
                        'Google ile Giris Yap',
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

              // İstatistik kartları
              if (!isGuest) ...[
                Row(
                  children: [
                    Expanded(
                      child: _statCard('0', 'Rezervasyon',
                          CupertinoIcons.doc_text, AppTheme.accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard('0', 'Favori Rota',
                          CupertinoIcons.heart, AppTheme.teal),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard('0', 'Ulke',
                          CupertinoIcons.map, const Color(0xFF8B5CF6)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // Menü başlığı
              const Text(
                'Hesabim',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),

              _menuItem(
                context,
                CupertinoIcons.doc_text,
                'Rezervasyonlarim',
                'Gecmis ve aktif rezervasyonlar',
                AppTheme.accent,
                () {},
              ),
              _menuItem(
                context,
                CupertinoIcons.heart,
                'Favori Rotalarim',
                'Kaydettigin rotalar',
                AppTheme.teal,
                () {},
              ),
              _menuItem(
                context,
                CupertinoIcons.bell,
                'Bildirimler',
                'Fiyat alarmlari ve duyurular',
                const Color(0xFF8B5CF6),
                () {},
              ),

              const SizedBox(height: 20),

              const Text(
                'Uygulama',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),

              _menuItem(
                context,
                CupertinoIcons.settings,
                'Ayarlar',
                'Dil, bildirim tercihleri',
                AppTheme.textMuted,
                () {},
              ),
              _menuItem(
                context,
                CupertinoIcons.question_circle,
                'Yardim & Destek',
                'SSS ve iletisim',
                AppTheme.textMuted,
                () {},
              ),
              _menuItem(
  context,
  CupertinoIcons.building_2_fill,
  'Klinik Basvurusu',
  'Vizegoo partner ol, hasta kazan',
  AppTheme.teal,
  () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (ctx) => const ClinicRegisterScreen(),
    ),
  ),
),
              _menuItem(
                context,
                CupertinoIcons.shield,
                'Gizlilik Politikasi',
                'KVKK ve veri guvenligi',
                AppTheme.textMuted,
                () {},
              ),

              const SizedBox(height: 24),

              // Versiyon
              Center(
                child: Text(
                  'Vizegoo v1.0.0',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textMuted),
                ),
              ),

              const SizedBox(height: 16),

              // Çıkış butonu
              if (!isGuest)
                GestureDetector(
                  onTap: () async {
                    await AuthService.signOut();
                    if (context.mounted) {
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (ctx) => const LoginScreen()));
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: Colors.red.withOpacity(0.2)),
                    ),
                    child: const Center(
                      child: Text(
                        'Cikis Yap',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
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

  Widget _statCard(
      String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _menuItem(
    BuildContext context,
    IconData icon,
    String label,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
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
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_right,
                size: 14, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}