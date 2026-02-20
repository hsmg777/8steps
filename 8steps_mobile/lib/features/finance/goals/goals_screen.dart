import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../core/utils/app_alert.dart';
import '../../../core/utils/app_style.dart';
import '../../../modules/accounts/models/app_account.dart';
import '../../../modules/goals/models/goal_models.dart';
import 'widgets/goal_card_item.dart';
import 'widgets/goal_recommendation_section.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  final _money = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  final _date = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future.wait([
        ref.read(goalsViewModelProvider.notifier).loadGoals(),
        ref.read(accountsViewModelProvider.notifier).loadAccounts(),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(goalsViewModelProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF13151D),
      appBar: AppBar(
        leading: widget.onBack == null
            ? null
            : IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back),
              ),
        title: const Text('Metas y ahorros'),
        actions: [
          IconButton(
            onPressed: state.loading
                ? null
                : () => ref.read(goalsViewModelProvider.notifier).loadGoals(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppStyle.brandBlue,
        onPressed: state.saving ? null : _openCreateGoal,
        child: const Icon(Icons.add),
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(goalsViewModelProvider.notifier).loadGoals(),
              child: state.goals.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 220),
                        Center(
                          child: Text(
                            'Aún no tienes metas',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 90),
                      itemBuilder: (_, index) => GoalCardItem(
                        goal: state.goals[index],
                        money: _money,
                        date: _date,
                        onTap: () => _openGoalDetail(state.goals[index]),
                        onContribute: () => _openContributionDialog(
                          goal: state.goals[index],
                        ),
                        onAuto: () => _openAutoContributionDialog(
                          goal: state.goals[index],
                        ),
                        onEdit: () => _openEditGoal(state.goals[index]),
                        onDelete: () => _deleteGoal(state.goals[index]),
                      ),
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemCount: state.goals.length,
                    ),
            ),
    );
  }

  Future<void> _openCreateGoal() async {
    final accounts = ref.read(accountsViewModelProvider).accounts;
    if (accounts.isEmpty) {
      AppAlert.error(context, 'Necesitas al menos una cuenta para aportar');
      return;
    }

    final payload = await showDialog<_CreateGoalPayload>(
      context: context,
      builder: (_) => _CreateGoalDialog(accounts: accounts),
    );

    if (!mounted || payload == null) return;

    final vm = ref.read(goalsViewModelProvider.notifier);
    final goal = await vm.createGoal(
      name: payload.name,
      type: payload.type,
      targetAmount: payload.targetAmount,
      targetDate: payload.targetDate,
    );

    if (!mounted) return;
    if (goal == null) {
      AppAlert.error(
        context,
        ref.read(goalsViewModelProvider).errorMessage ??
            'No se pudo crear meta',
      );
      return;
    }

    var followUpOk = true;

    if (payload.setupMode == GoalSetupMode.manualNow) {
      followUpOk = await vm.createContribution(
        goalId: goal.id,
        fromAccountId: payload.manualAccountId!,
        amount: payload.manualAmount!,
        date: DateTime.now(),
        note: payload.manualNote,
      );
    }

    if (payload.setupMode == GoalSetupMode.automatic) {
      final nextRunDate = _nextRunDate(payload.autoDayOfMonth!);
      followUpOk = await vm.upsertAutoContribution(
        goalId: goal.id,
        fromAccountId: payload.autoAccountId!,
        amount: payload.autoAmount!,
        frequency: payload.autoFrequency!,
        dayOfMonth: payload.autoDayOfMonth,
        nextRunDate: nextRunDate,
        enabled: true,
      );
    }

    if (!mounted) return;

    if (followUpOk) {
      AppAlert.success(context, 'Meta creada correctamente');
    } else {
      AppAlert.warning(
        context,
        'Meta creada, pero falló la configuración inicial: ${ref.read(goalsViewModelProvider).errorMessage ?? 'intenta de nuevo'}',
      );
    }
  }

  Future<void> _openEditGoal(Goal goal) async {
    final payload = await showDialog<_EditGoalPayload>(
      context: context,
      builder: (_) => _EditGoalDialog(goal: goal),
    );
    if (!mounted || payload == null) return;

    final ok = await ref.read(goalsViewModelProvider.notifier).updateGoal(
          id: goal.id,
          name: payload.name,
          type: payload.type,
          targetAmount: payload.targetAmount,
          targetDate: payload.targetDate,
          status: payload.status,
        );
    if (!mounted) return;
    if (ok) {
      AppAlert.success(context, 'Meta actualizada');
    } else {
      AppAlert.error(
        context,
        ref.read(goalsViewModelProvider).errorMessage ??
            'No se pudo actualizar meta',
      );
    }
  }

  Future<void> _deleteGoal(Goal goal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar meta'),
        content: Text('Se eliminará "${goal.name}" y sus aportes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final ok =
        await ref.read(goalsViewModelProvider.notifier).deleteGoal(goal.id);
    if (!mounted) return;
    if (ok) {
      AppAlert.success(context, 'Meta eliminada');
    } else {
      AppAlert.error(
        context,
        ref.read(goalsViewModelProvider).errorMessage ??
            'No se pudo eliminar meta',
      );
    }
  }

  Future<void> _openContributionDialog({required Goal goal}) async {
    final accounts = ref.read(accountsViewModelProvider).accounts;
    if (accounts.isEmpty) {
      AppAlert.error(context, 'No hay cuentas disponibles');
      return;
    }

    final payload = await showDialog<_ContributionPayload>(
      context: context,
      builder: (_) => _ContributionDialog(accounts: accounts),
    );
    if (!mounted || payload == null) return;

    final ok =
        await ref.read(goalsViewModelProvider.notifier).createContribution(
              goalId: goal.id,
              fromAccountId: payload.fromAccountId,
              amount: payload.amount,
              date: payload.date,
              note: payload.note,
            );
    if (!mounted) return;

    if (ok) {
      AppAlert.success(context, 'Aporte registrado');
    } else {
      AppAlert.error(
        context,
        ref.read(goalsViewModelProvider).errorMessage ??
            'No se pudo registrar aporte',
      );
    }
  }

  Future<void> _openAutoContributionDialog({required Goal goal}) async {
    final accounts = ref.read(accountsViewModelProvider).accounts;
    if (accounts.isEmpty) {
      AppAlert.error(context, 'No hay cuentas disponibles');
      return;
    }

    await ref.read(goalsViewModelProvider.notifier).loadGoalDetail(goal.id);
    if (!mounted) return;

    final detail = ref.read(goalsViewModelProvider).selectedGoal;
    final existing = detail?.autoContribution;

    final payload = await showDialog<_AutoPayload>(
      context: context,
      builder: (_) => _AutoContributionDialog(
        accounts: accounts,
        existing: existing,
      ),
    );

    if (!mounted || payload == null) return;

    final vm = ref.read(goalsViewModelProvider.notifier);
    bool ok;

    if (existing != null && payload.delete) {
      ok =
          await vm.deleteAutoContribution(goalId: goal.id, autoId: existing.id);
    } else if (existing != null) {
      ok = await vm.updateAutoContribution(
        goalId: goal.id,
        autoId: existing.id,
        fromAccountId: payload.fromAccountId,
        amount: payload.amount,
        frequency: payload.frequency,
        dayOfMonth: payload.dayOfMonth,
        nextRunDate: _nextRunDate(payload.dayOfMonth),
        enabled: payload.enabled,
      );
    } else {
      ok = await vm.upsertAutoContribution(
        goalId: goal.id,
        fromAccountId: payload.fromAccountId,
        amount: payload.amount,
        frequency: payload.frequency,
        dayOfMonth: payload.dayOfMonth,
        nextRunDate: _nextRunDate(payload.dayOfMonth),
        enabled: payload.enabled,
      );
    }

    if (!mounted) return;

    if (ok) {
      AppAlert.success(
        context,
        payload.delete
            ? 'Aporte automático eliminado'
            : 'Aporte automático guardado',
      );
    } else {
      AppAlert.error(
        context,
        ref.read(goalsViewModelProvider).errorMessage ??
            'No se pudo guardar aporte automático',
      );
    }
  }

  Future<void> _openGoalDetail(Goal goal) async {
    await ref.read(goalsViewModelProvider.notifier).loadGoalDetail(goal.id);
    if (!mounted) return;

    final state = ref.read(goalsViewModelProvider);
    final detail = state.selectedGoal;
    final recommendation = state.recommendation;

    if (detail == null) {
      AppAlert.error(
          context, state.errorMessage ?? 'No se pudo cargar detalle');
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A2130),
        title: Text(
          detail.goal.name,
          style: const TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: 380,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailLine(
                    'Objetivo', _money.format(detail.goal.targetAmount)),
                _detailLine('Ahorrado', _money.format(detail.goal.savedAmount)),
                _detailLine(
                  'Fecha meta',
                  detail.goal.targetDate == null
                      ? '-'
                      : _date.format(detail.goal.targetDate!.toLocal()),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Aporte automático',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  detail.autoContribution == null
                      ? 'No configurado'
                      : '${_frequencyEs(detail.autoContribution!.frequency)} • ${detail.autoContribution!.enabled ? 'Activo' : 'Pausado'} • ${_money.format(detail.autoContribution!.amount)}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Recomendaciones',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                if (recommendation == null)
                  const Text(
                    'No hay recomendación disponible en este momento.',
                    style: TextStyle(color: Colors.white70),
                  )
                else
                  GoalRecommendationSection(
                    recommendation: recommendation,
                    money: _money,
                    date: _date,
                  ),
                const SizedBox(height: 12),
                const Text(
                  'Últimos aportes',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                if (state.contributions.isEmpty)
                  const Text(
                    'Sin aportes todavía',
                    style: TextStyle(color: Colors.white70),
                  )
                else
                  ...state.contributions.take(10).map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '${_date.format(c.date.toLocal())} • ${_money.format(c.amount)}${(c.note ?? '').isEmpty ? '' : ' • ${c.note}'}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  DateTime _nextRunDate(int dayOfMonth) {
    final now = DateTime.now();
    final day = dayOfMonth.clamp(1, 28);
    final thisMonth = DateTime(now.year, now.month, day);
    if (!thisMonth.isBefore(DateTime(now.year, now.month, now.day))) {
      return thisMonth;
    }
    return DateTime(now.year, now.month + 1, day);
  }

  Widget _detailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '$label: $value',
        style: const TextStyle(color: Colors.white70),
      ),
    );
  }

  String _frequencyEs(String value) {
    switch (value.toLowerCase()) {
      case 'monthly':
        return 'Mensual';
      case 'quarterly':
        return 'Trimestral';
      case 'semiannual':
        return 'Semestral';
      case 'annual':
        return 'Anual';
      default:
        return value;
    }
  }
}

