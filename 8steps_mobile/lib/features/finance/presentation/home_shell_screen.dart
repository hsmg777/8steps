import 'package:flutter/material.dart';

import '../dashboard/dashboard_screen.dart';
import '../fixed_expenses/fixed_expenses_screen.dart';
import '../installments/installments_screen.dart';
import '../transactions/transactions_screen.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  int _index = 0;

  static const _tabs = [
    DashboardScreen(),
    TransactionsScreen(),
    FixedExpensesScreen(),
    InstallmentsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined), label: 'Transacciones'),
          NavigationDestination(
              icon: Icon(Icons.event_note_outlined), label: 'Fijos'),
          NavigationDestination(
              icon: Icon(Icons.credit_card_outlined), label: 'Cuotas'),
        ],
      ),
    );
  }
}
