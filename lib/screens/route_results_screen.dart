
import 'route_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/route_result_model.dart';
import '../models/search_model.dart';
import '../theme/app_theme.dart';
import '../widgets/route_result_card.dart';
import '../widgets/checkout_auth_sheet.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class RouteResultsScreen extends StatefulWidget {
  final SearchModel searchModel;

  const RouteResultsScreen({super.key, required this.searchModel});

  @override
  State<RouteResultsScreen> createState() => _RouteResultsScreenState();
}

class _RouteResultsScreenState extends State<RouteResultsScreen> {
  List<RouteResultModel> _routes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final routes = await ApiService.searchRoutes(
        originIata: widget.searchModel.originIata,
        departureDate: widget.searchModel.departureDate,
        returnDate: widget.searchModel.returnDate,
        totalBudgetTL: widget.searchModel.totalBudgetTL,
        passengers: widget.searchModel.passengers,
      );

      if (mounted) {
        setState(() {
          _routes = routes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Rotalar yüklenemedi.';
          _isLoading = false;
        });
      }
    }
  }

  String _formatPrice(double price) {
    return '${price.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} TL';
  }

  bool get _isGuest => !AuthService.isLoggedIn;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Akıllı Rotalar',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${widget.searchModel.originCity} · ${_formatPrice(widget.searchModel.totalBudgetTL)}',
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.refresh, color: AppTheme.textMuted),
            onPressed: _loadRoutes,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppTheme.accent),
            const SizedBox(height: 20),
            const Text(
              'Rotalar hesaplanıyor...',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Uçuş + Otel + Transfer optimize ediliyor',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.exclamationmark_circle,
                color: AppTheme.textMuted, size: 48),
            const SizedBox(height: 16),
            Text(_error!,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 14)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadRoutes,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_routes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.map, color: AppTheme.textMuted, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Bu bütçeye uygun rota bulunamadı.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Bütçeyi Değiştir'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Özet bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: AppTheme.bgSecondary,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_routes.length} rota bulundu',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'AI Motor',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Misafir uyarısı
        if (_isGuest && _routes.length > 3)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: AppTheme.accent.withOpacity(0.08),
            child: Row(
              children: [
                const Icon(CupertinoIcons.lock_fill,
                    size: 14, color: AppTheme.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_routes.length - 3} rota kilitli. Tüm rotaları görmek için giriş yap.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _showLoginSheet(),
                  child: const Text(
                    'Giriş Yap',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),

// Rota listesi
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadRoutes,
            color: AppTheme.accent,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: _routes.length,
              itemBuilder: (context, index) {
                final isLocked = _isGuest && index >= 3;

                if (isLocked) {
                  return _buildLockedCard(_routes[index]);
                }

                return RouteResultCard(
                  route: _routes[index],
                  rank: index + 1,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => RouteDetailScreen(
                          route: _routes[index],
                          originIata: widget.searchModel.originIata,
                          departureDate: widget.searchModel.departureDate,
                          returnDate: widget.searchModel.returnDate,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // KİLİTLİ KART (FOMO)
  // ============================================================
  Widget _buildLockedCard(RouteResultModel route) {
    return GestureDetector(
      onTap: _showLoginSheet,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 160,
        decoration: BoxDecoration(
          color: AppTheme.bgSecondary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Bulanık içerik
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppTheme.bgTertiary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 80,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppTheme.bgTertiary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 100,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppTheme.bgTertiary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),

              // Blur overlay
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.bgPrimary.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              // Kilit ikonu ve mesaj
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                            color: AppTheme.accent.withOpacity(0.3)),
                      ),
                      child: const Icon(
                        CupertinoIcons.lock_fill,
                        color: AppTheme.accent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Fırsat Rota Kilitli',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tek tıkla giriş yap ve kilidi aç',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLoginSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.bgSecondary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
            32, 24, 32, MediaQuery.of(context).padding.bottom + 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Fırsat rotaların\nseni bekliyor',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                height: 1.2,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_routes.length - 3} kilitli rota daha var. Giriş yap, tümünü gör.',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 28),
            _loginBtn(
              label: 'Google ile Giriş Yap',
              bgColor: Colors.white,
              textColor: const Color(0xFF1F1F1F),
              onTap: () async {
  Navigator.pop(ctx);
  await AuthService.signInWithGoogle();
  // Auth state değişimini bekle
  await Future.delayed(const Duration(seconds: 2));
  if (mounted) {
    setState(() {});
    _loadRoutes();
  }
},
            ),
            const SizedBox(height: 12),
            _loginBtn(
              label: 'Apple ile Giriş Yap',
              bgColor: Colors.black,
              textColor: Colors.white,
              border: Border.all(color: AppTheme.border),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Apple girişi yakında aktif olacak.'),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: const Text(
                  'Şimdi değil',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loginBtn({
    required String label,
    required Color bgColor,
    required Color textColor,
    Border? border,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: border,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}