import 'dart:async';
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

  final _profileController = StreamController<ProfileModel?>.broadcast();
  StreamSubscription<AuthState>? _authSubscription;
  ProfileModel? _currentProfile;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  ProfileModel? get currentProfile => _currentProfile;
  Stream<ProfileModel?> get profileStream => _profileController.stream;

  AuthRepository() {
    _initAuthListener();
  }

  void _initAuthListener() {
    final client = SupabaseService.client;
    if (client != null) {
      // 1. Check existing session immediately
      final session = client.auth.currentSession;
      if (session != null) {
        fetchProfileById(session.user.id).then((profile) {
          _currentProfile = profile;
          _isInitialized = true;
          if (!_profileController.isClosed) {
            _profileController.add(_currentProfile);
          }
        });
      } else {
        _isInitialized = true;
        if (!_profileController.isClosed) {
          _profileController.add(null);
        }
      }

      // 2. Listen to Supabase auth events
      _authSubscription = client.auth.onAuthStateChange.listen((data) async {
        final event = data.event;
        final session = data.session;
        debugPrint('Supabase AuthStateChange: $event, userId: ${session?.user.id}');

        if (event == AuthChangeEvent.signedIn ||
            event == AuthChangeEvent.initialSession ||
            event == AuthChangeEvent.tokenRefreshed ||
            event == AuthChangeEvent.userUpdated) {
          if (session?.user != null) {
            final profile = await fetchProfileById(session!.user.id);
            _currentProfile = profile;
            _isInitialized = true;
            if (!_profileController.isClosed) {
              _profileController.add(_currentProfile);
            }
          }
        } else if (event == AuthChangeEvent.signedOut) {
          _currentProfile = null;
          _isInitialized = true;
          if (!_profileController.isClosed) {
            _profileController.add(null);
          }
        }
      });
    } else {
      _isInitialized = true;
    }
  }

  void dispose() {
    _authSubscription?.cancel();
    _profileController.close();
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
        } else {
          final user = client.auth.currentUser;
          if (user != null && user.id == userId) {
            final email = user.email;
            final metaName = user.userMetadata?['name'] as String? ?? user.userMetadata?['full_name'] as String?;
            final name = ProfileModel.normalizeDisplayName(metaName, email);
            _currentProfile = ProfileModel(
              id: user.id,
              name: name,
              email: email,
              role: UserRole.seller,
              createdAt: DateTime.now(),
            );
            return _currentProfile;
          }
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

  Future<void> signOut() async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        await client.auth.signOut();
      } catch (e) {
        debugPrint('Supabase signOut error: $e');
      }
    }
    _currentProfile = null;
    if (!_profileController.isClosed) {
      _profileController.add(null);
    }
  }

  /// Strictly used for offline test harnesses
  void switchActiveSellerInDebug(ProfileModel profile) {
    _currentProfile = profile;
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
