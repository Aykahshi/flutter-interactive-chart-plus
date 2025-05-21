import 'package:flutter/material.dart';

/// TrendLine abstract class
abstract class TrendLine {
  /// TrendLine id to identify the trend line
  String get id;

  /// TrendLine display name
  String get displayName;

  /// TrendLine value
  double? get value;

  TrendLine copyWith({double? value});

  /// TrendLine default style
  Paint get defaultStyle;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrendLine &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          value == other.value;

  @override
  int get hashCode => id.hashCode ^ (value?.hashCode ?? 0);
}

class MALine extends TrendLine {
  final String _id;
  final String _displayName;
  final double? _value;
  final int period;

  MALine(this.period, {double? value})
      : _id = 'MA$period',
        _displayName = 'MA$period',
        _value = value;

  @override
  String get id => _id;

  @override
  String get displayName => _displayName;

  @override
  double? get value => _value;

  @override
  MALine copyWith({double? value}) => MALine(period, value: value ?? _value);

  @override
  Paint get defaultStyle => Paint()
    ..color = Colors.blue
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke;
}
