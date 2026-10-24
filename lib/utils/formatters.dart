/// Formats a number using Indian digit grouping, e.g. 1248560.4 -> 12,48,560.40.
String formatAmount(double value, {int decimals = 2}) {
  final parts = value.abs().toStringAsFixed(decimals).split('.');
  final intPart = parts[0];

  var grouped = intPart;
  if (intPart.length > 3) {
    var rest = intPart.substring(0, intPart.length - 3);
    final groups = <String>[];
    while (rest.length > 2) {
      groups.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) groups.insert(0, rest);
    grouped = '${groups.join(',')},${intPart.substring(intPart.length - 3)}';
  }

  final sign = value < 0 ? '-' : '';
  return decimals > 0 ? '$sign$grouped.${parts[1]}' : '$sign$grouped';
}

String formatCurrency(double value, {int decimals = 2}) {
  final sign = value < 0 ? '-' : '';
  return '$sign₹${formatAmount(value.abs(), decimals: decimals)}';
}

String formatSignedCurrency(double value) =>
    '${value >= 0 ? '+' : '-'}₹${formatAmount(value.abs())}';

String formatPercent(double value) =>
    '${value >= 0 ? '+' : ''}${value.toStringAsFixed(2)}%';
