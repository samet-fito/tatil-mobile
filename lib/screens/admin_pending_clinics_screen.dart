import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

class AdminPendingClinicsScreen extends StatefulWidget {
  const AdminPendingClinicsScreen({super.key});

  @override
  State<AdminPendingClinicsScreen> createState() =>
      _AdminPendingClinicsScreenState();
}

class _AdminPendingClinicsScreenState
    extends State<AdminPendingClinicsScreen> {
  List<Map<String, dynamic>> _clinics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingClinics();
  }

  Future<void> _loadPendingClinics() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final result = await supabase
          .from('clinics')
          .select('*')
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _clinics = List<Map<String, dynamic>>.from(result);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approve(String id, String name) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('clinics')
          .update({'status': 'approved', 'is_active': true, 'clinic_score': 80})
          .eq('id', id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name onaylandi!'),
            backgroundColor: AppTheme.teal,
          ),
        );
        _loadPendingClinics();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hata olustu.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _reject(String id, String name) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('clinics')
          .update({'status': 'rejected', 'is_active': false})
          .eq('id', id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name reddedildi.'),
            backgroundColor: Colors.red,
          ),
        );
        _loadPendingClinics();
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left,
              color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bekleyen Basvurular',
          style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.refresh,
                color: AppTheme.textMuted),
            onPressed: _loadPendingClinics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.teal))
          : _clinics.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(CupertinoIcons.checkmark_circle,
                          size: 48, color: AppTheme.teal),
                      const SizedBox(height: 12),
                      const Text(
                        'Bekleyen basvuru yok.',
                        style: TextStyle(
                            color: AppTheme.textMuted, fontSize: 15),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _clinics.length,
                  itemBuilder: (ctx, i) => _buildCard(_clinics[i]),
                ),
    );
  }

  Widget _buildCard(Map<String, dynamic> clinic) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clinic['name'] ?? '--',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary),
                    ),
                    Text(
                      '${clinic['city_name'] ?? ''} · ${clinic['specialty'] ?? 'Genel'}',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Bekliyor',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (clinic['contact_email'] != null)
            Text(
              clinic['contact_email'],
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textMuted),
            ),
          if (clinic['contact_phone'] != null)
            Text(
              clinic['contact_phone'],
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textMuted),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _reject(clinic['id'], clinic['name'] ?? ''),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.red.withOpacity(0.3)),
                    ),
                    child: const Center(
                      child: Text('Reddet',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.red)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => _approve(clinic['id'], clinic['name'] ?? ''),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.teal,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text('Onayla',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}