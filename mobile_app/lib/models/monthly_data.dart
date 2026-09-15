class MonthlyData {
  final String label;
  final DateTime date;
  double revenue;
  double cost;

  MonthlyData(this.label, this.date, this.revenue, this.cost);

  double get profit => revenue - cost;
  double get margin => revenue > 0 ? (profit / revenue) * 100 : 0;
}
