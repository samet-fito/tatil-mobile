import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../theme/app_theme.dart';

class AdminTreatmentsScreen extends StatefulWidget {
  final String clinicId;
  final String clinicName;

  const AdminTreatmentsScreen({
    super.key,
    required this.clinicId,
    required this.clinicName,
  });

  @override
  State<AdminTreatmentsScreen> createState() =>
      _AdminTreatmentsScreenState();
}

class _AdminTreatmentsScreenState extends State<AdminTreatmentsScreen> {
  List<Map<String, dynamic>> _treatments = [];
  bool _isLoading = true;

  final List<String> _categories = [
    'Saç Ekimi', 'Diş Estetiği', 'Burun Estetiği',
    'Göz Lazer', 'Obezite Cerrahisi', 'Meme Estetiği',
    'Liposuction', 'Yüz Estetiği', 'Diğer',
  ];

  @override
  void initState() {
    super.initState();
    _loadTreatments();
  }

  Future<void> _loadTreatments() async {
    setState(() => _isLoading = true);
    final treatments = await AdminService.getTreatments(
        clinicId: widget.clinicId);
    if (mounted) {
      setState(() {
        _treatments = treatments;
        _isLoading = false;
      });
    }
  }

  void _showTreatmentForm({Map<String, dynamic>? treatment}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TreatmentFormSheet(
        treatment: treatment,
        clinicId: widget.clinicId,
        categories: _categories,
        onSave: (data) async {
          bool success;
          if (treatment != null) {
            success =
                await AdminService.updateTreatment(treatment['id'], data);
          } else {
            success = await AdminService.addTreatment(data);
          }
          if (success && mounted) {
            Navigator.pop(ctx);
            _loadTreatments();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(treatment != null
                    ? '✅ Tedavi güncellendi!'
                    : '✅ Tedavi eklendi!'),
                backgroundColor: AppTheme.health,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _deleteTreatment(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tedaviyi Kaldır'),
        content: Text('$name tedavisi pasif yapılacak. Emin misin?'),
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
      await AdminService.deleteTreatment(id);
      _loadTreatments();
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚕️ Tedavi Paketleri',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700),
            ),
            Text(
              widget.clinicName,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadTreatments,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTreatmentForm(),
        backgroundColor: AppTheme.health,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tedavi Ekle',
            style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.health))
          : _treatments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('⚕️',
                          style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      const Text('Henüz tedavi paketi yok.',
                          style:
                              TextStyle(color: AppTheme.textMuted)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _showTreatmentForm(),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.health),
                        child: const Text('İlk Tedaviyi Ekle',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: _treatments.length,
                  itemBuilder: (ctx, i) =>
                      _buildTreatmentCard(_treatments[i]),
                ),
    );
  }

  Widget _buildTreatmentCard(Map<String, dynamic> t) {
    final isActive = t['is_active'] ?? true;
    final includes = t['package_includes'] as Map? ?? {};

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t['treatment_name_tr'] ??
                            t['treatment_name'] ??
                            '--',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700),
                      ),
                      Text(
                        t['category'] ?? '--',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '€${t['price_eur']?.toInt() ?? 0}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.health,
                      ),
                    ),
                    if (t['price_tl'] != null)
                      Text(
                        '${t['price_tl']?.toInt() ?? 0} TL',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _chip('📅',
                    '${t['duration_days']} gün tedavi'),
                _chip('🛏️',
                    '${t['recovery_days']} gün iyileşme'),
                _chip('✅',
                    '%${t['success_rate']?.toInt() ?? 0} başarı'),
                if (includes['hotel'] == true)
                  _chip('🏨', 'Otel Dahil'),
                if (includes['transfer'] == true)
                  _chip('🚗', 'Transfer Dahil'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showTreatmentForm(treatment: t),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Düzenle'),
                  style: TextButton.styleFrom(
                      foregroundColor: AppTheme.accent),
                ),
                TextButton.icon(
                  onPressed: () => _deleteTreatment(
                      t['id'],
                      t['treatment_name_tr'] ??
                          t['treatment_name'] ??
                          ''),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Kaldır'),
                  style: TextButton.styleFrom(
                      foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String emoji, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.healthLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.accent)),
        ],
      ),
    );
  }
}

// ============================================================
// TEDAVİ FORM
// ============================================================
class TreatmentFormSheet extends StatefulWidget {
  final Map<String, dynamic>? treatment;
  final String clinicId;
  final List<String> categories;
  final Function(Map<String, dynamic>) onSave;

  const TreatmentFormSheet({
    super.key,
    this.treatment,
    required this.clinicId,
    required this.categories,
    required this.onSave,
  });

  @override
  State<TreatmentFormSheet> createState() => _TreatmentFormSheetState();
}

