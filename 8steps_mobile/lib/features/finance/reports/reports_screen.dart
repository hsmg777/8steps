import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../core/utils/app_alert.dart';
import '../../../core/utils/app_style.dart';
import '../../../modules/reports/models/report_models.dart';
import '../../../modules/reports/viewmodels/reports_view_model.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  final _money = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  late String _selectedMonth;
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = _formatMonth(now);
    _selectedYear = now.year;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(reportsViewModelProvider.notifier).loadInitial();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportsViewModelProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF13151D),
      appBar: AppBar(
        title: const Text('Reportería'),
        actions: [
          IconButton(
            onPressed: state.loading ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 26),
          children: [
            _PeriodSwitcher(
              selected: state.period,
              onChanged: (p) async {
                await ref.read(reportsViewModelProvider.notifier).setPeriod(p);
              },
            ),
            const SizedBox(height: 12),
            if (state.period == ReportPeriod.monthly)
              _MonthPicker(
                selectedMonth: _selectedMonth,
                months: _monthOptions(),
                onChanged: (value) async {
                  setState(() => _selectedMonth = value);
                  await ref
                      .read(reportsViewModelProvider.notifier)
                      .loadMonthly(month: value);
                },
              )
            else
              _YearPicker(
                selectedYear: _selectedYear,
                years: _yearOptions(),
                onChanged: (value) async {
                  setState(() => _selectedYear = value);
                  await ref
                      .read(reportsViewModelProvider.notifier)
                      .loadYearly(year: value);
                },
              ),
            const SizedBox(height: 14),
            if (state.loading)
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              if (state.errorMessage != null)
                _ErrorCard(
                  message: state.errorMessage!,
                  onRetry: _refresh,
                ),
              if (state.period == ReportPeriod.monthly && state.monthly != null)
                _MonthlyContent(
                  report: state.monthly!,
                  money: _money,
                ),
              if (state.period == ReportPeriod.yearly && state.yearly != null)
                _YearlyContent(
                  report: state.yearly!,
                  money: _money,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    final vm = ref.read(reportsViewModelProvider.notifier);
    final state = ref.read(reportsViewModelProvider);

    if (state.period == ReportPeriod.monthly) {
      await vm.loadMonthly(month: _selectedMonth);
    } else {
      await vm.loadYearly(year: _selectedYear);
    }

    if (!mounted) return;
    final error = ref.read(reportsViewModelProvider).errorMessage;
    if (error != null) {
      AppAlert.error(context, error);
    }
  }

  List<String> _monthOptions() {
    final now = DateTime.now();
    return List.generate(24, (index) {
      final d = DateTime(now.year, now.month - 12 + index, 1);
      return _formatMonth(d);
    });
  }

  List<int> _yearOptions() {
    final now = DateTime.now();
    return List.generate(7, (i) => now.year - 4 + i);
  }

  String _formatMonth(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    return '${date.year}-$m';
  }
}

class _PeriodSwitcher extends StatelessWidget {
  const _PeriodSwitcher({required this.selected, required this.onChanged});

  final ReportPeriod selected;
  final ValueChanged<ReportPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2130),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x332D364A)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PeriodButton(
              text: 'Mensual',
              active: selected == ReportPeriod.monthly,
              onTap: () => onChanged(ReportPeriod.monthly),
            ),
          ),
          Expanded(
            child: _PeriodButton(
              text: 'Anual',
              active: selected == ReportPeriod.yearly,
              onTap: () => onChanged(ReportPeriod.yearly),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodButton extends StatelessWidget {
  const _PeriodButton({
    required this.text,
    required this.active,
    required this.onTap,
  });

  final String text;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: active ? const Color(0x332FB9E2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: active ? AppStyle.brandBlue : Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthPicker extends StatelessWidget {
  const _MonthPicker({
    required this.selectedMonth,
    required this.months,
    required this.onChanged,
  });

  final String selectedMonth;
  final List<String> months;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2130),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x332D364A)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          dropdownColor: const Color(0xFF1A2130),
          value: selectedMonth,
          iconEnabledColor: Colors.white70,
          style: const TextStyle(color: Colors.white),
          items: months
              .map(
                (m) => DropdownMenuItem<String>(
                  value: m,
                  child: Text(
                    _monthLabel(m),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            onChanged(value);
          },
        ),
      ),
    );
  }

  String _monthLabel(String ym) {
    final parts = ym.split('-');
    if (parts.length != 2) return ym;
    final y = int.tryParse(parts[0]) ?? DateTime.now().year;
    final m = int.tryParse(parts[1]) ?? DateTime.now().month;
    final d = DateTime(y, m, 1);
    return DateFormat('MMMM yyyy', 'es').format(d);
  }
}