enum GoalSetupMode { none, manualNow, automatic }

class _CreateGoalPayload {
  const _CreateGoalPayload({
    required this.name,
    required this.type,
    required this.targetAmount,
    required this.targetDate,
    required this.setupMode,
    this.manualAccountId,
    this.manualAmount,
    this.manualNote,
    this.autoAccountId,
    this.autoAmount,
    this.autoFrequency,
    this.autoDayOfMonth,
  });

  final String name;
  final String type;
  final double targetAmount;
  final DateTime targetDate;
  final GoalSetupMode setupMode;
  final String? manualAccountId;
  final double? manualAmount;
  final String? manualNote;
  final String? autoAccountId;
  final double? autoAmount;
  final String? autoFrequency;
  final int? autoDayOfMonth;
}

class _CreateGoalDialog extends StatefulWidget {
  const _CreateGoalDialog({required this.accounts});

  final List<AppAccount> accounts;

  @override
  State<_CreateGoalDialog> createState() => _CreateGoalDialogState();
}

class _CreateGoalDialogState extends State<_CreateGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _targetAmountCtrl = TextEditingController();
  final _manualAmountCtrl = TextEditingController();
  final _manualNoteCtrl = TextEditingController();
  final _autoAmountCtrl = TextEditingController();

  String _type = 'purchase';
  DateTime _targetDate = DateTime.now().add(const Duration(days: 180));
  GoalSetupMode _setupMode = GoalSetupMode.none;
  String? _manualAccountId;
  String? _autoAccountId;
  String _autoFrequency = 'monthly';
  int _autoDayOfMonth = 15;

  @override
  void initState() {
    super.initState();
    if (widget.accounts.isNotEmpty) {
      _manualAccountId = widget.accounts.first.id;
      _autoAccountId = widget.accounts.first.id;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetAmountCtrl.dispose();
    _manualAmountCtrl.dispose();
    _manualNoteCtrl.dispose();
    _autoAmountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva meta'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: const [
                    DropdownMenuItem(value: 'purchase', child: Text('Compra')),
                    DropdownMenuItem(value: 'saving', child: Text('Ahorro')),
                    DropdownMenuItem(
                        value: 'emergency', child: Text('Emergencia')),
                    DropdownMenuItem(value: 'travel', child: Text('Viaje')),
                    DropdownMenuItem(
                        value: 'custom', child: Text('Personalizada')),
                  ],
                  onChanged: (v) => setState(() => _type = v ?? 'purchase'),
                ),
                TextFormField(
                  controller: _targetAmountCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Monto objetivo'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    final amount = _toAmount(v);
                    if (amount == null || amount <= 0) return 'Monto inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    const Icon(Icons.calendar_month, size: 18),
                    Text(
                      'Fecha objetivo: ${DateFormat('dd/MM/yyyy').format(_targetDate)}',
                    ),
                    TextButton(
                      onPressed: _pickDate,
                      child: const Text('Cambiar'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _setupChip(
                      label: 'Sin aporte',
                      mode: GoalSetupMode.none,
                    ),
                    _setupChip(
                      label: 'Aporte manual',
                      mode: GoalSetupMode.manualNow,
                    ),
                    _setupChip(
                      label: 'Configurar automático',
                      mode: GoalSetupMode.automatic,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_setupMode == GoalSetupMode.manualNow) ...[
                  DropdownButtonFormField<String>(
                    initialValue: _manualAccountId,
                    decoration:
                        const InputDecoration(labelText: 'Cuenta origen'),
                    items: widget.accounts
                        .map(
                          (a) => DropdownMenuItem(
                              value: a.id, child: Text(a.name)),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _manualAccountId = v),
                  ),
                  TextFormField(
                    controller: _manualAmountCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Monto del primer aporte'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (_setupMode != GoalSetupMode.manualNow) return null;
                      final amount = _toAmount(v);
                      if (amount == null || amount <= 0) {
                        return 'Monto inválido';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _manualNoteCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Nota (opcional)'),
                  ),
                ],
                if (_setupMode == GoalSetupMode.automatic) ...[
                  DropdownButtonFormField<String>(
                    initialValue: _autoAccountId,
                    decoration:
                        const InputDecoration(labelText: 'Cuenta origen'),
                    items: widget.accounts
                        .map(
                          (a) => DropdownMenuItem(
                              value: a.id, child: Text(a.name)),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _autoAccountId = v),
                  ),
                  TextFormField(
                    controller: _autoAmountCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Monto automático'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (_setupMode != GoalSetupMode.automatic) return null;
                      final amount = _toAmount(v);
                      if (amount == null || amount <= 0) {
                        return 'Monto inválido';
                      }
                      return null;
                    },
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _autoFrequency,
                    decoration: const InputDecoration(labelText: 'Frecuencia'),
                    items: const [
                      DropdownMenuItem(
                          value: 'monthly', child: Text('Mensual')),
                      DropdownMenuItem(
                          value: 'quarterly', child: Text('Trimestral')),
                      DropdownMenuItem(
                          value: 'semiannual', child: Text('Semestral')),
                      DropdownMenuItem(value: 'annual', child: Text('Anual')),
                    ],
                    onChanged: (v) =>
                        setState(() => _autoFrequency = v ?? 'monthly'),
                  ),
                  DropdownButtonFormField<int>(
                    initialValue: _autoDayOfMonth,
                    decoration: const InputDecoration(labelText: 'Día del mes'),
                    items: List.generate(
                      28,
                      (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1}'),
                      ),
                    ),
                    onChanged: (v) => setState(() => _autoDayOfMonth = v ?? 15),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Crear'),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: _targetDate,
    );
    if (picked == null) return;
    setState(() => _targetDate = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_setupMode == GoalSetupMode.manualNow && _manualAccountId == null) {
      return;
    }
    if (_setupMode == GoalSetupMode.automatic && _autoAccountId == null) {
      return;
    }

    Navigator.of(context).pop(
      _CreateGoalPayload(
        name: _nameCtrl.text.trim(),
        type: _type,
        targetAmount: _toAmount(_targetAmountCtrl.text)!,
        targetDate: _targetDate,
        setupMode: _setupMode,
        manualAccountId: _manualAccountId,
        manualAmount: _toAmount(_manualAmountCtrl.text),
        manualNote: _manualNoteCtrl.text.trim().isEmpty
            ? null
            : _manualNoteCtrl.text.trim(),
        autoAccountId: _autoAccountId,
        autoAmount: _toAmount(_autoAmountCtrl.text),
        autoFrequency: _autoFrequency,
        autoDayOfMonth: _autoDayOfMonth,
      ),
    );
  }

  Widget _setupChip({
    required String label,
    required GoalSetupMode mode,
  }) {
    final selected = _setupMode == mode;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _setupMode = mode),
      selectedColor: const Color(0x332FB9E2),
      labelStyle: TextStyle(
        color: selected ? AppStyle.brandBlue : Colors.black87,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
      side: BorderSide(
        color: selected ? AppStyle.brandBlue : const Color(0x663A465A),
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    );
  }

  double? _toAmount(String? raw) {
    if (raw == null) return null;
    final normalized = raw.replaceAll(',', '.').trim();
    return double.tryParse(normalized);
  }
}

class _EditGoalPayload {
  const _EditGoalPayload({
    required this.name,
    required this.type,
    required this.targetAmount,
    required this.targetDate,
    required this.status,
  });

  final String name;
  final String type;
  final double targetAmount;
  final DateTime targetDate;
  final String status;
}

class _EditGoalDialog extends StatefulWidget {
  const _EditGoalDialog({required this.goal});

  final Goal goal;

  @override
  State<_EditGoalDialog> createState() => _EditGoalDialogState();
}

class _EditGoalDialogState extends State<_EditGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _amountCtrl;
  late String _type;
  late String _status;
  late DateTime _targetDate;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.goal.name);
    _amountCtrl = TextEditingController(
        text: widget.goal.targetAmount.toStringAsFixed(2));
    _type = _normalizeType(widget.goal.type);
    _status = _normalizeStatus(widget.goal.status);
    _targetDate =
        widget.goal.targetDate ?? DateTime.now().add(const Duration(days: 90));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar meta'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: const [
                  DropdownMenuItem(value: 'purchase', child: Text('Compra')),
                  DropdownMenuItem(value: 'saving', child: Text('Ahorro')),
                  DropdownMenuItem(
                      value: 'emergency', child: Text('Emergencia')),
                  DropdownMenuItem(value: 'travel', child: Text('Viaje')),
                  DropdownMenuItem(
                      value: 'custom', child: Text('Personalizada')),
                ],
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Estado'),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Activa')),
                  DropdownMenuItem(value: 'paused', child: Text('Pausada')),
                  DropdownMenuItem(
                      value: 'completed', child: Text('Completada')),
                ],
                onChanged: (v) => setState(() => _status = v ?? _status),
              ),
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(labelText: 'Monto objetivo'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final amount = _toAmount(v);
                  if (amount == null || amount <= 0) return 'Monto inválido';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  const Icon(Icons.calendar_month, size: 18),
                  Text(
                    'Fecha objetivo: ${DateFormat('dd/MM/yyyy').format(_targetDate)}',
                  ),
                  TextButton(
                    onPressed: _pickDate,
                    child: const Text('Cambiar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime(2100),
      initialDate: _targetDate,
    );
    if (picked == null) return;
    setState(() => _targetDate = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      _EditGoalPayload(
        name: _nameCtrl.text.trim(),
        type: _type,
        targetAmount: _toAmount(_amountCtrl.text)!,
        targetDate: _targetDate,
        status: _status,
      ),
    );
  }

  String _normalizeType(String raw) {
    final value = raw.toLowerCase().trim();
    const allowed = {'purchase', 'saving', 'emergency', 'travel', 'custom'};
    return allowed.contains(value) ? value : 'custom';
  }

  String _normalizeStatus(String raw) {
    final value = raw.toLowerCase().trim();
    const allowed = {'active', 'paused', 'completed'};
    return allowed.contains(value) ? value : 'active';
  }

  double? _toAmount(String? raw) {
    if (raw == null) return null;
    return double.tryParse(raw.replaceAll(',', '.').trim());
  }
}

