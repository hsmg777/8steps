import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/providers.dart';
import '../../../core/utils/app_alert.dart';
import '../../../core/utils/app_style.dart';
import '../dashboard/dashboard_screen.dart';
import '../goals/goals_screen.dart';
import '../transactions/transactions_screen.dart';
import 'widgets/app_sidebar.dart';

class HomeShellScreen extends ConsumerStatefulWidget {
  const HomeShellScreen({super.key});

  @override
  ConsumerState<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends ConsumerState<HomeShellScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const SizedBox.shrink(),
      TransactionsScreen(
        onBack: () => setState(() => _index = 0),
      ),
      GoalsScreen(
        onBack: () => setState(() => _index = 0),
      ),
      const _ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF13151D),
      drawer: AppSidebar(
        onGoDashboard: () {
          setState(() => _index = 0);
          Navigator.of(context).pop();
        },
        onGoTransactions: () {
          setState(() => _index = 1);
          Navigator.of(context).pop();
        },
        onGoGoals: () {
          setState(() => _index = 2);
          Navigator.of(context).pop();
        },
      ),
      body: Builder(
        builder: (innerContext) {
          if (_index == 0) {
            return DashboardScreen(
              onOpenSidebar: () => Scaffold.of(innerContext).openDrawer(),
            );
          }
          return tabs[_index];
        },
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF11141C),
          border: Border(top: BorderSide(color: Color(0x221F2A3C))),
        ),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
        child: Row(
          children: [
            _BottomItem(
              label: 'Resumen',
              iconPath: 'assets/icons/dashboard.svg',
              selected: _index == 0,
              onTap: () => setState(() => _index = 0),
            ),
            _BottomItem(
              label: 'Movimientos',
              iconPath: 'assets/icons/transfer.svg',
              selected: _index == 1,
              onTap: () => setState(() => _index = 1),
            ),
            _BottomItem(
              label: 'Metas',
              iconPath: 'assets/icons/goal.svg',
              selected: _index == 2,
              onTap: () => setState(() => _index = 2),
            ),
            _BottomItem(
              label: 'Perfil',
              iconPath: 'assets/icons/user.svg',
              selected: _index == 3,
              onTap: () => setState(() => _index = 3),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.label,
    required this.iconPath,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String iconPath;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppStyle.brandBlue : Colors.white;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                iconPath,
                width: 28,
                height: 28,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileScreen extends ConsumerStatefulWidget {
  const _ProfileScreen();

  @override
  ConsumerState<_ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<_ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(profileViewModelProvider.notifier).loadSubscription();
    });
  }

  @override
  void dispose() {
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final profileState = ref.watch(profileViewModelProvider);

    final firstName = authState.user?.firstName?.trim() ?? '';
    final lastName = authState.user?.lastName?.trim() ?? '';
    final fullName = '$firstName $lastName'.trim();

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
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Perfil',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              _InfoLine(
                  label: 'Nombre', value: fullName.isEmpty ? '-' : fullName),
              _InfoLine(label: 'Correo', value: authState.user?.email ?? '-'),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0x221F2A3C),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0x332D364A)),
                ),
                child: profileState.loading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Suscripción',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Estado: ${profileState.subscription?.status ?? authState.subscription?.status ?? 'FREE'}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Proveedor: ${profileState.subscription?.provider ?? authState.subscription?.provider ?? '-'}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Cambiar contraseña',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _currentPasswordCtrl,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: _profileInputDecoration('Contraseña actual'),
                      validator: (value) {
                        if (value == null || value.length < 8) {
                          return 'Mínimo 8 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _newPasswordCtrl,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: _profileInputDecoration('Nueva contraseña'),
                      validator: (value) {
                        if (value == null || value.length < 8) {
                          return 'Mínimo 8 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: AppStyle.primaryButtonStyle(radius: 14),
                        onPressed: profileState.loading
                            ? null
                            : () async {
                                final messenger = ScaffoldMessenger.of(context);
                                if (!_formKey.currentState!.validate()) return;
                                await ref
                                    .read(profileViewModelProvider.notifier)
                                    .changePassword(
                                      currentPassword:
                                          _currentPasswordCtrl.text.trim(),
                                      newPassword: _newPasswordCtrl.text.trim(),
                                    );
                                if (!mounted) return;
                                final nextState =
                                    ref.read(profileViewModelProvider);
                                final message = nextState.successMessage ??
                                    nextState.errorMessage;
                                if (message != null) {
                                  if (nextState.successMessage != null) {
                                    AppAlert.successOnMessenger(
                                      messenger,
                                      message,
                                    );
                                  } else {
                                    AppAlert.errorOnMessenger(
                                      messenger,
                                      message,
                                    );
                                  }
                                }
                              },
                        child: const Text('Actualizar contraseña'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _profileInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
      filled: true,
      fillColor: const Color(0x221F2A3C),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0x332D364A)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0x332D364A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppStyle.brandBlue),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

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
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
