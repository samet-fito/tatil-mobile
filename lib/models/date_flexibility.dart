/// Takvimde tarih esnekliği — arama ve fiyat gösterimini etkiler.
enum DateFlexibility {
  exact('Tam tarih'),
  dateRange('Tarih aralığı'),
  plusMinus1('± 1 gün'),
  plusMinus2('± 2 gün');

  const DateFlexibility(this.labelTr);
  final String labelTr;

  int get flexDays => switch (this) {
        DateFlexibility.exact => 0,
        DateFlexibility.dateRange => 0,
        DateFlexibility.plusMinus1 => 1,
        DateFlexibility.plusMinus2 => 2,
      };
}
