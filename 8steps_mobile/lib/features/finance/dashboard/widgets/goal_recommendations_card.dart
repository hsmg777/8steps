import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../modules/goals/models/goal_models.dart';

class GoalRecommendationsCard extends StatelessWidget {
  const GoalRecommendationsCard({
    super.key,
    required this.loading,
    required this.items,
    required this.errorMessage,
    required this.onRefresh,
  });

  final bool loading;
  final List<GoalRecommendationResult> items;
  final String? errorMessage;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0x1FFFFFFF),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Recomendaciones de metas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh, color: Colors.white70),
              ),
            ],
          ),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (errorMessage != null)
            Text(
              errorMessage!,
              style: const TextStyle(color: Color(0xFFFF9A9A)),
            )
          else if (items.isEmpty)
            const Text(
              'Aún no hay metas con recomendación.',
              style: TextStyle(color: Colors.white70),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Desliza para ver más',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 210,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, index) {
                      final item = items[index];
                      final rec = item.recommendation;
                      final statusUi = _statusUi(rec);
                      final onTrack =
                          statusUi.tone == _RecommendationTone.success;
                      final viabilityMessage = onTrack
                          ? 'Es viable en el tiempo seleccionado'
                          : 'No es viable en el tiempo seleccionado';

                      final projectedDate = rec.projectedFinishDate;
                      final targetDate = item.goal.targetDate;
                      final delayed = projectedDate != null &&
                          targetDate != null &&
                          projectedDate.isAfter(targetDate);

                      final topCut = item.categoryCuts.isEmpty
                          ? null
                          : item.categoryCuts.first;

                      final bestCard =
                          item.cardOptions.where((o) => o.eligible).isNotEmpty
                              ? item.cardOptions.firstWhere((o) => o.eligible)
                              : (item.cardOptions.isEmpty
                                  ? null
                                  : item.cardOptions.first);

                      return SizedBox(
                        width: 285,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: const Color(0xFF121827),
                            border: Border.all(color: const Color(0x332D364A)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.goal.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  _StatusPill(
                                    color: _toneColor(statusUi.tone),
                                    label: statusUi.badge,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Deberías ahorrar al mes:',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.68),
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                money.format(rec.recommendedMonthlySaving),
                                style: TextStyle(
                                  color: _toneColor(statusUi.tone),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 26,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                projectedDate == null
                                    ? 'Sin fecha estimada'
                                    : delayed
                                        ? 'Terminarías aprox: ${DateFormat('dd/MM').format(projectedDate.toLocal())} (tarde)'
                                        : 'Terminarías aprox: ${DateFormat('dd/MM').format(projectedDate.toLocal())}',
                                style: TextStyle(
                                  color: delayed
                                      ? Colors.orangeAccent
                                      : Colors.white70,
                                  fontSize: 13,
                                  fontWeight: delayed
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                viabilityMessage,
                                style: TextStyle(
                                  color: _toneColor(statusUi.tone),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _quickAction(
                                  topCut: topCut,
                                  bestCard: bestCard,
                                  money: money,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _quickAction({
    required GoalCategoryCut? topCut,
    required GoalCardOption? bestCard,
    required NumberFormat money,
  }) {
    if (topCut != null && topCut.suggestedCut > 0) {
      return 'Acción rápida: recorta ${topCut.categoryName} en ${money.format(topCut.suggestedCut)}.';
    }
    if (bestCard != null && bestCard.eligible) {
      return 'Acción rápida: ${bestCard.cardName} en ${bestCard.suggestedInstallments} cuotas de ${money.format(bestCard.estimatedInstallment)}.';
    }
    return 'Acción rápida: mantén el ahorro mensual recomendado.';
  }
}

_GoalStatusUi _statusUi(GoalRecommendationMetrics metrics) {
  final key = (metrics.configuredPlanStatus ?? '').toUpperCase();
  switch (key) {
    case 'ON_TRACK':
      return const _GoalStatusUi(
        badge: 'En ruta',
        tone: _RecommendationTone.success,
      );
    case 'BELOW_REQUIRED':
      return const _GoalStatusUi(
        badge: 'Ajuste sugerido',
        tone: _RecommendationTone.warning,
      );
    case 'NOT_CONFIGURED':
      return const _GoalStatusUi(
        badge: 'Sin automatización',
        tone: _RecommendationTone.info,
      );
    case 'UNFEASIBLE_BY_CASHFLOW':
      return const _GoalStatusUi(
        badge: 'Requiere cambios',
        tone: _RecommendationTone.danger,
      );
    case 'COMPLETED':
      return const _GoalStatusUi(
        badge: 'Completada',
        tone: _RecommendationTone.success,
      );
    default:
      final fallback =
          metrics.monthlyCapacity >= metrics.recommendedMonthlySaving;
      return _GoalStatusUi(
        badge: fallback ? 'En ruta' : 'Ajustar',
        tone: fallback
            ? _RecommendationTone.success
            : _RecommendationTone.warning,
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
      return const Color(0xFF2FB9E2);
    case _RecommendationTone.danger:
      return const Color(0xFFFF7D7D);
  }
}

enum _RecommendationTone { success, warning, info, danger }

class _GoalStatusUi {
  const _GoalStatusUi({
    required this.badge,
    required this.tone,
  });

  final String badge;
  final _RecommendationTone tone;
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}
