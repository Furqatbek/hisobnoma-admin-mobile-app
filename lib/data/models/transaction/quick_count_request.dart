class QuickCountRequest {
  final int productId;
  final int locationId;
  final int countedQuantity;
  final String? notes;

  const QuickCountRequest({
    required this.productId,
    required this.locationId,
    required this.countedQuantity,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'locationId': locationId,
        'countedQuantity': countedQuantity,
        if (notes != null) 'notes': notes,
      };
}
