import 'package:flutter/material.dart';

enum AppAlertType {
  success,
  error,
  info,
  warning,
}

class AppAlert {
  static void show(
    BuildContext context, {
    required String message,
    AppAlertType type = AppAlertType.info,
    Duration duration = const Duration(seconds: 5),
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          margin: const EdgeInsets.fromLTRB(14, 10, 14, 18),
          content: _AlertCard(
            message: message,
            type: type,
          ),
        ),
      );
  }

  static void showOnMessenger(
    ScaffoldMessengerState messenger, {
    required String message,
    AppAlertType type = AppAlertType.info,
    Duration duration = const Duration(seconds: 5),
  }) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          margin: const EdgeInsets.fromLTRB(14, 10, 14, 18),
          content: _AlertCard(
            message: message,
            type: type,
          ),
        ),
      );
  }

  static void success(BuildContext context, String message) {
    show(context, message: message, type: AppAlertType.success);
  }

  static void successOnMessenger(
    ScaffoldMessengerState messenger,
    String message,
  ) {
    showOnMessenger(messenger, message: message, type: AppAlertType.success);
  }

  static void error(BuildContext context, String message) {
    show(context, message: message, type: AppAlertType.error);
  }

  static void errorOnMessenger(
    ScaffoldMessengerState messenger,
    String message,
  ) {
    showOnMessenger(messenger, message: message, type: AppAlertType.error);
  }

  static void info(BuildContext context, String message) {
    show(context, message: message, type: AppAlertType.info);
  }

  static void warning(BuildContext context, String message) {
    show(context, message: message, type: AppAlertType.warning);
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.message,
    required this.type,
  });

  final String message;
  final AppAlertType type;

  @override
  Widget build(BuildContext context) {
    final theme = _AlertPalette.forType(type);

    return Container(
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(theme.icon, color: theme.iconColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: theme.text,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertPalette {
  const _AlertPalette({
    required this.background,
    required this.border,
    required this.text,
    required this.icon,
    required this.iconColor,
  });

  final Color background;
  final Color border;
  final Color text;
  final IconData icon;
  final Color iconColor;

  static _AlertPalette forType(AppAlertType type) {
    switch (type) {
      case AppAlertType.success:
        return const _AlertPalette(
          background: Color(0xFF11271C),
          border: Color(0xFF2AAE66),
          text: Color(0xFFD9F8E8),
          icon: Icons.check_circle_rounded,
          iconColor: Color(0xFF47D987),
        );
      case AppAlertType.error:
        return const _AlertPalette(
          background: Color(0xFF2A1516),
          border: Color(0xFFD95A5A),
          text: Color(0xFFFDE5E5),
          icon: Icons.error_rounded,
          iconColor: Color(0xFFFF8080),
        );
      case AppAlertType.warning:
        return const _AlertPalette(
          background: Color(0xFF30240D),
          border: Color(0xFFE0A541),
          text: Color(0xFFFFECCD),
          icon: Icons.warning_amber_rounded,
          iconColor: Color(0xFFFFC86B),
        );
      case AppAlertType.info:
        return const _AlertPalette(
          background: Color(0xFF102133),
          border: Color(0xFF53A0F6),
          text: Color(0xFFE1EFFF),
          icon: Icons.info_rounded,
          iconColor: Color(0xFF74BAFF),
        );
    }
  }
}
