import '../../features/home/models/home_model.dart';

class RiderActiveDeliveryStore {
  RiderActiveDeliveryStore._();

  static final RiderActiveDeliveryStore instance = RiderActiveDeliveryStore._();

  RiderOrderModel? activeOrder;

  void setActiveOrder(RiderOrderModel order) {
    activeOrder = order;
  }

  void clear() {
    activeOrder = null;
  }
}
