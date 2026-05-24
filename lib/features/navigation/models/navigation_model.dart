class PickupNavigationModel {
  const PickupNavigationModel({
    this.sellerName = 'Amanat Dairy',
    this.estimatedEarning = 'Rs. 80',
    this.itemsCount = 2,
    this.timeAway = '4 mins\naway',
    this.address =
        'Plot 42, Sector 18, Commercial Hub\nNear Metro Pillar 124, Landmark:\nCity Bank',
  });

  final String sellerName;
  final String estimatedEarning;
  final int itemsCount;
  final String timeAway;
  final String address;
}

class DeliveryNavigationModel {
  const DeliveryNavigationModel({
    this.orderId = 'order-amanat-dairy',
    this.customerName = 'Ahmed Ali',
    this.customerPhone = '+92 300 1234567',
    this.address = 'House 45, Sector B, Blue Area',
    this.eta = '8 mins',
    this.distance = '1.2 km',
    this.paymentAmount = 'Rs. 1,450',
    this.items = '3 Packs •\nGroceries',
    this.hasDeliveryPhoto = false,
    this.isDelivered = false,
    this.notificationSent = false,
  });

  final String orderId;
  final String customerName;
  final String customerPhone;
  final String address;
  final String eta;
  final String distance;
  final String paymentAmount;
  final String items;
  final bool hasDeliveryPhoto;
  final bool isDelivered;
  final bool notificationSent;

  DeliveryNavigationModel copyWith({
    String? orderId,
    String? customerName,
    String? customerPhone,
    String? address,
    String? eta,
    String? distance,
    String? paymentAmount,
    String? items,
    bool? hasDeliveryPhoto,
    bool? isDelivered,
    bool? notificationSent,
  }) {
    return DeliveryNavigationModel(
      orderId: orderId ?? this.orderId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      address: address ?? this.address,
      eta: eta ?? this.eta,
      distance: distance ?? this.distance,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      items: items ?? this.items,
      hasDeliveryPhoto: hasDeliveryPhoto ?? this.hasDeliveryPhoto,
      isDelivered: isDelivered ?? this.isDelivered,
      notificationSent: notificationSent ?? this.notificationSent,
    );
  }
}
