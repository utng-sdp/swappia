import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio para gestionar la conexión global con Supabase implementando el patrón Singleton.
class SupabaseService {
  // Instancia única privada
  static final SupabaseService _instance = SupabaseService._internal();

  // Constructor privado
  SupabaseService._internal();

  /// Fábrica que retorna la misma instancia única
  factory SupabaseService() => _instance;

  /// Getter estático para acceder a la instancia única
  static SupabaseService get instance => _instance;

  /// Getter para acceder al cliente de Supabase
  SupabaseClient get client => Supabase.instance.client;

  /// Getter auxiliar para acceder al servicio de autenticación
  GoTrueClient get auth => client.auth;

  /// Getter auxiliar para obtener el usuario autenticado actual
  User? get currentUser => client.auth.currentUser;

  /// Inicializa la conexión con Supabase utilizando las variables de entorno cargadas con flutter_dotenv.
  static Future<void> initialize() async {
    final rawUrl = dotenv.env['SUPABASE_URL']?.trim();
    final rawAnonKey = dotenv.env['SUPABASE_ANON_KEY']?.trim();

    if (rawUrl == null || rawUrl.isEmpty) {
      throw StateError(
        'La variable SUPABASE_URL no está definida o está vacía en el archivo .env',
      );
    }

    if (rawAnonKey == null || rawAnonKey.isEmpty) {
      throw StateError(
        'La variable SUPABASE_ANON_KEY no está definida o está vacía en el archivo .env',
      );
    }

    // Normalizar la URL: remover /rest/v1 o barras al final si fueron añadidas por error
    final sanitizedUrl = rawUrl
        .replaceAll(RegExp(r'/rest/v1/?$'), '')
        .replaceAll(RegExp(r'/+$'), '');

    await Supabase.initialize(
      url: sanitizedUrl,
      // ignore: deprecated_member_use
      anonKey: rawAnonKey,
    );
  }
}
