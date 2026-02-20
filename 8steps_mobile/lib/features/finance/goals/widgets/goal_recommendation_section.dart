import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/app_style.dart';
import '../../../../modules/goals/models/goal_models.dart';

class GoalRecommendationSection extends StatefulWidget {
  const GoalRecommendationSection({
    super.key,
    required this.recommendation,
    required this.money,
    required this.date,
  });

  final GoalRecommendationResult recommendation;
  final NumberFormat money;
  final DateFormat date;

  @override
  State<GoalRecommendationSection> createState() =>
      _GoalRecommendationSectionState();
}

class _GoalRecommendationSectionState extends State<GoalRecommendationSection> {
  int _selectedScenarioIndex = -1;

  @override
  Widget build(BuildContext context) {
    final rec = widget.recommendation;
    final statusUi = _statusUi(rec.recommendation);
    final canReach = statusUi.tone == _RecommendationTone.success;
    final viabilityMessage = canReach
        ? 'Es viable en el tiempo seleccionado'
        : 'No es viable en el tiempo seleccionado';
    final statusColor = _toneColor(statusUi.tone);
    final topCut = rec.categoryCuts.isNotEmpty ? rec.categoryCuts.first : null;
    final bestCard = rec.cardOptions.where((o) => o.eligible).isNotEmpty
        ? rec.cardOptions.firstWhere((o) => o.eligible)
        : (rec.cardOptions.isEmpty ? null : rec.cardOptions.first);
    final scenarios = rec.scenarios.take(3).toList();
    final selectedScenario =
        _selectedScenarioIndex < 0 || _selectedScenarioIndex >= scenarios.length
            ? null
            : scenarios[_selectedScenarioIndex];
    final monthlyGap = rec.recommendation.recommendedMonthlySaving -
        rec.recommendation.monthlyCapacity;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF121827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x332D364A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  statusUi.title,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  statusUi.badge,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            viabilityMessage,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            statusUi.message,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 10),
          const Text(
            'Para lograrlo deberías:',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ahorrar:',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          _MetricBox(
            label: 'Meta mensual',
            value:
                '${widget.money.format(rec.recommendation.recommendedMonthlySaving)}/mes',
            color: Colors.white,
          ),
          const SizedBox(height: 8),
          const Text(
            'Actualmente puedes ahorrar:',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          _MetricBox(
            label: 'Puedes ahorrar',
            value:
                '${widget.money.format(rec.recommendation.monthlyCapacity)}/mes',
            color: const Color(0xFF42D693),
          ),
          if (rec.recommendation.configuredAutoMonthlySaving != null) ...[
            const SizedBox(height: 8),
            _MetricBox(
              label: 'Aporte automático actual',
              value:
                  '${widget.money.format(rec.recommendation.configuredAutoMonthlySaving!)}/mes',
              color: Colors.white,
            ),
          ],
          const SizedBox(height: 8),
          Text(
            canReach
                ? 'Mantén este ritmo y lo lograrás.'
                : _gapMessage(rec: rec, topCut: topCut, monthlyGap: monthlyGap),
            style: TextStyle(
              color: canReach ? const Color(0xFF42D693) : statusColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (bestCard != null) ...[
            const SizedBox(height: 10),
            const Text(
              'Estrategia sugerida con tarjeta:',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              bestCard.eligible
                  ? 'Tarjeta sugerida: ${bestCard.cardName} • ${bestCard.suggestedInstallments} cuotas de ${widget.money.format(bestCard.estimatedInstallment)}'
                  : 'Tarjeta: ahora no conviene diferir.',
              style: TextStyle(
                color: bestCard.eligible
                    ? const Color(0xFF42D693)
                    : Colors.orangeAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (bestCard.reason.isNotEmpty)
              Text(
                bestCard.reason,
                style: const TextStyle(color: Colors.white70),
              ),
          ],
          const SizedBox(height: 12),
          const Text(
            'Simula el escenario:',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Mantén como está actualmente'),
                selected: _selectedScenarioIndex == -1,
                onSelected: (_) {
                  setState(() {
                    _selectedScenarioIndex = -1;
                  });
                },
                selectedColor: const Color(0x332FB9E2),
                labelStyle: TextStyle(
                  color: _selectedScenarioIndex == -1
                      ? AppStyle.brandBlue
                      : Colors.white70,
                  fontWeight: _selectedScenarioIndex == -1
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
                side: BorderSide(
                  color: _selectedScenarioIndex == -1
                      ? AppStyle.brandBlue
                      : const Color(0x553A465A),
                ),
                backgroundColor: const Color(0xFF0F1524),
              ),
              ...List.generate(scenarios.length, (index) {
                final scenario = scenarios[index];
                final selected = index == _selectedScenarioIndex;
                return ChoiceChip(
                  label: Text(_scenarioEs(scenario.type)),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      _selectedScenarioIndex = index;
                    });
                  },
                  selectedColor: const Color(0x332FB9E2),
                  labelStyle: TextStyle(
                    color: selected ? AppStyle.brandBlue : Colors.white70,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  side: BorderSide(
                    color:
                        selected ? AppStyle.brandBlue : const Color(0x553A465A),
                  ),
                  backgroundColor: const Color(0xFF0F1524),
                );
              }),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1524),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x332D364A)),
            ),
            child: Text(
              selectedScenario == null
                  ? 'Con el plan actual ahorrarías ${widget.money.format(rec.recommendation.monthlyCapacity)}/mes y terminarías ${_formatProjectedDate(rec.recommendation)}.'
                  : 'Con ${_scenarioEs(selectedScenario.type)} ahorrarías ${widget.money.format(selectedScenario.monthlySave)}/mes y terminarías ${selectedScenario.estimatedFinishDate == null ? '-' : widget.date.format(selectedScenario.estimatedFinishDate!.toLocal())}.',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Te falta para completar: ${widget.money.format(rec.goal.remainingAmount)}',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  String _scenarioEs(String value) {
    switch (value.toUpperCase()) {
      case 'CONSERVATIVE':
        return 'Conservador';
      case 'BALANCED':
        return 'Balanceado';
      case 'AGGRESSIVE':
        return 'Agresivo';
      default:
        return value;
    }
  }

