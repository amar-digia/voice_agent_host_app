import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/market_models.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'app_message.dart';

enum OrderSide { buy, sell }

/// Opens the order form. Shows a confirmation message once an order is placed.
Future<void> showOrderSheet(
  BuildContext context, {
  OrderSide side = OrderSide.buy,
  String? symbol,
}) async {
  final placed = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (_) => _OrderSheet(initialSide: side, initialSymbol: symbol),
  );
  if (placed != null && context.mounted) showAppMessage(context, placed);
}

class _OrderSheet extends StatefulWidget {
  const _OrderSheet({required this.initialSide, this.initialSymbol});

  final OrderSide initialSide;
  final String? initialSymbol;

  @override
  State<_OrderSheet> createState() => _OrderSheetState();
}

class _OrderSheetState extends State<_OrderSheet> {
  late OrderSide _side = widget.initialSide;
  late Stock _stock = allStocks.firstWhere(
    (s) => s.symbol == widget.initialSymbol,
    orElse: () => allStocks.first,
  );
  int _quantity = 1;

  void _place() {
    final verb = _side == OrderSide.buy ? 'Buy' : 'Sell';
    Navigator.pop(context, '$verb order placed: $_quantity × ${_stock.symbol}');
  }

  @override
  Widget build(BuildContext context) {
    final sideColor = _side == OrderSide.buy ? AppColors.gain : AppColors.loss;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'New order',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            SegmentedButton<OrderSide>(
              segments: const [
                ButtonSegment(value: OrderSide.buy, label: Text('Buy')),
                ButtonSegment(value: OrderSide.sell, label: Text('Sell')),
              ],
              selected: {_side},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _side = s.first),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Stock>(
              initialValue: _stock,
              decoration: const InputDecoration(
                labelText: 'Stock',
                border: OutlineInputBorder(),
              ),
              dropdownColor: AppColors.surfaceRaised,
              items: [
                for (final stock in allStocks)
                  DropdownMenuItem(value: stock, child: Text(stock.symbol)),
              ],
              onChanged: (s) => setState(() => _stock = s ?? _stock),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Quantity',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                IconButton.outlined(
                  onPressed: _quantity > 1
                      ? () => setState(() => _quantity--)
                      : null,
                  icon: const Icon(Icons.remove),
                ),
                SizedBox(
                  width: 48,
                  child: Text(
                    '$_quantity',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton.outlined(
                  onPressed: () => setState(() => _quantity++),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Estimated amount',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                Text(
                  formatCurrency(_stock.price * _quantity),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              key: const ValueKey('order_place'),
              style: FilledButton.styleFrom(
                backgroundColor: sideColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _place,
              child: Text(
                _side == OrderSide.buy ? 'Place buy order' : 'Place sell order',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
