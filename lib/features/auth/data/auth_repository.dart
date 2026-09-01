import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_service.dart';
import '../domain/profile_model.dart';

class AuthRepository {
  // Pre-configured profiles used solely in debug / unit test mode
  static final List<ProfileModel> mockProfiles = [
    ProfileModel(
      id: '00000000-0000-0000-0000-000000000001',
      name: 'Nammalvar Admin (Owner)',
      email: 'admin@nammalvar.com',
      phone: '9876543210',
      role: UserRole.admin,
      createdAt: DateTime(2026, 1, 1),
    ),
    ProfileModel(
      id: '00000000-0000-0000-0000-000000000002',
      name: 'Seller 1 (Murugan)',
      email: 'seller1@nammalvar.com',
      phone: '9876543211',
      role: UserRole.seller,
      createdAt: DateTime(2026, 1, 1),
    ),
    ProfileModel(
      id: '00000000-0000-0000-0000-000000000003',
      name: 'Seller 2 (Kavitha)',
      email: 'seller2@nammalvar.com',
      phone: '9876543212',
      role: UserRole.seller,
      createdAt: DateTime(2026, 1, 1),
    ),
    ProfileModel(
      id: '00000000-0000-0000-0000-000000000004',
      name: 'Seller 3 (Selvam)',
      email: 'seller3@nammalvar.com',
      phone: '9876543213',
      role: UserRole.seller,
      createdAt: DateTime(2026, 1, 1),
    ),
    ProfileModel(
      id: '00000000-0000-0000-0000-000000000005',
      name: 'Seller 4 (Anbarasan)',
      email: 'seller4@nammalvar.com',
      phone: '9876543214',
      role: UserRole.seller,
      createdAt: DateTime(2026, 1, 1),
    ),
  ];

  ProfileModel? _currentProfile;

  ProfileModel? get currentProfile => _currentProfile;

  AuthRepository() {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final client = SupabaseService.client;
    if (client != null && client.auth.currentSession != null) {
      final user = client.auth.currentUser;
      if (user != null) {
        await fetchProfileById(user.id);
      }
    }
  }

  Future<ProfileModel?> fetchProfileById(String userId) async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        final profileData = await client
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();

        if (profileData != null) {
          _currentProfile = ProfileModel.fromJson(profileData);
          return _currentProfile;
        }
      } catch (e) {
        debugPrint('Error fetching profile from Supabase: $e');
      }
    }
    return null;
  }

  Future<ProfileModel?> signInWithEmail(String email, String password) async {
    final client = SupabaseService.client;
    
    if (client == null) {
      // If client is completely unavailable (e.g. running in offline test harness)
      if (kDebugMode) {
        debugPrint('Supabase client unavailable, checking test profiles for offline development...');
        final matched = mockProfiles.firstWhere(
          (p) => p.email?.toLowerCase() == email.trim().toLowerCase(),
          orElse: () => throw Exception('Supabase client is not initialized and user not found in local test profiles.'),
        );
        _currentProfile = matched;
        return _currentProfile;
      }
      throw Exception('Supabase service is not initialized. Please check network connection.');
    }

    try {
      debugPrint('Attempting Supabase Auth signInWithPassword for: ${email.trim()}');
      final response = await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user != null) {
        final profile = await fetchProfileById(response.user!.id);
        if (profile == null) {
          throw Exception('User profile record not found in public.profiles. Please assign profile in Supabase.');
        }
        if (!profile.isActive) {
          await client.auth.signOut();
          throw Exception('This account has been deactivated. Please contact store owner.');
        }
        _currentProfile = profile;
        return _currentProfile;
      }

      throw Exception('Authentication failed: No user returned from Supabase Auth.');
    } on AuthException catch (e) {
      debugPrint('Supabase AuthException -> code: ${e.code}, statusCode: ${e.statusCode}, message: ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      debugPrint('Authentication unexpected error: $e');
      rethrow;
    }
  }

  /// Strictly gated for debug/test mode
  void switchActiveSellerInDebug(ProfileModel profile) {
    if (!kDebugMode) {
      throw Exception('Seller switching is prohibited in production builds.');
    }
    _currentProfile = profile;
  }

  Future<void> signOut() async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        await client.auth.signOut();
      } catch (_) {}
    }
    _currentProfile = null;
  }

  Future<List<ProfileModel>> getAllProfiles() async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        final res = await client.from('profiles').select().order('name');
        return (res as List).map((e) => ProfileModel.fromJson(e)).toList();
      } catch (e) {
        debugPrint('Error fetching profiles: $e');
      }
    }
    return mockProfiles;
  }
}
