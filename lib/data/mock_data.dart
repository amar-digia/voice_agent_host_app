import 'dart:math';

import '../models/market_models.dart';

// Placeholder data until the app is wired to a real market-data API.

/// Generates a random-walk price series that ends exactly at [end].
List<double> _series(
  int seed, {
  required double end,
  int points = 40,
  double drift = 0.0,
  double volatility = 0.008,
}) {
  final random = Random(seed);
  var value = 100.0;
  final raw = <double>[];
  for (var i = 0; i < points; i++) {
    value *= 1 + drift + (random.nextDouble() - 0.5) * 2 * volatility;
    raw.add(value);
  }
  final scale = end / raw.last;
  return raw.map((v) => v * scale).toList();
}

const portfolioValue = 1248560.42;
const portfolioInvested = 1032000.00;

final Map<ChartRange, List<double>> portfolioHistory = {
  ChartRange.day: _series(1, end: portfolioValue, drift: 0.0004),
  ChartRange.week: _series(2, end: portfolioValue, drift: 0.0012),
  ChartRange.month: _series(3, end: portfolioValue, drift: 0.002),
  ChartRange.year: _series(4, end: portfolioValue, drift: 0.005, points: 60),
  ChartRange.all: _series(5, end: portfolioValue, drift: 0.006, points: 80),
};

const marketIndices = [
  MarketIndex(name: 'NIFTY 50', value: 24854.80, changePercent: 0.62),
  MarketIndex(name: 'SENSEX', value: 81224.75, changePercent: 0.48),
  MarketIndex(name: 'BANK NIFTY', value: 52310.15, changePercent: -0.31),
  MarketIndex(name: 'NIFTY IT', value: 41982.40, changePercent: 1.24),
];

final watchlist = [
  Stock(
    symbol: 'RELIANCE',
    name: 'Reliance Industries',
    history: _series(11, end: 2945.60, drift: 0.0006),
  ),
  Stock(
    symbol: 'TCS',
    name: 'Tata Consultancy Services',
    history: _series(12, end: 4128.35, drift: 0.0009),
  ),
  Stock(
    symbol: 'HDFCBANK',
    name: 'HDFC Bank',
    history: _series(13, end: 1678.90, drift: -0.0005),
  ),
  Stock(
    symbol: 'INFY',
    name: 'Infosys',
    history: _series(14, end: 1892.15, drift: 0.0011),
  ),
  Stock(
    symbol: 'ICICIBANK',
    name: 'ICICI Bank',
    history: _series(15, end: 1254.30, drift: -0.0003),
  ),
];

final topGainers = [
  Stock(
    symbol: 'TATAMOTORS',
    name: 'Tata Motors',
    history: _series(21, end: 1012.45, drift: 0.0014),
  ),
  Stock(
    symbol: 'ADANIENT',
    name: 'Adani Enterprises',
    history: _series(22, end: 3148.20, drift: 0.0012),
  ),
  Stock(
    symbol: 'BAJFINANCE',
    name: 'Bajaj Finance',
    history: _series(23, end: 7245.00, drift: 0.001),
  ),
];

final topLosers = [
  Stock(
    symbol: 'WIPRO',
    name: 'Wipro',
    history: _series(31, end: 548.70, drift: -0.0012),
  ),
  Stock(
    symbol: 'ITC',
    name: 'ITC',
    history: _series(32, end: 472.15, drift: -0.0009),
  ),
  Stock(
    symbol: 'SBIN',
    name: 'State Bank of India',
    history: _series(33, end: 812.60, drift: -0.0008),
  ),
];

const marketNews = [
  NewsItem(
    source: 'Markets Desk',
    headline: 'Benchmarks extend gains as IT stocks rally on strong deal wins',
    timeAgo: '12m ago',
    symbol: 'NIFTY IT',
  ),
  NewsItem(
    source: 'Economy',
    headline: 'RBI keeps repo rate unchanged, signals focus on inflation',
    timeAgo: '1h ago',
  ),
  NewsItem(
    source: 'Earnings',
    headline: 'Reliance Q2 profit beats estimates on retail and telecom',
    timeAgo: '3h ago',
    symbol: 'RELIANCE',
  ),
];

List<Stock> get allStocks => [...watchlist, ...topGainers, ...topLosers];
