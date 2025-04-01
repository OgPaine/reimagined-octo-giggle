import 'package:flutter/foundation.dart';

/// A data model for a single heat map cell.
///
/// This model represents usage data by storing the number of times the app
/// was opened and the number of words used. It also provides an aggregate value
/// that can be used to visualize intensity in heat map widgets.
@immutable
class UsageCellData {
  /// Number of times the app was opened.
  final int appOpens;

  /// Number of words used.
  final int wordsUsed;

  /// Creates an instance of [UsageCellData].
  ///
  /// Both [appOpens] and [wordsUsed] are required.
  const UsageCellData({
    required this.appOpens,
    required this.wordsUsed,
  });

  /// Returns the aggregate value (appOpens + wordsUsed).
  int get total => appOpens + wordsUsed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsageCellData &&
          runtimeType == other.runtimeType &&
          appOpens == other.appOpens &&
          wordsUsed == other.wordsUsed;

  @override
  int get hashCode => appOpens.hashCode ^ wordsUsed.hashCode;

  @override
  String toString() =>
      'UsageCellData(appOpens: $appOpens, wordsUsed: $wordsUsed, total: $total)';
}
