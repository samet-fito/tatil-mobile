import '../data/country_meta.dart';
import '../models/destination_model.dart';

class DestinationCatalog {
  static List<DestinationModel> parseAll(List<Map<String, dynamic>> raw) {
    return raw
        .map(DestinationModel.fromJson)
        .where((d) => d.iataCode.isNotEmpty && d.cityName.isNotEmpty)
        .toList()
      ..sort((a, b) => a.cityName.compareTo(b.cityName));
  }

  static List<CountryOption> countriesFrom(List<DestinationModel> destinations) {
    final grouped = <String, List<DestinationModel>>{};
    for (final d in destinations) {
      grouped.putIfAbsent(d.country, () => []).add(d);
    }

    final options = grouped.entries.map((entry) {
      final costs = entry.value
          .map((d) => d.costIndex)
          .whereType<double>()
          .toList();
      final avg = costs.isEmpty
          ? null
          : costs.reduce((a, b) => a + b) / costs.length;

      return CountryOption(
        country: entry.key,
        labelTr: CountryMeta.labelTr(entry.key),
        flag: CountryMeta.flag(entry.key),
        continent: CountryMeta.continent(entry.key),
        cities: entry.value,
        avgCostIndex: avg,
      );
    }).toList();

    options.sort((a, b) => a.labelTr.compareTo(b.labelTr));
    return options;
  }

  static List<DestinationModel> filterByCountry(
    List<DestinationModel> all,
    String? country,
  ) {
    if (country == null || country.isEmpty) return all;
    return all.where((d) => d.country == country).toList();
  }

  static List<DestinationModel> filterByContinent(
    List<DestinationModel> all,
    String? continent,
  ) {
    if (continent == null || continent.isEmpty) return all;
    if (continent == 'domestic') {
      return all.where((d) => d.country == 'Turkey').toList();
    }
    return all
        .where((d) => CountryMeta.continent(d.country) == continent)
        .toList();
  }
}
