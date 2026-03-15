/// Generic sync response wrapper
class SyncResponse<T> {
  final DateTime lastSyncAt;
  final String syncVersion;
  final bool fullSyncRequired;
  final List<T> items;

  const SyncResponse({
    required this.lastSyncAt,
    required this.syncVersion,
    required this.fullSyncRequired,
    required this.items,
  });

  factory SyncResponse.fromJson(
    Map<String, dynamic> json, {
    required String itemsKey,
    required T Function(Map<String, dynamic>) fromJsonT,
  }) {
    return SyncResponse(
      lastSyncAt: DateTime.parse(json['lastSyncAt'] as String),
      syncVersion: json['syncVersion'] as String? ?? '1.0',
      fullSyncRequired: json['fullSyncRequired'] as bool? ?? false,
      items: (json[itemsKey] as List?)
              ?.map((e) => fromJsonT(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  bool get isEmpty => items.isEmpty;
  int get count => items.length;
}