class _ContributionPayload {
  const _ContributionPayload({
    required this.fromAccountId,
    required this.amount,
    required this.date,
    this.note,
  });

  final String fromAccountId;
  final double amount;
  final DateTime date;
  final String? note;
}

class _ContributionDialog extends StatefulWidget {
  const _ContributionDialog({required this.accounts});

  final List<AppAccount> accounts;

  @override
  State<_ContributionDialog> createState() => _ContributionDialogState();
}

class _ContributionDialogState extends State<_ContributionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  late String _accountId;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _accountId = widget.accounts.first.id;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Aporte manual'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _accountId,
                decoration: const InputDecoration(labelText: 'Cuenta origen'),
                items: widget.accounts
                    .map((a) =>
                        DropdownMenuItem(value: a.id, child: Text(a.name)))
                    .toList(),
                onChanged: (v) => setState(() => _accountId = v ?? _accountId),
              ),
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(labelText: 'Monto'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final amount = _toAmount(v);
                  if (amount == null || amount <= 0) return 'Monto inválido';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_month, size: 18),
                  const SizedBox(width: 8),
                  Text('Fecha: ${DateFormat('dd/MM/yyyy').format(_date)}'),
                  const Spacer(),
                  TextButton(
                      onPressed: _pickDate, child: const Text('Cambiar')),
                ],
              ),
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(labelText: 'Nota (opcional)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime(2100),
      initialDate: _date,
    );
    if (picked == null) return;
    setState(() => _date = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      _ContributionPayload(
        fromAccountId: _accountId,
        amount: _toAmount(_amountCtrl.text)!,
        date: _date,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      ),
    );
  }

  double? _toAmount(String? raw) {
    if (raw == null) return null;
    return double.tryParse(raw.replaceAll(',', '.').trim());
  }
}

