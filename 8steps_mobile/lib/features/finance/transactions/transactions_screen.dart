import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../core/utils/app_alert.dart';
import '../../../core/utils/app_style.dart';
import '../../../modules/accounts/models/app_account.dart';
import '../../../modules/categories/models/app_category.dart';
import '../../../modules/transactions/models/app_transaction.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({
    super.key,
    this.onBack,
  });

  final VoidCallback? onBack;

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _money = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  final _dt = DateFormat('yyyy-MM-dd HH:mm');
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final txVm = ref.read(transactionsViewModelProvider.notifier);
      final accountsVm = ref.read(accountsViewModelProvider.notifier);
      final categoriesVm = ref.read(categoriesViewModelProvider.notifier);

      txVm.load();
      accountsVm.loadAccounts();
      categoriesVm.load(_monthKey(DateTime.now()));
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionsViewModelProvider);
    final accounts = ref.watch(accountsViewModelProvider).accounts;
    final categories = ref.watch(categoriesViewModelProvider).categories;

    return Scaffold(
      backgroundColor: const Color(0xFF13151D),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
              return;
            }
            Navigator.of(context).maybePop();
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text('Movimientos'),
        actions: [
          IconButton(
            onPressed: state.loading
                ? null
                : () => ref.read(transactionsViewModelProvider.notifier).load(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppStyle.brandBlue,
        onPressed:
            state.saving ? null : () => _openUpsertDialog(accounts, categories),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _FiltersToggleBar(
            visible: _showFilters,
            onToggle: () => setState(() => _showFilters = !_showFilters),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: _showFilters
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: _FiltersCard(
              state: state,
              accounts: accounts,
              categories: categories,
              onPickFrom: _pickFrom,
              onPickTo: _pickTo,
              onTypeChanged: (value) => ref
                  .read(transactionsViewModelProvider.notifier)
                  .setType(value),
              onAccountChanged: (value) => ref
                  .read(transactionsViewModelProvider.notifier)
                  .setAccount(value),
              onCategoryChanged: (value) => ref
                  .read(transactionsViewModelProvider.notifier)
                  .setCategory(value),
              onApply: () => ref
                  .read(transactionsViewModelProvider.notifier)
                  .load(page: 1),
              onClear: () {
                ref.read(transactionsViewModelProvider.notifier).clearFilters();
                ref.read(transactionsViewModelProvider.notifier).load(page: 1);
              },
            ),
            secondChild: const SizedBox.shrink(),
          ),
          Expanded(
            child: state.loading
                ? const Center(child: CircularProgressIndicator())
                : state.items.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay movimientos con estos filtros',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                        itemCount: state.items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final tx = state.items[index];
                          return _TransactionCard(
                            tx: tx,
                            amountText: _money.format(tx.amount),
                            dateText: _dt.format(tx.occurredAt.toLocal()),
                            onOpen: () => _openDetail(tx.id),
                            onEdit: () => _openUpsertDialog(
                                accounts, categories,
                                existing: tx),
                            onDelete: () => _deleteTransaction(tx.id),
                          );
                        },
                      ),
          ),
          _PaginationRow(
            page: state.page,
            totalPages: state.totalPages,
            canPrev: state.hasPrev && !state.loading,
            canNext: state.hasNext && !state.loading,
            onPrev: () => ref
                .read(transactionsViewModelProvider.notifier)
                .load(page: state.page - 1),
            onNext: () => ref
                .read(transactionsViewModelProvider.notifier)
                .load(page: state.page + 1),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFrom() async {
    final state = ref.read(transactionsViewModelProvider);
    final initial = state.from ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: initial,
    );
    if (picked == null) return;

    final from = DateTime(picked.year, picked.month, picked.day, 0, 0, 0);
    final to = state.to ?? DateTime.now();
    ref
        .read(transactionsViewModelProvider.notifier)
        .setDateRange(from: from, to: to);
  }

  Future<void> _pickTo() async {
    final state = ref.read(transactionsViewModelProvider);
    final initial = state.to ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: initial,
    );
    if (picked == null) return;

    final to = DateTime(picked.year, picked.month, picked.day, 23, 59, 59, 999);
    final from = state.from ?? DateTime.now();
    ref
        .read(transactionsViewModelProvider.notifier)
        .setDateRange(from: from, to: to);
  }

  Future<void> _openDetail(String id) async {
    final item =
        await ref.read(transactionsViewModelProvider.notifier).getById(id);
    if (!mounted) return;

    if (item == null) {
      final msg = ref.read(transactionsViewModelProvider).errorMessage ??
          'No se pudo cargar detalle';
      AppAlert.error(context, msg);
      return;
    }

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        return Dialog(
          alignment: Alignment.topCenter,
          insetPadding: const EdgeInsets.fromLTRB(18, 90, 18, 18),
          backgroundColor: const Color(0xFF1A1E28),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Detalle movimiento',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _detail('ID', item.id),
                _detail('Tipo', item.type),
                _detail('Monto', _money.format(item.amount)),
                _detail('Cuenta', item.accountName ?? item.accountId ?? '-'),
                _detail('Categoría', item.categoryName ?? item.categoryId ?? '-'),
                _detail('Fecha', _dt.format(item.occurredAt.toLocal())),
                _detail('Nota', item.note ?? '-'),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cerrar'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700),
            ),
            TextSpan(
                text: value, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteTransaction(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar movimiento'),
          content: const Text('¿Seguro que deseas eliminar este movimiento?'),
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
        .read(transactionsViewModelProvider.notifier)
        .deleteTransaction(id);
    if (!mounted) return;

    if (ok) {
      AppAlert.success(context, 'Movimiento eliminado');
    } else {
      final msg = ref.read(transactionsViewModelProvider).errorMessage ??
          'No se pudo eliminar';
      AppAlert.error(context, msg);
    }
  }

  Future<void> _openUpsertDialog(
    List<AppAccount> accounts,
    List<AppCategory> categories, {
    AppTransaction? existing,
  }) async {
    final formKey = GlobalKey<FormState>();

    String type = existing?.type.toLowerCase() ?? 'expense';
    String amountText = existing?.amount.toStringAsFixed(2) ?? '';
    String? accountId = existing?.accountId;
    String? categoryId = existing?.categoryId;
    DateTime occurredAt = existing?.occurredAt.toLocal() ?? DateTime.now();
    String note = existing?.note ?? '';

    if (accountId == null && accounts.length == 1) {
      accountId = accounts.first.id;
    }

    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: Text(
                  existing == null ? 'Nuevo movimiento' : 'Editar movimiento'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: type,
                        items: const [
                          DropdownMenuItem(
                              value: 'expense', child: Text('Egreso')),
                          DropdownMenuItem(
                              value: 'income', child: Text('Ingreso')),
                        ],
                        onChanged: (v) {
                          setLocalState(() {
                            type = v ?? 'expense';
                            if (type == 'income') {
                              categoryId = null;
                            }
                          });
                        },
                        decoration: const InputDecoration(labelText: 'Tipo'),
                      ),
                      TextFormField(
                        initialValue: amountText,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(labelText: 'Monto'),
                        onChanged: (v) => amountText = v,
                        validator: (v) {
                          final n = _parseAmount(v);
                          if (n == null || n <= 0) return 'Monto inválido';
                          return null;
                        },
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: accountId,
                        items: accounts
                            .map((a) => DropdownMenuItem(
                                value: a.id, child: Text(a.name)))
                            .toList(),
                        onChanged: (v) => accountId = v,
                        decoration: const InputDecoration(labelText: 'Cuenta'),
                        validator: (_) {
                          if (accounts.length > 1 && accountId == null) {
                            return 'Selecciona una cuenta';
                          }
                          return null;
                        },
                      ),
                      if (type == 'expense')
                        DropdownButtonFormField<String>(
                          initialValue: categoryId,
                          items: categories
                              .map((c) => DropdownMenuItem(
                                  value: c.id, child: Text(c.name)))
                              .toList(),
                          onChanged: (v) => categoryId = v,
                          decoration:
                              const InputDecoration(labelText: 'Categoría'),
                          validator: (_) {
                            if (categoryId == null) {
                              return 'Categoría requerida';
                            }
                            return null;
                          },
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _dt.format(occurredAt),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                                initialDate: occurredAt,
                              );
                              if (picked == null) return;
                              setLocalState(() {
                                occurredAt = DateTime(
                                  picked.year,
                                  picked.month,
                                  picked.day,
                                  occurredAt.hour,
                                  occurredAt.minute,
                                );
                              });
                            },
                            child: const Text('Fecha'),
                          ),
                          TextButton(
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(occurredAt),
                              );
                              if (picked == null) return;
                              setLocalState(() {
                                occurredAt = DateTime(
                                  occurredAt.year,
                                  occurredAt.month,
                                  occurredAt.day,
                                  picked.hour,
                                  picked.minute,
                                );
                              });
                            },
                            child: const Text('Hora'),
                          ),
                        ],
                      ),
                      TextFormField(
                        initialValue: note,
                        decoration: const InputDecoration(labelText: 'Motivo'),
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
                      'type': type,
                      'amount': _parseAmount(amountText)!,
                      'accountId': accountId,
                      'categoryId': categoryId,
                      'occurredAt': occurredAt,
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

    final resolvedAccountId = payload['accountId'] as String?;
    final finalAccountId =
        resolvedAccountId ?? (accounts.length == 1 ? accounts.first.id : null);

    final bool ok;
    if (existing == null) {
      ok = await ref
          .read(transactionsViewModelProvider.notifier)
          .createTransaction(
            type: payload['type'] as String,
            amount: payload['amount'] as double,
            accountId: finalAccountId,
            categoryId: payload['categoryId'] as String?,
            occurredAt: payload['occurredAt'] as DateTime,
            note: payload['note'] as String,
          );
    } else {
      ok = await ref
          .read(transactionsViewModelProvider.notifier)
          .updateTransaction(
            id: existing.id,
            type: payload['type'] as String,
            amount: payload['amount'] as double,
            accountId: finalAccountId,
            categoryId: payload['categoryId'] as String?,
            occurredAt: payload['occurredAt'] as DateTime,
            note: payload['note'] as String,
          );
    }

    if (!mounted) return;

    if (ok) {
      AppAlert.success(context,
          existing == null ? 'Movimiento creado' : 'Movimiento actualizado');
    } else {
      final msg = ref.read(transactionsViewModelProvider).errorMessage ??
          (existing == null ? 'No se pudo crear' : 'No se pudo actualizar');
      AppAlert.error(context, msg);
    }
  }

  double? _parseAmount(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  String _monthKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    return '${date.year}-$month';
  }
}

