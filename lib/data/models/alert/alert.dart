enum AlertType {
  lowStock,
  outOfStock,
  expiringInventory,
  largeTransaction,
  dailySummary,
  priceChange,
  newOrder,
  paymentReceived,
  paymentDue,
  paymentOverdue,
  system;

  static AlertType fromString(String value) {
    switch (value) {
      case 'LOW_STOCK':
        return AlertType.lowStock;
      case 'OUT_OF_STOCK':
        return AlertType.outOfStock;
      case 'EXPIRING_INVENTORY':
        return AlertType.expiringInventory;
      case 'LARGE_TRANSACTION':
        return AlertType.largeTransaction;
      case 'DAILY_SUMMARY':
        return AlertType.dailySummary;
      case 'PRICE_CHANGE':
        return AlertType.priceChange;
      case 'NEW_ORDER':
      case 'ORDER_PLACED':
      case 'ORDER_CANCELLED':
        return AlertType.newOrder;
      case 'PAYMENT_RECEIVED':
        return AlertType.paymentReceived;
      case 'PAYMENT_DUE':
        return AlertType.paymentDue;
      case 'PAYMENT_OVERDUE':
        return AlertType.paymentOverdue;
      case 'WEEKLY_SUMMARY':
        return AlertType.dailySummary;
      case 'SYSTEM':
      case 'SYSTEM_ALERT':
      case 'APPROVAL_REQUIRED':
      case 'CUSTOM':
        return AlertType.system;
      default:
        return AlertType.system;
    }
  }

  String get apiValue {
    switch (this) {
      case AlertType.lowStock:
        return 'LOW_STOCK';
      case AlertType.outOfStock:
        return 'OUT_OF_STOCK';
      case AlertType.expiringInventory:
        return 'EXPIRING_INVENTORY';
      case AlertType.largeTransaction:
        return 'LARGE_TRANSACTION';
      case AlertType.dailySummary:
        return 'DAILY_SUMMARY';
      case AlertType.priceChange:
        return 'PRICE_CHANGE';
      case AlertType.newOrder:
        return 'NEW_ORDER';
      case AlertType.paymentReceived:
        return 'PAYMENT_RECEIVED';
      case AlertType.paymentDue:
        return 'PAYMENT_DUE';
      case AlertType.paymentOverdue:
        return 'PAYMENT_OVERDUE';
      case AlertType.system:
        return 'SYSTEM';
    }
  }
}

enum AlertPriority {
  low,
  normal,
  high,
  urgent;

  static AlertPriority fromString(String value) {
    switch (value) {
      case 'LOW':
        return AlertPriority.low;
      case 'NORMAL':
        return AlertPriority.normal;
      case 'HIGH':
        return AlertPriority.high;
      case 'URGENT':
        return AlertPriority.urgent;
      default:
        return AlertPriority.normal;
    }
  }
}

class Alert {
  final int id;
  final AlertType alertType;
  final String title;
  final String message;
  final AlertPriority priority;
  final String? entityType;
  final int? entityId;
  final bool isRead;
  final DateTime createdAt;

  const Alert({
    required this.id,
    required this.alertType,
    required this.title,
    required this.message,
    required this.priority,
    this.entityType,
    this.entityId,
    required this.isRead,
    required this.createdAt,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] as int,
      alertType: AlertType.fromString(json['alertType'] as String),
      title: json['title'] as String,
      message: json['message'] as String,
      priority: AlertPriority.fromString(json['priority'] as String),
      entityType: json['entityType'] as String?,
      entityId: json['entityId'] as int?,
      // Backend documents this field as `read`; older builds used `isRead`.
      // Accept either so read-state survives both shapes.
      isRead: json['isRead'] as bool? ?? json['read'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Alert copyWith({bool? isRead}) {
    return Alert(
      id: id,
      alertType: alertType,
      title: title,
      message: message,
      priority: priority,
      entityType: entityType,
      entityId: entityId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
