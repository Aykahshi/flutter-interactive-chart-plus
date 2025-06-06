import 'dart:math';

import 'package:flutter/material.dart';

import 'candle_data.dart';
import 'painter_params.dart';

typedef TimeLabelGetter = String Function(int timestamp, int visibleDataCount);
typedef PriceLabelGetter = String Function(double price);
typedef OverlayInfoGetter = Map<String, String> Function(CandleData candle);

class ChartPainter extends CustomPainter {
  final PainterParams params;
  final TimeLabelGetter getTimeLabel;
  final PriceLabelGetter getPriceLabel;
  final OverlayInfoGetter getOverlayInfo;

  ChartPainter({
    required this.params,
    required this.getTimeLabel,
    required this.getPriceLabel,
    required this.getOverlayInfo,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw time labels (dates) & price labels
    _drawTimeLabels(canvas, params);
    _drawPriceGridAndLabels(canvas, params);
    _drawCurrentPriceLabel(canvas, params);
    _drawCurrentPriceLine(canvas, params);

    // Draw prices, volumes & trend line
    canvas.save();
    canvas.clipRect(Offset.zero & Size(params.chartWidth, params.chartHeight));
    // canvas.drawRect(
    //   // apply yellow tint to clipped area (for debugging)
    //   Offset.zero & Size(params.chartWidth, params.chartHeight),
    //   Paint()..color = Colors.yellow[100]!,
    // );
    canvas.translate(params.xShift, 0);
    for (int i = 0; i < params.candles.length; i++) {
      _drawSingleDay(canvas, params, i);
    }
    canvas.restore();

    // Draw tap highlight & overlay
    if (params.tapPosition != null) {
      if (params.tapPosition!.dx < params.chartWidth) {
        _drawTapHighlightAndOverlay(canvas, params);
      }
    }
  }

  void _drawTimeLabels(canvas, PainterParams params) {
    // We draw one time label per 90 pixels of screen width
    final lineCount = params.chartWidth ~/ 90;
    final gap = 1 / (lineCount + 1);
    for (int i = 1; i <= lineCount; i++) {
      double x = i * gap * params.chartWidth;
      final index = params.getCandleIndexFromOffset(x);
      if (index < params.candles.length) {
        final candle = params.candles[index];
        final visibleDataCount = params.candles.length;
        final timeTp = TextPainter(
          text: TextSpan(
            text: getTimeLabel(candle.timestamp, visibleDataCount),
            style: params.style.timeLabelStyle,
          ),
        )
          ..textDirection = TextDirection.ltr
          ..layout();

        // Align texts towards vertical bottom
        final topPadding = params.style.timeLabelHeight - timeTp.height;
        timeTp.paint(
          canvas,
          Offset(x - timeTp.width / 2, params.chartHeight + topPadding),
        );
      }
    }
  }

  void _drawPriceGridAndLabels(canvas, PainterParams params) {
    [0.0, 0.25, 0.5, 0.75, 1.0]
        .map((v) => ((params.maxPrice - params.minPrice) * v) + params.minPrice)
        .forEach((y) {
      canvas.drawLine(
        Offset(0, params.fitPrice(y)),
        Offset(params.chartWidth, params.fitPrice(y)),
        Paint()
          ..strokeWidth = 0.5
          ..color = params.style.priceGridLineColor,
      );
      final priceTp = TextPainter(
        text: TextSpan(
          text: getPriceLabel(y),
          style: params.style.priceLabelStyle.labelStyle,
        ),
      )
        ..textDirection = TextDirection.ltr
        ..layout();
      priceTp.paint(
          canvas,
          Offset(
            params.chartWidth + 4,
            params.fitPrice(y) - priceTp.height / 2,
          ));
    });
  }

  void _drawSelectionHighlightPriceAndLabels(
      canvas, PainterParams params, CandleData candle) {
    final price = candle.close ?? candle.open ?? 0;
    final priceY = params.fitPrice(price);

    canvas.drawLine(
      Offset(0, priceY),
      Offset(params.chartWidth, priceY),
      Paint()
        ..strokeWidth = 1.0
        ..color = params.style.selectionHighlightColor,
    );
    final priceTp = TextPainter(
      text: TextSpan(
        text: getPriceLabel(price),
        style: params.style.priceLabelStyle.highlightLabelStyle,
      ),
    )
      ..textDirection = TextDirection.ltr
      ..layout();

    // Define padding for the background rect
    final backgroundPadding = params.style.priceLabelStyle.highlightBgPadding;
    final rectWidth =
        priceTp.width + backgroundPadding.left + backgroundPadding.right;
    final rectHeight =
        priceTp.height + backgroundPadding.top + backgroundPadding.bottom;

    // Calculate position for the background rect and text
    final rectX = params.chartWidth + params.style.priceLabelStyle.labelLeftGap;
    final rectY = priceY - rectHeight / 2;

    // Draw the rounded rectangle background
    final RRect backgroundRRect = RRect.fromLTRBR(
      rectX,
      rectY,
      rectX + rectWidth,
      rectY + rectHeight,
      params.style.priceLabelStyle.highlightBgRadius,
    );
    canvas.drawRRect(
      backgroundRRect,
      Paint()..color = params.style.priceLabelStyle.highlightBgColor,
    );

    priceTp.paint(
        canvas,
        Offset(
          params.chartWidth + 10,
          params.fitPrice(price) - priceTp.height / 2,
        ));
  }

  void _drawCurrentPriceLabel(
    Canvas canvas,
    PainterParams params,
  ) {
    final currentPrice = params.currentPrice;
    if (currentPrice == null) {
      return;
    }
    final priceY =
        params.fitPrice(currentPrice).clamp(0, params.chartHeight).toDouble();

    final priceTp = TextPainter(
      text: TextSpan(
        text: getPriceLabel(currentPrice),
        style: params.style.currentPriceStyle.labelStyle,
      ),
    )
      ..textDirection = TextDirection.ltr
      ..layout();

    // define rect padding and size
    final padding = params.style.currentPriceStyle.rectPadding;
    final rectWidth = priceTp.width + padding.left + padding.right;
    final rectHeight = priceTp.height + padding.top + padding.bottom;

    final rectX = params.chartWidth + 4;
    final rectY = priceY - rectHeight / 2;

    final textX = rectX + params.style.currentPriceStyle.labelLeftGap;
    final textY = priceY - priceTp.height / 2;

    // draw rounded rect background
    final RRect backgroundRRect = RRect.fromLTRBR(
      rectX,
      rectY,
      rectX + rectWidth,
      rectY + rectHeight,
      Radius.circular(params.style.currentPriceStyle.rectRadius),
    );
    canvas.drawRRect(
      backgroundRRect,
      Paint()..color = params.style.currentPriceStyle.rectColor,
    );

    // draw price text
    priceTp.paint(canvas, Offset(textX, textY));
  }

  void _drawCurrentPriceLine(Canvas canvas, PainterParams params) {
    final currentPrice = params.currentPrice;
    if (currentPrice == null) {
      return;
    }
    final paint = Paint()
      ..color = params.style.currentPriceStyle.rectColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final dashWidth = 4.0;
    final dashSpace = 2.0;
    double startX = 0;
    final clampedPrice =
        params.fitPrice(currentPrice).clamp(0, params.chartHeight).toDouble();
    while (startX < params.chartWidth) {
      canvas.drawLine(
        Offset(startX, clampedPrice),
        Offset(startX + dashWidth, clampedPrice),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  void _drawSingleDay(canvas, PainterParams params, int i) {
    final candle = params.candles[i];
    final x = i * params.candleWidth;
    final thickWidth = max(params.candleWidth * 0.8, 0.8);
    final thinWidth = max(params.candleWidth * 0.2, 0.2);
    // Draw price bar
    final open = candle.open;
    final close = candle.close;
    final high = candle.high;
    final low = candle.low;
    if (open != null && close != null) {
      final color = open > close
          ? params.style.priceLossColor
          : params.style.priceGainColor;
      canvas.drawLine(
        Offset(x, params.fitPrice(open)),
        Offset(x, params.fitPrice(close)),
        Paint()
          ..strokeWidth = thickWidth
          ..color = color,
      );
      if (high != null && low != null) {
        canvas.drawLine(
          Offset(x, params.fitPrice(high)),
          Offset(x, params.fitPrice(low)),
          Paint()
            ..strokeWidth = thinWidth
            ..color = color,
        );
      }
    }
    // Draw volume bar
    final volume = candle.volume;
    if (volume != null && open != null && close != null) {
      Color color = open > close
          ? params.style.volumeLossColor
          : params.style.volumeGainColor;

      if (open == close) {
        color = Colors.grey;
      }

      canvas.drawLine(
        Offset(x, params.chartHeight),
        Offset(x, params.fitVolume(volume)),
        Paint()
          ..strokeWidth = thickWidth
          ..color = color,
      );
    }

    // 繪制趨勢線 - 向下相容的方式
    for (int j = 0; j < candle.trends.length; j++) {
      final trendLinePaint = j < params.style.trendLineStyles.length
          ? params.style.trendLineStyles[j]
          : (Paint()
            ..strokeWidth = 2.0
            ..strokeCap = StrokeCap.round
            ..color = Colors.blue);

      final pt = candle.trends.length > j
          ? candle.trends[j]
          : null; // current data point
      final prevCandle = i > 0 ? params.candles[i - 1] : null;
      final prevPt = prevCandle != null && prevCandle.trends.length > j
          ? prevCandle.trends[j]
          : null;

      if (pt != null && prevPt != null) {
        canvas.drawLine(
          Offset(x - params.candleWidth, params.fitPrice(prevPt)),
          Offset(x, params.fitPrice(pt)),
          trendLinePaint,
        );
      }

      if (i == 0) {
        // In the front, draw an extra line connecting to out-of-window data
        if (pt != null &&
            params.leadingTrends != null &&
            params.leadingTrends!.length > j &&
            params.leadingTrends![j] != null) {
          canvas.drawLine(
            Offset(x - params.candleWidth,
                params.fitPrice(params.leadingTrends![j]!)),
            Offset(x, params.fitPrice(pt)),
            trendLinePaint,
          );
        }
      } else if (i == params.candles.length - 1) {
        // At the end, draw an extra line connecting to out-of-window data
        if (pt != null &&
            params.trailingTrends != null &&
            params.trailingTrends!.length > j &&
            params.trailingTrends![j] != null) {
          canvas.drawLine(
            Offset(x, params.fitPrice(pt)),
            Offset(
              x + params.candleWidth,
              params.fitPrice(params.trailingTrends![j]!),
            ),
            trendLinePaint,
          );
        }
      }
    }

    // 繪制新的趨勢線實作
    for (final trendLine in candle.trendLines.values) {
      if (trendLine.value == null) continue;

      // 獲取趨勢線樣式
      final Paint trendLinePaint = params.style.getTrendLineStyle(trendLine);

      // 繪制趨勢線
      if (i > 0) {
        final prevCandle = params.candles[i - 1];
        final prevTrendLine = prevCandle.trendLines[trendLine.id];

        if (prevTrendLine != null && prevTrendLine.value != null) {
          canvas.drawLine(
            Offset(
                x - params.candleWidth, params.fitPrice(prevTrendLine.value!)),
            Offset(x, params.fitPrice(trendLine.value!)),
            trendLinePaint,
          );
        }
      }
    }
  }

  void _drawTapHighlightAndOverlay(canvas, PainterParams params) {
    final pos = params.tapPosition!;
    final i = params.getCandleIndexFromOffset(pos.dx);
    final candle = params.candles[i];
    canvas.save();
    canvas.translate(params.xShift, 0.0);
    // Draw highlight bar (selection box)
    canvas.drawLine(
        Offset(i * params.candleWidth, 0.0),
        Offset(i * params.candleWidth, params.chartHeight),
        Paint()
          ..strokeWidth = 1.0
          ..color = params.style.selectionHighlightColor);
    canvas.restore();
    // Draw info pane
    _drawSelectionHighlightPriceAndLabels(canvas, params, candle);
    _drawTapInfoOverlay(canvas, params, candle);
  }

  void _drawTapInfoOverlay(canvas, PainterParams params, CandleData candle) {
    final xGap = 8.0;
    final yGap = 4.0;

    TextPainter makeTP(String text) => TextPainter(
          text: TextSpan(
            text: text,
            style: params.style.overlayTextStyle,
          ),
        )
          ..textDirection = TextDirection.ltr
          ..layout();

    final info = getOverlayInfo(candle);
    if (info.isEmpty) return;
    final labels = info.keys.map((text) => makeTP(text)).toList();
    final values = info.values.map((text) => makeTP(text)).toList();

    final labelsMaxWidth = labels.map((tp) => tp.width).reduce(max);
    final valuesMaxWidth = values.map((tp) => tp.width).reduce(max);
    final panelWidth = labelsMaxWidth + valuesMaxWidth + xGap * 3;
    final panelHeight = max(
          labels.map((tp) => tp.height).reduce((a, b) => a + b),
          values.map((tp) => tp.height).reduce((a, b) => a + b),
        ) +
        yGap * (values.length + 1);

    // Shift the canvas, so the overlay panel can appear near touch position.
    canvas.save();
    final pos = params.tapPosition!;
    final fingerSize = 32.0; // leave some margin around user's finger
    double dx, dy;
    assert(params.size.width >= panelWidth, "Overlay panel is too wide.");
    if (pos.dx <= params.size.width / 2) {
      // If user touches the left-half of the screen,
      // we show the overlay panel near finger touch position, on the right.
      dx = pos.dx + fingerSize;
    } else {
      // Otherwise we show panel on the left of the finger touch position.
      dx = pos.dx - panelWidth - fingerSize;
    }
    dx = dx.clamp(0, params.size.width - panelWidth);
    dy = pos.dy - panelHeight - fingerSize;
    if (dy < 0) dy = 0.0;
    canvas.translate(dx, dy);

    // Draw the background for overlay panel
    canvas.drawRRect(
        RRect.fromRectAndRadius(
          Offset.zero & Size(panelWidth, panelHeight),
          Radius.circular(8),
        ),
        Paint()..color = params.style.overlayBackgroundColor);

    // Draw texts
    var y = 0.0;
    for (int i = 0; i < labels.length; i++) {
      y += yGap;
      final rowHeight = max(labels[i].height, values[i].height);
      // Draw labels (left align, vertical center)
      final labelY = y + (rowHeight - labels[i].height) / 2; // vertical center
      labels[i].paint(canvas, Offset(xGap, labelY));

      // Draw values (right align, vertical center)
      final leading = valuesMaxWidth - values[i].width; // right align
      final valueY = y + (rowHeight - values[i].height) / 2; // vertical center
      values[i].paint(
        canvas,
        Offset(labelsMaxWidth + xGap * 2 + leading, valueY),
      );
      y += rowHeight;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(ChartPainter oldDelegate) =>
      params.shouldRepaint(oldDelegate.params);
}

extension ElementAtOrNull<E> on List<E> {
  E? at(int index) {
    if (index < 0 || index >= length) return null;
    return elementAt(index);
  }
}
