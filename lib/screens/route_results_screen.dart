import '../widgets/checkout_auth_sheet.dart';
import 'package:flutter/material.dart';
import '../models/route_result_model.dart';
import '../models/search_model.dart';
import '../theme/app_theme.dart';
import '../widgets/route_result_card.dart';
import '../services/api_service.dart';

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
  String _dataSource = 'python';

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
          _error = 'Rotalar yüklenemedi: $e';
          _isLoading = false;
        });
      }
    }
  }

  String _formatPrice(double price) {
    return '${price.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} TL';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Akıllı Rotalar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${widget.searchModel.originCity} · ${_formatPrice(widget.searchModel.totalBudgetTL)}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
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
              'Akıllı rotalar hesaplanıyor...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Uçuş + Otel + Transfer optimize ediliyor 🧠',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadRoutes,
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    if (_routes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🗺️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text(
              'Bu bütçeye uygun rota bulunamadı.',
              style: TextStyle(
                  fontSize: 15, color: AppTheme.textMuted),
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
        // Özet başlık
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 12),
          color: AppTheme.cardBg,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_routes.length} rota bulundu',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Python AI Motor',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
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
              padding: const EdgeInsets.all(16),
              itemCount: _routes.length,
              itemBuilder: (context, index) {
                return RouteResultCard(
                  route: _routes[index],
                  rank: index + 1,
                  onTap: () {
  CheckoutAuthSheet.show(
    context,
    cityName: _routes[index].cityName,
    totalPrice: _routes[index].estimatedCost.total,
    onSuccess: () {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_routes[index].cityName} rezervasyonu başlatıldı!',
          ),
          backgroundColor: AppTheme.accent,
        ),
      );
    },
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
}