import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/formatters/money_formatter.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(monthlySummaryProvider);
    final topCategoriesAsync = ref.watch(monthlyCategoryExpensesProvider);
    final month = ref.watch(selectedMonthProvider);
    final authState = ref.watch(authControllerProvider);
    final subscription = authState.subscription;
    final isPremium = subscription?.isPremium ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(isPremium ? 'Premium' : 'Free'),
                backgroundColor:
                    isPremium ? Colors.green.shade100 : Colors.grey.shade200,
              ),
            ),
          ),
          IconButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                initialDate: month,
                initialDatePickerMode: DatePickerMode.year,
              );
              if (picked != null) {
                ref.read(selectedMonthProvider.notifier).state =
                    DateTime(picked.year, picked.month, 1);
              }
            },
            icon: const Icon(Icons.calendar_month),
          ),
          IconButton(
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) {
                context.go(AppRoutes.login);
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          summaryAsync.when(
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (e, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error: $e'),
              ),
            ),
            data: (s) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Ingresos: ${MoneyFormatter.formatCents(s.incomeCents)}'),
                    Text(
                        'Egresos: ${MoneyFormatter.formatCents(s.expenseCents)}'),
                    const SizedBox(height: 8),
                    Text(
                      'Balance: ${MoneyFormatter.formatCents(s.balanceCents)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: topCategoriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
                data: (items) {
                  if (items.isEmpty) return const Text('Sin gastos este mes');
                  final top = items.take(5).toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Top categorías',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ...top.map(
                        (e) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(e.category),
                          trailing: Text(MoneyFormatter.formatCents(e.cents)),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => context.push(AppRoutes.projection),
            icon: const Icon(Icons.trending_up),
            label: const Text('Abrir proyecciones'),
          ),
        ],
      ),
    );
  }
}
