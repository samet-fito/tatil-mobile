import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/admin_service.dart';
import '../theme/app_theme.dart';
import 'admin_clinics_screen.dart';
import 'admin_hotels_screen.dart';
import 'admin_transfers_screen.dart';
import 'admin_pending_clinics_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  int _pendingClinics = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final stats = await AdminService.getStats();
    final pending = await AdminService.getPendingClinicsCount();
    if (mounted) {
      setState(() {
        _stats = stats;
        _pendingClinics = pending;
        _isLoading = false;
      });
    }
  }

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
        title: const Text(
          'Admin Paneli',
          style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.refresh, color: AppTheme.textMuted),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStatsRow(),
                  const SizedBox(height: 24),

                  // Bekleyen başvurular
                  if (_pendingClinics > 0) ...[
                    _buildPendingAlert(),
                    const SizedBox(height: 16),
                  ],

                  _buildSectionTitle('Icerik Yonetimi'),
                  const SizedBox(height: 12),

                  _buildMenuCard(
                    icon: CupertinoIcons.building_2_fill,
                    title: 'Bekleyen Klinik Basvurulari',
                    subtitle: '$_pendingClinics basvuru inceleme bekliyor',
                    color: _pendingClinics > 0 ? AppTheme.accent : AppTheme.textMuted,
                    badge: _pendingClinics > 0 ? '$_pendingClinics' : null,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => const AdminPendingClinicsScreen(),
                      ),
                    ).then((_) => _loadStats()),
                  ),
                  const SizedBox(height: 10),

                  _buildMenuCard(
                    icon: CupertinoIcons.bandage,
                    title: 'Klinik Yonetimi',
                    subtitle: 'Klinik ve tedavi paketleri',
                    color: AppTheme.teal,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => const AdminClinicsScreen(),
                      ),
                    ).then((_) => _loadStats()),
                  ),
                  const SizedBox(height: 10),

                  _buildMenuCard(
                    icon: CupertinoIcons.house,
                    title: 'Otel Yonetimi',
                    subtitle: '${_stats['total_hotels'] ?? 0} aktif otel',
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
                    icon: CupertinoIcons.car,
                    title: 'Transfer Yonetimi',
                    subtitle: '${_stats['total_transfers'] ?? 0} aktif transfer',
                    color: const Color(0xFF0EA5E9),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => const AdminTransfersScreen(),
                      ),
                    ).then((_) => _loadStats()),
                  ),

                  const SizedBox(height: 24),
                  _buildSectionTitle('Sistem Durumu'),
                  const SizedBox(height: 12),
                  _buildSystemStatus(),
                ],
              ),
            ),
    );
  }

  Widget _buildPendingAlert() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.exclamationmark_circle,
              color: AppTheme.accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$_pendingClinics klinik basvurusu inceleme bekliyor!',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            CupertinoIcons.house,
            '${_stats['total_hotels'] ?? 0}',
            'Aktif Otel',
            AppTheme.accent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            CupertinoIcons.car,
            '${_stats['total_transfers'] ?? 0}',
            'Transfer',
            const Color(0xFF0EA5E9),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            CupertinoIcons.building_2_fill,
            '${_stats['total_clinics'] ?? 0}',
            'Klinik',
            AppTheme.teal,
          ),
        ),
      ],
    );
  }

  Widget _statCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w700, color: color)),
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary));
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
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
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(badge,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            const SizedBox(width: 8),
            const Icon(CupertinoIcons.chevron_right,
                color: AppTheme.textMuted, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          _statusRow('Node.js Gateway', 'tatil-backend.onrender.com', true),
          const Divider(height: 16, color: AppTheme.border),
          _statusRow('Python AI Motor', 'vizegoo-python-api.onrender.com', true),
          const Divider(height: 16, color: AppTheme.border),
          _statusRow('Supabase', 'Veritabani baglantisi', true),
        ],
      ),
    );
  }

  Widget _statusRow(String name, String url, bool isOnline) {
    return Row(
      children: [
        Container(
          width: 8, height: 8,
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
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
              Text(url,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textMuted),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isOnline
                ? const Color(0xFF22C55E).withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            isOnline ? 'Cevrimici' : 'Cevrimdisi',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isOnline ? const Color(0xFF22C55E) : Colors.red),
          ),
        ),
      ],
    );
  }
}