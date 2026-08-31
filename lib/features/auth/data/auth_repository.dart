import 'package:flutter/foundation.dart';
import '../../../core/network/supabase_service.dart';
import '../domain/profile_model.dart';

class AuthRepository {
  // Pre-configured seller profiles matching BPD
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

  ProfileModel? _currentProfile = mockProfiles[0]; // Defaults to Admin for ease of test

  ProfileModel? get currentProfile => _currentProfile;

  Future<ProfileModel?> signInWithEmail(String email, String password) async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        final response = await client.auth.signInWithPassword(
          email: email.trim(),
          password: password,
        );
        if (response.user != null) {
          final profileData = await client
              .from('profiles')
              .select()
              .eq('id', response.user!.id)
              .maybeSingle();

          if (profileData != null) {
            _currentProfile = ProfileModel.fromJson(profileData);
            return _currentProfile;
          }
        }
      } catch (e) {
        debugPrint('Supabase Auth error: $e. Falling back to local seller matching.');
      }
    }

    // Local / Demo mode fallback
    final matched = mockProfiles.firstWhere(
      (p) => p.email?.toLowerCase() == email.trim().toLowerCase(),
      orElse: () => ProfileModel(
        id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
        name: email.split('@').first,
        email: email,
        role: email.toLowerCase().contains('admin') ? UserRole.admin : UserRole.seller,
        createdAt: DateTime.now(),
      ),
    );
    _currentProfile = matched;
    return _currentProfile;
  }

  void switchActiveSeller(ProfileModel profile) {
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
        debugPrint('Error fetching profiles from Supabase: $e');
      }
    }
    return mockProfiles;
  }
}
