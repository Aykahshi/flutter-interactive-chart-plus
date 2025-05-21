import 'candle_data.dart';

class XAxisOffsetDetails {
  XAxisOffsetDetails({
    required this.offset,
    required this.maxOffset,
    this.lastVisibleCandle,
  });

  final double offset;
  final double maxOffset;
  
  /// The last visible candle in the current view
  final CandleData? lastVisibleCandle;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XAxisOffsetDetails &&
          runtimeType == other.runtimeType &&
          offset == other.offset &&
          maxOffset == other.maxOffset &&
          lastVisibleCandle == other.lastVisibleCandle;

  @override
  int get hashCode => 
      offset.hashCode ^ 
      maxOffset.hashCode ^ 
      (lastVisibleCandle?.hashCode ?? 0);

  @override
  String toString() {
    return 'XAxisOffsetDetails{offset: $offset, maxOffset: $maxOffset, lastVisibleCandle: $lastVisibleCandle}';
  }
}
