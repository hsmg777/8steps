import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/utils/app_alert.dart';
import '../../../core/utils/app_style.dart';
import '../../../modules/accounts/models/app_account.dart';

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(accountsViewModelProvider.notifier).loadAccounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accountsViewModelProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF13151D),
      appBar: AppBar(
        title: const Text('Cuentas'),
        actions: [
          IconButton(
            onPressed: state.loading
                ? null
                : () =>
                    ref.read(accountsViewModelProvider.notifier).loadAccounts(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppStyle.brandBlue,
        onPressed: state.saving ? null : _openCreateDialog,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(accountsViewModelProvider.notifier).loadAccounts(),
        child: Builder(
          builder: (context) {
            if (state.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.accounts.isEmpty) {
              return ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.65,
                    child: const Center(
                      child: Text(
                        'No tienes cuentas todavía',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.accounts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final account = state.accounts[index];
                return _AccountCard(
                  account: account,
                  onOpen: () => _openDetail(account.id),
                  onEdit: () => _openEditDialog(account),
                  onAdjust: () => _openAdjustDialog(account),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _openDetail(String accountId) async {
    final vm = ref.read(accountsViewModelProvider.notifier);
    final account = await vm.getAccountById(accountId);

    if (!mounted) return;

    if (account == null) {
      final error = ref.read(accountsViewModelProvider).errorMessage ??
          'No se pudo cargar detalle';
      AppAlert.error(context, error);
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
                  'Detalle de cuenta',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                _DetailLine(label: 'ID', value: account.id),
                _DetailLine(label: 'Nombre', value: account.name),
                _DetailLine(label: 'Estado', value: account.status),
                _DetailLine(
                    label: 'Saldo', value: _formatAmount(account.balance)),
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

  Future<void> _openCreateDialog() async {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String initialBalanceText = '';
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Nueva cuenta'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: '',
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  onChanged: (value) => name = value,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requerido';
                    return null;
                  },
                ),
                TextFormField(
                  initialValue: '',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Saldo inicial'),
                  onChanged: (value) => initialBalanceText = value,
                  validator: (v) {
                    if (_parseAmount(v) == null) return 'Monto inválido';
                    return null;
                  },
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
                  'initialBalance': _parseAmount(initialBalanceText)!,
                });
              },
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );
    if (payload == null || !mounted) return;
    final ok = await ref.read(accountsViewModelProvider.notifier).createAccount(
          name: payload['name'] as String,
          initialBalance: payload['initialBalance'] as double,
        );
    if (!mounted) return;
    if (ok) {
      AppAlert.success(context, 'Cuenta creada');
    } else {
      final errorMessage = ref.read(accountsViewModelProvider).errorMessage ??
          'No se pudo crear la cuenta';
      AppAlert.error(context, errorMessage);
    }
  }

  Future<void> _openEditDialog(AppAccount account) async {
    String name = account.name;
    var status = account.status.toUpperCase();
    final formKey = GlobalKey<FormState>();
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setLocalState) {
            return AlertDialog(
              title: const Text('Editar cuenta'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      initialValue: account.name,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      onChanged: (value) => name = value,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Requerido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      items: const [
                        DropdownMenuItem(
                            value: 'ACTIVE', child: Text('ACTIVE')),
                        DropdownMenuItem(
                            value: 'INACTIVE', child: Text('INACTIVE')),
                      ],
                      onChanged: (value) =>
                          setLocalState(() => status = value ?? 'ACTIVE'),
                      decoration: const InputDecoration(labelText: 'Estado'),
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
                      'status': status,
                    });
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
    if (payload == null || !mounted) return;
    final ok = await ref.read(accountsViewModelProvider.notifier).updateAccount(
          id: account.id,
          name: payload['name'] as String,
          status: payload['status'] as String,
        );
    if (!mounted) return;
    if (ok) {
      AppAlert.success(context, 'Cuenta actualizada');
    } else {
      final errorMessage = ref.read(accountsViewModelProvider).errorMessage ??
          'No se pudo actualizar';
      AppAlert.error(context, errorMessage);
    }
  }

  Future<void> _openAdjustDialog(AppAccount account) async {
    final formKey = GlobalKey<FormState>();
    String amountText = '';
    String reason = '';
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Ajustar saldo'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: '',
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                  decoration: const InputDecoration(
                    labelText: 'Monto (+/-)',
                    hintText: '-35.5',
                  ),
                  onChanged: (value) => amountText = value,
                  validator: (v) {
                    if (_parseAmount(v) == null) return 'Monto inválido';
                    return null;
                  },
                ),
                TextFormField(
                  initialValue: '',
                  decoration: const InputDecoration(labelText: 'Razón'),
                  onChanged: (value) => reason = value,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requerido';
                    return null;
                  },
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
                  'amount': _parseAmount(amountText)!,
                  'reason': reason.trim(),
                });
              },
              child: const Text('Aplicar'),
            ),
          ],
        );
      },
    );
    if (payload == null || !mounted) return;
    final ok = await ref.read(accountsViewModelProvider.notifier).addAdjustment(
          id: account.id,
          amount: payload['amount'] as double,
          reason: payload['reason'] as String,
        );
    if (!mounted) return;
    if (ok) {
      AppAlert.success(context, 'Ajuste aplicado');
    } else {
      final errorMessage = ref.read(accountsViewModelProvider).errorMessage ??
          'No se pudo aplicar el ajuste';
      AppAlert.error(context, errorMessage);
    }
  }

  double? _parseAmount(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return double.tryParse(raw.trim().replaceAll(',', '.'));
  }

  String _formatAmount(double amount) => '\$${amount.toStringAsFixed(2)}';
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.account,
    required this.onOpen,
    required this.onEdit,
    required this.onAdjust,
  });

  final AppAccount account;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onAdjust;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(14),
      child: Container(
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
                    account.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: account.isActive
                        ? const Color(0x223CCF87)
                        : const Color(0x33FF8080),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    account.status,
                    style: TextStyle(
                      color: account.isActive
                          ? const Color(0xFF7EF3B4)
                          : const Color(0xFFFFA1A1),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Saldo: \$${account.balance.toStringAsFixed(2)}',
              style: const TextStyle(
                color: AppStyle.brandBlue,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton(onPressed: onEdit, child: const Text('Editar')),
                const SizedBox(width: 10),
                OutlinedButton(
                    onPressed: onAdjust, child: const Text('Ajustar')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
