/// Typed wrapper for API responses matching the backend format:
/// { "success": bool, "data": T } or { "success": false, "error": { ... } }
class ApiResponse<T> {
  final bool success;
  final T? data;
  final ApiErrorBody? error;

  const ApiResponse({required this.success, this.data, this.error});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromJsonT,
  ) {
    final success = json['success'] as bool? ?? false;
    return ApiResponse(
      success: success,
      data: success && json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      error: !success && json['error'] != null
          ? ApiErrorBody.fromJson(json['error'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Unwrap the data or throw
  T get dataOrThrow {
    if (success && data != null) return data as T;
    throw Exception(error?.message ?? 'Unknown API error');
  }
}

/// Paginated API response
class PaginatedResponse<T> {
  final List<T> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  const PaginatedResponse({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final pageRaw = json['page'];
    final int parsedPage;
    final int parsedSize;
    final int parsedTotalElements;
    final int parsedTotalPages;

    if (pageRaw is Map<String, dynamic>) {
      // Nested page object: { "number": 0, "size": 20, "totalElements": 14, ... }
      parsedPage = pageRaw['number'] as int? ?? 0;
      parsedSize = pageRaw['size'] as int? ?? 20;
      parsedTotalElements = pageRaw['totalElements'] as int? ?? 0;
      parsedTotalPages = pageRaw['totalPages'] as int? ?? 0;
    } else {
      // Flat format: { "page": 0, "size": 20, "totalElements": 14, ... }
      parsedPage = pageRaw as int? ?? 0;
      parsedSize = json['size'] as int? ?? 20;
      parsedTotalElements = json['totalElements'] as int? ?? 0;
      parsedTotalPages = json['totalPages'] as int? ?? 0;
    }

    return PaginatedResponse(
      content: (json['content'] as List)
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(),
      page: parsedPage,
      size: parsedSize,
      totalElements: parsedTotalElements,
      totalPages: parsedTotalPages,
    );
  }

  bool get hasMore => page < totalPages - 1;
  bool get isEmpty => content.isEmpty;
}

/// Error body from API
class ApiErrorBody {
  final String code;
  final String message;
  final List<String>? details;

  const ApiErrorBody({required this.code, required this.message, this.details});

  factory ApiErrorBody.fromJson(Map<String, dynamic> json) {
    return ApiErrorBody(
      code: json['code'] as String? ?? 'UNKNOWN',
      message: json['message'] as String? ?? 'Unknown error',
      details: (json['details'] as List?)?.cast<String>(),
    );
  }
}
