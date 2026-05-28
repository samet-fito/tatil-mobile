import 'detail_screen.dart';
import 'package:flutter/material.dart';
import '../models/package_model.dart';
import '../models/search_model.dart';
import '../theme/app_theme.dart';
import '../widgets/package_card.dart';
import '../services/api_service.dart';

class ResultsScreen extends StatefulWidget {
  final SearchModel searchModel;

  const ResultsScreen({super.key, required this.searchModel});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  List<PackageModel> _packages = [];
  bool _isLoading = true;
  String? _error;
  String _dataSource = 'mock';

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await ApiService.searchPackages(widget.searchModel);

    if (!mounted) return;

    if (result['success'] == true) {
      final data = result['data'];
      final packages = (data['packages'] as List? ?? [])
          .map((p) => PackageModel.fromJson(p))
          .toList();

      setState(() {
        _packages = packages;
        _dataSource = data['meta']?['dataSource'] ?? 'mock';
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['error']?['message'] ?? 'Bir hata oluştu.';
        _isLoading = false;
      });
    }
  }

  String get _sourceLabel {
    switch (_dataSource) {
      case 'live_api': return '🟢 Canlı Fiyat';
      case 'cache': return '🔵 Önbellekten';
      default: return '⚪ Demo Veri';
    }
  }

  Color get _sourceColor {
    switch (_dataSource) {
      case 'live_api': return const Color(0xFF0F6E56);
      case 'cache': return const Color(0xFF185FA5);
      default: return AppTheme.textMuted;
    }
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
              'Bulunan Paketler',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${widget.searchModel.originCity} · ${widget.searchModel.totalBudgetTL.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} TL',
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
            onPressed: _loadPackages,
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
            const SizedBox(height: 16),
            const Text(
              'Paketler aranıyor...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sana özel rotalar hesaplanıyor 🌍',
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
                  fontSize: 15,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadPackages,
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    if (_packages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🗺️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text(
              'Bu filtrelere uygun paket bulunamadı.',
              style: TextStyle(fontSize: 15, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Filtreleri Değiştir'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: AppTheme.cardBg,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_packages.length} paket bulundu',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _sourceColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  _sourceLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _sourceColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadPackages,
            color: AppTheme.accent,
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _packages.length,
              itemBuilder: (context, index) {
                return PackageCard(
                  package: _packages[index],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailScreen(
                          package: _packages[index],
                          searchModel: widget.searchModel,
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
}