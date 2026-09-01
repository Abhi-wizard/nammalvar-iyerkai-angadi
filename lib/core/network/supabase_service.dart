import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

class SupabaseConfig {
  static String? _url;
  static String? _anonKey;

  static const String _prefUrlKey = 'sp_supabase_url';
  static const String _prefAnonKey = 'sp_supabase_anon_key';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    final storedUrl = prefs.getString(_prefUrlKey);
    final envUrl = const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    _url = (storedUrl != null && storedUrl.isNotEmpty)
        ? storedUrl
        : (envUrl.isNotEmpty ? envUrl : AppConstants.defaultSupabaseUrl);

    final storedKey = prefs.getString(_prefAnonKey);
    final envKey = const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
    _anonKey = (storedKey != null && storedKey.isNotEmpty)
        ? storedKey
        : (envKey.isNotEmpty ? envKey : AppConstants.defaultSupabaseAnonKey);

    if (_url != null && _url!.isNotEmpty && _anonKey != null && _anonKey!.isNotEmpty) {
      try {
        await Supabase.initialize(
          url: _url!,
          // ignore: deprecated_member_use
          anonKey: _anonKey!,
          realtimeClientOptions: const RealtimeClientOptions(
            eventsPerSecond: 10,
          ),
        );
        debugPrint('Supabase initialized with live backend URL: $_url');
      } catch (e) {
        debugPrint('Supabase init error: $e');
      }
    }
  }

  static bool get isConfigured {
    try {
      return Supabase.instance.client.auth.currentSession != null || 
             (_url != null && _url!.isNotEmpty && _anonKey != null && _anonKey!.isNotEmpty);
    } catch (_) {
      return false;
    }
  }

  static Future<void> saveCredentials(String url, String anonKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefUrlKey, url.trim());
    await prefs.setString(_prefAnonKey, anonKey.trim());
    _url = url.trim();
    _anonKey = anonKey.trim();

    try {
      await Supabase.initialize(
        url: _url!,
        // ignore: deprecated_member_use
        anonKey: _anonKey!,
      );
    } catch (e) {
      debugPrint('Re-init error: $e');
    }
  }

  static String get currentUrl => _url ?? '';
  static String get currentAnonKey => _anonKey ?? '';
}

class SupabaseService {
  static SupabaseClient? get client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static bool get isLive => client != null;
}
