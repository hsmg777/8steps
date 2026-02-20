import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/utils/app_style.dart';
import '../../../modules/auth/viewmodels/auth_view_model.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    if (authState.status == AuthStatus.unknown || authState.loading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF000000), Color(0xFF1E1E22)],
            ),
          ),
          child: Center(
            child: Image.asset(
              'assets/images/logo.png',
              width: 160,
              height: 160,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/mainbg.jpg', fit: BoxFit.cover),
          Container(color: AppStyle.darkOverlay),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 36),
                  Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 140,
                      height: 140,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Inicia sesion con tu cuenta',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21.5,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '8 steps. One plan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    height: 56,
                    child: FilledButton(
                      style: AppStyle.primaryButtonStyle(),
                      onPressed: () => context.push(AppRoutes.login),
                      child: const Text('Iniciar sesion'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 56,
                    child: FilledButton(
                      style: AppStyle.primaryButtonStyle(),
                      onPressed: () => context.push(AppRoutes.register),
                      child: const Text('Registrarse'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
