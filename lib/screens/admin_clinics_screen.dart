import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../theme/app_theme.dart';
import 'admin_treatments_screen.dart';

class AdminClinicsScreen extends StatefulWidget {
  const AdminClinicsScreen({super.key});

  @override
  State<AdminClinicsScreen> createState() => _AdminClinicsScreenState();
}

class _AdminClinicsScreenState extends State<AdminClinicsScreen> {
  List<Map<String, dynamic>> _clinics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClinics();
  }

  Future<void> _loadClinics() async {
    setState(() => _isLoading = true);
    final clinics = await AdminService.getClinics();
    if (mounted) {
      setState(() {
        _clinics = clinics;
        _isLoading = false;
      });
    }
  }

  void _showClinicForm({Map<String, dynamic>? clinic}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClinicFormSheet(
        clinic: clinic,
        onSave: (data) async {
          bool success;
          if (clinic != null) {
            success = await AdminService.updateClinic(clinic['id'], data);
          } else {
            success = await AdminService.addClinic(data);
          }
          if (success && mounted) {
            Navigator.pop(ctx);
            _loadClinics();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(clinic != null
                    ? '✅ Klinik güncellendi!'
                    : '✅ Klinik eklendi!'),
                backgroundColor: AppTheme.health,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _deleteClinic(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kliniği Kaldır'),
        content: Text('$name kliniği pasif yapılacak. Emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kaldır',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await AdminService.deleteClinic(id);
      _loadClinics();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.health,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '🏥 Klinik Yönetimi',
          style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadClinics,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showClinicForm(),
        backgroundColor: AppTheme.health,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Klinik Ekle',
            style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.health))
          : _clinics.isEmpty
              ? const Center(
                  child: Text('Henüz klinik yok.',
                      style: TextStyle(color: AppTheme.textMuted)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: _clinics.length,
                  itemBuilder: (ctx, i) =>
                      _buildClinicCard(_clinics[i]),
                ),
    );
  }

  Widget _buildClinicCard(Map<String, dynamic> clinic) {
    final isActive = clinic['is_active'] ?? true;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? Colors.black.withOpacity(0.06)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.healthLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('🏥', style: TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clinic['name'] ?? '--',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${clinic['city_name']} · ${clinic['country']}',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${clinic['rating']}/10',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.health,
                      ),
                    ),
                    if (!isActive)
                      const Text('Pasif',
                          style: TextStyle(
                              fontSize: 11, color: Colors.red)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (clinic['is_ministry_accredited'] == true)
                  _badge('🏛️ Bakanlık Onaylı', AppTheme.health),
                if (clinic['is_jci_accredited'] == true)
                  _badge('🌍 JCI', const Color(0xFF1E40AF)),
                _badge(
                    '${clinic['commission_rate'] != null ? (clinic['commission_rate'] * 100).toInt() : 20}% komisyon',
                    const Color(0xFF854F0B)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => AdminTreatmentsScreen(
                        clinicId: clinic['id'],
                        clinicName: clinic['name'],
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.medical_services, size: 16),
                  label: const Text('Tedaviler'),
                  style: TextButton.styleFrom(
                      foregroundColor: AppTheme.health),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () =>
                          _showClinicForm(clinic: clinic),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Düzenle'),
                      style: TextButton.styleFrom(
                          foregroundColor: AppTheme.accent),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          _deleteClinic(clinic['id'], clinic['name']),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Kaldır'),
                      style: TextButton.styleFrom(
                          foregroundColor: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

// ============================================================
// KLİNİK FORM
// ============================================================
class ClinicFormSheet extends StatefulWidget {
  final Map<String, dynamic>? clinic;
  final Function(Map<String, dynamic>) onSave;

  const ClinicFormSheet({super.key, this.clinic, required this.onSave});

  @override
  State<ClinicFormSheet> createState() => _ClinicFormSheetState();
}

class _ClinicFormSheetState extends State<ClinicFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _countryCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _ratingCtrl;
  late TextEditingController _commissionCtrl;
  bool _isMinistry = false;
  bool _isJci = false;

  @override
  void initState() {
    super.initState();
    final c = widget.clinic;
    _nameCtrl = TextEditingController(text: c?['name'] ?? '');
    _cityCtrl = TextEditingController(text: c?['city_name'] ?? '');
    _countryCtrl = TextEditingController(text: c?['country'] ?? 'Turkey');
    _addressCtrl = TextEditingController(text: c?['address'] ?? '');
    _phoneCtrl = TextEditingController(text: c?['contact_phone'] ?? '');
    _emailCtrl = TextEditingController(text: c?['contact_email'] ?? '');
    _ratingCtrl = TextEditingController(text: c?['rating']?.toString() ?? '8.0');
    _commissionCtrl = TextEditingController(
        text: c != null ? (c['commission_rate'] * 100).toInt().toString() : '20');
    _isMinistry = c?['is_ministry_accredited'] ?? false;
    _isJci = c?['is_jci_accredited'] ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _ratingCtrl.dispose();
    _commissionCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave({
      'name': _nameCtrl.text,
      'city_name': _cityCtrl.text,
      'country': _countryCtrl.text,
      'address': _addressCtrl.text,
      'contact_phone': _phoneCtrl.text,
      'contact_email': _emailCtrl.text,
      'rating': double.tryParse(_ratingCtrl.text) ?? 8.0,
      'commission_rate': (int.tryParse(_commissionCtrl.text) ?? 20) / 100,
      'is_ministry_accredited': _isMinistry,
      'is_jci_accredited': _isJci,
      'is_active': true,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.clinic != null ? 'Kliniği Düzenle' : 'Yeni Klinik Ekle',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 16),
              _field(_nameCtrl, 'Klinik Adı', 'Örn: Antalya Clinic'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _field(_cityCtrl, 'Şehir', 'Antalya')),
                  const SizedBox(width: 10),
                  Expanded(child: _field(_countryCtrl, 'Ülke', 'Turkey')),
                ],
              ),
              const SizedBox(height: 10),
              _field(_addressCtrl, 'Adres', 'Tam adres'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _field(_phoneCtrl, 'Telefon', '+90 xxx')),
                  const SizedBox(width: 10),
                  Expanded(child: _field(_emailCtrl, 'E-posta', 'info@klinik.com')),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _field(_ratingCtrl, 'Puan (0-10)', '9.0', isNumber: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _field(_commissionCtrl, 'Komisyon (%)', '20', isNumber: true)),
                ],
              ),
              const SizedBox(height: 16),
              _switchRow('Sağlık Bakanlığı Onaylı', _isMinistry,
                  (v) => setState(() => _isMinistry = v)),
              _switchRow('JCI Akreditasyonlu', _isJci,
                  (v) => setState(() => _isJci = v)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.teal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    widget.clinic != null ? 'Güncelle' : 'Ekle',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _switchRow(String label, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.bgTertiary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.teal,
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, String hint,
      {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        const SizedBox(height: 4),
        TextFormField(
          controller: ctrl,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(color: AppTheme.textPrimary),
          validator: (v) => v!.isEmpty ? '$label zorunlu' : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppTheme.textMuted),
            filled: true,
            fillColor: AppTheme.bgTertiary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.teal),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}