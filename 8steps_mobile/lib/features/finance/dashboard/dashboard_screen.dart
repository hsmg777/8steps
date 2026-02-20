import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../core/utils/app_style.dart';
import 'widgets/category_budget_chart_card.dart';
import 'widgets/goal_recommendations_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key, required this.onOpenSidebar});

  final VoidCallback onOpenSidebar;

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _money = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(dashboardViewModelProvider.notifier).loadBalance();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final dashboardState = ref.watch(dashboardViewModelProvider);
    final goalsRecommendationsAsync = ref.watch(goalsRecommendationsProvider);
    final categoryBudgetChartAsync =
        ref.watch(dashboardCategoryBudgetChartProvider);

    final userName = authState.user?.firstName?.trim();
    final fallbackEmailName =
        (authState.user?.email ?? 'usuario').split('@').first;
    final displayName = (userName != null && userName.isNotEmpty)
        ? userName
        : fallbackEmailName;

    final now = DateTime.now();
    final today =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF181A23), Color(0xFF13151D)],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: widget.onOpenSidebar,
                    icon: SvgPicture.asset(
                      'assets/icons/menu.svg',
                      width: 28,
                      height: 28,
                      colorFilter:
                          const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    ),
                  ),
                  const Spacer(),
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Hola $displayName',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Organicemos tus finanzas!',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                'Hoy: $today',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 26),
              const Text(
                'Balance General:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: dashboardState.loading
                    ? const CircularProgressIndicator()
                    : Text(
                        _money.format(dashboardState.balance.cashAvailable),
                        style: const TextStyle(
                          color: AppStyle.brandBlue,
                          fontSize: 44,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0x1FFFFFFF),
                  border: Border.all(color: const Color(0x33FFFFFF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Efectivo disponible: ${_money.format(dashboardState.balance.cashAvailable)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Deuda total tarjetas: ${_money.format(dashboardState.balance.cardDebtTotal)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (dashboardState.errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        dashboardState.errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFFFF9A9A),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              GoalRecommendationsCard(
                loading: goalsRecommendationsAsync.isLoading,
                items: goalsRecommendationsAsync.value ?? const [],
                errorMessage: goalsRecommendationsAsync.hasError
                    ? 'No se pudieron cargar recomendaciones'
                    : null,
                onRefresh: () {
                  ref.invalidate(goalsRecommendationsProvider);
                },
              ),
              const SizedBox(height: 14),
              CategoryBudgetChartCard(
                loading: categoryBudgetChartAsync.isLoading,
                items: categoryBudgetChartAsync.value ?? const [],
                errorMessage: categoryBudgetChartAsync.hasError
                    ? 'No se pudo cargar el gráfico por categorías'
                    : null,
                onRefresh: () {
                  ref.invalidate(dashboardCategoryBudgetChartProvider);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
