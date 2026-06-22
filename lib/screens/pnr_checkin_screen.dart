import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../theme/tatil_theme.dart';

/// PNR sorgulama ve online check-in — Turna tarzı satış sonrası hub.
class PnrCheckinScreen extends StatefulWidget {
  const PnrCheckinScreen({super.key});

  @override
  State<PnrCheckinScreen> createState() => _PnrCheckinScreenState();
}

class _PnrCheckinScreenState extends State<PnrCheckinScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _pnrCtrl = TextEditingController();
  final _surnameCtrl = TextEditingController();
  bool _lookedUp = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _pnrCtrl.dispose();
    _surnameCtrl.dispose();
    super.dispose();
  }

  void _lookup() {
    if (_pnrCtrl.text.trim().length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Geçerli bir PNR kodu girin (en az 5 karakter)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _lookedUp = true);
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
          'PNR & Check-in',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppTheme.orange,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorColor: AppTheme.orange,
          tabs: const [
            Tab(text: 'PNR Sorgula'),
            Tab(text: 'Online Check-in'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildLookupTab(checkInMode: false),
          _buildLookupTab(checkInMode: true),
        ],
      ),
    );
  }

  Widget _buildLookupTab({required bool checkInMode}) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.orangeSoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.orange.withValues(alpha: 0.25)),
          ),
          child: Text(
            checkInMode
                ? 'Vizegoo üzerinden aldığınız biletin check-in işlemini buradan başlatın. '
                    'Havayolu sayfasına yönlendirilirsiniz.'
                : 'Rezervasyon numaranız (PNR) ile bilet durumunuzu görüntüleyin. '
                    'Vizegoo dışından alınan biletlerde havayolu sitesine yönlendirilirsiniz.',
            style: const TextStyle(fontSize: 13, height: 1.45),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _pnrCtrl,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]'))],
          decoration: const InputDecoration(
            labelText: 'Rezervasyon no (PNR)',
            hintText: 'Örn. VG12AB34',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _surnameCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Yolcu soyadı',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _lookup,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              checkInMode ? 'Check-in Başlat' : 'Rezervasyonu Bul',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        if (_lookedUp) ...[
          const SizedBox(height: 24),
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
                Row(
                  children: [
                    Icon(
                      checkInMode
                          ? CupertinoIcons.airplane
                          : CupertinoIcons.checkmark_seal_fill,
                      color: AppTheme.teal,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        checkInMode
                            ? 'Check-in için hazır'
                            : 'Rezervasyon bulundu',
                        style: TatilTheme.sectionLabel.copyWith(fontSize: 15),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'PNR: ${_pnrCtrl.text.trim().toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  checkInMode
                      ? 'Check-in genelde uçuştan 24 saat önce açılır. '
                          'Profil → Rezervasyonlarım üzerinden seyahat kartınıza da ulaşabilirsiniz.'
                      : 'Detaylar için Profil → Rezervasyonlarım bölümünü kontrol edin '
                          'veya onay e-postanızdaki bağlantıyı kullanın.',
                  style: TatilTheme.hint.copyWith(height: 1.4),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          checkInMode
                              ? 'Havayolu check-in sayfası açılacak (entegrasyon yakında)'
                              : 'Bilet detayı yüklenecek (entegrasyon yakında)',
                        ),
                        backgroundColor: AppTheme.orange,
                      ),
                    );
                  },
                  icon: const Icon(CupertinoIcons.arrow_up_right_square, size: 18),
                  label: Text(checkInMode ? 'Havayoluna git' : 'Seyahat kartını aç'),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        Text(
          'İpuçları',
          style: TatilTheme.sectionLabel.copyWith(fontSize: 13),
        ),
        const SizedBox(height: 8),
        _tip('PNR kodu e-biletinizde ve onay SMS\'inde yer alır.'),
        _tip('Check-in için pasaport veya kimlik bilgilerinizi hazır bulundurun.'),
        _tip('Vizegoo rezervasyonlarınız otomatik olarak Rezervasyonlarım\'da listelenir.'),
      ],
    );
  }

  Widget _tip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppTheme.orange)),
          Expanded(child: Text(text, style: TatilTheme.hint.copyWith(fontSize: 12))),
        ],
      ),
    );
  }
}
