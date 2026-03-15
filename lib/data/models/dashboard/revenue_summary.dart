class RevenueSummary {
  final double todayRevenue;
  final double yesterdayRevenue;
  final double thisWeekRevenue;
  final double lastWeekRevenue;
  final double thisMonthRevenue;
  final double lastMonthRevenue;
  final double todayChangePercent;
  final double weekChangePercent;
  final double monthChangePercent;
  final int todayTransactionCount;
  final int thisWeekTransactionCount;
  final int thisMonthTransactionCount;
  final double averageTransactionValue;

  const RevenueSummary({
    required this.todayRevenue,
    required this.yesterdayRevenue,
    required this.thisWeekRevenue,
    required this.lastWeekRevenue,
    required this.thisMonthRevenue,
    required this.lastMonthRevenue,
    required this.todayChangePercent,
    required this.weekChangePercent,
    required this.monthChangePercent,
    required this.todayTransactionCount,
    required this.thisWeekTransactionCount,
    required this.thisMonthTransactionCount,
    required this.averageTransactionValue,
  });

  factory RevenueSummary.fromJson(Map<String, dynamic> json) {
    return RevenueSummary(
      todayRevenue: (json['todayRevenue'] as num?)?.toDouble() ?? 0,
      yesterdayRevenue: (json['yesterdayRevenue'] as num?)?.toDouble() ?? 0,
      thisWeekRevenue: (json['thisWeekRevenue'] as num?)?.toDouble() ?? 0,
      lastWeekRevenue: (json['lastWeekRevenue'] as num?)?.toDouble() ?? 0,
      thisMonthRevenue: (json['thisMonthRevenue'] as num?)?.toDouble() ?? 0,
      lastMonthRevenue: (json['lastMonthRevenue'] as num?)?.toDouble() ?? 0,
      todayChangePercent:
          (json['todayChangePercent'] as num?)?.toDouble() ?? 0,
      weekChangePercent:
          (json['weekChangePercent'] as num?)?.toDouble() ?? 0,
      monthChangePercent:
          (json['monthChangePercent'] as num?)?.toDouble() ?? 0,
      todayTransactionCount:
          (json['todayTransactionCount'] as num?)?.toInt() ?? 0,
      thisWeekTransactionCount:
          (json['thisWeekTransactionCount'] as num?)?.toInt() ?? 0,
      thisMonthTransactionCount:
          (json['thisMonthTransactionCount'] as num?)?.toInt() ?? 0,
      averageTransactionValue:
          (json['averageTransactionValue'] as num?)?.toDouble() ?? 0,
    );
  }
}
