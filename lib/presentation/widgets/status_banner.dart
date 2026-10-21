import 'package:flutter/material.dart';

enum StatusBannerType {
  error,
  success,
  warning,
  info,
}

/// Banner visual para mostrar mensajes de estado, alertas y errores en formularios.
/// Disenado con un estilo minimalista, moderno y adaptativo al modo claro y oscuro.
class StatusBanner extends StatelessWidget {
  final String message;
  final StatusBannerType type;
  final VoidCallback? onDismiss;
  final EdgeInsetsGeometry margin;

  const StatusBanner({
    super.key,
    required this.message,
    this.type = StatusBannerType.error,
    this.onDismiss,
    this.margin = const EdgeInsets.only(bottom: 16.0),
  });

  @override
  Widget build(BuildContext context) {
    if (message.trim().isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color bg;
    Color fg;
    IconData icon;

    switch (type) {
      case StatusBannerType.error:
        bg = isDark ? const Color(0xFF441818) : const Color(0xFFFEE2E2);
        fg = isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626);
        icon = Icons.error_outline_rounded;
        break;
      case StatusBannerType.success:
        bg = isDark ? const Color(0xFF14381C) : const Color(0xFFDCFCE7);
        fg = isDark ? const Color(0xFF86EFAC) : const Color(0xFF16A34A);
        icon = Icons.check_circle_outline_rounded;
        break;
      case StatusBannerType.warning:
        bg = isDark ? const Color(0xFF42280A) : const Color(0xFFFEF3C7);
        fg = isDark ? const Color(0xFFFCD34D) : const Color(0xFFD97706);
        icon = Icons.warning_amber_rounded;
        break;
      case StatusBannerType.info:
        bg = isDark ? const Color(0xFF132A4A) : const Color(0xFFDBEAFE);
        fg = isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB);
        icon = Icons.info_outline_rounded;
        break;
    }

    return Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: fg,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: Padding(
                padding: const EdgeInsets.only(left: 6.0),
                child: Icon(Icons.close_rounded, color: fg, size: 18),
              ),
            ),
        ],
      ),
    );
  }
}
