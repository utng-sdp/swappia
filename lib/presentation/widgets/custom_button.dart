import 'package:flutter/material.dart';

/// Variantes de estilo para [CustomButton].
enum CustomButtonVariant {
  /// Boton solido con el color primario institucional (Terracota).
  primary,

  /// Boton solido con el color secundario (Verde intercambio).
  secondary,

  /// Boton con borde delineado y fondo transparente.
  outlined,

  /// Boton con fondo suave y texto a tono (Material 3 Tonal).
  tonal,

  /// Boton de texto plano sin elevacion ni fondo.
  text,
}

/// Tamanos estandarizados para [CustomButton].
enum CustomButtonSize {
  small,
  medium,
  large,
}

/// Componente atomico reutilizable de boton para Swappia.
/// Diseñado conforme a Material 3, con soporte reactivo para tema claro/oscuro,
/// feedback tactil, indicador de carga responsivo y accesibilidad semantica.
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final CustomButtonVariant variant;
  final CustomButtonSize size;
  final bool isLoading;
  final Widget? icon;
  final bool isTrailingIcon;
  final bool isFullWidth;
  final double? width;
  final double? height;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? textColor;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = CustomButtonVariant.primary,
    this.size = CustomButtonSize.medium,
    this.isLoading = false,
    this.icon,
    this.isTrailingIcon = false,
    this.isFullWidth = true,
    this.width,
    this.height,
    this.borderRadius = 12.0,
    this.backgroundColor,
    this.textColor,
  });

  bool get isEnabled => onPressed != null && !isLoading;

  double _getCalculatedHeight() {
    if (height != null) return height!;
    switch (size) {
      case CustomButtonSize.small:
        return 38.0;
      case CustomButtonSize.medium:
        return 50.0;
      case CustomButtonSize.large:
        return 56.0;
    }
  }

  double _getFontSize() {
    switch (size) {
      case CustomButtonSize.small:
        return 13.0;
      case CustomButtonSize.medium:
        return 15.0;
      case CustomButtonSize.large:
        return 16.0;
    }
  }

  EdgeInsetsGeometry _getPadding() {
    switch (size) {
      case CustomButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 14, vertical: 8);
      case CustomButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
      case CustomButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 14);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveHeight = _getCalculatedHeight();
    final effectiveFontSize = _getFontSize();

    // Determinacion de colores segun la variante y el tema
    Color resolvedBgColor;
    Color resolvedFgColor;
    BorderSide? borderSide;

    switch (variant) {
      case CustomButtonVariant.primary:
        resolvedBgColor = backgroundColor ?? colorScheme.primary;
        resolvedFgColor = textColor ?? colorScheme.onPrimary;
        borderSide = BorderSide.none;
        break;
      case CustomButtonVariant.secondary:
        resolvedBgColor = backgroundColor ?? colorScheme.secondary;
        resolvedFgColor = textColor ?? colorScheme.onSecondary;
        borderSide = BorderSide.none;
        break;
      case CustomButtonVariant.outlined:
        resolvedBgColor = backgroundColor ?? Colors.transparent;
        resolvedFgColor = textColor ?? colorScheme.primary;
        borderSide = BorderSide(
          color: textColor ?? colorScheme.primary,
          width: 1.5,
        );
        break;
      case CustomButtonVariant.tonal:
        resolvedBgColor = backgroundColor ?? colorScheme.primaryContainer;
        resolvedFgColor = textColor ?? colorScheme.onPrimaryContainer;
        borderSide = BorderSide.none;
        break;
      case CustomButtonVariant.text:
        resolvedBgColor = backgroundColor ?? Colors.transparent;
        resolvedFgColor = textColor ?? colorScheme.primary;
        borderSide = BorderSide.none;
        break;
    }

    // Estado deshabilitado
    if (!isEnabled) {
      if (variant == CustomButtonVariant.outlined || variant == CustomButtonVariant.text) {
        resolvedBgColor = Colors.transparent;
        resolvedFgColor = colorScheme.onSurface.withValues(alpha: 0.38);
        if (variant == CustomButtonVariant.outlined) {
          borderSide = BorderSide(
            color: colorScheme.onSurface.withValues(alpha: 0.18),
            width: 1.2,
          );
        }
      } else {
        resolvedBgColor = colorScheme.onSurface.withValues(alpha: 0.12);
        resolvedFgColor = colorScheme.onSurface.withValues(alpha: 0.38);
        borderSide = BorderSide.none;
      }
    }

    // Contenido del boton (texto, icono o spinner de carga)
    Widget content;
    if (isLoading) {
      final spinnerSize = size == CustomButtonSize.small ? 16.0 : 20.0;
      content = SizedBox(
        width: spinnerSize,
        height: spinnerSize,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(resolvedFgColor),
        ),
      );
    } else {
      final textWidget = Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: resolvedFgColor,
          fontSize: effectiveFontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      );

      if (icon != null) {
        final iconWidget = IconTheme(
          data: IconThemeData(color: resolvedFgColor, size: effectiveFontSize + 4),
          child: icon!,
        );

        content = Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: isTrailingIcon
              ? [textWidget, const SizedBox(width: 8), iconWidget]
              : [iconWidget, const SizedBox(width: 8), textWidget],
        );
      } else {
        content = textWidget;
      }
    }

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      side: borderSide,
    );

    final buttonWidget = Material(
      color: resolvedBgColor,
      shape: buttonShape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: _getPadding(),
          child: Center(child: content),
        ),
      ),
    );

    final container = SizedBox(
      width: width ?? (isFullWidth ? double.infinity : null),
      height: effectiveHeight,
      child: buttonWidget,
    );

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: text,
      child: container,
    );
  }
}
