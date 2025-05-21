import 'package:flutter/material.dart';
import 'package:interactive_chart/interactive_chart.dart';

import 'mock_data.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<CandleData> _data = MockDataTesla.candles;
  bool _darkMode = true;
  TimeFrame _chartState = TimeFrame.day;
  bool _showAverage = false;

  // 最後一根可見蠟燭
  CandleData? _lastVisibleCandle;

  void _switchTimeFrame(TimeFrame timeFrame) {
    switch (timeFrame) {
      case TimeFrame.day:
        setState(() {
          _chartState = timeFrame;
          _data = MockDataTesla.candles;
        });
        break;
      case TimeFrame.week:
        setState(() {
          _chartState = timeFrame;
          _data = CandleData.convertToWeekly(MockDataTesla.candles);
        });
        break;
      case TimeFrame.month:
        setState(() {
          _chartState = timeFrame;
          _data = CandleData.convertToMonthly(MockDataTesla.candles);
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: _darkMode ? Brightness.dark : Brightness.light,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Interactive Chart Demo"),
          actions: [
            IconButton(
              icon: Icon(_darkMode ? Icons.dark_mode : Icons.light_mode),
              onPressed: () => setState(() => _darkMode = !_darkMode),
            ),
            IconButton(
              icon: Icon(
                _showAverage ? Icons.show_chart : Icons.bar_chart_outlined,
              ),
              onPressed: () {
                setState(() => _showAverage = !_showAverage);
                if (_showAverage) {
                  _computeTrendLines();
                } else {
                  _removeTrendLines();
                }
              },
            ),
          ],
        ),
        body: SafeArea(
          minimum: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ToggleButtons(
                    isSelected: [
                      _chartState == TimeFrame.day,
                      _chartState == TimeFrame.week,
                      _chartState == TimeFrame.month,
                    ],
                    onPressed: (index) {
                      final timeFrame = TimeFrame.values[index];
                      _switchTimeFrame(timeFrame);
                    },
                    children: [
                      Text('Day'),
                      Text('Week'),
                      Text('Month'),
                    ],
                  ),
                ],
              ),
              if (_lastVisibleCandle != null && _showAverage)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: _darkMode ? Colors.grey[800] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last visible candle trend line values',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _darkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Time: ${DateTime.fromMillisecondsSinceEpoch(_lastVisibleCandle!.timestamp).toString().substring(0, 16)}',
                        style: TextStyle(
                          color: _darkMode ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      Text(
                        'Close: ${_lastVisibleCandle!.close?.toStringAsFixed(2) ?? "N/A"}',
                        style: TextStyle(
                          color: _darkMode ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: _buildTrendLineChips(),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: InteractiveChart(
                  /** Only [candles] is required */
                  candles: _data,
                  /** Uncomment the following for examples on optional parameters */
                  initialVisibleCandleCount: 50,

                  currentPrice: _data.last.open,

                  timeFrame: _chartState,

                  /** Example styling */
                  style: ChartStyle(
                    volumeGainColor: Colors.red.withValues(alpha: 0.8),
                    volumeLossColor: Colors.green.withValues(alpha: 0.8),
                    trendLineStyles: [
                      Paint()
                        ..strokeWidth = 2.0
                        ..strokeCap = StrokeCap.round
                        ..color = Colors.deepOrange,
                      Paint()
                        ..strokeWidth = 4.0
                        ..strokeCap = StrokeCap.round
                        ..color = Colors.orange,
                    ],
                    priceGridLineColor: Colors.blue[200]!,
                    priceLabelStyle: PriceLabelStyle(
                      labelLeftGap: 4,
                      labelStyle: TextStyle(color: Colors.blue[200]),
                      highlightLabelStyle: TextStyle(color: Colors.black),
                      highlightBgPadding: EdgeInsets.zero,
                      highlightBgRadius: Radius.zero,
                      highlightBgColor:
                          Colors.blue[200]!.withValues(alpha: 0.8),
                    ),
                    timeLabelStyle: TextStyle(color: Colors.blue[200]),
                    selectionHighlightColor:
                        Colors.white.withValues(alpha: 0.8),
                    overlayBackgroundColor:
                        Colors.red[900]!.withValues(alpha: 0.6),
                    overlayTextStyle: TextStyle(color: Colors.red[100]),
                    timeLabelHeight: 32,
                    volumeHeightFactor:
                        0.3, // volume area is 20% of total height
                  ),
                  onXOffsetChanged: (details) {
                    // 獲取可見範圍的最後一根蠟燭
                    final lastCandle = details.lastVisibleCandle;
                    if (lastCandle != null) {
                      // 使用 WidgetsBinding.instance.addPostFrameCallback 確保在當前 frame 結束後更新狀態
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _lastVisibleCandle = lastCandle;
                          });
                        }
                      });
                      print('Last visible candle close: ${lastCandle.close}');
                      print(
                          'Last visible candle timestamp: ${lastCandle.timestamp}');
                    }
                  },
                  /** Customize axis labels */
                  // timeLabel: (timestamp, visibleDataCount) => "📅",
                  // priceLabel: (price) => "${price.round()} 💎",
                  /** Customize overlay (tap and hold to see it)
                   ** Or return an empty object to disable overlay info. */
                  // overlayInfo: (candle) => {
                  //   "💎": "🤚    ",
                  //   "Hi": "${candle.high?.toStringAsFixed(2)}",
                  //   "Lo": "${candle.low?.toStringAsFixed(2)}",
                  // },
                  /** Callbacks */
                  // onTap: (candle) => print("user tapped on $candle"),
                  // onCandleResize: (width) => print("each candle is $width wide"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _computeTrendLines() {
    setState(() {
      _data = CandleData.computeMAWithTrendLine(_data, 7);
      _data = CandleData.computeMAWithTrendLine(_data, 30);
      _data = CandleData.computeMAWithTrendLine(_data, 90);

      for (int i = 0; i < _data.length; i++) {
        final ma7Value = _data[i].trendLines['MA7']?.value;
        final ma30Value = _data[i].trendLines['MA30']?.value;
        final ma90Value = _data[i].trendLines['MA90']?.value;

        final trends = [ma7Value, ma30Value, ma90Value];

        _data[i] = CandleData(
          timestamp: _data[i].timestamp,
          open: _data[i].open,
          close: _data[i].close,
          high: _data[i].high,
          low: _data[i].low,
          volume: _data[i].volume,
          trendLines: _data[i].trendLines,
          trends: trends,
        );
      }

      if (_data.isNotEmpty) {
        _lastVisibleCandle = _data.last;
      }
    });
  }

  _removeTrendLines() {
    setState(() {
      _data = _data.map((candle) {
        return CandleData(
          timestamp: candle.timestamp,
          open: candle.open,
          close: candle.close,
          high: candle.high,
          low: candle.low,
          volume: candle.volume,
          trendLines: {},
          trends: [],
        );
      }).toList();
    });
  }

  List<Widget> _buildTrendLineChips() {
    if (_lastVisibleCandle == null) return [];

    final List<Widget> chips = [];

    final sortedTrendLines = _lastVisibleCandle!.trendLines.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    for (final entry in sortedTrendLines) {
      final trendLine = entry.value;
      if (trendLine.value == null) continue;

      // 根據趨勢線的類型決定小卡片的顏色
      Color chipColor;
      if (trendLine is MALine) {
        chipColor = Colors.blue;
      } else {
        chipColor = Colors.orange;
      }

      chips.add(
        Chip(
          label: Text(
            '${trendLine.displayName}: ${trendLine.value!.toStringAsFixed(2)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
          backgroundColor: chipColor,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: EdgeInsets.symmetric(horizontal: 4),
        ),
      );
    }

    return chips;
  }
}
