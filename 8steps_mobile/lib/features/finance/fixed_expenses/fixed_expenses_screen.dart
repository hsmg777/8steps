import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../../core/utils/amount_parser.dart';
import '../../../data/local/app_database.dart';

class FixedExpensesScreen extends ConsumerWidget {
  const FixedExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(fixedExpensesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Gastos Fijos')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context, ref),
        child: const Icon(Icons.add),
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty)
            return const Center(child: Text('Sin gastos fijos'));
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: Text(item.name),
                subtitle: Text('Día ${item.dayOfMonth}'),
                trailing: Text(MoneyFormatter.formatCents(item.amountCents)),
                onTap: () => _openForm(context, ref, existing: item),
                onLongPress: () => ref
                    .read(financeControllerProvider)
                    .deleteFixedExpense(item.id),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref,
      {FixedExpense? existing}) async {
    final categories =
        await ref.read(appDatabaseProvider).categoriesDao.getAll();
    if (context.mounted) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) =>
            _FixedExpenseForm(existing: existing, categories: categories),
      );
    }
  }
}

class _FixedExpenseForm extends ConsumerStatefulWidget {
  const _FixedExpenseForm({required this.categories, this.existing});

  final List<Category> categories;
  final FixedExpense? existing;

  @override
  ConsumerState<_FixedExpenseForm> createState() => _FixedExpenseFormState();
}

class _FixedExpenseFormState extends ConsumerState<_FixedExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _dayCtrl;
  String? _categoryId;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _amountCtrl = TextEditingController(
      text: e == null ? '' : (e.amountCents / 100).toStringAsFixed(2),
    );
    _dayCtrl = TextEditingController(text: (e?.dayOfMonth ?? 1).toString());
    _categoryId = e?.categoryId ??
        (widget.categories.isNotEmpty ? widget.categories.first.id : null);
    _active = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _dayCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
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
            TextFormField(
              controller: _dayCtrl,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Día de cobro (1-31)'),
              validator: (v) {
                final day = int.tryParse(v ?? '');
                if (day == null || day < 1 || day > 31) return 'Día inválido';
                return null;
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _categoryId,
              items: widget.categories
                  .where((c) => c.type == 'EXPENSE' || c.type == 'BOTH')
                  .map(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                  .toList(),
              onChanged: (v) => setState(() => _categoryId = v),
              decoration: const InputDecoration(labelText: 'Categoría'),
              validator: (v) => v == null ? 'Selecciona categoría' : null,
            ),
            SwitchListTile(
              value: _active,
              onChanged: (v) => setState(() => _active = v),
              title: const Text('Activo'),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  final controller = ref.read(financeControllerProvider);
                  if (widget.existing == null) {
                    await controller.createFixedExpense(
                      name: _nameCtrl.text.trim(),
                      amountCents: AmountParser.textToCents(_amountCtrl.text),
                      dayOfMonth: int.parse(_dayCtrl.text),
                      categoryId: _categoryId!,
                      isActive: _active,
                    );
                  } else {
                    await controller.updateFixedExpense(
                      id: widget.existing!.id,
                      name: _nameCtrl.text.trim(),
                      amountCents: AmountParser.textToCents(_amountCtrl.text),
                      dayOfMonth: int.parse(_dayCtrl.text),
                      categoryId: _categoryId!,
                      isActive: _active,
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
