import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/utils/app_alert.dart';
import '../../../core/utils/app_style.dart';
import '../../../modules/categories/models/app_category.dart';
import '../../../modules/categories/models/budget_models.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(categoriesViewModelProvider.notifier)
          .load(_monthKey(_selectedMonth));
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoriesViewModelProvider);
    final statusById = <String, BudgetStatusItem>{
      for (final s in state.statuses) s.categoryId: s,
    };
    final categoriesById = <String, AppCategory>{
      for (final c in state.categories) c.id: c,
    };
    final carryoverById = <String, double>{
      for (final c in state.carryovers)
        if (c.categoryId != null && c.categoryId!.isNotEmpty)
          c.categoryId!: c.amount,
    };
    final carryoverByName = <String, double>{
      for (final c in state.carryovers) c.categoryName.toLowerCase(): c.amount,
    };

    final displayCategories = state.statuses.isNotEmpty
        ? state.statuses
            .map(
              (s) =>
                  categoriesById[s.categoryId] ??
                  AppCategory(
                    id: s.categoryId,
                    name: s.categoryName,
                    monthlyBudget: s.budget,
                  ),
            )
            .toList()
        : state.categories;

    return Scaffold(
      backgroundColor: const Color(0xFF13151D),
      appBar: AppBar(
        title: const Text('Categorías y Presupuesto'),
        actions: [
          IconButton(
            onPressed: state.loading
                ? null
                : () => ref
                    .read(categoriesViewModelProvider.notifier)
                    .load(_monthKey(_selectedMonth)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppStyle.brandBlue,
        onPressed: state.saving ? null : _openCreateCategory,
        child: const Icon(Icons.add),
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref
                  .read(categoriesViewModelProvider.notifier)
                  .load(_monthKey(_selectedMonth)),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _MonthSelector(
                    monthLabel: _monthKey(_selectedMonth),
                    onPick: _pickMonth,
                  ),
                  const SizedBox(height: 12),
                  _BudgetOverviewCard(
                    summary: state.summary,
                    affordability: state.affordability,
                  ),
                  const SizedBox(height: 10),
                  _CarryoversCard(carryovers: state.carryovers),
                  const SizedBox(height: 16),
                  if (displayCategories.isEmpty)
                    const _EmptyCategories()
                  else
                    ...displayCategories.map(
                      (category) {
                        final status = statusById[category.id];
                        final carryoverAdjustment =
                            status?.carryoverAdjustment ??
                                carryoverById[category.id] ??
                                carryoverByName[category.name.toLowerCase()] ??
                                0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CategoryCard(
                            category: category,
                            status: status,
                            carryoverAdjustment: carryoverAdjustment,
                            onEdit: () => _openEditCategory(category),
                            onDelete: () => _deleteCategory(category.id),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Future<void> _pickMonth() async {
    int selectedYear = _selectedMonth.year;
    int selectedMonth = _selectedMonth.month;

    final picked = await showDialog<DateTime>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setLocalState) {
            return AlertDialog(
              title: const Text('Seleccionar mes'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: selectedMonth,
                    decoration: const InputDecoration(labelText: 'Mes'),
                    items: List.generate(
                      12,
                      (index) => DropdownMenuItem<int>(
                        value: index + 1,
                        child: Text(_monthNames[index]),
                      ),
                    ),
                    onChanged: (value) {
                      if (value == null) return;
                      setLocalState(() => selectedMonth = value);
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: selectedYear,
                    decoration: const InputDecoration(labelText: 'Año'),
                    items: List.generate(
                      81,
                      (index) => 2020 + index,
                    ).map((year) {
                      return DropdownMenuItem<int>(
                        value: year,
                        child: Text('$year'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setLocalState(() => selectedYear = value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(
                      DateTime(selectedYear, selectedMonth, 1),
                    );
                  },
                  child: const Text('Aplicar'),
                ),
              ],
            );
          },
        );
      },
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedMonth = DateTime(picked.year, picked.month, 1);
    });
    await ref
        .read(categoriesViewModelProvider.notifier)
        .load(_monthKey(_selectedMonth));
  }

  Future<void> _openCreateCategory() async {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String budgetText = '';

    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Nueva categoría'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  onChanged: (v) => name = v,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                TextFormField(
                  decoration:
                      const InputDecoration(labelText: 'Presupuesto mensual'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) => budgetText = v,
                  validator: (v) =>
                      _parseAmount(v) == null ? 'Monto inválido' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.of(dialogContext).pop({
                  'name': name.trim(),
                  'monthlyBudget': _parseAmount(budgetText)!,
                });
              },
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );

    if (payload == null || !mounted) return;
    final ok =
        await ref.read(categoriesViewModelProvider.notifier).createCategory(
              name: payload['name'] as String,
              monthlyBudget: payload['monthlyBudget'] as double,
              month: _monthKey(_selectedMonth),
            );
    if (!mounted) return;

    if (ok) {
      final warning = ref.read(categoriesViewModelProvider).warning;
      if (warning != null) {
        AppAlert.warning(context, _warningText(warning));
      } else {
        AppAlert.success(context, 'Categoría creada');
      }
    } else {
      final msg = ref.read(categoriesViewModelProvider).errorMessage ??
          'No se pudo crear';
      AppAlert.error(context, msg);
    }
  }

  Future<void> _openEditCategory(AppCategory category) async {
    final formKey = GlobalKey<FormState>();
    String name = category.name;
    String budgetText = category.monthlyBudget.toStringAsFixed(2);

    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Editar categoría'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: category.name,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  onChanged: (v) => name = v,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                TextFormField(
                  initialValue: category.monthlyBudget.toStringAsFixed(2),
                  decoration:
                      const InputDecoration(labelText: 'Presupuesto mensual'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) => budgetText = v,
                  validator: (v) =>
                      _parseAmount(v) == null ? 'Monto inválido' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.of(dialogContext).pop({
                  'name': name.trim(),
                  'monthlyBudget': _parseAmount(budgetText)!,
                });
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (payload == null || !mounted) return;
    final ok =
        await ref.read(categoriesViewModelProvider.notifier).updateCategory(
              categoryId: category.id,
              name: payload['name'] as String,
              monthlyBudget: payload['monthlyBudget'] as double,
              month: _monthKey(_selectedMonth),
            );
    if (!mounted) return;

    if (ok) {
      final warning = ref.read(categoriesViewModelProvider).warning;
      if (warning != null) {
        AppAlert.warning(context, _warningText(warning));
      } else {
        AppAlert.success(context, 'Categoría actualizada');
      }
    } else {
      final msg = ref.read(categoriesViewModelProvider).errorMessage ??
          'No se pudo actualizar';
      AppAlert.error(context, msg);
    }
  }

  Future<void> _deleteCategory(String categoryId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar categoría'),
          content: const Text('¿Seguro que deseas eliminar esta categoría?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;
    final ok = await ref
        .read(categoriesViewModelProvider.notifier)
        .deleteCategory(categoryId);
    if (!mounted) return;

    if (ok) {
      AppAlert.success(context, 'Categoría eliminada');
    } else {
      final msg = ref.read(categoriesViewModelProvider).errorMessage ??
          'No se pudo eliminar';
      AppAlert.error(context, msg);
    }
  }

  String _monthKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    return '${date.year}-$month';
  }

  double? _parseAmount(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return double.tryParse(value.replaceAll(',', '.').trim());
  }

  String _warningText(CategoryWarning warning) {
    final overBy = warning.overBy;
    final recommended = warning.recommendedBudgetTotal;
    final attempted = warning.attemptedTotalBudget;

    if (overBy != null && recommended != null && attempted != null) {
      return '${warning.message} (Recomendado: \$${recommended.toStringAsFixed(2)}, '
          'Intentado: \$${attempted.toStringAsFixed(2)}, '
          'Exceso: \$${overBy.toStringAsFixed(2)})';
    }
    return warning.message;
  }

  static const _monthNames = <String>[
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({required this.monthLabel, required this.onPick});

  final String monthLabel;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Mes:',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: onPick,
          icon: const Icon(Icons.calendar_month),
          label: Text(monthLabel),
        ),
      ],
    );
  }
}

class _BudgetOverviewCard extends StatelessWidget {
  const _BudgetOverviewCard({
    required this.summary,
    required this.affordability,
  });

  final BudgetSummary summary;
  final BudgetAffordability affordability;

  @override
  Widget build(BuildContext context) {
    final month =
        affordability.month.isEmpty ? '-' : _monthName(affordability.month);
    final remaining = affordability.remainingToBudget;
    final remainingColor =
        remaining < 0 ? const Color(0xFFFF8080) : const Color(0xFF6AE7A3);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1E28),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x332D364A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen del presupuesto',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text('Mes: $month', style: const TextStyle(color: Colors.white70)),
          Text('Ya presupuestado: \$${summary.totalBudget.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white70)),
          Text('Gastado: \$${summary.totalSpent.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          Text(
            'Disponible para presupuestar: \$${remaining.toStringAsFixed(2)}',
            style: TextStyle(
              color: remainingColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(String monthKey) {
    final parts = monthKey.split('-');
    if (parts.length != 2) return monthKey;
    final year = parts[0];
    final month = int.tryParse(parts[1]) ?? 0;
    const monthNames = <String>[
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    if (month < 1 || month > 12) return monthKey;
    return '${monthNames[month - 1]} $year';
  }
}

class _CarryoversCard extends StatelessWidget {
  const _CarryoversCard({required this.carryovers});

  final List<BudgetCarryover> carryovers;

  @override
  Widget build(BuildContext context) {
    if (carryovers.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1E28),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x332D364A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Carry-overs',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          ...carryovers.map(
            (c) => Text(
              '${c.categoryName}: \$${c.amount.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.status,
    required this.carryoverAdjustment,
    required this.onEdit,
    required this.onDelete,
  });

  final AppCategory category;
  final BudgetStatusItem? status;
  final double carryoverAdjustment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final baseBudget = status?.budget ?? category.monthlyBudget;
    final effectiveBudget =
        status?.effectiveBudget ?? (baseBudget + carryoverAdjustment);
    final spent = status?.spent ?? 0;
    final remaining = status?.remaining ?? (effectiveBudget - spent);
    final percent = status?.percentUsed ??
        (effectiveBudget <= 0 ? 0 : (spent / effectiveBudget) * 100);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1E28),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x332D364A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  category.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, color: Colors.white70),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Presupuesto mes: \$${baseBudget.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white70),
          ),
          if (carryoverAdjustment != 0)
            Text(
              'Arrastre: ${carryoverAdjustment >= 0 ? '+' : ''}\$${carryoverAdjustment.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white70),
            ),
          Text('Presupuesto efectivo: \$${effectiveBudget.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white70)),
          Text('Gastado: \$${spent.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white70)),
          Text('Disponible: \$${remaining.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (percent / 100).clamp(0, 1),
              minHeight: 8,
              backgroundColor: Colors.white12,
              color: _progressColor(percent),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${percent.toStringAsFixed(0)}% usado ${_alertLabel(status?.alertLevel)}',
            style: const TextStyle(color: Colors.white60),
          ),
        ],
      ),
    );
  }

  String _alertLabel(String? level) {
    if (level == null || level.isEmpty || level.toUpperCase() == 'NONE') {
      return '';
    }
    return level;
  }

  Color _progressColor(double percent) {
    if (percent >= 100) return const Color(0xFFFF5B5B);
    if (percent >= 90) return const Color(0xFFFF9A45);
    if (percent >= 70) return const Color(0xFFE6B74F);
    return AppStyle.brandBlue;
  }
}

class _EmptyCategories extends StatelessWidget {
  const _EmptyCategories();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1E28),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x332D364A)),
      ),
      child: const Text(
        'No hay categorías aún. Crea una para comenzar.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white70),
      ),
    );
  }
}
