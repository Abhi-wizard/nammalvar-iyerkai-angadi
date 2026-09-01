import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../domain/profile_model.dart';
import '../../expenses/presentation/expense_providers.dart';
import '../../products/presentation/product_providers.dart';
import '../../sales/presentation/sales_providers.dart';
import '../../stock/presentation/stock_providers.dart';

import 'dart:async';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final repo = AuthRepository();
  ref.onDispose(() {
    repo.dispose();
  });
  return repo;
});

final currentProfileProvider = StateNotifierProvider<AuthNotifier, ProfileModel?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo, ref);
});

class AuthNotifier extends StateNotifier<ProfileModel?> {
  final AuthRepository _repo;
  final Ref _ref;
  StreamSubscription<ProfileModel?>? _profileSubscription;

  AuthNotifier(this._repo, this._ref) : super(_repo.currentProfile) {
    _profileSubscription = _repo.profileStream.listen((profile) {
      if (state?.id != profile?.id || state?.name != profile?.name || state?.role != profile?.role) {
        state = profile;
        if (profile != null) {
          _refreshAllUserData();
        }
      }
    });

    if (_repo.currentProfile != null && state == null) {
      state = _repo.currentProfile;
    }
  }

  void _refreshAllUserData() {
    _ref.invalidate(salesStreamProvider);
    _ref.read(salesRepositoryProvider).refreshSales();
    _ref.read(expenseRepositoryProvider).refreshExpenses();
    _ref.read(productRepositoryProvider).refreshProducts();
    _ref.read(stockRepositoryProvider).refreshMovements();
  }

  Future<bool> signIn(String email, String password) async {
    final profile = await _repo.signInWithEmail(email, password);
    state = profile;
    if (profile != null) {
      _refreshAllUserData();
    }
    return profile != null;
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = null;
    _ref.invalidate(salesStreamProvider);
    _ref.read(salesRepositoryProvider).refreshSales();
    _ref.read(expenseRepositoryProvider).refreshExpenses();
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    super.dispose();
  }
}

final allProfilesProvider = FutureProvider<List<ProfileModel>>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  return repo.getAllProfiles();
});
