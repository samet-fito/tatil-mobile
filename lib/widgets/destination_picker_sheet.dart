import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/destination_model.dart';
import '../theme/tatil_theme.dart';

/// Destinasyon seçimi — aranabilir alt sayfa (dropdown yerine).
/// `iataCode` boş dönerse → herhangi bir yer.
Future<DestinationModel?> showDestinationPickerSheet(
  BuildContext context, {
  required List<DestinationModel> destinations,
  String? selectedIata,
}) {
  return showModalBottomSheet<DestinationModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _DestinationPickerSheet(
      destinations: destinations,
      selectedIata: selectedIata,
    ),
  );
}

class _DestinationPickerSheet extends StatefulWidget {
  const _DestinationPickerSheet({
    required this.destinations,
    required this.selectedIata,
  });

  final List<DestinationModel> destinations;
  final String? selectedIata;

  @override
  State<_DestinationPickerSheet> createState() =>
      _DestinationPickerSheetState();
}

class _DestinationPickerSheetState extends State<_DestinationPickerSheet> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<DestinationModel> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.destinations;
    return widget.destinations.where((d) {
      return d.cityName.toLowerCase().contains(q) ||
          d.country.toLowerCase().contains(q) ||
          d.iataCode.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final filtered = _filtered;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: TatilTheme.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Text(
                'Destinasyon seç',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _search,
                decoration: InputDecoration(
                  hintText: 'Şehir veya ülke ara…',
                  prefixIcon: const Icon(Icons.search, size: 22),
                  filled: true,
                  fillColor: const Color(0xFFF9F9F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: TatilTheme.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: TatilTheme.border),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.public, color: TatilTheme.orange),
              title: const Text(
                'Herhangi bir yer',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              trailing: widget.selectedIata == null
                  ? const Icon(Icons.check_circle, color: TatilTheme.orange)
                  : null,
              onTap: () => Navigator.pop(
                context,
                const DestinationModel(
                  iataCode: '',
                  cityName: 'Herhangi bir yer',
                  country: '',
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'Sonuç bulunamadı',
                        style: TatilTheme.hint,
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final d = filtered[i];
                        final selected = d.iataCode == widget.selectedIata;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: TatilTheme.orangeSoft,
                            child: Text(
                              d.iataCode,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: TatilTheme.orange,
                              ),
                            ),
                          ),
                          title: Text(
                            d.cityName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(d.country),
                          trailing: selected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: TatilTheme.orange,
                                )
                              : null,
                          onTap: () => Navigator.pop(context, d),
                        );
                      },
                    ),
            ),
            SizedBox(height: bottom + 8),
          ],
        ),
      ),
    );
  }
}