class _FiltersCard extends StatelessWidget {
  const _FiltersCard({
    required this.state,
    required this.accounts,
    required this.categories,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onTypeChanged,
    required this.onAccountChanged,
    required this.onCategoryChanged,
    required this.onApply,
    required this.onClear,
  });

  final dynamic state;
  final List<AppAccount> accounts;
  final List<AppCategory> categories;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<String?> onAccountChanged;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onApply;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('yyyy-MM-dd');
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0x334D5A73)),
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1E28),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x332D364A)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0x5560718E)),
                  ),
                  onPressed: onPickFrom,
                  child: Text(
                      'Desde: ${state.from == null ? '-' : dateFmt.format(state.from!)}'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0x5560718E)),
                  ),
                  onPressed: onPickTo,
                  child: Text(
                      'Hasta: ${state.to == null ? '-' : dateFmt.format(state.to!)}'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: state.type,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w500),
            dropdownColor: const Color(0xFF1F2430),
            iconEnabledColor: Colors.white70,
            items: const [
              DropdownMenuItem(value: null, child: Text('Tipo: todos')),
              DropdownMenuItem(value: 'income', child: Text('Ingreso')),
              DropdownMenuItem(value: 'expense', child: Text('Egreso')),
            ],
            onChanged: onTypeChanged,
            decoration: InputDecoration(
              labelText: 'Tipo',
              labelStyle: const TextStyle(color: Colors.white70),
              enabledBorder: inputBorder,
              focusedBorder: inputBorder.copyWith(
                borderSide: const BorderSide(color: AppStyle.brandBlue),
              ),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: state.accountId,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w500),
            dropdownColor: const Color(0xFF1F2430),
            iconEnabledColor: Colors.white70,
            items: [
              const DropdownMenuItem(value: null, child: Text('Cuenta: todas')),
              ...accounts.map(
                  (a) => DropdownMenuItem(value: a.id, child: Text(a.name))),
            ],
            onChanged: onAccountChanged,
            decoration: InputDecoration(
              labelText: 'Cuenta',
              labelStyle: const TextStyle(color: Colors.white70),
              enabledBorder: inputBorder,
              focusedBorder: inputBorder.copyWith(
                borderSide: const BorderSide(color: AppStyle.brandBlue),
              ),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: state.categoryId,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w500),
            dropdownColor: const Color(0xFF1F2430),
            iconEnabledColor: Colors.white70,
            items: [
              const DropdownMenuItem(
                  value: null, child: Text('Categoría: todas')),
              ...categories.map(
                  (c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
            ],
            onChanged: onCategoryChanged,
            decoration: InputDecoration(
              labelText: 'Categoría',
              labelStyle: const TextStyle(color: Colors.white70),
              enabledBorder: inputBorder,
              focusedBorder: inputBorder.copyWith(
                borderSide: const BorderSide(color: AppStyle.brandBlue),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: AppStyle.primaryButtonStyle(radius: 12),
                  onPressed: onApply,
                  child: const Text('Aplicar filtros'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0x5560718E)),
                  ),
                  onPressed: onClear,
                  child: const Text('Limpiar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FiltersToggleBar extends StatelessWidget {
  const _FiltersToggleBar({
    required this.visible,
    required this.onToggle,
  });

  final bool visible;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Color(0x5560718E)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: onToggle,
        icon: Icon(visible ? Icons.expand_less : Icons.expand_more),
        label: Text(visible ? 'Ocultar filtros' : 'Mostrar filtros'),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({
    required this.tx,
    required this.amountText,
    required this.dateText,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final AppTransaction tx;
  final String amountText;
  final String dateText;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color =
        tx.isExpense ? const Color(0xFFFF8A80) : const Color(0xFF71E6A7);

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1E28),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x332D364A)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.note?.isNotEmpty == true
                        ? tx.note!
                        : (tx.categoryName ?? tx.type),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${tx.accountName ?? tx.accountId ?? '-'} • $dateText',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(amountText,
                style: TextStyle(color: color, fontWeight: FontWeight.w700)),
            PopupMenuButton<String>(
              iconColor: Colors.white70,
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Editar')),
                PopupMenuItem(value: 'delete', child: Text('Eliminar')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaginationRow extends StatelessWidget {
  const _PaginationRow({
    required this.page,
    required this.totalPages,
    required this.canPrev,
    required this.canNext,
    required this.onPrev,
    required this.onNext,
  });

  final int page;
  final int totalPages;
  final bool canPrev;
  final bool canNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      color: const Color(0xFF11141C),
      child: Row(
        children: [
          OutlinedButton(
              onPressed: canPrev ? onPrev : null,
              child: const Text('Anterior')),
          const Spacer(),
          Text(
            'Página $page/$totalPages',
            style: const TextStyle(color: Colors.white70),
          ),
          const Spacer(),
          OutlinedButton(
              onPressed: canNext ? onNext : null,
              child: const Text('Siguiente')),
        ],
      ),
    );
  }
}
