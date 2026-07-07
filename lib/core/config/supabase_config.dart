import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  const SupabaseConfig._();

  static String get url => dotenv.env['SUPABASE_URL'] ?? '';
  static String get anonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static void validate() {
    if (url.isEmpty || anonKey.isEmpty) {
      throw StateError(
        'Faltan SUPABASE_URL o SUPABASE_ANON_KEY en el archivo .env',
      );
    }
  }
}
