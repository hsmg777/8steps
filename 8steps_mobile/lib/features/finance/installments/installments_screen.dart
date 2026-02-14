import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../../core/utils/amount_parser.dart';
import '../../../data/local/app_database.dart';

class InstallmentsScreen extends ConsumerWidget {
  const InstallmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(installmentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cuotas / Deudas')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context, ref),
        child: const Icon(Icons.add),
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) return const Center(child: Text('Sin deudas'));
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final monthly =
                  (item.totalAmountCents / item.installmentsCount).round();
              return ListTile(
                title: Text(item.name),
                subtitle: Text(
                  '${item.installmentsPaid}/${item.installmentsCount} cuotas • Inicio ${DateFormatter.short(item.startDate)}',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(MoneyFormatter.formatCents(item.totalAmountCents)),
                    Text('Cuota: ${MoneyFormatter.formatCents(monthly)}'),
                  ],
                ),
                onTap: () => _openForm(context, ref, existing: item),
                onLongPress: () => ref
                    .read(financeControllerProvider)
                    .deleteInstallment(item.id),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref,
      {Installment? existing}) async {
    final categories =
        await ref.read(appDatabaseProvider).categoriesDao.getAll();
    if (context.mounted) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) =>
            _InstallmentForm(existing: existing, categories: categories),
      );
    }
  }
}

class _InstallmentForm extends ConsumerStatefulWidget {
  const _InstallmentForm({required this.categories, this.existing});

  final List<Category> categories;
  final Installment? existing;

  @override
  ConsumerState<_InstallmentForm> createState() => _InstallmentFormState();
}

class _InstallmentFormState extends ConsumerState<_InstallmentForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _totalCtrl;
  late final TextEditingController _countCtrl;
  late final TextEditingController _paidCtrl;
  late DateTime _startDate;
  String? _categoryId;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _totalCtrl = TextEditingController(
      text: e == null ? '' : (e.totalAmountCents / 100).toStringAsFixed(2),
    );
    _countCtrl =
        TextEditingController(text: (e?.installmentsCount ?? 1).toString());
    _paidCtrl =
        TextEditingController(text: (e?.installmentsPaid ?? 0).toString());
    _startDate = e?.startDate ?? DateTime.now();
    _categoryId = e?.categoryId ??
        (widget.categories.isNotEmpty ? widget.categories.first.id : null);
    _active = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _totalCtrl.dispose();
    _countCtrl.dispose();
    _paidCtrl.dispose();
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
              controller: _totalCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Monto total'),
              validator: (v) => AmountParser.textToCents(v ?? '') <= 0
                  ? 'Monto inválido'
                  : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _countCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Número de cuotas'),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Inválido';
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _paidCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cuotas pagadas'),
              validator: (v) {
                final paid = int.tryParse(v ?? '');
                final count = int.tryParse(_countCtrl.text) ?? 0;
                if (paid == null || paid < 0 || paid > count) return 'Inválido';
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
            Row(
              children: [
                Expanded(
                    child: Text('Inicio: ${DateFormatter.short(_startDate)}')),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      initialDate: _startDate,
                    );
                    if (picked != null) setState(() => _startDate = picked);
                  },
                  child: const Text('Elegir'),
                )
              ],
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
                  final total = AmountParser.textToCents(_totalCtrl.text);
                  final count = int.parse(_countCtrl.text);
                  final paid = int.parse(_paidCtrl.text);

                  if (widget.existing == null) {
                    await controller.createInstallment(
                      name: _nameCtrl.text.trim(),
                      totalAmountCents: total,
                      installmentsCount: count,
                      installmentsPaid: paid,
                      startDate: _startDate,
                      categoryId: _categoryId!,
                      isActive: _active,
                    );
                  } else {
                    await controller.updateInstallment(
                      id: widget.existing!.id,
                      name: _nameCtrl.text.trim(),
                      totalAmountCents: total,
                      installmentsCount: count,
                      installmentsPaid: paid,
                      startDate: _startDate,
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
