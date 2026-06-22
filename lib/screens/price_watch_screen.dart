import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/price_watch.dart';
import '../services/price_watch_store.dart';
import '../theme/app_theme.dart';
import '../theme/tatil_theme.dart';
import '../utils/price_format.dart';

class PriceWatchScreen extends StatefulWidget {
  const PriceWatchScreen({super.key});

  @override
  State<PriceWatchScreen> createState() => _PriceWatchScreenState();
}

class _PriceWatchScreenState extends State<PriceWatchScreen> {
  List<PriceWatch> _watches = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await PriceWatchStore.list();
    if (mounted) {
      setState(() {
        _watches = list;
        _loading = false;
      });
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TatilTheme.bgSoft,
      appBar: AppBar(
        title: const Text('Fiyat Alarmlarım'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CupertinoActivityIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _watches.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppTheme.bgSecondary,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                CupertinoIcons.bell,
                                size: 48,
                                color: AppTheme.orange.withValues(alpha: 0.7),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Henüz fiyat alarmınız yok',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Rota sonuçlarında çan ikonuna basarak hedef fiyat belirleyin. '
                                'Fiyat düştüğünde bildirim alırsınız.',
                                textAlign: TextAlign.center,
                                style: TatilTheme.hint.copyWith(height: 1.45),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _watches.length,
                      itemBuilder: (context, i) {
                        final w = _watches[i];
                        final met = w.isTargetMet;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.bgSecondary,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: met
                                  ? AppTheme.teal.withValues(alpha: 0.4)
                                  : AppTheme.border,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      w.cityName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (met)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.teal.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                      child: const Text(
                                        'Hedefe ulaştı',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.teal,
                                        ),
                                      ),
                                    ),
                                  IconButton(
                                    icon: const Icon(
                                      CupertinoIcons.trash,
                                      size: 18,
                                      color: AppTheme.textMuted,
                                    ),
                                    onPressed: () async {
                                      await PriceWatchStore.remove(w.id);
                                      _load();
                                    },
                                  ),
                                ],
                              ),
                              Text(
                                '${w.routeLabel} · ${_fmtDate(w.departureDate)} – ${_fmtDate(w.returnDate)}',
                                style: TatilTheme.hint.copyWith(fontSize: 12),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _priceCol(
                                    'Hedef',
                                    PriceFormat.format(w.targetPriceTL),
                                    AppTheme.teal,
                                  ),
                                  _priceCol(
                                    'Son görülen',
                                    PriceFormat.format(w.lastSeenPriceTL),
                                    AppTheme.textPrimary,
                                  ),
                                  _priceCol(
                                    'Fark',
                                    w.lastSeenPriceTL > 0
                                        ? PriceFormat.format(
                                            (w.lastSeenPriceTL - w.targetPriceTL)
                                                .abs(),
                                          )
                                        : '—',
                                    w.isTargetMet
                                        ? AppTheme.teal
                                        : AppTheme.orange,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _priceCol(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TatilTheme.hint.copyWith(fontSize: 10)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Rota kartından fiyat alarmı oluşturma sheet'i.
abstract final class PriceWatchSheet {
  static Future<void> show(
    BuildContext context, {
    required String originIata,
    required String destinationIata,
    required String cityName,
    required String country,
    required DateTime departureDate,
    required DateTime returnDate,
    required int currentPriceTL,
    int passengers = 1,
    int nights = 5,
  }) async {
    var target = (currentPriceTL * 0.9).round().clamp(5000, 9999999);

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppTheme.bgSecondary,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fiyat alarmı kur',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$cityName · Güncel ${PriceFormat.format(currentPriceTL)}',
                      style: TatilTheme.hint.copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Hedef fiyat: ${PriceFormat.format(target)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Slider(
                      value: target.toDouble(),
                      min: (currentPriceTL * 0.7).clamp(5000, 9999999).toDouble(),
                      max: currentPriceTL.toDouble(),
                      divisions: 20,
                      activeColor: AppTheme.orange,
                      onChanged: (v) => setSheet(() => target = v.round()),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Alarmı kaydet',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (saved != true || !context.mounted) return;

    await PriceWatchStore.add(
      originIata: originIata,
      destinationIata: destinationIata,
      cityName: cityName,
      country: country,
      departureDate: departureDate,
      returnDate: returnDate,
      targetPriceTL: target,
      currentPriceTL: currentPriceTL,
      passengers: passengers,
      nights: nights,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$cityName için ${PriceFormat.format(target)} altı alarm kuruldu',
          ),
          backgroundColor: AppTheme.teal,
        ),
      );
    }
  }
}
