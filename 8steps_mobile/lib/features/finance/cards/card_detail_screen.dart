import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../core/utils/app_alert.dart';
import '../../../core/utils/app_style.dart';
import '../../../modules/cards/models/app_card.dart';

enum _CardViewMode { charges, payments }

class CardDetailScreen extends ConsumerStatefulWidget {
  const CardDetailScreen({
    super.key,
    required this.cardId,
  });

  final String cardId;

  @override
  ConsumerState<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends ConsumerState<CardDetailScreen> {
  final _money = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  final _dt = DateFormat('yyyy-MM-dd HH:mm');
  final _monthText = DateFormat('MMMM yyyy');

  _CardViewMode _mode = _CardViewMode.charges;
  DateTime _selectedMonth =
      DateTime(DateTime.now().year, DateTime.now().month, 1);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.cardId.isEmpty) {
        AppAlert.error(context, 'Tarjeta inválida');
        return;
      }
      _reloadDetail();
      ref.read(accountsViewModelProvider.notifier).loadAccounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cardsViewModelProvider);
    final card = state.selectedCard;
    final monthPlans = state.installmentPlans;

    return Scaffold(
      backgroundColor: const Color(0xFF13151D),
      appBar: AppBar(
        title: Text(card?.name ?? 'Detalle tarjeta'),
        actions: [
          IconButton(
            onPressed: state.loading ? null : _reloadDetail,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: state.loading && card == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _reloadDetail(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (card != null) _CardSummary(card: card, money: _money),
                  const SizedBox(height: 14),
                  _ModeToggle(
                    mode: _mode,
                    onCharges: () =>
                        setState(() => _mode = _CardViewMode.charges),
                    onPayments: () =>
                        setState(() => _mode = _CardViewMode.payments),
                  ),
                  if (_mode == _CardViewMode.charges) ...[
                    const SizedBox(height: 12),
                    _MonthDropdownBar(
                      selectedMonth: _selectedMonth,
                      items: _monthOptions(),
                      monthLabel: _monthLabel,
                      onChanged: (month) async {
                        setState(() => _selectedMonth = month);
                        await _reloadDetail();
                      },
                    ),
                    const SizedBox(height: 12),
                    _SectionHeaderWithAction(
                      title: 'Cargos de este mes',
                      subtitle: 'Desliza a la derecha para editar o eliminar',
                      actionLabel: '+',
                      onAction: _openCreateChargeDialog,
                    ),
                    const SizedBox(height: 8),
                    if (state.charges.isEmpty)
                      const _EmptyLabel('Sin cargos registrados')
                    else
                      ...state.charges.map(
                        (charge) => _SwipeActionChargeTile(
                          charge: charge,
                          money: _money,
                          dt: _dt,
                          onEdit: () => _openEditChargeDialog(charge),
                          onDelete: () => _deleteCharge(charge),
                        ),
                      ),
                    const SizedBox(height: 18),
                    _SectionTitle(
                      title: 'Planes y cuotas del mes',
                      subtitle: _monthKey(_selectedMonth),
                    ),
                    const SizedBox(height: 8),
                    if (monthPlans.isEmpty)
                      const _EmptyLabel('No hay planes/cuotas en este mes')
                    else
                      ...monthPlans.map(
                        (plan) => _PlanTile(plan: plan, money: _money),
                      ),
                  ] else ...[
                    _SectionHeaderWithAction(
                      title: 'Pagos a tarjeta',
                      subtitle: 'Historial del mes seleccionado',
                      actionLabel: 'Pagar tarjeta',
                      onAction: _openCreatePaymentDialog,
                    ),
                    const SizedBox(height: 8),
                    if (state.payments.isEmpty)
                      const _EmptyLabel('Sin pagos registrados')
                    else
                      ...state.payments.map(
                        (payment) => _PaymentTile(
                          payment: payment,
                          money: _money,
                          dt: _dt,
                        ),
                      ),
                  ],
                ],
              ),
            ),
    );
  }

  List<DateTime> _monthOptions() {
    final now = DateTime.now();
    return List.generate(12, (index) {
      final month = DateTime(now.year, now.month - 5 + index, 1);
      return DateTime(month.year, month.month, 1);
    });
  }

  String _monthLabel(DateTime month) {
    final raw = _monthText.format(month);
    return '${raw[0].toUpperCase()}${raw.substring(1)}';
  }

  Future<void> _reloadDetail() async {
    final from = DateTime.utc(_selectedMonth.year, _selectedMonth.month, 1);
    final to = DateTime.utc(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
      23,
      59,
      59,
      999,
    );
    await ref.read(cardsViewModelProvider.notifier).loadCardDetail(
          widget.cardId,
          from: from,
          to: to,
          month: _monthKey(_selectedMonth),
        );
  }

  Future<void> _openCreateChargeDialog() async {
    await _openChargeDialog();
  }

  Future<void> _openEditChargeDialog(CardCharge charge) async {
    await _openChargeDialog(existing: charge);
  }

  Future<void> _openChargeDialog({CardCharge? existing}) async {
    final formKey = GlobalKey<FormState>();
    String name = existing?.name ?? '';
    String amountText = existing?.amount.toStringAsFixed(2) ?? '';
    DateTime occurredAt = existing?.occurredAt.toLocal() ?? DateTime.now();
    final rawType = (existing?.type ?? 'current').toLowerCase();
    String type =
        (rawType == 'deferred' || rawType == 'current') ? rawType : 'current';
    String installmentsText = (existing?.installmentsCount ?? 12).toString();
    String progressInstallmentsText =
        (existing?.progressInstallments ?? 0).toString();
    String startMonth = existing?.startMonth ?? _monthKey(_selectedMonth);

    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: Text(existing == null ? 'Nuevo cargo' : 'Editar cargo'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
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
                        validator: (v) {
                          final n = _parseAmount(v);
                          if (n == null || n <= 0) return 'Monto inválido';
                          return null;
                        },
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: type,
                        decoration: const InputDecoration(labelText: 'Tipo'),
                        items: const [
                          DropdownMenuItem(
                              value: 'current', child: Text('Corriente')),
                          DropdownMenuItem(
                              value: 'deferred', child: Text('Diferido')),
                        ],
                        onChanged: existing == null
                            ? (v) => setLocalState(() => type = v ?? type)
                            : null,
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
                              final date = await showDatePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                                initialDate: occurredAt,
                              );
                              if (date == null) return;
                              if (!context.mounted) return;
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(occurredAt),
                              );
                              if (time == null) return;
                              setLocalState(() {
                                occurredAt = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  time.hour,
                                  time.minute,
                                );
                              });
                            },
                            child: const Text('Fecha/Hora'),
                          ),
                        ],
                      ),
                      if (type == 'deferred') ...[
                        TextFormField(
                          initialValue: installmentsText,
                          decoration:
                              const InputDecoration(labelText: 'N° cuotas'),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => installmentsText = v,
                          validator: (v) {
                            final n = int.tryParse((v ?? '').trim());
                            if (n == null || n <= 1) return 'Inválido';
                            return null;
                          },
                        ),
                        TextFormField(
                          initialValue: progressInstallmentsText,
                          decoration: const InputDecoration(
                              labelText: 'Cuotas pagadas'),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => progressInstallmentsText = v,
                          validator: (v) {
                            final installments =
                                int.tryParse(installmentsText.trim()) ?? 0;
                            final progress = int.tryParse((v ?? '').trim());
                            if (progress == null || progress < 0) {
                              return 'Inválido';
                            }
                            if (installments > 0 && progress > installments) {
                              return 'No puede ser mayor a cuotas';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          initialValue: startMonth,
                          decoration:
                              const InputDecoration(labelText: 'Mes inicio'),
                          readOnly: true,
                          onTap: () async {
                            final pick = await showDatePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                              initialDate: DateTime.now(),
                              initialDatePickerMode: DatePickerMode.year,
                            );
                            if (pick == null) return;
                            setLocalState(() {
                              startMonth =
                                  _monthKey(DateTime(pick.year, pick.month, 1));
                            });
                          },
                        ),
                      ],
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
                      'type': type,
                      'occurredAt': occurredAt,
                      if (type == 'deferred')
                        'installmentsCount': int.parse(installmentsText.trim()),
                      if (type == 'deferred')
                        'progressInstallments':
                            int.parse(progressInstallmentsText.trim()),
                      if (type == 'deferred') 'startMonth': startMonth,
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
    await _afterDialogFrame();

    final vm = ref.read(cardsViewModelProvider.notifier);
    final ok = existing == null
        ? await vm.createCharge(
            cardId: widget.cardId,
            name: payload['name'] as String,
            amount: payload['amount'] as double,
            occurredAt: payload['occurredAt'] as DateTime,
            type: payload['type'] as String,
            installmentsCount: payload['installmentsCount'] as int?,
            progressInstallments: payload['progressInstallments'] as int?,
            startMonth: payload['startMonth'] as String?,
          )
        : await vm.updateCharge(
            cardId: widget.cardId,
            chargeId: existing.id,
            type: type,
            name: payload['name'] as String,
            amount: payload['amount'] as double,
            occurredAt: payload['occurredAt'] as DateTime,
            installmentsCount: payload['installmentsCount'] as int?,
            progressInstallments: payload['progressInstallments'] as int?,
            startMonth: payload['startMonth'] as String?,
          );

    if (!mounted) return;
    if (ok) {
      AppAlert.success(
          context, existing == null ? 'Cargo registrado' : 'Cargo actualizado');
    } else {
      final msg = ref.read(cardsViewModelProvider).errorMessage ??
          (existing == null
              ? 'No se pudo registrar cargo'
              : 'No se pudo editar cargo');
      AppAlert.error(context, msg);
    }
  }

  Future<void> _deleteCharge(CardCharge charge) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar cargo'),
          content: Text('¿Eliminar "${charge.name}"?'),
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
    await _afterDialogFrame();

    final ok = await ref.read(cardsViewModelProvider.notifier).deleteCharge(
          cardId: widget.cardId,
          chargeId: charge.id,
        );

    if (!mounted) return;
    if (ok) {
      AppAlert.success(context, 'Cargo eliminado');
    } else {
      final msg = ref.read(cardsViewModelProvider).errorMessage ??
          'No se pudo eliminar cargo';
      AppAlert.error(context, msg);
    }
  }

  Future<void> _openCreatePaymentDialog() async {
    final vm = ref.read(cardsViewModelProvider.notifier);
    final initialContext = await vm.getPaymentContext(cardId: widget.cardId);
    if (!mounted) return;
    if (initialContext == null) {
      AppAlert.error(
        context,
        ref.read(cardsViewModelProvider).errorMessage ??
            'No se pudo cargar contexto de pago',
      );
      return;
    }

    final accounts = ref.read(accountsViewModelProvider).accounts;
    final cardNextPayment =
        ref.read(cardsViewModelProvider).selectedCard?.nextPaymentAmount ?? 0;
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    var paymentContext = initialContext;
    final allocationControllers = <String, TextEditingController>{};
    for (final target in paymentContext.allocatableTargets) {
      allocationControllers[target.key] = TextEditingController();
    }

    final suggestedAmount = paymentContext.remainingDue > 0
        ? paymentContext.remainingDue
        : (paymentContext.dueThisPeriod > 0
            ? paymentContext.dueThisPeriod
            : cardNextPayment);
    final suggestedLabel = paymentContext.remainingDue > 0
        ? 'Monto total (pendiente del período)'
        : 'Monto total (próximo pago del mes)';
    var useSuggestedAmount = suggestedAmount > 0;
    if (useSuggestedAmount) {
      amountController.text = suggestedAmount.toStringAsFixed(2);
    }

    final paidAt = DateTime.now();
    String? fromAccountId = accounts.length == 1 ? accounts.first.id : null;
    String note = '';

    double currentAmount() => _parseAmount(amountController.text) ?? 0;
    double extraFromAmount(double amount) {
      if (paymentContext.remainingDue <= 0) return amount;
      return amount > paymentContext.remainingDue
          ? amount - paymentContext.remainingDue
          : 0;
    }

    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            final amount = currentAmount();
            final extra = extraFromAmount(amount);
            final showAllocations =
                extra > 0 || (paymentContext.remainingDue <= 0 && amount > 0);
            var allocatedSum = 0.0;
            for (final target in paymentContext.allocatableTargets) {
              allocatedSum +=
                  _parseAmount(allocationControllers[target.key]!.text) ?? 0;
            }
            final allocationsValid =
                !showAllocations || _sameAmount(allocatedSum, extra);
            final accountValid = accounts.length <= 1 || fromAccountId != null;
            final canSubmit = amount > 0 && allocationsValid && accountValid;

            return AlertDialog(
              title: const Text('Pagar tarjeta'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1E28),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0x332D364A)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Próximo pago: ${_money.format(paymentContext.dueThisPeriod)}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pagado período: ${_money.format(paymentContext.paidThisPeriod)}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pendiente período: ${_money.format(paymentContext.remainingDue)}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Deuda total: ${_money.format(paymentContext.totalDebt)}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {
                          setLocalState(() {
                            useSuggestedAmount = !useSuggestedAmount;
                            if (useSuggestedAmount) {
                              amountController.text =
                                  suggestedAmount.toStringAsFixed(2);
                            } else {
                              amountController.clear();
                            }
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: useSuggestedAmount
                                ? const Color(0xFFDDF6E8)
                                : const Color(0xFF1A1E28),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: useSuggestedAmount
                                  ? const Color(0xFF8ED9AE)
                                  : const Color(0x332D364A),
                            ),
                          ),
                          child: Text(
                            '$suggestedLabel (${_money.format(suggestedAmount)})',
                            style: TextStyle(
                              color: useSuggestedAmount
                                  ? const Color(0xFF1E5A37)
                                  : Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Paso 1: Define cuánto pagar',
                          style: TextStyle(
                            color: AppStyle.brandBlue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: amountController,
                        enabled: !useSuggestedAmount,
                        onChanged: (_) => setLocalState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Monto',
                          prefixText: '\$ ',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) {
                          final n = _parseAmount(v);
                          if (n == null || n <= 0) return 'Monto inválido';
                          return null;
                        },
                      ),
                      if (showAllocations) ...[
                        const SizedBox(height: 12),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Paso 2: Asigna el excedente',
                            style: TextStyle(
                              color: AppStyle.brandBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Excedente a asignar: ${_money.format(extra)}',
                          style: const TextStyle(
                            color: AppStyle.brandBlue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (paymentContext.allocatableTargets.isEmpty)
                          const Text(
                            'No hay destinos para asignar',
                            style: TextStyle(color: AppStyle.brandBlue),
                          )
                        else
                          ...paymentContext.allocatableTargets.map((target) {
                            final ctrl = allocationControllers[target.key]!;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: TextFormField(
                                controller: ctrl,
                                onChanged: (_) => setLocalState(() {}),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: InputDecoration(
                                  labelText:
                                      '${target.name} (${target.type == 'general_debt' ? 'deuda general' : 'cuota'})',
                                  helperText:
                                      'Saldo: ${_money.format(target.remainingBalance)}',
                                ),
                                validator: (_) {
                                  final n = _parseAmount(ctrl.text) ?? 0;
                                  if (n < 0) return 'Monto inválido';
                                  if (n > target.remainingBalance) {
                                    return 'Supera saldo pendiente';
                                  }
                                  return null;
                                },
                              ),
                            );
                          }),
                        const SizedBox(height: 4),
                        Text(
                          'Asignado: ${_money.format(allocatedSum)} / ${_money.format(extra)}',
                          style: TextStyle(
                            color: allocationsValid
                                ? const Color(0xFF4CD08A)
                                : const Color(0xFFF2A646),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      DropdownButtonFormField<String>(
                        initialValue: fromAccountId,
                        decoration:
                            const InputDecoration(labelText: 'Cuenta origen'),
                        items: accounts
                            .map(
                              (a) => DropdownMenuItem(
                                value: a.id,
                                child: Text(a.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setLocalState(() => fromAccountId = v),
                        validator: (_) {
                          if (accounts.length > 1 && fromAccountId == null) {
                            return 'Selecciona una cuenta';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Fecha y hora: ${_dt.format(paidAt)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppStyle.brandBlue,
                          ),
                        ),
                      ),
                      TextFormField(
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
                  onPressed: canSubmit
                      ? () {
                          if (!formKey.currentState!.validate()) return;
                          final allocations = <PaymentAllocationInput>[];
                          var sum = 0.0;
                          for (final target
                              in paymentContext.allocatableTargets) {
                            final raw = allocationControllers[target.key]!.text;
                            final parsed = _parseAmount(raw) ?? 0;
                            if (parsed > 0) {
                              sum += parsed;
                              allocations.add(
                                PaymentAllocationInput(
                                  targetType: target.type,
                                  targetId: target.id,
                                  amount: parsed,
                                ),
                              );
                            }
                          }

                          if (extra > 0 && !_sameAmount(sum, extra)) {
                            return;
                          }

                          Navigator.of(dialogContext).pop({
                            'amount': amount,
                            'fromAccountId': fromAccountId,
                            'paidAt': paidAt,
                            'allocations': allocations,
                            'note': note.trim(),
                          });
                        }
                      : null,
                  child: const Text('Pagar'),
                ),
              ],
            );
          },
        );
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      amountController.dispose();
      for (final ctrl in allocationControllers.values) {
        ctrl.dispose();
      }
    });

    if (payload == null || !mounted) return;
    await _afterDialogFrame();
    final result = await vm.submitPayment(
      cardId: widget.cardId,
      amount: payload['amount'] as double,
      fromAccountId: payload['fromAccountId'] as String?,
      date: payload['paidAt'] as DateTime,
      allocations: payload['allocations'] as List<PaymentAllocationInput>,
      note: payload['note'] as String,
    );

    if (!mounted) return;
    if (result.success) {
      AppAlert.success(context, result.message ?? 'Pago registrado');
      return;
    }

    if (result.requiresAllocation && result.paymentContext != null) {
      AppAlert.warning(
        context,
        'Debes asignar el excedente para continuar',
      );
      return;
    }

    if (result.message != null && result.message!.isNotEmpty) {
      AppAlert.error(context, result.message!);
    } else {
      AppAlert.error(context, 'No se pudo registrar pago');
    }
  }

  double? _parseAmount(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return double.tryParse(raw.trim().replaceAll(',', '.'));
  }

  String _monthKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    return '${date.year}-$month';
  }

  bool _sameAmount(double a, double b) => (a - b).abs() < 0.01;

  Future<void> _afterDialogFrame() {
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      completer.complete();
    });
    return completer.future;
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({
    required this.mode,
    required this.onCharges,
    required this.onPayments,
  });

  final _CardViewMode mode;
  final VoidCallback onCharges;
  final VoidCallback onPayments;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1E28),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x332D364A)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              selected: mode == _CardViewMode.charges,
              label: 'Cargo',
              onTap: onCharges,
            ),
          ),
          Expanded(
            child: _ModeButton(
              selected: mode == _CardViewMode.payments,
              label: 'Pagos',
              onTap: onPayments,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppStyle.brandBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _MonthDropdownBar extends StatelessWidget {
  const _MonthDropdownBar({
    required this.selectedMonth,
    required this.items,
    required this.monthLabel,
    required this.onChanged,
  });

  final DateTime selectedMonth;
  final List<DateTime> items;
  final String Function(DateTime month) monthLabel;
  final Future<void> Function(DateTime month) onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedValue =
        '${selectedMonth.year}-${selectedMonth.month.toString().padLeft(2, '0')}';

    return DropdownButtonFormField<String>(
      initialValue: selectedValue,
      dropdownColor: const Color(0xFF1A1E28),
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(labelText: 'Mes'),
      items: items
          .map(
            (month) => DropdownMenuItem<String>(
              value: '${month.year}-${month.month.toString().padLeft(2, '0')}',
              child: Text(
                monthLabel(month),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          )
          .toList(),
      onChanged: (value) async {
        if (value == null) return;
        final parts = value.split('-');
        if (parts.length != 2) return;
        final year = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        if (year == null || month == null) return;
        await onChanged(DateTime(year, month, 1));
      },
    );
  }
}

class _SectionHeaderWithAction extends StatelessWidget {
  const _SectionHeaderWithAction({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 3),
              Text(subtitle, style: const TextStyle(color: Colors.white54)),
            ],
          ),
        ),
        FilledButton(
          style: AppStyle.primaryButtonStyle(radius: 10),
          onPressed: onAction,
          child: Text(actionLabel),
        ),
      ],
    );
  }
}

