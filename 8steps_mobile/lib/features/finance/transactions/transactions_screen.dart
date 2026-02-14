import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../../core/utils/amount_parser.dart';
import '../../../data/local/app_database.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(monthlyTransactionsProvider);
    final month = ref.watch(selectedMonthProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transacciones'),
        actions: [
          IconButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                initialDate: month,
                initialDatePickerMode: DatePickerMode.year,
              );
              if (picked != null) {
                ref.read(selectedMonthProvider.notifier).state =
                    DateTime(picked.year, picked.month, 1);
              }
            },
            icon: const Icon(Icons.filter_alt_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context, ref),
        child: const Icon(Icons.add),
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty)
            return const Center(child: Text('Sin transacciones en este mes'));
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isIncome = item.type == 'INCOME';
              return ListTile(
                title: Text(
                    item.note?.isNotEmpty == true ? item.note! : item.type),
                subtitle: Text(DateFormatter.short(item.date)),
                trailing: Text(
                  MoneyFormatter.formatCents(item.amountCents),
                  style: TextStyle(color: isIncome ? Colors.green : Colors.red),
                ),
                onTap: () => _openForm(context, ref, existing: item),
                onLongPress: () => ref
                    .read(financeControllerProvider)
                    .deleteTransaction(item.id),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref,
      {Transaction? existing}) async {
    final categories =
        await ref.read(appDatabaseProvider).categoriesDao.getAll();
    if (context.mounted) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) =>
            _TransactionForm(existing: existing, categories: categories),
      );
    }
  }
}

class _TransactionForm extends ConsumerStatefulWidget {
  const _TransactionForm({required this.categories, this.existing});

  final List<Category> categories;
  final Transaction? existing;

  @override
  ConsumerState<_TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends ConsumerState<_TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;
  late DateTime _date;
  late String _type;
  String? _categoryId;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _amountCtrl = TextEditingController(
      text: e == null ? '' : (e.amountCents / 100).toStringAsFixed(2),
    );
    _noteCtrl = TextEditingController(text: e?.note ?? '');
    _date = e?.date ?? DateTime.now();
    _type = e?.type ?? 'EXPENSE';
    _categoryId = e?.categoryId ??
        (widget.categories.isNotEmpty ? widget.categories.first.id : null);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.categories
        .where((c) => c.type == 'BOTH' || c.type == _type)
        .toList();
    if (categories.isNotEmpty && categories.every((c) => c.id != _categoryId)) {
      _categoryId = categories.first.id;
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _type,
              items: const [
                DropdownMenuItem(value: 'INCOME', child: Text('Ingreso')),
                DropdownMenuItem(value: 'EXPENSE', child: Text('Egreso')),
              ],
              onChanged: (v) => setState(() => _type = v ?? 'EXPENSE'),
              decoration: const InputDecoration(labelText: 'Tipo'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Monto'),
              validator: (v) => AmountParser.textToCents(v ?? '') <= 0
                  ? 'Monto inválido'
                  : null,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _categoryId,
              items: categories
                  .map(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                  .toList(),
              onChanged: (v) => setState(() => _categoryId = v),
              decoration: const InputDecoration(labelText: 'Categoría'),
              validator: (v) => v == null ? 'Selecciona categoría' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _noteCtrl,
              decoration: const InputDecoration(labelText: 'Nota (opcional)'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Text('Fecha: ${DateFormatter.short(_date)}')),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      initialDate: _date,
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                  child: const Text('Elegir'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;

                  final controller = ref.read(financeControllerProvider);
                  final amount = AmountParser.textToCents(_amountCtrl.text);

                  if (widget.existing == null) {
                    await controller.createTransaction(
                      type: _type,
                      amountCents: amount,
                      date: _date,
                      categoryId: _categoryId!,
                      note: _noteCtrl.text.trim().isEmpty
                          ? null
                          : _noteCtrl.text.trim(),
                    );
                  } else {
                    await controller.updateTransaction(
                      id: widget.existing!.id,
                      type: _type,
                      amountCents: amount,
                      date: _date,
                      categoryId: _categoryId!,
                      note: _noteCtrl.text.trim().isEmpty
                          ? null
                          : _noteCtrl.text.trim(),
                    );
                  }

                  if (mounted) Navigator.of(context).pop();
                },
                child: Text(widget.existing == null ? 'Crear' : 'Actualizar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