class _YearPicker extends StatelessWidget {
  const _YearPicker({
    required this.selectedYear,
    required this.years,
    required this.onChanged,
  });

  final int selectedYear;
  final List<int> years;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2130),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x332D364A)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          dropdownColor: const Color(0xFF1A2130),
          value: selectedYear,
          iconEnabledColor: Colors.white70,
          style: const TextStyle(color: Colors.white),
          items: years
              .map(
                (y) => DropdownMenuItem<int>(
                  value: y,
                  child: Text(
                    '$y',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            onChanged(value);
          },
        ),
      ),
    );
  }
}

class _MonthlyContent extends StatelessWidget {
  const _MonthlyContent({required this.report, required this.money});

  final MonthlyReport report;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BudgetUsageCard(
          budgeted: report.budgets.totalBudgeted,
          spent: report.budgets.totalSpentInCategories,
          variance: report.budgets.variance,
          percentUsed: report.budgets.percentUsed,
          money: money,
        ),
        const SizedBox(height: 12),
        _TrendsCard(
          title: '¿Te sobró o te faltó dinero por mes?',
          subtitle:
              'Cada barra es el resultado del mes: ingresos menos egresos.',
          points: report.trends
              .map((e) => _TrendBarPoint(label: e.month, net: e.net))
              .toList(),
        ),
        const SizedBox(height: 12),
        _CategoriesCard(
          title: 'Presupuesto vs real por categoría',
          rows: report.categories
              .map(
                (c) => _CategoryUsageRow(
                  name: c.categoryName,
                  budget: c.budget,
                  spent: c.spent,
                  percentUsed: c.percentUsed,
                ),
              )
              .toList(),
          money: money,
        ),
      ],
    );
  }
}

class _YearlyContent extends StatelessWidget {
  const _YearlyContent({required this.report, required this.money});

