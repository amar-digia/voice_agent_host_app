class Stock {
  const Stock({
    required this.symbol,
    required this.name,
    required this.history,
  });

  final String symbol;
  final String name;

  /// Intraday price points, oldest first. The last point is the current price.
  final List<double> history;

  double get price => history.last;
  double get change => history.last - history.first;
  double get changePercent => change / history.first * 100;
}

class MarketIndex {
  const MarketIndex({
    required this.name,
    required this.value,
    required this.changePercent,
  });

  final String name;
  final double value;
  final double changePercent;
}

class NewsItem {
  const NewsItem({
    required this.source,
    required this.headline,
    required this.timeAgo,
    this.symbol,
  });

  final String source;
  final String headline;
  final String timeAgo;
  final String? symbol;
}

enum ChartRange {
  day('1D'),
  week('1W'),
  month('1M'),
  year('1Y'),
  all('ALL');

  const ChartRange(this.label);
  final String label;
}
