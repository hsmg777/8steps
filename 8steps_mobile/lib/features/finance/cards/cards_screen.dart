import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/utils/app_alert.dart';
import '../../../core/utils/app_style.dart';
import '../../../modules/cards/models/app_card.dart';

class CardsScreen extends ConsumerStatefulWidget {
  const CardsScreen({super.key});

  @override
  ConsumerState<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends ConsumerState<CardsScreen> {
  final _money = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(cardsViewModelProvider.notifier).loadCards();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cardsViewModelProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF13151D),
      appBar: AppBar(
        title: const Text('Tarjetas de crédito'),
        actions: [
          IconButton(
            onPressed: state.loading
                ? null
                : () => ref.read(cardsViewModelProvider.notifier).loadCards(),
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
        onRefresh: () => ref.read(cardsViewModelProvider.notifier).loadCards(),
        child: Builder(
          builder: (context) {
            if (state.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.cards.isEmpty) {
              return ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.65,
                    child: const Center(
                      child: Text(
                        'No tienes tarjetas todavía',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.cards.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final card = state.cards[index];
                return _CreditCardTile(
                  card: card,
                  availableText: _money.format(card.availableLimit),
                  nextPaymentText: _money.format(card.nextPaymentAmount),
                  onOpen: () => context.push(AppRoutes.cardDetail(card.id)),
                  onEdit: () => _openEditDialog(card),
                  onDelete: () => _deleteCard(card),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _openCreateDialog() async {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String limitText = '';
    int cutoffDay = 15;
    int paymentDay = 2;

    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setLocalState) {
            return AlertDialog(
              title: const Text('Nueva tarjeta'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Nombre'),
                        onChanged: (value) => name = value,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Requerido';
                          return null;
                        },
                      ),
                      TextFormField(
                        decoration:
                            const InputDecoration(labelText: 'Cupo total'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (value) => limitText = value,
                        validator: (v) {
                          final n = _parseAmount(v);
                          if (n == null || n <= 0) return 'Monto inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        initialValue: cutoffDay,
                        decoration:
                            const InputDecoration(labelText: 'Día de corte'),
                        items: List.generate(
                          31,
                          (i) => DropdownMenuItem<int>(
                            value: i + 1,
                            child: Text('${i + 1}'),
                          ),
                        ),
                        onChanged: (value) {
                          setLocalState(() => cutoffDay = value ?? 15);
                        },
                      ),
                      DropdownButtonFormField<int>(
                        initialValue: paymentDay,
                        decoration:
                            const InputDecoration(labelText: 'Día de pago'),
                        items: List.generate(
                          31,
                          (i) => DropdownMenuItem<int>(
                            value: i + 1,
                            child: Text('${i + 1}'),
                          ),
                        ),
                        onChanged: (value) {
                          setLocalState(() => paymentDay = value ?? 2);
                        },
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
                      'totalLimit': _parseAmount(limitText)!,
                      'cutoffDay': cutoffDay,
                      'paymentDay': paymentDay,
                    });
                  },
                  child: const Text('Crear'),
                ),
              ],
            );
          },
        );
      },
    );

    if (payload == null || !mounted) return;
    final ok = await ref.read(cardsViewModelProvider.notifier).createCard(
          name: payload['name'] as String,
          cutoffDay: payload['cutoffDay'] as int,
          paymentDay: payload['paymentDay'] as int,
          totalLimit: payload['totalLimit'] as double,
        );

    if (!mounted) return;
    if (ok) {
      AppAlert.success(context, 'Tarjeta creada');
    } else {
      final msg =
          ref.read(cardsViewModelProvider).errorMessage ?? 'No se pudo crear';
      AppAlert.error(context, msg);
    }
  }

  Future<void> _openEditDialog(AppCard card) async {
    final formKey = GlobalKey<FormState>();
    String name = card.name;
    String limitText = card.totalLimit.toStringAsFixed(2);
    int cutoffDay = card.cutoffDay;
    int paymentDay = card.paymentDay;

    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setLocalState) {
            return AlertDialog(
              title: const Text('Editar tarjeta'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        initialValue: name,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                        onChanged: (value) => name = value,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Requerido';
                          return null;
                        },
                      ),
                      TextFormField(
                        initialValue: limitText,
                        decoration:
                            const InputDecoration(labelText: 'Cupo total'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (value) => limitText = value,
                        validator: (v) {
                          final n = _parseAmount(v);
                          if (n == null || n <= 0) return 'Monto inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        initialValue: cutoffDay,
                        decoration:
                            const InputDecoration(labelText: 'Día de corte'),
                        items: List.generate(
                          31,
                          (i) => DropdownMenuItem<int>(
                            value: i + 1,
                            child: Text('${i + 1}'),
                          ),
                        ),
                        onChanged: (value) {
                          setLocalState(() => cutoffDay = value ?? cutoffDay);
                        },
                      ),
                      DropdownButtonFormField<int>(
                        initialValue: paymentDay,
                        decoration:
                            const InputDecoration(labelText: 'Día de pago'),
                        items: List.generate(
                          31,
                          (i) => DropdownMenuItem<int>(
                            value: i + 1,
                            child: Text('${i + 1}'),
                          ),
                        ),
                        onChanged: (value) {
                          setLocalState(() => paymentDay = value ?? paymentDay);
                        },
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
                      'totalLimit': _parseAmount(limitText)!,
                      'cutoffDay': cutoffDay,
                      'paymentDay': paymentDay,
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
    final ok = await ref.read(cardsViewModelProvider.notifier).updateCard(
          id: card.id,
          name: payload['name'] as String,
          cutoffDay: payload['cutoffDay'] as int,
          paymentDay: payload['paymentDay'] as int,
          totalLimit: payload['totalLimit'] as double,
        );

    if (!mounted) return;
    if (ok) {
      AppAlert.success(context, 'Tarjeta actualizada');
    } else {
      final msg = ref.read(cardsViewModelProvider).errorMessage ??
          'No se pudo actualizar';
      AppAlert.error(context, msg);
    }
  }

  Future<void> _deleteCard(AppCard card) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar tarjeta'),
          content: Text('¿Eliminar "${card.name}" y todos sus movimientos?'),
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
    final ok =
        await ref.read(cardsViewModelProvider.notifier).deleteCard(card.id);

    if (!mounted) return;
    if (ok) {
      AppAlert.success(context, 'Tarjeta eliminada');
    } else {
      final msg = ref.read(cardsViewModelProvider).errorMessage ??
          'No se pudo eliminar';
      AppAlert.error(context, msg);
    }
  }

  double? _parseAmount(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return double.tryParse(raw.trim().replaceAll(',', '.'));
  }
}

class _CreditCardTile extends StatelessWidget {
  const _CreditCardTile({
    required this.card,
    required this.availableText,
    required this.nextPaymentText,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final AppCard card;
  final String availableText;
  final String nextPaymentText;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = _paletteFor(card.id);
    final rawStatus = card.paymentStatus.toUpperCase();
    final isPaid = rawStatus == 'PAID';
    final statusColor =
        isPaid ? const Color(0xFF4CD08A) : const Color(0xFFF2A646);
    final statusBg = isPaid ? const Color(0x3326B66E) : const Color(0x33F2A646);
    final statusLabel = isPaid ? 'PAGADA' : 'PENDIENTE';

    final proxPagoLabel = _proxPagoLabel(card.nextPaymentDate);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onOpen,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -80,
                bottom: -100,
                child: Container(
                  width: 280,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Tarjeta',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      PopupMenuButton<String>(
                        iconColor: Colors.white,
                        onSelected: (value) {
                          if (value == 'edit') onEdit();
                          if (value == 'delete') onDelete();
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Editar')),
                          PopupMenuItem(
                              value: 'delete', child: Text('Eliminar')),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    card.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Cupo disponible: $availableText',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'PROX PAGO $proxPagoLabel: $nextPaymentText',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _proxPagoLabel(DateTime? date) {
    if (date == null) return '--/--';
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  List<Color> _paletteFor(String key) {
    const palettes = <List<Color>>[
      [Color(0xFF4136C4), Color(0xFFC1325F)],
      [Color(0xFF1D3557), Color(0xFF2A9D8F)],
      [Color(0xFF4B2A7B), Color(0xFF6A4C93)],
      [Color(0xFF0F4C75), Color(0xFF3282B8)],
      [Color(0xFF3A0CA3), Color(0xFF7209B7)],
      [Color(0xFF1B4332), Color(0xFF2D6A4F)],
      [Color(0xFF6A040F), Color(0xFF9D0208)],
      [Color(0xFF495057), Color(0xFF212529)],
    ];
    final index = key.hashCode.abs() % palettes.length;
    return palettes[index];
  }
}
