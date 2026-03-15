class RevenueChartData {
  final String label;
  final double value;
  final int count;

  const RevenueChartData({
    required this.label,
    required this.value,
    required this.count,
  });

  factory RevenueChartData.fromJson(Map<String, dynamic> json) {
    return RevenueChartData(
      label: json['label'] as String,
      value: (json['value'] as num?)?.toDouble() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}
