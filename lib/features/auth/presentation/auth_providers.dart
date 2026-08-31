import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../domain/profile_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final currentProfileProvider = StateNotifierProvider<AuthNotifier, ProfileModel?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});

class AuthNotifier extends StateNotifier<ProfileModel?> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(_repo.currentProfile);

  Future<bool> signIn(String email, String password) async {
    final profile = await _repo.signInWithEmail(email, password);
    state = profile;
    return profile != null;
  }

  void switchSellerInDebug(ProfileModel profile) {
    if (kDebugMode) {
      _repo.switchActiveSellerInDebug(profile);
      state = profile;
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = null;
  }
}

final allProfilesProvider = FutureProvider<List<ProfileModel>>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  return repo.getAllProfiles();
});