  final YearlyReport report;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TotalsCard(
          title: 'Totales del año',
          income: report.totals.income,
          expense: report.totals.expense,
          net: report.totals.net,
          money: money,
          footer:
              'Presupuestado: ${money.format(report.totals.budgeted)} • Variación: ${money.format(report.totals.budgetVariance)}',
        ),
        const SizedBox(height: 12),
        _TrendsCard(
          title: 'Resultado de cada mes del año',
          subtitle: 'Cada barra = ingresos menos egresos de ese mes.',
          points: report.monthly
              .map((e) => _TrendBarPoint(label: e.month, net: e.net))
              .toList(),
        ),
        const SizedBox(height: 12),
        _AnnualCategoriesCard(
          rows: report.categories,
          money: money,
        ),
      ],
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({
    required this.title,
    required this.income,
    required this.expense,
    required this.net,
    required this.money,
    this.footer,
  });

  final String title;
  final double income;
  final double expense;
  final double net;
  final NumberFormat money;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2130),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x332D364A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _line('Ingresos', money.format(income), const Color(0xFF42D693)),
          const SizedBox(height: 4),
          _line('Egresos', money.format(expense), const Color(0xFFFF8080)),
          const SizedBox(height: 4),
          _line(
            'Neto',
            money.format(net),
            net >= 0 ? AppStyle.brandBlue : const Color(0xFFFF8080),
          ),
          if (footer != null) ...[
            const SizedBox(height: 8),
            Text(
              footer!,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _line(String label, String value, Color color) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _BudgetUsageCard extends StatelessWidget {
  const _BudgetUsageCard({
    required this.budgeted,
    required this.spent,
    required this.variance,
    required this.percentUsed,
    required this.money,
  });

  final double budgeted;
  final double spent;
  final double variance;
  final double percentUsed;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    final used = percentUsed.clamp(0, 100) / 100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2130),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x332D364A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Presupuesto mensual',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 84,
                height: 84,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: 1,
                      strokeWidth: 8,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    CircularProgressIndicator(
                      value: used,
                      strokeWidth: 8,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppStyle.brandBlue),
                      backgroundColor: Colors.transparent,
                    ),
                    Text(
                      '${(used * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _line('Presupuestado', money.format(budgeted)),
                    const SizedBox(height: 4),
                    _line('Gastado', money.format(spent)),
                    const SizedBox(height: 4),
                    _line('Diferencia', money.format(variance)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _line(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: Colors.white70)),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _TrendBarPoint {
  const _TrendBarPoint({required this.label, required this.net});

  final String label;
  final double net;
}

class _TrendsCard extends StatelessWidget {
  const _TrendsCard({
    required this.title,
    required this.points,
    this.subtitle,
  });

  final String title;
  final List<_TrendBarPoint> points;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return _emptyCard(title, 'Sin datos para tendencia');
    }

    final maxAbs = points
        .map((e) => e.net.abs())
        .fold<double>(0, (prev, n) => math.max(prev, n));
    final normalizedMax = maxAbs == 0 ? 1.0 : maxAbs;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2130),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x332D364A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 8),
            const Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _LegendItem(
                  color: AppStyle.brandBlue,
                  text: 'Azul: te sobró dinero',
                ),
                _LegendItem(
                  color: Color(0xFFFF8080),
                  text: 'Rojo: te faltó dinero',
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: points.map((p) {
                final value = p.net.abs() / normalizedMax;
                final color =
                    p.net >= 0 ? AppStyle.brandBlue : const Color(0xFFFF8080);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: 95 * value + 8,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _monthShort(p.label),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(String title, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2130),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x332D364A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  String _monthShort(String raw) {
    final p = raw.split('-');
    if (p.length != 2) return raw;
    final y = int.tryParse(p[0]) ?? 0;
    final m = int.tryParse(p[1]) ?? 1;
    return DateFormat('MMM', 'es').format(DateTime(y, m, 1));
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

class _CategoryUsageRow {
  const _CategoryUsageRow({
    required this.name,
    required this.budget,
    required this.spent,
    required this.percentUsed,
  });

  final String name;
  final double budget;
  final double spent;
  final double percentUsed;
}

class _CategoriesCard extends StatelessWidget {
  const _CategoriesCard({
    required this.title,
    required this.rows,
    required this.money,
  });

  final String title;
  final List<_CategoryUsageRow> rows;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2130),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x332D364A)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text('No hay categorías para este periodo',
                style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2130),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x332D364A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...rows.map((c) {
            final percent = c.percentUsed.clamp(0, 100) / 100;
            final barColor = c.percentUsed >= 100
                ? const Color(0xFFFF8080)
                : (c.percentUsed >= 70
                    ? const Color(0xFFFFB84D)
                    : AppStyle.brandBlue);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '${c.percentUsed.toStringAsFixed(0)}%',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Gastado ${money.format(c.spent)} de ${money.format(c.budget)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: percent,
                      backgroundColor: const Color(0xFF3B4254),
                      valueColor: AlwaysStoppedAnimation<Color>(barColor),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _AnnualCategoriesCard extends StatelessWidget {
  const _AnnualCategoriesCard({required this.rows, required this.money});

  final List<YearlyCategoryReport> rows;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2130),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x332D364A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top categorías del año',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (rows.isEmpty)
            const Text('Sin datos', style: TextStyle(color: Colors.white70))
          else
            ...rows.take(8).map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            r.categoryName,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        Text(
                          money.format(r.annualSpent),
                          style: const TextStyle(
                            color: AppStyle.brandBlue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x33FF8080),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x66FF8080)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(color: Color(0xFFFFC0C0)),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ),
        ],
      ),
    );
  }
}
