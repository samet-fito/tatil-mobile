import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GuestInfoScreen extends StatefulWidget {
  final String cityName;
  final int totalPrice;
  final VoidCallback onComplete;

  const GuestInfoScreen({
    super.key,
    required this.cityName,
    required this.totalPrice,
    required this.onComplete,
  });

  @override
  State<GuestInfoScreen> createState() => _GuestInfoScreenState();
}

class _GuestInfoScreenState extends State<GuestInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _idController = TextEditingController();
  bool _isPassport = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _idController.dispose();
    super.dispose();
  }

  String _formatPrice(int price) {
    return '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} TL';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.pop(context);
    widget.onComplete();
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
          'Rezervasyon Bilgileri',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Özet kart
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Text('✈️', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.cityName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.accent,
                        ),
                      ),
                      Text(
                        _formatPrice(widget.totalPrice),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Kişisel Bilgiler
            _sectionTitle('👤 Kişisel Bilgiler'),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _nameController,
                    label: 'Ad',
                    hint: 'Adınız',
                    validator: (v) =>
                        v!.isEmpty ? 'Ad zorunludur' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    controller: _surnameController,
                    label: 'Soyad',
                    hint: 'Soyadınız',
                    validator: (v) =>
                        v!.isEmpty ? 'Soyad zorunludur' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildField(
              controller: _emailController,
              label: 'E-posta',
              hint: 'ornek@email.com',
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v!.isEmpty) return 'E-posta zorunludur';
                if (!v.contains('@')) return 'Geçerli e-posta girin';
                return null;
              },
            ),
            const SizedBox(height: 12),

            _buildField(
              controller: _phoneController,
              label: 'Telefon',
              hint: '05XX XXX XX XX',
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  v!.isEmpty ? 'Telefon zorunludur' : null,
            ),
            const SizedBox(height: 24),

            // Kimlik Bilgileri
            _sectionTitle('🪪 Kimlik Bilgileri'),
            const SizedBox(height: 12),

            // Toggle: TC / Pasaport
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.black.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _isPassport = false),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !_isPassport
                              ? AppTheme.accent
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '🇹🇷 T.C. Kimlik No',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: !_isPassport
                                  ? Colors.white
                                  : AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _isPassport = true),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _isPassport
                              ? AppTheme.accent
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '🌍 Pasaport No',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _isPassport
                                  ? Colors.white
                                  : AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            _buildField(
              controller: _idController,
              label: _isPassport ? 'Pasaport No' : 'T.C. Kimlik No',
              hint: _isPassport ? 'A12345678' : '12345678901',
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v!.isEmpty) return 'Bu alan zorunludur';
                if (!_isPassport && v.length != 11) {
                  return 'T.C. Kimlik No 11 haneli olmalıdır';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Devam butonu
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      )
                    : const Text(
                        'Rezervasyonu Tamamla',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              '🔒 Bilgileriniz SSL ile şifrelenerek güvenle saklanır.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                color: AppTheme.textMuted, fontSize: 14),
            filled: true,
            fillColor: AppTheme.cardBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: Colors.black.withOpacity(0.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: Colors.black.withOpacity(0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppTheme.accent, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}