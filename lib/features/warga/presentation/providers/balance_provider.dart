import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/get_user_balance.dart';
import 'transaction_provider.dart';

class BalanceState {
  final double balance;
  final bool isLoading;
  final String? errorMessage;

  const BalanceState({
    required this.balance,
    this.isLoading = false,
    this.errorMessage,
  });

  BalanceState copyWith({
    double? balance,
    bool? isLoading,
    String? errorMessage,
  }) {
    return BalanceState(
      balance: balance ?? this.balance,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class BalanceNotifier extends StateNotifier<BalanceState> {
  final GetUserBalance getUserBalance;

  BalanceNotifier(this.getUserBalance)
      : super(const BalanceState(balance: 125000.0));

  Future<void> loadBalance(String userId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final balance = await getUserBalance.execute(userId);
      state = BalanceState(balance: balance, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}

final balanceNotifierProvider =
    StateNotifierProvider<BalanceNotifier, BalanceState>((ref) {
  final getBalanceUseCase = ref.watch(getUserBalanceProvider);
  return BalanceNotifier(getBalanceUseCase);
});
