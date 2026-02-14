import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters/money_formatter.dart';
import '../../../core/utils/amount_parser.dart';
import 'projection_controller.dart';

class ProjectionScreen extends ConsumerStatefulWidget {
  const ProjectionScreen({super.key});

  @override
  ConsumerState<ProjectionScreen> createState() => _ProjectionScreenState();
}

class _ProjectionScreenState extends ConsumerState<ProjectionScreen> {
  final _targetCtrl = TextEditingController();
  final _monthsCtrl = TextEditingController(text: '12');
  final _monthlyCtrl = TextEditingController();

  @override
  void dispose() {
    _targetCtrl.dispose();
    _monthsCtrl.dispose();
    _monthlyCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    final target = AmountParser.textToCents(_targetCtrl.text);
    final months = int.tryParse(_monthsCtrl.text) ?? 1;
    final monthly = AmountParser.textToCents(_monthlyCtrl.text);

    final notifier = ref.read(projectionControllerProvider.notifier);
    notifier.setTarget(target);
    notifier.setMonths(months <= 0 ? 1 : months);
    notifier.setMonthlySaving(monthly);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(projectionControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Proyecciones')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _targetCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Meta de ahorro'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _monthsCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Meses'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _monthlyCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
                labelText: 'Ahorro mensual actual (opcional)'),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _calculate, child: const Text('Calcular')),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ahorro mensual necesario: ${MoneyFormatter.formatCents(state.requiredMonthlyForTarget)}',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Monto proyectado en N meses: ${MoneyFormatter.formatCents(state.projectedByMonthly)}',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
