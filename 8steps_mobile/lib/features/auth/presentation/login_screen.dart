import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/utils/app_alert.dart';
import '../../../core/utils/app_style.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      AppAlert.warning(context, 'Completa correo y contraseña válidos');
      return;
    }

    final ok = await ref
        .read(authControllerProvider.notifier)
        .login(_emailCtrl.text.trim(), _passwordCtrl.text.trim());

    if (!mounted) return;

    if (ok) {
      AppAlert.success(context, 'Bienvenido');
      context.go(AppRoutes.dashboard);
      return;
    }

    final message = ref.read(authControllerProvider).errorMessage ??
        'Credenciales inválidas';
    AppAlert.error(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/loginbg.jpg', fit: BoxFit.cover),
          Container(color: AppStyle.darkOverlay),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    24,
                    0,
                    24,
                    MediaQuery.of(context).viewInsets.bottom + 18,
                  ),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 72),
                          const Text(
                            'Bienvenido!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 44,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Es un gusto tenerte de vuelta',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 72),
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Text(
                              'Correo:',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(
                              color: Color(0xFF303030),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration:
                                _inputDecoration(hint: 'Escribe tu email'),
                            validator: (v) {
                              if (v == null || v.isEmpty || !v.contains('@')) {
                                return 'Email inválido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 22),
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Text(
                              'Contraseña:',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _obscurePassword,
                            style: const TextStyle(
                              color: Color(0xFF303030),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: _inputDecoration(
                              hint: 'Escribe tu contraseña',
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: const Color(0xFF4A4A4A),
                                ),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.length < 4) {
                                return 'Mínimo 4 caracteres';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 64,
                            child: FilledButton(
                              style: AppStyle.primaryButtonStyle(radius: 18),
                              onPressed: state.loading ? null : _submit,
                              child: state.loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Iniciar sesion'),
                            ),
                          ),
                          const SizedBox(height: 42),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 18),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'No tienes cuenta?',
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.55),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        context.push(AppRoutes.register),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppStyle.brandBlue,
                                      textStyle: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    child: const Text('Registrate'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF4A4A4A),
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.92),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppStyle.brandBlue, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFFF8A80), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFFF8A80), width: 1),
      ),
    );
  }
}
