import 'package:flutter/material.dart';

import 'trend_line.dart';

class ChartStyle {
  /// The percentage height of volume.
  ///
  /// Defaults to 0.2, which means volume bars will be 20% of total height,
  /// thus leaving price bars to be 80% of the total height.
  final double volumeHeightFactor;

  /// The padding on the right-side of the chart.
  final double priceLabelWidth;

  /// The padding on the bottom-side of the chart.
  ///
  /// Defaults to 24.0, date/time labels is drawn vertically bottom-aligned,
  /// thus adjusting this value would also control the padding between
  /// the chart and the date/time labels.
  final double timeLabelHeight;

  /// The style of date/time labels (on the bottom of the chart).
  final TextStyle timeLabelStyle;

  /// The style of price labels (on the right of the chart).
  final PriceLabelStyle priceLabelStyle;

  /// The style of overlay texts. These texts are drawn on top of the
  /// background color specified in [overlayBackgroundColor].
  ///
  /// This appears when user clicks on the chart.
  final TextStyle overlayTextStyle;

  /// The color to use when the `close` price is higher than `open` price.
  final Color priceGainColor;

  /// The color to use when the `close` price is lower than `open` price.
  final Color priceLossColor;

  /// The color of the `volume` bars when `volume` is higher than `open` volume.
  final Color volumeGainColor;

  /// The color of the `volume` bars when `volume` is lower than `open` volume.
  final Color volumeLossColor;

  /// 趨勢線樣式列表
  ///
  /// 如果有多條趨勢線，它們的樣式將按照在這個列表中的出現順序選擇。
  /// 如果這個列表比趨勢線的數量短，則會使用預設的藍色繪制。
  final List<Paint> trendLineStyles;

  /// The color of the price grid line.
  final Color priceGridLineColor;

  /// The highlight color. This appears when user clicks on the chart.
  final Color selectionHighlightColor;

  /// The background color of the overlay.
  ///
  /// This appears when user clicks on the chart.
  final Color overlayBackgroundColor;

  /// The style of current price labels (on the right of the chart).
  final CurrentPriceStyle currentPriceStyle;
  
  /// 獲取趨勢線樣式，如果沒有設定，則使用趨勢線的預設樣式
  Paint getTrendLineStyle(TrendLine trendLine, int index) {
    // 如果索引在範圍內，則使用對應的樣式
    if (index < trendLineStyles.length) {
      return trendLineStyles[index];
    }
    // 否則使用趨勢線的預設樣式
    return trendLine.defaultStyle;
  }

  const ChartStyle({
    this.volumeHeightFactor = 0.2,
    this.priceLabelWidth = 48.0,
    this.timeLabelHeight = 24.0,
    this.timeLabelStyle = const TextStyle(
      fontSize: 16,
      color: Colors.grey,
    ),
    this.priceLabelStyle = const PriceLabelStyle(
      labelStyle: TextStyle(
        fontSize: 12,
        color: Colors.grey,
      ),
      labelLeftGap: 4,
      highlightLabelStyle: TextStyle(
        fontSize: 12,
        color: Colors.white,
      ),
      highlightBgPadding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
      highlightBgRadius: Radius.circular(4.0),
      highlightBgColor: const Color(0x33757575),
    ),
    this.overlayTextStyle = const TextStyle(
      fontSize: 16,
      color: Colors.white,
    ),
    this.priceGainColor = Colors.red,
    this.priceLossColor = Colors.green,
    this.volumeGainColor = Colors.red,
    this.volumeLossColor = Colors.green,
    this.trendLineStyles = const [],
    this.priceGridLineColor = Colors.grey,
    this.selectionHighlightColor = const Color(0x33757575),
    this.overlayBackgroundColor = const Color(0xEE757575),
    this.currentPriceStyle = const CurrentPriceStyle(
      labelStyle: TextStyle(
        fontSize: 12,
        color: Colors.white,
      ),
      labelLeftGap: 4,
      rectPadding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
      rectRadius: 4.0,
      rectColor: Colors.red,
    ),
  });
}

class CurrentPriceStyle {
  const CurrentPriceStyle({
    required this.labelStyle,
    required this.labelLeftGap,
    required this.rectPadding,
    required this.rectRadius,
    required this.rectColor,
  });

  /// The style of current price labels (on the right of the chart).
  final TextStyle labelStyle;

  /// The padding around the current price rect.
  final EdgeInsets rectPadding;

  /// The radius of the current price rect.
  final double rectRadius;

  /// The left gap of label inside rect.
  final double labelLeftGap;

  /// The color of the current price rect.
  final Color rectColor;
}

class PriceLabelStyle {
  const PriceLabelStyle({
    required this.labelStyle,
    required this.labelLeftGap,
    required this.highlightLabelStyle,
    required this.highlightBgPadding,
    required this.highlightBgRadius,
    required this.highlightBgColor,
  });

  /// The style of price labels (on the right of the chart).
  final TextStyle labelStyle;

  /// The style of price labels when highlighted.
  final TextStyle highlightLabelStyle;

  /// The padding around the highlight background.
  final EdgeInsets highlightBgPadding;

  /// The radius of the highlight background.
  final Radius highlightBgRadius;

  /// The left gap of label inside rect.
  final double labelLeftGap;

  /// The color of the highlight background.
  final Color highlightBgColor;
}
