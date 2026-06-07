import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized Supabase configuration.
///
/// Call [SupabaseConfig.initialize] once in `main()` before `runApp()`.
class SupabaseConfig {
  SupabaseConfig._();

  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  /// Whether valid Supabase credentials are configured.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      supabaseUrl != 'https://your-project-id.supabase.co' &&
      supabaseAnonKey != 'your-anon-key-here';

  /// Initialize Supabase with credentials from `.env`.
  ///
  /// Skips initialization gracefully when credentials are placeholder values,
  /// so the app can still run in demo / CI mode.
  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');

    if (!isConfigured) {
      // ignore: avoid_print
      print(
        '⚠️  Supabase credentials not configured. '
        'Update .env with your project URL and anon key.',
      );
      return;
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  /// Convenience getter for the Supabase client.
  /// Returns `null` when credentials are not configured.
  static SupabaseClient? get client =>
      isConfigured ? Supabase.instance.client : null;
}
