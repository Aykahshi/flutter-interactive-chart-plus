import 'trend_line.dart';

class CandleData {
  /// The timestamp of this data point, in milliseconds since epoch.
  final int timestamp;

  /// The "open" price of this data point. It's acceptable to have null here for
  /// a few data points, but they must not all be null. If either [open] or
  /// [close] is null for a data point, it will appear as a gap in the chart.
  final double? open;

  /// The "high" price. If either one of [high] or [low] is null, we won't
  /// draw the narrow part of the candlestick for that data point.
  final double? high;

  /// The "low" price. If either one of [high] or [low] is null, we won't
  /// draw the narrow part of the candlestick for that data point.
  final double? low;

  /// The "close" price of this data point. It's acceptable to have null here
  /// for a few data points, but they must not all be null. If either [open] or
  /// [close] is null for a data point, it will appear as a gap in the chart.
  final double? close;

  /// The volume information of this data point.
  final double? volume;

  /// 趨勢線集合，使用 Map 存儲，key 為趨勢線的 id
  ///
  /// 例如，若要添加 7 日移動平均線，可以使用：
  /// ```dart
  /// trendLines = {'MA7': MALine(7, value: ma7Value)}
  /// ```
  ///
  /// 若要添加多條趨勢線，可以使用：
  /// ```dart
  /// trendLines = {
  ///   'MA7': MALine(7, value: ma7Value),
  ///   'MA30': MALine(30, value: ma30Value),
  /// }
  /// ```
  final Map<String, TrendLine> trendLines;

  /// 向下相容的趨勢線列表
  ///
  /// 這個屬性是為了向下相容而保留的，新的程式碼應該使用 [trendLines] 屬性。
  /// 這是一個不可修改的列表，所以請不要使用 `add` 或 `clear` 方法。
  /// 如果需要修改趨勢線，請使用 [addTrendLine] 或 [removeTrendLine] 方法。
  List<double?> trends;

  CandleData({
    required this.timestamp,
    required this.open,
    required this.close,
    required this.volume,
    this.high,
    this.low,
    Map<String, TrendLine>? trendLines,
    List<double?>? trends,
  })  : this.trendLines = trendLines ?? {},
        this.trends = List.unmodifiable(trends ?? []);

  /// 添加趨勢線
  CandleData addTrendLine(TrendLine trendLine) {
    final newTrendLines = Map<String, TrendLine>.from(trendLines);
    newTrendLines[trendLine.id] = trendLine;

    return CandleData(
      timestamp: timestamp,
      open: open,
      close: close,
      high: high,
      low: low,
      volume: volume,
      trendLines: newTrendLines,
      trends: trends,
    );
  }

  /// 移除趨勢線
  CandleData removeTrendLine(String trendLineId) {
    final newTrendLines = Map<String, TrendLine>.from(trendLines);
    newTrendLines.remove(trendLineId);

    return CandleData(
      timestamp: timestamp,
      open: open,
      close: close,
      high: high,
      low: low,
      volume: volume,
      trendLines: newTrendLines,
      trends: trends,
    );
  }

  /// 從 trendLines Map 創建舊的 trends 列表
  static List<double?> trendMapToList(Map<String, TrendLine> trendLines) {
    final result = <double?>[];
    final sortedKeys = trendLines.keys.toList()..sort();
    for (final key in sortedKeys) {
      result.add(trendLines[key]?.value);
    }
    return List.unmodifiable(result);
  }

  /// 計算移動平均線並返回值列表
  static List<double?> computeMA(List<CandleData> data, [int period = 7]) {
    // If data is not at least twice as long as the period, return nulls.
    if (data.length < period * 2) return List.filled(data.length, null);

    final List<double?> result = [];
    // Skip the first [period] data points. For example, skip 7 data points.
    final firstPeriod =
        data.take(period).map((d) => d.close).whereType<double>();
    double ma = firstPeriod.reduce((a, b) => a + b) / firstPeriod.length;
    result.addAll(List.filled(period, null));

    // Compute the moving average for the rest of the data points.
    for (int i = period; i < data.length; i++) {
      final curr = data[i].close;
      final prev = data[i - period].close;
      if (curr != null && prev != null) {
        ma = (ma * period + curr - prev) / period;
        result.add(ma);
      } else {
        result.add(null);
      }
    }
    return result;
  }

  /// 計算移動平均線並返回帶有趨勢線的蠟燭資料列表
  static List<CandleData> computeMAWithTrendLine(
    List<CandleData> data,
    int period,
  ) {
    final maValues = computeMA(data, period);
    final result = <CandleData>[];

    for (int i = 0; i < data.length; i++) {
      final candle = data[i];
      final trendLine = MALine(period, value: maValues[i]);

      result.add(candle.addTrendLine(trendLine));
    }

    return result;
  }

