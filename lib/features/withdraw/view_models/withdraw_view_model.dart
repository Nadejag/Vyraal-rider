import 'dart:async';

import '../../../core/base/base_view_model.dart';
import '../../../core/realtime/rider_realtime_service.dart';
import '../../../core/realtime/rider_withdrawal_repository.dart';
import '../models/withdraw_model.dart';

class WithdrawViewModel extends BaseViewModel {
  WithdrawViewModel({
    RiderRealtimeService? realtimeService,
    RiderWithdrawalRepository? withdrawalRepository,
  })  : _realtimeService = realtimeService ?? RiderRealtimeService.instance,
        _withdrawalRepository = withdrawalRepository ?? RiderWithdrawalRepository() {
    _bindRealtimeBalance();
  }

  final RiderRealtimeService _realtimeService;
  final RiderWithdrawalRepository _withdrawalRepository;

  StreamSubscription<WithdrawalSummary>? _summarySubscription;

  WithdrawModel _model = const WithdrawModel();

  WithdrawModel get model => _model;

  @override
  bool get isBusy => busy;

  void _bindRealtimeBalance() {
    _summarySubscription = _withdrawalRepository.watchSummary().listen(
      (summary) {
        _model = _model.applySummary(summary);
        notifyListeners();
      },
      onError: (_) {
        _model = _model.copyWith(
          isLoading: false,
          errorMessage:
              'Could not load realtime wallet. Please check Firebase rules and internet.',
        );
        notifyListeners();
      },
    );
  }

  void setAmount(int amount) {
    final safeAmount = amount.clamp(0, _model.availableBalance).toInt();
    _model = _model.copyWith(withdrawalAmount: safeAmount, clearError: true);
    notifyListeners();
  }

  void selectMethod(PayoutMethod method) {
    if (_model.selectedMethod == method) return;
    _model = _model.copyWith(selectedMethod: method, clearError: true);
    notifyListeners();
  }

  void updateAccountTitle(String value) {
    _model = _model.copyWith(accountTitle: value, clearError: true);
    notifyListeners();
  }

  void updateAccountNumber(PayoutMethod method, String value) {
    if (method == PayoutMethod.easypaisa) {
      _model = _model.copyWith(easypaisaNumber: value, clearError: true);
    } else {
      _model = _model.copyWith(jazzCashNumber: value, clearError: true);
    }
    notifyListeners();
  }

  Future<bool> requestWithdrawal() async {
    if (_model.availableBalance <= 0) {
      _model = _model.copyWith(
        errorMessage: 'No withdrawable balance yet. Complete deliveries first.',
      );
      notifyListeners();
      return false;
    }

    if (_model.withdrawalAmount <= 0) {
      _model = _model.copyWith(errorMessage: 'Enter a valid withdrawal amount.');
      notifyListeners();
      return false;
    }

    if (_model.withdrawalAmount > _model.availableBalance) {
      _model = _model.copyWith(
        errorMessage: 'Amount cannot be greater than your available balance.',
      );
      notifyListeners();
      return false;
    }

    if (!_model.hasAccountNumber) {
      _model = _model.copyWith(
        errorMessage: 'Enter a valid ${_model.selectedMethod.shortLabel} number.',
      );
      notifyListeners();
      return false;
    }

    setBusy(true);
    final ok = await _withdrawalRepository.requestWithdrawal(_model);
    setBusy(false);

    if (!ok) {
      _model = _model.copyWith(
        errorMessage:
            'Could not send withdrawal request. Please confirm login and Firebase rules.',
      );
      notifyListeners();
      return false;
    }

    final requestedAmount = _model.withdrawalAmount;
    _model = _model.copyWith(
      withdrawalAmount: 0,
      payoutStatus: PayoutStatus.pending,
      clearError: true,
    );
    _realtimeService.withdrawalRequested(
      requestedAmount,
      method: _model.selectedMethod.name,
      status: PayoutStatus.pending.name,
    );
    notifyListeners();
    return true;
  }

  @override
  void dispose() {
    _summarySubscription?.cancel();
    super.dispose();
  }
}