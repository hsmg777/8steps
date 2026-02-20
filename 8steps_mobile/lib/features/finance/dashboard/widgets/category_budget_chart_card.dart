import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../modules/categories/models/budget_models.dart';

class CategoryBudgetChartCard extends StatelessWidget {
  const CategoryBudgetChartCard({
    super.key,
    required this.items,
    required this.loading,
    required this.errorMessage,
    required this.onRefresh,
  });

  final List<BudgetStatusItem> items;
  final bool loading;
  final String? errorMessage;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final visible = items.where((e) => e.effectiveBudget > 0).take(6).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0x1FFFFFFF),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Categorías: gastado vs restante',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (errorMessage != null)
            Text(
              errorMessage!,
              style: const TextStyle(color: Color(0xFFFF9A9A)),
            )
          else if (visible.isEmpty)
            const Text(
              'No hay categorías con presupuesto este mes.',
              style: TextStyle(color: Colors.white70),
            )
          else
            Column(
              children: visible.map((item) {
                final budget =
                    item.effectiveBudget <= 0 ? 1.0 : item.effectiveBudget;
                final spent = item.spent.clamp(0, budget);
                final remaining = (budget - spent).clamp(0, budget);
                final spentRatio = (spent / budget).clamp(0, 1).toDouble();
                final remainingRatio =
                    (remaining / budget).clamp(0, 1).toDouble();
                final over = item.spent > budget;
                final spentColor = _spentColor(item.percentUsed, over);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.categoryName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            over
                                ? 'Excedido ${money.format(item.spent - budget)}'
                                : 'Resta ${money.format(item.remaining)}',
                            style: TextStyle(
                              color: over
                                  ? const Color(0xFFFF8080)
                                  : const Color(0xFFA7AFBF),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Gastado ${money.format(item.spent)}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Presup. ${money.format(item.effectiveBudget)}',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: SizedBox(
                          height: 10,
                          child: LayoutBuilder(
                            builder: (_, constraints) {
                              final totalW = constraints.maxWidth;
                              final spentW = totalW * spentRatio;
                              final remainingW = totalW * remainingRatio;
                              return Stack(
                                children: [
                                  Container(
                                    width: totalW,
                                    height: 10,
                                    color: const Color(0xFF3B4254),
                                  ),
                                  if (spentW > 0)
                                    Positioned(
                                      left: 0,
                                      child: Container(
                                        width: spentW,
                                        height: 10,
                                        color: spentColor,
                                      ),
                                    ),
                                  if (!over && remainingW > 0)
                                    Positioned(
                                      left: spentW,
                                      child: Container(
                                        width: remainingW,
                                        height: 10,
                                        color: const Color(0xFF5A6275),
                                      ),
                                    ),
                                  if (over)
                                    Positioned(
                                      right: 0,
                                      child: Container(
                                        width: totalW * 0.22,
                                        height: 10,
                                        color: const Color(0xFFFF8080),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Color _spentColor(double percentUsed, bool over) {
    if (over || percentUsed >= 90) return const Color(0xFFFF8080);
    if (percentUsed >= 60) return const Color(0xFFFFB84D);
    return const Color(0xFF42D693);
  }
}
