import '../../../core/base/base_view_model.dart';
import '../../../core/realtime/rider_realtime_service.dart';
import '../models/withdraw_model.dart';

class WithdrawViewModel extends BaseViewModel {
  WithdrawViewModel({RiderRealtimeService? realtimeService})
    : _realtimeService = realtimeService ?? RiderRealtimeService.instance;

  final RiderRealtimeService _realtimeService;

  WithdrawModel _model = const WithdrawModel();

  WithdrawModel get model => _model;

  void setAmount(int amount) {
    final safeAmount = amount.clamp(0, _model.availableBalance);
    _model = _model.copyWith(withdrawalAmount: safeAmount);
    notifyListeners();
  }

  void selectMethod(PayoutMethod method) {
    if (_model.selectedMethod == method) return;

    _model = _model.copyWith(selectedMethod: method);
    notifyListeners();
  }

  void requestWithdrawal() {
    if (_model.withdrawalAmount <= 0) return;

    _model = _model.copyWith(payoutStatus: PayoutStatus.pending);
    _realtimeService.withdrawalRequested(
      _model.withdrawalAmount,
      method: _model.selectedMethod.name,
      status: _model.payoutStatus.name,
    );
    notifyListeners();
  }
}