  /// 計算指數移動平均線並返回值列表
  static List<double?> computeEMA(List<CandleData> data, [int period = 7]) {
    if (data.length < period * 2) return List.filled(data.length, null);

    final List<double?> result = [];
    // 填充前 period 個值為 null
    result.addAll(List.filled(period, null));

    // 計算第一個 EMA 值（使用簡單移動平均作為初始值）
    final firstPeriod =
        data.take(period).map((d) => d.close).whereType<double>().toList();
    if (firstPeriod.isEmpty) return List.filled(data.length, null);

    double ema = firstPeriod.reduce((a, b) => a + b) / firstPeriod.length;

    // 計算權重因子
    final multiplier = 2.0 / (period + 1);

    // 計算剩餘資料點的 EMA
    for (int i = period; i < data.length; i++) {
      final curr = data[i].close;
      if (curr != null) {
        ema = (curr - ema) * multiplier + ema;
        result.add(ema);
      } else {
        result.add(null);
      }
    }

    return result;
  }

  static List<CandleData> convertToWeekly(List<CandleData> dailyCandles) {
    if (dailyCandles.isEmpty) return [];

    // candle data group by week
    Map<int, List<CandleData>> weeklyGroups = {};

    for (var candle in dailyCandles) {
      // get the week of the date
      DateTime date = DateTime.fromMillisecondsSinceEpoch(candle.timestamp);
      // calculate the first day of the week (Monday)
      DateTime weekStart = date.subtract(Duration(days: date.weekday - 1));
      int weekKey = DateTime(weekStart.year, weekStart.month, weekStart.day)
          .millisecondsSinceEpoch;

      if (!weeklyGroups.containsKey(weekKey)) {
        weeklyGroups[weekKey] = [];
      }
      weeklyGroups[weekKey]!.add(candle);
    }

    // merge weekly candle data
    List<CandleData> weeklyCandles = [];
    weeklyGroups.forEach((timestamp, candles) {
      if (candles.isEmpty) return;

      // open price of the week
      double? open = candles.first.open;

      // close price of the week
      double? close = candles.last.close;

      // highest price of the week
      double? high = candles
          .map((c) => c.high ?? double.negativeInfinity)
          .reduce((a, b) => a > b ? a : b);
      if (high == double.negativeInfinity) high = null;

      // lowest price of the week
      double? low = candles
          .map((c) => c.low ?? double.infinity)
          .reduce((a, b) => a < b ? a : b);
      if (low == double.infinity) low = null;

      // volume of the week
      double? volume =
          candles.map((c) => c.volume ?? 0).reduce((a, b) => a + b);

      // create weekly candle
      weeklyCandles.add(CandleData(
        timestamp: timestamp,
        open: open,
        close: close,
        high: high,
        low: low,
        volume: volume,
      ));
    });

    // sort by timestamp
    weeklyCandles.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return weeklyCandles;
  }

  /// convert daily candle data to monthly candle data
  static List<CandleData> convertToMonthly(List<CandleData> dailyCandles) {
    if (dailyCandles.isEmpty) return [];

    // group by month
    Map<int, List<CandleData>> monthlyGroups = {};

    for (var candle in dailyCandles) {
      // get the month of the date
      DateTime date = DateTime.fromMillisecondsSinceEpoch(candle.timestamp);
      int monthKey = DateTime(date.year, date.month, 1).millisecondsSinceEpoch;

      if (!monthlyGroups.containsKey(monthKey)) {
        monthlyGroups[monthKey] = [];
      }
      monthlyGroups[monthKey]!.add(candle);
    }

    // merge monthly candle data
    List<CandleData> monthlyCandles = [];
    monthlyGroups.forEach((timestamp, candles) {
      if (candles.isEmpty) return;

      // open price of the month
      double? open = candles.first.open;

      // close price of the month
      double? close = candles.last.close;

      // highest price of the month
      double? high = candles
          .map((c) => c.high ?? double.negativeInfinity)
          .reduce((a, b) => a > b ? a : b);
      if (high == double.negativeInfinity) high = null;

      // lowest price of the month
      double? low = candles
          .map((c) => c.low ?? double.infinity)
          .reduce((a, b) => a < b ? a : b);
      if (low == double.infinity) low = null;

      // volume of the month
      double? volume =
          candles.map((c) => c.volume ?? 0).reduce((a, b) => a + b);

      // create monthly candle
      monthlyCandles.add(CandleData(
        timestamp: timestamp,
        open: open,
        close: close,
        high: high,
        low: low,
        volume: volume,
      ));
    });

    // sort by timestamp
    monthlyCandles.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return monthlyCandles;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CandleData &&
          runtimeType == other.runtimeType &&
          timestamp == other.timestamp &&
          open == other.open &&
          high == other.high &&
          low == other.low &&
          close == other.close &&
          volume == other.volume &&
          trends == other.trends;

  @override
  int get hashCode =>
      timestamp.hashCode ^
      open.hashCode ^
      high.hashCode ^
      low.hashCode ^
      close.hashCode ^
      volume.hashCode ^
      trends.hashCode;

  @override
  String toString() => "<CandleData ($timestamp: $close)>";
}
