import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';

import '../data/bundled_destinations.dart';
import '../models/app_search_selection.dart';
import '../models/destination_model.dart';
import '../models/search_category.dart';
import '../services/api_service.dart';
import '../services/recent_destination_store.dart';
import '../theme/custom_page_route.dart';
import '../theme/tatil_theme.dart';
import '../utils/destination_catalog.dart';
import 'ai_assistant_screen.dart';
import 'medical_search_screen.dart';
import 'my_reservations_screen.dart';

class _SearchEntry {
  const _SearchEntry({
    required this.title,
    required this.subtitle,
    required this.keywords,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final List<String> keywords;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  bool matches(String query) {
    if (query.isEmpty) return true;
    final haystack = '$title $subtitle ${keywords.join(' ')}'.toLowerCase();
    return haystack.contains(query);
  }
}

/// Uygulama içi genel arama — hizmetler, destinasyonlar ve sayfalar.
class AppSearchScreen extends StatefulWidget {
  const AppSearchScreen({super.key, this.currentCategory});

  final SearchCategory? currentCategory;

  @override
  State<AppSearchScreen> createState() => _AppSearchScreenState();
}

class _AppSearchScreenState extends State<AppSearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';
  List<DestinationModel> _destinations = [];
  List<DestinationModel> _recentDestinations = [];
  bool _loadingDestinations = true;

  @override
  void initState() {
    super.initState();
    _loadDestinations();
    _loadRecent();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    final recent = await RecentDestinationStore.load();
    if (mounted) setState(() => _recentDestinations = recent);
  }

  Future<void> _loadDestinations() async {
    final bundled = DestinationCatalog.parseAll(BundledDestinations.raw);
    setState(() {
      _destinations = bundled;
      _loadingDestinations = true;
    });

    final raw = await ApiService.getDestinations();
    if (!mounted) return;
    final list = DestinationCatalog.parseAll(raw);
    setState(() {
      _destinations = list.isNotEmpty ? list : bundled;
      _loadingDestinations = false;
    });
  }

  String get _normalizedQuery => _query.trim().toLowerCase();

  List<_SearchEntry> get _serviceEntries => [
        for (final category in SearchCategory.values)
          _SearchEntry(
            title: category.label,
            subtitle: category.headerSubtitle,
            keywords: [
              category.label,
              category.gridLabel,
              category.searchButtonLabel,
              category.headerSubtitle,
            ],
            icon: category.icon,
            iconColor: TatilTheme.orange,
            onTap: () => _popWith(
              AppSearchSelection(category: category),
            ),
          ),
      ];

  List<_SearchEntry> get _pageEntries => [
        _SearchEntry(
          title: 'Rezervasyonlarım',
          subtitle: 'Seyahat kartı ve belgeler',
          keywords: ['rezervasyon', 'seyahat kartı', 'bilet', 'voucher'],
          icon: CupertinoIcons.doc_text,
          iconColor: TatilTheme.orange,
          onTap: () => _openPage(const MyReservationsScreen()),
        ),
        _SearchEntry(
          title: 'AI Asistan',
          subtitle: 'Tatil planında yardım al',
          keywords: ['ai', 'asistan', 'sohbet', 'plan'],
          icon: CupertinoIcons.sparkles,
          iconColor: TatilTheme.orange,
          onTap: () => _openPage(const AiAssistantScreen()),
        ),
        _SearchEntry(
          title: 'Sağlık Turizmi',
          subtitle: 'Tedavi ve konaklama paketleri',
          keywords: ['sağlık', 'klinik', 'tedavi', 'medical'],
          icon: CupertinoIcons.heart,
          iconColor: const Color(0xFF0D9488),
          onTap: () => _openPage(const MedicalSearchScreen()),
        ),
        _SearchEntry(
          title: 'Yardım & Destek',
          subtitle: 'SSS ve iletişim',
          keywords: ['yardım', 'destek', 'sss', 'soru'],
          icon: CupertinoIcons.question_circle,
          iconColor: TatilTheme.textMuted,
          onTap: () => _popWith(
            const AppSearchSelection(action: AppSearchAction.openHelp),
          ),
        ),
      ];

  List<DestinationModel> get _filteredDestinations {
    final q = _normalizedQuery;
    if (q.isEmpty) {
      return _destinations.take(8).toList();
    }
    return _destinations
        .where(
          (d) =>
              d.cityName.toLowerCase().contains(q) ||
              d.country.toLowerCase().contains(q) ||
              d.iataCode.toLowerCase().contains(q),
        )
        .take(12)
        .toList();
  }

  void _popWith(AppSearchSelection selection) {
    Navigator.pop(context, selection);
  }

  void _openPage(Widget page) {
    Navigator.pop(context);
    pushAppRoute(context, page);
  }

  void _selectDestination(DestinationModel destination) {
    unawaited(
      RecentDestinationStore.record(
        iataCode: destination.iataCode,
        cityName: destination.cityName,
        country: destination.country,
      ),
    );
    _popWith(
      AppSearchSelection(
        category: widget.currentCategory ?? SearchCategory.packageTour,
        destinationIata: destination.iataCode,
        destinationCity: destination.cityName,
        destinationCountry: destination.country,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _normalizedQuery;
    final services = _serviceEntries.where((e) => e.matches(q)).toList();
    final pages = _pageEntries.where((e) => e.matches(q)).toList();
    final destinations = _filteredDestinations;
    final hasResults =
        services.isNotEmpty || pages.isNotEmpty || destinations.isNotEmpty;

    return Scaffold(
      backgroundColor: TatilTheme.bgSoft,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: TatilTheme.textDark,
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          textInputAction: TextInputAction.search,
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'Destinasyon, hizmet veya sayfa ara…',
            hintStyle: GoogleFonts.inter(
              fontSize: 15,
              color: TatilTheme.textMuted,
              fontWeight: FontWeight.w500,
            ),
            border: InputBorder.none,
            isDense: true,
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              color: TatilTheme.textMuted,
              onPressed: () {
                _controller.clear();
                setState(() => _query = '');
                _focusNode.requestFocus();
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (widget.currentCategory != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: TatilTheme.orangeSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: TatilTheme.orange.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.currentCategory!.icon,
                      size: 18,
                      color: TatilTheme.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Seçili kategori: ${widget.currentCategory!.label}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: TatilTheme.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (!hasResults && q.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 48,
                    color: TatilTheme.textMuted.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sonuç bulunamadı',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: TatilTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Farklı bir anahtar kelime deneyin',
                    style: TatilTheme.hint,
                  ),
                ],
              ),
            )
          else ...[
            if (_normalizedQuery.isEmpty && _recentDestinations.isNotEmpty) ...[
              _sectionTitle('Son arananlar'),
              ..._recentDestinations.map(_destinationTile),
              const SizedBox(height: 16),
            ],
            if (destinations.isNotEmpty) ...[
              _sectionTitle(q.isEmpty ? 'Popüler destinasyonlar' : 'Destinasyonlar'),
              ...destinations.map(_destinationTile),
              const SizedBox(height: 16),
            ] else if (_loadingDestinations) ...[
              _sectionTitle('Destinasyonlar'),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: TatilTheme.orange,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (services.isNotEmpty) ...[
              _sectionTitle('Hizmetler'),
              ...services.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _entryTile(e),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (pages.isNotEmpty) ...[
              _sectionTitle('Uygulama'),
              ...pages.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _entryTile(e),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: TatilTheme.textMuted,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _entryTile(_SearchEntry entry) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: entry.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: entry.iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(entry.icon, size: 20, color: entry.iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: TatilTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.subtitle,
                      style: TatilTheme.hint.copyWith(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: TatilTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _destinationTile(DestinationModel destination) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _selectDestination(destination),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: TatilTheme.orangeSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    destination.iataCode,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: TatilTheme.orange,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        destination.cityName,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: TatilTheme.textDark,
                        ),
                      ),
                      Text(
                        destination.country,
                        style: TatilTheme.hint.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: TatilTheme.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