class _CardSummary extends StatelessWidget {
  const _CardSummary({
    required this.card,
    required this.money,
  });

  final AppCard card;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF29437C), Color(0xFF8D4BA0)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen de tarjeta',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            card.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _summaryLine('Cupo', money.format(card.totalLimit)),
              _summaryLine('Deuda', money.format(card.currentDebt)),
              _summaryLine('Disponible', money.format(card.availableLimit)),
              _summaryLine('Pago', '${card.paymentDay}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryLine(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.white),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(color: Colors.white70),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.white54)),
      ],
    );
  }
}

class _SwipeActionChargeTile extends StatefulWidget {
  const _SwipeActionChargeTile({
    required this.charge,
    required this.money,
    required this.dt,
    required this.onEdit,
    required this.onDelete,
  });

  final CardCharge charge;
  final NumberFormat money;
  final DateFormat dt;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_SwipeActionChargeTile> createState() => _SwipeActionChargeTileState();
}

class _SwipeActionChargeTileState extends State<_SwipeActionChargeTile> {
  double _dx = 0;

  @override
  Widget build(BuildContext context) {
    final color =
        widget.charge.isDeferred ? const Color(0xFF4BC0FF) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Stack(
        children: [
          Positioned.fill(
            child: Row(
              children: [
                _ActionButton(
                  color: const Color(0xFF1F4E8C),
                  icon: Icons.edit,
                  label: 'Editar',
                  onTap: widget.onEdit,
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  color: const Color(0xFF8C2D2D),
                  icon: Icons.delete,
                  label: 'Eliminar',
                  onTap: widget.onDelete,
                ),
                const Spacer(),
              ],
            ),
          ),
          GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                _dx = (_dx + details.delta.dx).clamp(0, 160);
              });
            },
            onHorizontalDragEnd: (_) {
              setState(() {
                _dx = _dx > 70 ? 160 : 0;
              });
            },
            onTap: () {
              if (_dx != 0) {
                setState(() => _dx = 0);
              }
            },
            child: Transform.translate(
              offset: Offset(_dx, 0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1E28),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x332D364A)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.charge.name,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${widget.charge.type == 'deferred' ? 'Diferido' : 'Corriente'} · ${widget.dt.format(widget.charge.occurredAt.toLocal())}',
                            style: const TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      widget.money.format(widget.charge.amount),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.plan,
    required this.money,
  });

  final InstallmentPlan plan;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    final monthInstallment = plan.monthInstallment;
    final statusEs = _statusInSpanish(monthInstallment?.status);
    final fraction = monthInstallment != null && plan.totalInstallments > 0
        ? '${monthInstallment.installmentNumber}/${plan.totalInstallments}'
        : (plan.progressLabel ??
            '${plan.progressInstallments}/${plan.totalInstallments}');
    final subtitle = monthInstallment != null
        ? '$fraction · $statusEs'
        : '$fraction · Inicio ${plan.startMonth}';
    final amount = monthInstallment?.amount ?? plan.monthlyAmount;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1E28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x332D364A)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
          Text(
            money.format(amount),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  String _statusInSpanish(String? status) {
    switch ((status ?? '').toUpperCase()) {
      case 'PAID':
        return 'PAGADA';
      case 'PENDING':
        return 'PENDIENTE';
      case 'OVERDUE':
        return 'VENCIDA';
      case 'CANCELED':
        return 'CANCELADA';
      default:
        return (status ?? '').toUpperCase();
    }
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({
    required this.payment,
    required this.money,
    required this.dt,
  });

  final CardPayment payment;
  final NumberFormat money;
  final DateFormat dt;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1E28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x332D364A)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dt.format(payment.paidAt.toLocal()),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  payment.note?.isNotEmpty == true ? payment.note! : '-',
                  style: const TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
          Text(
            money.format(payment.amount),
            style: const TextStyle(
              color: Color(0xFF7CF3A0),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLabel extends StatelessWidget {
  const _EmptyLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1E28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x332D364A)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70),
      ),
    );
  }
}
