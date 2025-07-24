import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://zfpngctpqjjfqqylhtzb.supabase.co';

  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpmcG5nY3RwcWpqZnFxeWxodHpiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMzMDY2NzAsImV4cCI6MjA2ODg4MjY3MH0.0yM2PWz2XiPKksYJhvf6HcqW3mpHo0l0m-Tw36CV_L8';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      // Production flag
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: true,
      ),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;
}
