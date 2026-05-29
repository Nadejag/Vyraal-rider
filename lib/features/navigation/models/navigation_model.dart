class PickupNavigationModel {
  const PickupNavigationModel({
    this.orderId = '',
    this.sellerName = 'Seller',
    this.sellerPhone = '',
    this.estimatedEarning = 'Rs. 0',
    this.itemsCount = 0,
    this.timeAway = 'Calculating',
    this.address = 'Seller pickup location not set',
    this.sellerImageUrl,
    this.sellerImageBase64,
    this.hasShopLocation = false,
  });

  final String orderId;
  final String sellerName;
  final String sellerPhone;
  final String estimatedEarning;
  final int itemsCount;
  final String timeAway;
  final String address;
  final String? sellerImageUrl;
  final String? sellerImageBase64;
  final bool hasShopLocation;
}

class DeliveryNavigationModel {
  const DeliveryNavigationModel({
    this.orderId = '',
    this.customerName = 'Customer',
    this.customerPhone = '',
    this.address = 'Customer location',
    this.eta = 'Calculating',
    this.distance = '--',
    this.paymentAmount = 'Rs. 0',
    this.items = '',
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