  String _gapMessage({
    required GoalRecommendationResult rec,
    required GoalCategoryCut? topCut,
    required double monthlyGap,
  }) {
    final configuredGap = rec.recommendation.configuredPlanRequiredGap;
    final gap =
        configuredGap != null && configuredGap > 0 ? configuredGap : monthlyGap;
    final cutText = topCut != null
        ? ' Se recomienda recortar ${topCut.categoryName} en ${widget.money.format(topCut.suggestedCut)}.'
        : '';
    return 'Te falta ${widget.money.format(gap)} al mes.$cutText';
  }

  String _formatProjectedDate(GoalRecommendationMetrics metrics) {
    final configured = metrics.configuredProjectedFinishDate;
    final projected = metrics.projectedFinishDate;
    if (configured != null) return widget.date.format(configured.toLocal());
    if (projected != null) return widget.date.format(projected.toLocal());
    return '-';
  }

  _GoalStatusUi _statusUi(GoalRecommendationMetrics metrics) {
    final key = (metrics.configuredPlanStatus ?? '').toUpperCase();
    switch (key) {
      case 'ON_TRACK':
        return const _GoalStatusUi(
          title: 'Vas en buen camino',
          badge: 'En ruta',
          tone: _RecommendationTone.success,
          message:
              'Tu aporte automático actual es suficiente para llegar en la fecha objetivo.',
        );
      case 'BELOW_REQUIRED':
        return const _GoalStatusUi(
          title: 'Debes ajustar tu aporte',
          badge: 'Ajuste sugerido',
          tone: _RecommendationTone.warning,
          message:
              'Con tu aporte actual no llegarás en la fecha meta. Aumenta el aporte mensual.',
        );
      case 'NOT_CONFIGURED':
        return const _GoalStatusUi(
          title: 'Configura un aporte automático',
          badge: 'Sin automatización',
          tone: _RecommendationTone.info,
          message: 'No tienes aporte automático activo para esta meta.',
        );
      case 'UNFEASIBLE_BY_CASHFLOW':
        return const _GoalStatusUi(
          title: 'Meta no viable con flujo actual',
          badge: 'Requiere cambios',
          tone: _RecommendationTone.danger,
          message:
              'Aunque aumentes aporte, tu flujo mensual actual no alcanza para esta meta en ese plazo.',
        );
      case 'COMPLETED':
        return const _GoalStatusUi(
          title: 'Meta completada',
          badge: 'Completada',
          tone: _RecommendationTone.success,
          message: 'Ya alcanzaste el objetivo de esta meta.',
        );
      default:
        final fallback =
            metrics.monthlyCapacity >= metrics.recommendedMonthlySaving;
        return _GoalStatusUi(
          title: fallback ? 'Vas en buen camino' : 'Necesitas ajustar el plan',
          badge: fallback ? 'En ruta' : 'Ajustar',
          tone: fallback
              ? _RecommendationTone.success
              : _RecommendationTone.warning,
          message: fallback
              ? 'Tu capacidad actual cubre el ahorro recomendado.'
              : 'Tu capacidad actual no cubre el ahorro recomendado.',
        );
    }
  }

  Color _toneColor(_RecommendationTone tone) {
    switch (tone) {
      case _RecommendationTone.success:
        return const Color(0xFF42D693);
      case _RecommendationTone.warning:
        return Colors.orangeAccent;
      case _RecommendationTone.info:
        return AppStyle.brandBlue;
      case _RecommendationTone.danger:
        return const Color(0xFFFF7D7D);
    }
  }
}

enum _RecommendationTone { success, warning, info, danger }

class _GoalStatusUi {
  const _GoalStatusUi({
    required this.title,
    required this.badge,
    required this.tone,
    required this.message,
  });

  final String title;
  final String badge;
  final _RecommendationTone tone;
  final String message;
}

class _MetricBox extends StatelessWidget {
  const _MetricBox({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1524),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x332D364A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