class _TreatmentFormSheetState extends State<TreatmentFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _nameTrCtrl;
  late TextEditingController _priceEurCtrl;
  late TextEditingController _priceTlCtrl;
  late TextEditingController _durationCtrl;
  late TextEditingController _recoveryCtrl;
  late TextEditingController _successCtrl;
  late TextEditingController _commissionCtrl;
  String _category = 'Saç Ekimi';
  bool _hotelIncluded = false;
  bool _transferIncluded = true;
  bool _medicationIncluded = true;

  @override
  void initState() {
    super.initState();
    final t = widget.treatment;
    _nameCtrl = TextEditingController(text: t?['treatment_name'] ?? '');
    _nameTrCtrl =
        TextEditingController(text: t?['treatment_name_tr'] ?? '');
    _priceEurCtrl =
        TextEditingController(text: t?['price_eur']?.toString() ?? '');
    _priceTlCtrl =
        TextEditingController(text: t?['price_tl']?.toString() ?? '');
    _durationCtrl =
        TextEditingController(text: t?['duration_days']?.toString() ?? '1');
    _recoveryCtrl = TextEditingController(
        text: t?['recovery_days']?.toString() ?? '0');
    _successCtrl = TextEditingController(
        text: t?['success_rate']?.toString() ?? '95.0');
    _commissionCtrl = TextEditingController(
        text: t != null
            ? (t['commission_rate'] * 100).toInt().toString()
            : '20');
    _category = t?['category'] ?? widget.categories.first;
    final includes = t?['package_includes'] as Map? ?? {};
    _hotelIncluded = includes['hotel'] == true;
    _transferIncluded = includes['transfer'] != false;
    _medicationIncluded = includes['medication'] != false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameTrCtrl.dispose();
    _priceEurCtrl.dispose();
    _priceTlCtrl.dispose();
    _durationCtrl.dispose();
    _recoveryCtrl.dispose();
    _successCtrl.dispose();
    _commissionCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave({
      'clinic_id': widget.clinicId,
      'treatment_name': _nameCtrl.text,
      'treatment_name_tr': _nameTrCtrl.text,
      'category': _category,
      'price_eur': double.tryParse(_priceEurCtrl.text) ?? 0,
      'price_tl': double.tryParse(_priceTlCtrl.text),
      'duration_days': int.tryParse(_durationCtrl.text) ?? 1,
      'recovery_days': int.tryParse(_recoveryCtrl.text) ?? 0,
      'success_rate': double.tryParse(_successCtrl.text) ?? 95.0,
      'commission_rate':
          (int.tryParse(_commissionCtrl.text) ?? 20) / 100,
      'package_includes': {
        'hotel': _hotelIncluded,
        'transfer': _transferIncluded,
        'medication': _medicationIncluded,
      },
      'is_active': true,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.treatment != null
                    ? '✏️ Tedaviyi Düzenle'
                    : '➕ Yeni Tedavi Ekle',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              _field(_nameCtrl, 'Tedavi Adı (EN)',
                  'FUE Hair Transplant'),
              const SizedBox(height: 10),
              _field(_nameTrCtrl, 'Tedavi Adı (TR)',
                  'FUE Saç Ekimi'),
              const SizedBox(height: 10),
              const Text('Kategori',
                  style: TextStyle(
                      fontSize: 12, color: AppTheme.textMuted)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppTheme.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                        color: Colors.black.withOpacity(0.08)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
                items: widget.categories
                    .map((c) => DropdownMenuItem(
                        value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: _field(
                          _priceEurCtrl, 'Fiyat (€)', '1250',
                          isNumber: true)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _field(
                          _priceTlCtrl, 'Fiyat (TL)', '45000',
                          isNumber: true)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: _field(
                          _durationCtrl, 'Tedavi (gün)', '2',
                          isNumber: true)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _field(
                          _recoveryCtrl, 'İyileşme (gün)', '3',
                          isNumber: true)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: _field(
                          _successCtrl, 'Başarı Oranı (%)', '97.5',
                          isNumber: true)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _field(
                          _commissionCtrl, 'Komisyon (%)', '20',
                          isNumber: true)),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Pakete Dahil',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              _switchRow('🏨 Otel', _hotelIncluded,
                  (v) => setState(() => _hotelIncluded = v)),
              _switchRow('🚗 Transfer', _transferIncluded,
                  (v) => setState(() => _transferIncluded = v)),
              _switchRow('💊 İlaçlar', _medicationIncluded,
                  (v) => setState(() => _medicationIncluded = v)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.health,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    widget.treatment != null ? 'Güncelle' : 'Ekle',
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

  Widget _switchRow(
      String label, bool value, Function(bool) onChanged) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        const Spacer(),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.health,
        ),
      ],
    );
  }

  Widget _field(TextEditingController ctrl, String label, String hint,
      {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppTheme.textMuted)),
        const SizedBox(height: 4),
        TextFormField(
          controller: ctrl,
          keyboardType:
              isNumber ? TextInputType.number : TextInputType.text,
          validator: (v) => v!.isEmpty ? '$label zorunlu' : null,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppTheme.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: Colors.black.withOpacity(0.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: Colors.black.withOpacity(0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppTheme.health),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}