class _AutoPayload {
  const _AutoPayload({
    required this.fromAccountId,
    required this.amount,
    required this.frequency,
    required this.dayOfMonth,
    required this.enabled,
    this.delete = false,
  });

  final String fromAccountId;
  final double amount;
  final String frequency;
  final int dayOfMonth;
  final bool enabled;
  final bool delete;
}

class _AutoContributionDialog extends StatefulWidget {
  const _AutoContributionDialog({
    required this.accounts,
    required this.existing,
  });

  final List<AppAccount> accounts;
  final GoalAutoContribution? existing;

  @override
  State<_AutoContributionDialog> createState() =>
      _AutoContributionDialogState();
}

class _AutoContributionDialogState extends State<_AutoContributionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountCtrl;
  late String _accountId;
  late String _frequency;
  late int _dayOfMonth;
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _amountCtrl = TextEditingController(
      text: existing == null ? '' : existing.amount.toStringAsFixed(2),
    );
    final accountIds = widget.accounts.map((a) => a.id).toSet();
    final existingAccountId = existing?.fromAccountId;
    _accountId =
        (existingAccountId != null && accountIds.contains(existingAccountId))
            ? existingAccountId
            : widget.accounts.first.id;
    _frequency = _normalizeFrequency(existing?.frequency);
    _dayOfMonth = (existing?.dayOfMonth ?? 15).clamp(1, 28);
    _enabled = existing?.enabled ?? true;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null
          ? 'Aporte automático'
          : 'Editar aporte automático'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _accountId,
                decoration: const InputDecoration(labelText: 'Cuenta origen'),
                items: widget.accounts
                    .map((a) =>
                        DropdownMenuItem(value: a.id, child: Text(a.name)))
                    .toList(),
                onChanged: (v) => setState(() => _accountId = v ?? _accountId),
              ),
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(labelText: 'Monto'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final amount = _toAmount(v);
                  if (amount == null || amount <= 0) return 'Monto inválido';
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                initialValue: _frequency,
                decoration: const InputDecoration(labelText: 'Frecuencia'),
                items: const [
                  DropdownMenuItem(value: 'monthly', child: Text('Mensual')),
                  DropdownMenuItem(
                      value: 'quarterly', child: Text('Trimestral')),
                  DropdownMenuItem(
                      value: 'semiannual', child: Text('Semestral')),
                  DropdownMenuItem(value: 'annual', child: Text('Anual')),
                ],
                onChanged: (v) => setState(() => _frequency = v ?? _frequency),
              ),
              DropdownButtonFormField<int>(
                initialValue: _dayOfMonth,
                decoration: const InputDecoration(labelText: 'Día del mes'),
                items: List.generate(
                  28,
                  (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text('${index + 1}'),
                  ),
                ),
                onChanged: (v) =>
                    setState(() => _dayOfMonth = v ?? _dayOfMonth),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Activo'),
                value: _enabled,
                onChanged: (v) => setState(() => _enabled = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (widget.existing != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop(
              _AutoPayload(
                fromAccountId: _accountId,
                amount: _toAmount(_amountCtrl.text) ?? 0,
                frequency: _frequency,
                dayOfMonth: _dayOfMonth,
                enabled: false,
                delete: true,
              ),
            ),
            child: const Text('Eliminar'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      _AutoPayload(
        fromAccountId: _accountId,
        amount: _toAmount(_amountCtrl.text)!,
        frequency: _frequency,
        dayOfMonth: _dayOfMonth,
        enabled: _enabled,
      ),
    );
  }

  double? _toAmount(String? raw) {
    if (raw == null) return null;
    return double.tryParse(raw.replaceAll(',', '.').trim());
  }

  String _normalizeFrequency(String? raw) {
    final value = (raw ?? '').toLowerCase().trim();
    switch (value) {
      case 'monthly':
      case 'quarterly':
      case 'semiannual':
      case 'annual':
        return value;
      default:
        return 'monthly';
    }
  }
}
