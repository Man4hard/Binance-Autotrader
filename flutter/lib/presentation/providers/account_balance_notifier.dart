import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/account_balance.dart';
import '../../domain/repositories/binance_repository.dart';
import '../../domain/repositories/secure_storage_repository.dart';

class AccountBalanceState {
  final AccountBalance? balance;
  final bool isLoading;
  final String? error;

  const AccountBalanceState({
    this.balance,
    this.isLoading = false,
    this.error,
  });

  AccountBalanceState copyWith({
    AccountBalance? balance,
    bool? isLoading,
    String? error,
  }) =>
      AccountBalanceState(
        balance: balance ?? this.balance,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class AccountBalanceNotifier extends StateNotifier<AccountBalanceState> {
  final BinanceRepository _repo;
  final SecureStorageRepository _secure;

  AccountBalanceNotifier(this._repo, this._secure)
      : super(const AccountBalanceState());

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiKey = await _secure.getApiKey();
      final secret = await _secure.getSecretKey();
      if (apiKey == null || secret == null || apiKey.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'API keys not configured',
          balance: AccountBalance.empty(),
        );
        return;
      }
      final balance = await _repo.getAccountBalance(
        apiKey: apiKey,
        secret: secret,
      );
      state = state.copyWith(balance: balance, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        balance: AccountBalance.empty(),
      );
    }
  }
}
