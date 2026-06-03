import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class ClinicRegisterScreen extends StatefulWidget {
  const ClinicRegisterScreen({super.key});

  @override
  State<ClinicRegisterScreen> createState() => _ClinicRegisterScreenState();
}

class _ClinicRegisterScreenState extends State<ClinicRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String _specialty = 'Sac Ekimi';
  bool _isLoading = false;
  bool _submitted = false;

  final List<String> _specialties = [
    'Sac Ekimi',
    'Dis Estetigi',
    'Burun Estetigi',
    'Goz Lazer',
    'Obezite Cerrahisi',
    'Meme Estetigi',
    'Liposuction',
    'Yuz Estetigi',
    'Genel Cerrahi',
    'Diger',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _websiteCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final success = await ApiService.registerClinic(
        name: _nameCtrl.text,
        specialty: _specialty,
        cityName: _cityCtrl.text,
        contactEmail: _emailCtrl.text,
        contactPhone: _phoneCtrl.text,
        website: _websiteCtrl.text,
        address: _addressCtrl.text,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _submitted = success;
        });
        if (!success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hata olustu. Tekrar deneyin.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
          icon: const Icon(CupertinoIcons.arrow_left,
              color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Klinik Basvurusu',
          style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700),
        ),
      ),
      body: _submitted ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(CupertinoIcons.checkmark_circle,
                  color: AppTheme.teal, size: 40),
            ),
            const SizedBox(height: 24),
            const Text(
              'Basvurunuz Alindi!',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            const Text(
              '2-3 is gunu icinde ekibimiz sizinle iletisime gececek. Basvurunuz onaylandiginda kliniklerimiz arasinda yer alacaksiniz.',
              style: TextStyle(
                  fontSize: 14, color: AppTheme.textMuted, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.teal,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text(
                    'Ana Sayfaya Don',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst bilgi kartı
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.teal.withOpacity(0.15),
                    AppTheme.teal.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.teal.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.building_2_fill,
                      color: AppTheme.teal, size: 32),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vizegoo Partner Ol',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.teal),
                        ),
                        Text(
                          'Binlerce hastaya ulasin, komisyon kazanin',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _field(_nameCtrl, 'Klinik Adi', 'Ornek: Antalya Hair Clinic'),
            const SizedBox(height: 12),

            _label('Uzmanlik Alani'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _specialty,
              dropdownColor: AppTheme.bgSecondary,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.bgSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.teal),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
              items: _specialties
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _specialty = v ?? _specialty),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                    child: _field(_cityCtrl, 'Sehir', 'Antalya')),
                const SizedBox(width: 12),
                Expanded(
                    child: _field(_phoneCtrl, 'Telefon', '+90 xxx')),
              ],
            ),
            const SizedBox(height: 12),

            _field(_emailCtrl, 'E-posta', 'info@klinik.com',
                isEmail: true),
            const SizedBox(height: 12),

            _field(_websiteCtrl, 'Website', 'www.klinik.com'),
            const SizedBox(height: 12),

            _field(_addressCtrl, 'Adres', 'Tam adres'),
            const SizedBox(height: 24),

            // Avantajlar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.bgSecondary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Partner Avantajlari',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  _advantageRow(CupertinoIcons.person_2,
                      'Binlerce potansiyel hastaya erisim'),
                  _advantageRow(CupertinoIcons.money_dollar_circle,
                      'Her rezervasyondan komisyon geliri'),
                  _advantageRow(CupertinoIcons.checkmark_shield,
                      'Vizegoo guven rozeti'),
                  _advantageRow(CupertinoIcons.chart_bar,
                      'Detayli analitik ve raporlama'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: _isLoading ? null : _submit,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.teal, AppTheme.teal.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2)
                        : const Text(
                            'Basvuruyu Gonder',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _advantageRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.teal, size: 16),
          const SizedBox(width: 10),
          Text(text,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.textMuted));
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    String hint, {
    bool isEmail = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 4),
        TextFormField(
          controller: ctrl,
          keyboardType:
              isEmail ? TextInputType.emailAddress : TextInputType.text,
          style: const TextStyle(color: AppTheme.textPrimary),
          validator: (v) => v!.isEmpty ? '$label zorunludur' : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppTheme.textMuted),
            filled: true,
            fillColor: AppTheme.bgSecondary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.teal),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}