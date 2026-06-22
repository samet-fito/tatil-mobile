import 'search_category.dart';

enum AppSearchAction { none, openHelp }

/// Keşfet genel aramasından dönen seçim.
class AppSearchSelection {
  const AppSearchSelection({
    this.category,
    this.destinationIata,
    this.destinationCity,
    this.destinationCountry,
    this.action = AppSearchAction.none,
  });

  final SearchCategory? category;
  final String? destinationIata;
  final String? destinationCity;
  final String? destinationCountry;
  final AppSearchAction action;

  bool get hasDestination =>
      destinationIata != null && destinationCity != null;
}
