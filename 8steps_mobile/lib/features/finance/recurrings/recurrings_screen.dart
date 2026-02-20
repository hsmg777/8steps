import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../core/utils/app_alert.dart';
import '../../../core/utils/app_style.dart';
import '../../../modules/recurrings/models/recurrent_item.dart';

class RecurringsScreen extends ConsumerStatefulWidget {
  const RecurringsScreen({super.key});

  @override
  ConsumerState<RecurringsScreen> createState() => _RecurringsScreenState();
}

class _RecurringsScreenState extends ConsumerState<RecurringsScreen> {
  final _money = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  final _date = DateFormat('yyyy-MM-dd');
  bool _showExpenses = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future.wait([
        ref.read(recurringsViewModelProvider.notifier).loadAll(),
        ref.read(accountsViewModelProvider.notifier).loadAccounts(),
        ref
            .read(categoriesViewModelProvider.notifier)
            .load(_monthKey(DateTime.now())),
        ref.read(cardsViewModelProvider.notifier).loadCards(),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recurringsViewModelProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF13151D),
      appBar: AppBar(
        title: const Text('Recurrentes'),
        actions: [
          IconButton(
            onPressed: state.loading
                ? null
                : () =>
                    ref.read(recurringsViewModelProvider.notifier).loadAll(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppStyle.brandBlue,
        onPressed: state.saving
            ? null
            : () => _showExpenses ? _openExpenseDialog() : _openIncomeDialog(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<bool>(
              style: ButtonStyle(
                foregroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? Colors.white
                      : Colors.white70,
                ),
                backgroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? AppStyle.brandBlue
                      : const Color(0x1F2FB9E2),
                ),
                side: const WidgetStatePropertyAll(
                  BorderSide(color: Color(0x333A465A)),
                ),
              ),
              segments: const [
                ButtonSegment<bool>(
                  value: true,
                  label: Text('Gastos recurrentes'),
                  icon: Icon(Icons.trending_down),
                ),
                ButtonSegment<bool>(
                  value: false,
                  label: Text('Ingresos recurrentes'),
                  icon: Icon(Icons.trending_up),
                ),
              ],
              selected: {_showExpenses},
              onSelectionChanged: (selection) {
                if (selection.isEmpty) return;
                setState(() => _showExpenses = selection.first);
              },
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: state.loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => ref
                        .read(recurringsViewModelProvider.notifier)
                        .loadAll(),
                    child: _showExpenses
                        ? _buildExpensesList(state)
                        : _buildIncomesList(state),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesList(state) {
    if (state.expenses.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 220),
          Center(
            child: Text(
              'No tienes gastos recurrentes',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
      itemCount: state.expenses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = state.expenses[index];
        final statusActive = item.status.toLowerCase() == 'active';

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2130),
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
                      item.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  _StatusChip(active: statusActive),
                  PopupMenuButton<String>(
                    color: const Color(0xFF1A2130),
                    iconColor: Colors.white,
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _openExpenseDialog(existing: item);
                        case 'toggle':
                          _toggleExpense(item);
                        case 'delete':
                          _deleteExpense(item);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text(
                          'Editar',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Text(
                          statusActive ? 'Pausar' : 'Reanudar',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Eliminar',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _money.format(item.amount),
                style: const TextStyle(
                  color: Color(0xFFFF8C8C),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_frequencyEs(item.frequency)} • ${item.method == 'card' ? 'Tarjeta' : 'Cuenta'}',
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                'Inicio: ${_date.format(item.startAt.toLocal())}',
                style: const TextStyle(color: Colors.white60),
              ),
              if ((item.note ?? '').isNotEmpty)
                Text(
                  item.note!,
                  style: const TextStyle(color: Colors.white60),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIncomesList(state) {
    if (state.incomes.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 220),
          Center(
            child: Text(
              'No tienes ingresos recurrentes',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
      itemCount: state.incomes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = state.incomes[index];
        final statusActive = item.status.toLowerCase() == 'active';

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2130),
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
                      item.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  _StatusChip(active: statusActive),
                  PopupMenuButton<String>(
                    color: const Color(0xFF1A2130),
                    iconColor: Colors.white,
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _openIncomeDialog(existing: item);
                        case 'toggle':
                          _toggleIncome(item);
                        case 'delete':
                          _deleteIncome(item);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text(
                          'Editar',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Text(
                          statusActive ? 'Pausar' : 'Reanudar',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Eliminar',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _money.format(item.amount),
                style: const TextStyle(
                  color: Color(0xFF6AE7A3),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _frequencyEs(item.frequency),
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                'Inicio: ${_date.format(item.startAt.toLocal())}',
                style: const TextStyle(color: Colors.white60),
              ),
              if ((item.note ?? '').isNotEmpty)
                Text(
                  item.note!,
                  style: const TextStyle(color: Colors.white60),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openExpenseDialog({RecurrentExpense? existing}) async {
    final accounts = ref
        .read(accountsViewModelProvider)
        .accounts
        .where((a) => a.isActive)
        .toList();
    final categories = ref.read(categoriesViewModelProvider).categories;
    final cards = ref.read(cardsViewModelProvider).cards;

    final formKey = GlobalKey<FormState>();
    String name = existing?.name ?? '';
    String amountText =
        existing == null ? '' : existing.amount.toStringAsFixed(2);
    String frequency = _resolveFrequency(existing?.frequency);
    DateTime startAt = existing?.startAt ?? DateTime.now();
    String method = _resolveMethod(existing?.method);
    String? accountId =
        existing?.accountId ?? (accounts.isNotEmpty ? accounts.first.id : null);
    String? cardId =
        existing?.cardId ?? (cards.isNotEmpty ? cards.first.id : null);
    String? categoryId = existing?.categoryId ??
        (categories.isNotEmpty ? categories.first.id : null);
    String note = existing?.note ?? '';

    if (accountId != null && !accounts.any((a) => a.id == accountId)) {
      accountId = accounts.isNotEmpty ? accounts.first.id : null;
    }
    if (cardId != null && !cards.any((c) => c.id == cardId)) {
      cardId = cards.isNotEmpty ? cards.first.id : null;
    }
    if (categoryId != null && !categories.any((c) => c.id == categoryId)) {
      categoryId = categories.isNotEmpty ? categories.first.id : null;
    }

    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: Text(existing == null
                  ? 'Nuevo gasto recurrente'
                  : 'Editar gasto recurrente'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        initialValue: name,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                        onChanged: (v) => name = v,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Requerido'
                            : null,
                      ),
                      TextFormField(
                        initialValue: amountText,
                        decoration: const InputDecoration(labelText: 'Monto'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (v) => amountText = v,
                        validator: (v) =>
                            _parseAmount(v) == null ? 'Monto inválido' : null,
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: frequency,
                        decoration:
                            const InputDecoration(labelText: 'Frecuencia'),
                        items: recurringFrequencies
                            .map((f) => DropdownMenuItem(
                                value: f, child: Text(_frequencyEs(f))))
                            .toList(),
                        onChanged: (value) => setLocal(() =>
                            frequency = value ?? recurringFrequencies.first),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () async {
                            final picked = await _pickDateOnly(startAt);
                            if (picked != null) {
                              setLocal(() => startAt = picked);
                            }
                          },
                          icon: const Icon(Icons.event),
                          label:
                              Text('Fecha: ${_date.format(startAt.toLocal())}'),
                        ),
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: method,
                        decoration: const InputDecoration(labelText: 'Método'),
                        items: const [
                          DropdownMenuItem(
                              value: 'account', child: Text('Cuenta')),
                          DropdownMenuItem(
                              value: 'card', child: Text('Tarjeta')),
                        ],
                        onChanged: (value) {
                          setLocal(() {
                            method = _resolveMethod(value);
                          });
                        },
                      ),
                      if (method == 'account') ...[
                        DropdownButtonFormField<String>(
                          initialValue: accountId,
                          decoration:
                              const InputDecoration(labelText: 'Cuenta'),
                          items: accounts
                              .map((a) => DropdownMenuItem(
                                  value: a.id, child: Text(a.name)))
                              .toList(),
                          onChanged: (value) =>
                              setLocal(() => accountId = value),
                          validator: (_) => accountId == null
                              ? 'Selecciona una cuenta'
                              : null,
                        ),
                        DropdownButtonFormField<String>(
                          initialValue: categoryId,
                          decoration:
                              const InputDecoration(labelText: 'Categoría'),
                          items: categories
                              .map((c) => DropdownMenuItem(
                                  value: c.id, child: Text(c.name)))
                              .toList(),
                          onChanged: (value) =>
                              setLocal(() => categoryId = value),
                          validator: (_) => categoryId == null
                              ? 'Selecciona una categoría'
                              : null,
                        ),
                      ] else ...[
                        DropdownButtonFormField<String>(
                          initialValue: cardId,
                          decoration:
                              const InputDecoration(labelText: 'Tarjeta'),
                          items: cards
                              .map((c) => DropdownMenuItem(
                                  value: c.id, child: Text(c.name)))
                              .toList(),
                          onChanged: (value) => setLocal(() => cardId = value),
                          validator: (_) =>
                              cardId == null ? 'Selecciona una tarjeta' : null,
                        ),
                      ],
                      TextFormField(
                        initialValue: note,
                        decoration:
                            const InputDecoration(labelText: 'Nota (opcional)'),
                        onChanged: (v) => note = v,
                      ),
                    ],
                  ),
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
                      'amount': _parseAmount(amountText)!,
                      'frequency': frequency,
                      'startAt': startAt,
                      'method': method,
                      'accountId': accountId,
                      'cardId': cardId,
                      'categoryId': categoryId,
                      'note': note.trim(),
                    });
                  },
                  child: Text(existing == null ? 'Crear' : 'Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (payload == null || !mounted) return;
    final notifier = ref.read(recurringsViewModelProvider.notifier);
    final ok = existing == null
        ? await notifier.createExpense(
            name: payload['name'] as String,
            amount: payload['amount'] as double,
            frequency: payload['frequency'] as String,
            startAt: payload['startAt'] as DateTime,
            method: payload['method'] as String,
            accountId: payload['method'] == 'account'
                ? payload['accountId'] as String?
                : null,
            cardId: payload['method'] == 'card'
                ? payload['cardId'] as String?
                : null,
            categoryId: payload['method'] == 'account'
                ? payload['categoryId'] as String?
                : null,
            note: payload['note'] as String,
          )
        : await notifier.updateExpense(
            id: existing.id,
            name: payload['name'] as String,
            amount: payload['amount'] as double,
            frequency: payload['frequency'] as String,
            startAt: payload['startAt'] as DateTime,
            method: payload['method'] as String,
            accountId: payload['method'] == 'account'
                ? payload['accountId'] as String?
                : null,
            cardId: payload['method'] == 'card'
                ? payload['cardId'] as String?
                : null,
            categoryId: payload['method'] == 'account'
                ? payload['categoryId'] as String?
                : null,
            note: payload['note'] as String,
          );

    if (!mounted) return;
    if (ok) {
      AppAlert.success(
          context,
          existing == null
              ? 'Gasto recurrente creado'
              : 'Gasto recurrente actualizado');
    } else {
      AppAlert.error(
          context,
          ref.read(recurringsViewModelProvider).errorMessage ??
              'Ocurrió un error');
    }
  }

  Future<void> _openIncomeDialog({RecurrentIncome? existing}) async {
    final accounts = ref
        .read(accountsViewModelProvider)
        .accounts
        .where((a) => a.isActive)
        .toList();

    final formKey = GlobalKey<FormState>();
    String name = existing?.name ?? '';
    String amountText =
        existing == null ? '' : existing.amount.toStringAsFixed(2);
    String frequency = _resolveFrequency(existing?.frequency);
    DateTime startAt = existing?.startAt ?? DateTime.now();
    String? accountId =
        existing?.accountId ?? (accounts.isNotEmpty ? accounts.first.id : null);
    String note = existing?.note ?? '';

    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: Text(existing == null
                  ? 'Nuevo ingreso recurrente'
                  : 'Editar ingreso recurrente'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        initialValue: name,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                        onChanged: (v) => name = v,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Requerido'
                            : null,
                      ),
                      TextFormField(
                        initialValue: amountText,
                        decoration: const InputDecoration(labelText: 'Monto'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (v) => amountText = v,
                        validator: (v) =>
                            _parseAmount(v) == null ? 'Monto inválido' : null,
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: frequency,
                        decoration:
                            const InputDecoration(labelText: 'Frecuencia'),
                        items: recurringFrequencies
                            .map((f) => DropdownMenuItem(
                                value: f, child: Text(_frequencyEs(f))))
                            .toList(),
                        onChanged: (value) => setLocal(() =>
                            frequency = value ?? recurringFrequencies.first),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () async {
                            final picked = await _pickDateOnly(startAt);
                            if (picked != null) {
                              setLocal(() => startAt = picked);
                            }
                          },
                          icon: const Icon(Icons.event),
                          label:
                              Text('Fecha: ${_date.format(startAt.toLocal())}'),
                        ),
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: accountId,
                        decoration:
                            const InputDecoration(labelText: 'Cuenta destino'),
                        items: accounts
                            .map((a) => DropdownMenuItem(
                                value: a.id, child: Text(a.name)))
                            .toList(),
                        onChanged: (value) => setLocal(() => accountId = value),
                        validator: (_) =>
                            accountId == null ? 'Selecciona una cuenta' : null,
                      ),
                      TextFormField(
                        initialValue: note,
                        decoration:
                            const InputDecoration(labelText: 'Nota (opcional)'),
                        onChanged: (v) => note = v,
                      ),
                    ],
                  ),
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
                      'amount': _parseAmount(amountText)!,
                      'frequency': frequency,
                      'startAt': startAt,
                      'accountId': accountId,
                      'note': note.trim(),
                    });
                  },
                  child: Text(existing == null ? 'Crear' : 'Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (payload == null || !mounted) return;
    final notifier = ref.read(recurringsViewModelProvider.notifier);
    final ok = existing == null
        ? await notifier.createIncome(
            name: payload['name'] as String,
            amount: payload['amount'] as double,
            frequency: payload['frequency'] as String,
            startAt: payload['startAt'] as DateTime,
            accountId: payload['accountId'] as String,
            note: payload['note'] as String,
          )
        : await notifier.updateIncome(
            id: existing.id,
            name: payload['name'] as String,
            amount: payload['amount'] as double,
            frequency: payload['frequency'] as String,
            startAt: payload['startAt'] as DateTime,
            accountId: payload['accountId'] as String,
            note: payload['note'] as String,
          );

    if (!mounted) return;
    if (ok) {
      AppAlert.success(
          context,
          existing == null
              ? 'Ingreso recurrente creado'
              : 'Ingreso recurrente actualizado');
    } else {
      AppAlert.error(
          context,
          ref.read(recurringsViewModelProvider).errorMessage ??
              'Ocurrió un error');
    }
  }

  Future<void> _toggleExpense(RecurrentExpense item) async {
    final toStatus =
        item.status.toLowerCase() == 'active' ? 'paused' : 'active';
    final ok =
        await ref.read(recurringsViewModelProvider.notifier).updateExpense(
              id: item.id,
              status: toStatus,
            );
    if (!mounted) return;
    if (ok) {
      AppAlert.success(
          context, toStatus == 'active' ? 'Gasto reanudado' : 'Gasto pausado');
    } else {
      AppAlert.error(
          context,
          ref.read(recurringsViewModelProvider).errorMessage ??
              'Ocurrió un error');
    }
  }

  Future<void> _toggleIncome(RecurrentIncome item) async {
    final toStatus =
        item.status.toLowerCase() == 'active' ? 'paused' : 'active';
    final ok =
        await ref.read(recurringsViewModelProvider.notifier).updateIncome(
              id: item.id,
              status: toStatus,
            );
    if (!mounted) return;
    if (ok) {
      AppAlert.success(context,
          toStatus == 'active' ? 'Ingreso reanudado' : 'Ingreso pausado');
    } else {
      AppAlert.error(
          context,
          ref.read(recurringsViewModelProvider).errorMessage ??
              'Ocurrió un error');
    }
  }

  Future<void> _deleteExpense(RecurrentExpense item) async {
    final confirm = await _confirmDelete('Eliminar gasto recurrente');
    if (!confirm || !mounted) return;
    final ok = await ref
        .read(recurringsViewModelProvider.notifier)
        .deleteExpense(item.id);
    if (!mounted) return;
    if (ok) {
      AppAlert.success(context, 'Gasto recurrente eliminado');
    } else {
      AppAlert.error(
          context,
          ref.read(recurringsViewModelProvider).errorMessage ??
              'Ocurrió un error');
    }
  }

  Future<void> _deleteIncome(RecurrentIncome item) async {
    final confirm = await _confirmDelete('Eliminar ingreso recurrente');
    if (!confirm || !mounted) return;
    final ok = await ref
        .read(recurringsViewModelProvider.notifier)
        .deleteIncome(item.id);
    if (!mounted) return;
    if (ok) {
      AppAlert.success(context, 'Ingreso recurrente eliminado');
    } else {
      AppAlert.error(
          context,
          ref.read(recurringsViewModelProvider).errorMessage ??
              'Ocurrió un error');
    }
  }

  Future<bool> _confirmDelete(String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: const Text('¿Deseas continuar?'),
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
    return confirm == true;
  }

  Future<DateTime?> _pickDateOnly(DateTime initial) async {
    final pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: initial,
    );
    if (pickedDate == null || !mounted) return null;
    return DateTime(pickedDate.year, pickedDate.month, pickedDate.day);
  }

  double? _parseAmount(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return double.tryParse(value.replaceAll(',', '.').trim());
  }

  String _monthKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    return '${date.year}-$month';
  }

  String _frequencyEs(String frequency) {
    switch (_normalizeFrequency(frequency)) {
      case 'monthly':
        return 'Mensual';
      case 'quarterly':
        return 'Trimestral';
      case 'semiannual':
        return 'Semestral';
      case 'annual':
        return 'Anual';
      default:
        return frequency;
    }
  }

  String _resolveFrequency(String? value) {
    final normalized = _normalizeFrequency(value ?? '');
    if (recurringFrequencies.contains(normalized)) {
      return normalized;
    }
    return recurringFrequencies.first;
  }

  String _normalizeFrequency(String value) {
    return value.trim().toLowerCase();
  }

  String _resolveMethod(String? value) {
    final method = (value ?? '').trim().toLowerCase();
    if (method == 'card') return 'card';
    return 'account';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: active ? const Color(0x1F46D98A) : const Color(0x33F9A825),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active ? const Color(0xFF46D98A) : const Color(0xFFF9A825),
        ),
      ),
      child: Text(
        active ? 'Activo' : 'Pausado',
        style: TextStyle(
          color: active ? const Color(0xFF46D98A) : const Color(0xFFF9A825),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
