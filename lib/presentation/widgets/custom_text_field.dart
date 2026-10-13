import 'package:flutter/material.dart';

/// Campo de texto atomico, accesible y reutilizable para el ecosistema Swappia.
/// Responde directamente a las especificaciones de Material 3 y sincroniza su
/// apariencia tanto en modo claro como en modo oscuro.
/// Incluye soporte integrado para campos de contrasena con alternancia de visibilidad,
/// etiquetas contextuales, validaciones, iconos y multi-lineas.
class CustomTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? initialValue;
  final bool isPassword;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final String? helperText;
  final String? errorText;
  final bool autofocus;
  final FocusNode? focusNode;
  final double borderRadius;
  final EdgeInsetsGeometry? contentPadding;

  const CustomTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.initialValue,
    this.isPassword = false,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.helperText,
    this.errorText,
    this.autofocus = false,
    this.focusNode,
    this.borderRadius = 12.0,
    this.contentPadding,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.isPassword || widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final inputTheme = theme.inputDecorationTheme;

    // Manejo del icono de sufijo cuando es password o cuando el usuario provee uno
    Widget? effectiveSuffixIcon = widget.suffixIcon;
    if (widget.isPassword) {
      effectiveSuffixIcon = IconButton(
        icon: Icon(
          _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: colorScheme.onSurfaceVariant,
          size: 20,
        ),
        onPressed: () {
          setState(() {
            _obscured = !_obscured;
          });
        },
        tooltip: _obscured ? 'Mostrar contrasena' : 'Ocultar contrasena',
      );
    }

    final effectiveBorderRadius = BorderRadius.circular(widget.borderRadius);

    final decoration = InputDecoration(
      labelText: widget.label,
      hintText: widget.hint,
      helperText: widget.helperText,
      errorText: widget.errorText,
      prefixIcon: widget.prefixIcon,
      suffixIcon: effectiveSuffixIcon,
      contentPadding: widget.contentPadding ?? inputTheme.contentPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: inputTheme.fillColor,
      border: OutlineInputBorder(
        borderRadius: effectiveBorderRadius,
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: effectiveBorderRadius,
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: effectiveBorderRadius,
        borderSide: BorderSide(color: colorScheme.primary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: effectiveBorderRadius,
        borderSide: BorderSide(color: colorScheme.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: effectiveBorderRadius,
        borderSide: BorderSide(color: colorScheme.error, width: 1.8),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: effectiveBorderRadius,
        borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
    );

    return TextFormField(
      controller: widget.controller,
      initialValue: widget.initialValue,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      obscureText: _obscured,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      maxLines: widget.isPassword ? 1 : widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      style: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 15,
      ),
      decoration: decoration,
    );
  }
}
