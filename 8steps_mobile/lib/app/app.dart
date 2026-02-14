import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/app_style.dart';
import 'router.dart';

class EightStepsApp extends ConsumerWidget {
  const EightStepsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: '8steps',
      debugShowCheckedModeBanner: false,
      theme: AppStyle.theme,
      routerConfig: router,
    );
  }
}
