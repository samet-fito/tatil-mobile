import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../data/explore_promotions.dart';
import '../models/app_search_selection.dart';
import '../models/search_category.dart';
import '../services/api_service.dart';
import '../services/recent_destination_store.dart';
import '../services/route_search_service.dart';
import '../theme/custom_page_route.dart';
import '../theme/tatil_theme.dart';
import '../utils/app_navigation.dart';
import '../widgets/explore_top_section.dart';
import 'app_search_screen.dart';
import 'detailed_search_screen.dart';
import '../widgets/help_support_sheet.dart';

/// Keşfet sekmesi — üst kategorilere göre arama kartı ve sonuç akışı.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  SearchCategory _category = SearchCategory.packageTour;
  AppSearchSelection? _searchSelection;
  String? _initialOriginIata;
  String? _initialOriginCity;
  String? _pendingCouponCode;
  int _formGeneration = 0;

  void _onCampaignTap(ExploreCampaign campaign) {
    setState(() {
      _category = campaign.category;
      _pendingCouponCode = campaign.code;
      _formGeneration++;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${campaign.code} kodu ödeme adımında uygulanabilir — ${campaign.discountLabel}',
        ),
        backgroundColor: TatilTheme.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _onQuickRouteTap(ExploreQuickRoute route) {
    setState(() {
      _category = route.category;
      _searchSelection = AppSearchSelection(
        category: route.category,
        destinationIata: route.destinationIata,
        destinationCity: route.destinationCity,
        destinationCountry: route.destinationCountry,
      );
      _initialOriginIata = route.originIata;
      _initialOriginCity = route.originCity;
      _formGeneration++;
    });
    unawaited(
      RecentDestinationStore.record(
        iataCode: route.destinationIata,
        cityName: route.destinationCity,
        country: route.destinationCountry,
      ),
    );
  }

  void _onRegionalDealTap(ExploreRegionalDeal deal) {
    _onQuickRouteTap(deal.route);
    if (!mounted) return;
    if (deal.isUrgent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${deal.route.label} · ${deal.subtitle}',
          ),
          backgroundColor: TatilTheme.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    ExploreSearchController.instance.attach((category) {
      if (mounted) setState(() => _category = category);
    });
    initializeDateFormatting('tr_TR', null);
    ApiService.warmGateway();
    RouteSearchService.prewarm();
  }

  @override
  void dispose() {
    ExploreSearchController.instance.detach();
    super.dispose();
  }

  Future<void> _openAppSearch() async {
    final result = await pushAppRoute<AppSearchSelection>(
      context,
      AppSearchScreen(currentCategory: _category),
    );
    if (result == null || !mounted) return;
    if (result.action == AppSearchAction.openHelp) {
      showHelpSupportSheet(context);
      return;
    }
    setState(() {
      if (result.category != null) _category = result.category!;
      _searchSelection = result.hasDestination ? result : null;
    });
    if (result.hasDestination) {
      unawaited(
        RecentDestinationStore.record(
          iataCode: result.destinationIata!,
          cityName: result.destinationCity!,
          country: result.destinationCountry ?? '',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selection = _searchSelection;
    return Scaffold(
      backgroundColor: TatilTheme.bgSoft,
      body: Column(
        children: [
          ExploreTopSection(
            selected: _category,
            onSelected: (c) => setState(() => _category = c),
            onSearchTap: _openAppSearch,
          ),
          Expanded(
            child: DetailedSearchScreen(
              key: ValueKey(
                'gen$_formGeneration'
                '_${_category.name}'
                '_${selection?.destinationIata ?? ''}',
              ),
              category: _category,
              initialDestinationIata: selection?.destinationIata,
              initialDestinationCity: selection?.destinationCity,
              initialDestinationCountry: selection?.destinationCountry,
              initialOriginIata: _initialOriginIata,
              initialOriginCity: _initialOriginCity,
              pendingCouponCode: _pendingCouponCode,
              onCampaignTap: _onCampaignTap,
              onRegionalDealTap: _onRegionalDealTap,
            ),
          ),
        ],
      ),
    );
  }
}
