import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../theme/app_theme.dart';

class AdminTransfersScreen extends StatefulWidget {
  const AdminTransfersScreen({super.key});

  @override
  State<AdminTransfersScreen> createState() => _AdminTransfersScreenState();
}

class _AdminTransfersScreenState extends State<AdminTransfersScreen> {
  List<Map<String, dynamic>> _transfers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransfers();
  }

  Future<void> _loadTransfers() async {
    setState(() => _isLoading = true);
    final transfers = await AdminService.getTransfers();
    if (mounted) {
      setState(() {
        _transfers = transfers;
        _isLoading = false;
      });
    }
  }

  void _showTransferForm({Map<String, dynamic>? transfer}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TransferFormSheet(
        transfer: transfer,
        onSave: (data) async {
          bool success;
          if (transfer != null) {
            success = await AdminService.updateTransfer(transfer['id'], data);
          } else {
            success = await AdminService.addTransfer(data);
          }
          if (success && mounted) {
            Navigator.pop(ctx);
            _loadTransfers();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(transfer != null
                    ? '✅ Transfer güncellendi!'
                    : '✅ Transfer eklendi!'),
                backgroundColor: AppTheme.accent,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _deleteTransfer(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Transferi Kaldır'),
        content: Text('$name transferi pasif yapılacak. Emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kaldır', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await AdminService.deleteTransfer(id);
      _loadTransfers();
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
          '🚗 Transfer Yönetimi',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadTransfers,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTransferForm(),
        backgroundColor: const Color(0xFF0EA5E9),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Transfer Ekle', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : _transfers.isEmpty
              ? const Center(
                  child: Text('Henüz transfer yok.',
                      style: TextStyle(color: AppTheme.textMuted)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: _transfers.length,
                  itemBuilder: (ctx, i) => _buildTransferCard(_transfers[i]),
                ),
    );
  }

  Widget _buildTransferCard(Map<String, dynamic> transfer) {
    final isActive = transfer['is_active'] ?? true;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? Colors.black.withOpacity(0.06) : Colors.red.withOpacity(0.3),
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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.directions_car,
                      color: Color(0xFF0EA5E9), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transfer['company_name'] ?? 'Transfer',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${transfer['city_name']} · ${transfer['destination_iata']} · ${transfer['vehicle_type']}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                if (!isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Text('Pasif',
                        style: TextStyle(fontSize: 11, color: Colors.red)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _chip('📍', '${transfer['route_from']} → ${transfer['route_to']}'),
                _chip('💰', '${transfer['price_fixed']?.toInt() ?? 0} TL'),
                if (transfer['duration_minutes'] != null)
                  _chip('⏱️', '${transfer['duration_minutes']} dk'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showTransferForm(transfer: transfer),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Düzenle'),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.accent),
                ),
                TextButton.icon(
                  onPressed: () => _deleteTransfer(
                      transfer['id'], transfer['company_name'] ?? 'Transfer'),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Kaldır'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
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
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class TransferFormSheet extends StatefulWidget {
  final Map<String, dynamic>? transfer;
  final Function(Map<String, dynamic>) onSave;

  const TransferFormSheet({super.key, this.transfer, required this.onSave});

  @override
  State<TransferFormSheet> createState() => _TransferFormSheetState();
}

class _TransferFormSheetState extends State<TransferFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _companyCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _iataCtrl;
  late TextEditingController _fromCtrl;
  late TextEditingController _toCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _durationCtrl;
  String _vehicleType = 'sedan';
  bool _isAirport = true;

  final List<String> _vehicleTypes = ['sedan', 'minivan', 'bus', 'vip'];

  @override
  void initState() {
    super.initState();
    final t = widget.transfer;
    _companyCtrl = TextEditingController(text: t?['company_name'] ?? '');
    _cityCtrl = TextEditingController(text: t?['city_name'] ?? '');
    _iataCtrl = TextEditingController(text: t?['destination_iata'] ?? '');
    _fromCtrl = TextEditingController(text: t?['route_from'] ?? '');
    _toCtrl = TextEditingController(text: t?['route_to'] ?? '');
    _priceCtrl = TextEditingController(text: t?['price_fixed']?.toString() ?? '');
    _durationCtrl = TextEditingController(text: t?['duration_minutes']?.toString() ?? '');
    _vehicleType = t?['vehicle_type'] ?? 'sedan';
    _isAirport = t?['is_airport_transfer'] ?? true;
  }

  @override
  void dispose() {
    _companyCtrl.dispose();
    _cityCtrl.dispose();
    _iataCtrl.dispose();
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _priceCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave({
      'company_name': _companyCtrl.text,
      'city_name': _cityCtrl.text,
      'destination_iata': _iataCtrl.text.toUpperCase(),
      'route_from': _fromCtrl.text,
      'route_to': _toCtrl.text,
      'price_fixed': double.parse(_priceCtrl.text),
      'duration_minutes': int.tryParse(_durationCtrl.text),
      'vehicle_type': _vehicleType,
      'is_airport_transfer': _isAirport,
      'capacity': _vehicleType == 'minivan' ? 8 : _vehicleType == 'bus' ? 20 : 4,
      'is_active': true,
      'commission_rate': 0.10,
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
                widget.transfer != null ? '✏️ Transferi Düzenle' : '➕ Yeni Transfer Ekle',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              _field(_companyCtrl, 'Firma Adı', 'Örn: Antalya VIP'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _field(_cityCtrl, 'Şehir', 'Antalya')),
                  const SizedBox(width: 10),
                  Expanded(child: _field(_iataCtrl, 'IATA', 'AYT', maxLength: 3)),
                ],
              ),
              const SizedBox(height: 10),
              _field(_fromCtrl, 'Nereden', 'Antalya Havalimanı'),
              const SizedBox(height: 10),
              _field(_toCtrl, 'Nereye', 'Şehir Merkezi'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _field(_priceCtrl, 'Fiyat (TL)', '350', isNumber: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _field(_durationCtrl, 'Süre (dk)', '30', isNumber: true)),
                ],
              ),
              const SizedBox(height: 10),
              const Text('Araç Tipi',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: _vehicleTypes.map((type) {
                  final isSelected = _vehicleType == type;
                  return GestureDetector(
                    onTap: () => setState(() => _vehicleType = type),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0EA5E9) : AppTheme.background,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF0EA5E9)
                              : Colors.black.withOpacity(0.1),
                        ),
                      ),
                      child: Text(
                        type,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white : AppTheme.textMuted,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('Havalimanı Transferi',
                      style: TextStyle(fontSize: 13)),
                  const Spacer(),
                  Switch(
                    value: _isAirport,
                    onChanged: (v) => setState(() => _isAirport = v),
                    activeColor: const Color(0xFF0EA5E9),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0EA5E9),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    widget.transfer != null ? 'Güncelle' : 'Ekle',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, String hint,
      {bool isNumber = false, int? maxLength}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        const SizedBox(height: 4),
        TextFormField(
          controller: ctrl,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          maxLength: maxLength,
          validator: (v) => v!.isEmpty ? '$label zorunlu' : null,
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            filled: true,
            fillColor: AppTheme.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF0EA5E9)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}