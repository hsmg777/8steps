import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers.dart';
import '../../../../core/constants/app_routes.dart';

class AppSidebar extends ConsumerWidget {
  const AppSidebar({
    super.key,
    required this.onGoDashboard,
    required this.onGoTransactions,
    required this.onGoGoals,
  });

  final VoidCallback onGoDashboard;
  final VoidCallback onGoTransactions;
  final VoidCallback onGoGoals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: const Color(0xFF12151D),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            const SizedBox(height: 8),
            Center(
              child: Image.asset(
                'assets/images/logo.png',
                width: 150,
                height: 150,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: SvgPicture.asset(
                'assets/icons/dashboard.svg',
                colorFilter:
                    const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
              title:
                  const Text('Resumen', style: TextStyle(color: Colors.white)),
              onTap: onGoDashboard,
            ),
            ListTile(
              leading: SvgPicture.asset(
                'assets/icons/transfer.svg',
                colorFilter:
                    const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
              title: const Text('Movimientos',
                  style: TextStyle(color: Colors.white)),
              onTap: onGoTransactions,
            ),
            ListTile(
              leading: SvgPicture.asset(
                'assets/icons/goal.svg',
                colorFilter:
                    const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
              title: const Text('Metas', style: TextStyle(color: Colors.white)),
              onTap: onGoGoals,
            ),
            const Divider(color: Color(0x332D364A)),
            ListTile(
              leading: const Icon(Icons.category_outlined, color: Colors.white),
              title: const Text('Categorías',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.categories);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.credit_card_outlined, color: Colors.white),
              title:
                  const Text('Cuentas', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.accounts);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.credit_score_outlined, color: Colors.white),
              title: const Text('Tarjeta de crédito',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.cards);
              },
            ),
            ListTile(
              leading: const Icon(Icons.repeat_rounded, color: Colors.white),
              title: const Text('Recurrentes',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.recurrings);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month, color: Colors.white),
              title: const Text('Calendario financiero',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.financialCalendar);
              },
            ),
            ListTile(
              leading: const Icon(Icons.query_stats, color: Colors.white),
              title: const Text('Reportería',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.reports);
              },
            ),
            const Divider(color: Color(0x332D364A)),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.white),
              title: const Text('Cerrar sesión',
                  style: TextStyle(color: Colors.white)),
              onTap: () async {
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) {
                  context.go(AppRoutes.login);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
