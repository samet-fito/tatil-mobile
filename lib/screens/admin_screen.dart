import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../theme/app_theme.dart';
import 'admin_hotels_screen.dart';
import 'admin_transfers_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final stats = await AdminService.getStats();
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
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
        title: const Text(
          '⚙️ Admin Paneli',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accent))
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // İstatistik kartları
                  _buildStatsRow(),
                  const SizedBox(height: 24),

                  // Yönetim menüsü
                  _buildSectionTitle('📋 İçerik Yönetimi'),
                  const SizedBox(height: 12),
                  _buildMenuCard(
                    icon: Icons.hotel,
                    title: 'Otel & Pansiyon Yönetimi',
                    subtitle:
                        '${_stats['total_hotels'] ?? 0} aktif otel',
                    color: AppTheme.accent,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => const AdminHotelsScreen(),
                      ),
                    ).then((_) => _loadStats()),
                  ),
                  const SizedBox(height: 10),
                  _buildMenuCard(
                    icon: Icons.directions_car,
                    title: 'Transfer Yönetimi',
                    subtitle:
                        '${_stats['total_transfers'] ?? 0} aktif transfer',
                    color: const Color(0xFF0EA5E9),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => const AdminTransfersScreen(),
                      ),
                    ).then((_) => _loadStats()),
                  ),
                  const SizedBox(height: 24),

                  // Sistem durumu
                  _buildSectionTitle('🔧 Sistem Durumu'),
                  const SizedBox(height: 12),
                  _buildSystemStatus(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            '🏨',
            '${_stats['total_hotels'] ?? 0}',
            'Aktif Otel',
            AppTheme.accentLight,
            AppTheme.accent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            '🚗',
            '${_stats['total_transfers'] ?? 0}',
            'Transfer',
            const Color(0xFFE0F2FE),
            const Color(0xFF0EA5E9),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            '🔍',
            '${_stats['weekly_searches'] ?? 0}',
            'Haftalık Arama',
            const Color(0xFFF3E8FF),
            const Color(0xFF7C3AED),
          ),
        ),
      ],
    );
  }

  Widget _statCard(String emoji, String value, String label,
      Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: textColor.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          _statusRow('Node.js Gateway',
              'https://tatil-backend.onrender.com', true),
          const Divider(height: 16),
          _statusRow('Python AI Motor',
              'https://tatil-python-api.onrender.com', true),
          const Divider(height: 16),
          _statusRow('Supabase', 'Veritabanı bağlantısı', true),
        ],
      ),
    );
  }

  Widget _statusRow(String name, String url, bool isOnline) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isOnline ? const Color(0xFF22C55E) : Colors.red,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              Text(url,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textMuted),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isOnline
                ? const Color(0xFFDCFCE7)
                : const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            isOnline ? 'Çevrimiçi' : 'Çevrimdışı',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isOnline
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFDC2626),
            ),
          ),
        ),
      ],
    );
  }
}