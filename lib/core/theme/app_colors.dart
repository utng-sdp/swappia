import 'package:flutter/material.dart';

/// Paleta de colores institucional y semantica de Swappia.
/// Inspirada en la identidad de Dolores Hidalgo (arcilla/terracota y ceramica tradicional)
/// combinada con tonos de intercambio comunitario y confianza vecinal.
abstract class AppColors {
  // --- Colores Primarios (Identidad Swappia) ---
  /// Terracota calido - Color representativo de la marca
  static const Color primary = Color(0xFFC84B31);
  static const Color primaryLight = Color(0xFFE26D5C);
  static const Color primaryDark = Color(0xFF9E2A15);
  static const Color primaryContainer = Color(0xFFFFDBCF);
  static const Color onPrimaryContainer = Color(0xFF380D03);

  // --- Colores Secundarios (Intercambio, Confianza & Acuerdos) ---
  /// Verde esmeralda comunitario para trueques y calificaciones
  static const Color secondary = Color(0xFF2E7D32);
  static const Color secondaryLight = Color(0xFF60AD5E);
  static const Color secondaryDark = Color(0xFF005005);
  static const Color secondaryContainer = Color(0xFFB8F5B8);
  static const Color onSecondaryContainer = Color(0xFF002204);

  // --- Colores Terciarios / Acentos ---
  /// Ambar artesanal para destacar oportunidades y valoraciones
  static const Color tertiary = Color(0xFFD97706);
  static const Color tertiaryLight = Color(0xFFFBBF24);
  static const Color tertiaryContainer = Color(0xFFFFE2A9);
  static const Color onTertiaryContainer = Color(0xFF2B1700);

  // --- Tema Claro (Light Theme) ---
  static const Color lightBackground = Color(0xFFFBF9F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF3EFEA);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1E232A);
  static const Color lightTextSecondary = Color(0xFF5A6270);
  static const Color lightTextTertiary = Color(0xFF8C95A6);
  static const Color lightBorder = Color(0xFFE2E4E9);
  static const Color lightInputFill = Color(0xFFF7F6F4);

  // --- Tema Oscuro (Dark Theme) ---
  static const Color darkBackground = Color(0xFF121417);
  static const Color darkSurface = Color(0xFF1A1D24);
  static const Color darkSurfaceVariant = Color(0xFF252932);
  static const Color darkCard = Color(0xFF20242D);
  static const Color darkTextPrimary = Color(0xFFF3F4F6);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkTextTertiary = Color(0xFF6B7280);
  static const Color darkBorder = Color(0xFF2E3440);
  static const Color darkInputFill = Color(0xFF1E222A);

  // --- Estados y Semantica ---
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
}
