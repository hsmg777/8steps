import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/app_style.dart';
import '../../../../modules/goals/models/goal_models.dart';

class GoalCardItem extends StatelessWidget {
  const GoalCardItem({
    super.key,
    required this.goal,
    required this.money,
    required this.date,
    required this.onTap,
    required this.onContribute,
    required this.onAuto,
    required this.onEdit,
    required this.onDelete,
  });

  final Goal goal;
  final NumberFormat money;
  final DateFormat date;
  final VoidCallback onTap;
  final VoidCallback onContribute;
  final VoidCallback onAuto;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final progress = goal.progressPercent.clamp(0, 100).toDouble();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2130),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x332D364A)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    goal.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _GoalStatusChip(status: goal.status),
                PopupMenuButton<String>(
                  color: const Color(0xFF1A2130),
                  iconColor: Colors.white,
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child:
                          Text('Editar', style: TextStyle(color: Colors.white)),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Eliminar',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Ahorrado: ${money.format(goal.savedAmount)}',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            Text(
              'Meta: ${money.format(goal.targetAmount)}',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            if (goal.targetDate != null)
              Text(
                'Fecha objetivo: ${date.format(goal.targetDate!.toLocal())}',
                style: const TextStyle(color: Colors.white60),
              ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: progress / 100,
                backgroundColor: const Color(0xFF384053),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppStyle.brandBlue),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${progress.toStringAsFixed(0)}% completado',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onContribute,
                    icon: const Icon(Icons.add),
                    label: const Text('Aportar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0x553A465A)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onAuto,
                    icon: const Icon(Icons.sync),
                    label: const Text('Config. automática'),
                    style: AppStyle.primaryButtonStyle(radius: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalStatusChip extends StatelessWidget {
  const _GoalStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    final active = s == 'active';
    final label =
        active ? 'Activa' : (s == 'completed' ? 'Completada' : 'Pausada');
    final color = active ? const Color(0xFF42D693) : Colors.orangeAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
