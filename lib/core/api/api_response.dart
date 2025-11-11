class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final dynamic error;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.error,
  });

  // Factory constructor form JSON
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      error: json['error'],
    );
  }

  // Success response helper
  factory ApiResponse.success({
    required String message,
    T? data,
  }) {
    return ApiResponse<T>(
      success: true,
      message: message,
      data: data,
    );
  }

  // Error response helper
  factory ApiResponse.failure({
    required String message,
    dynamic error,
  }) {
    return ApiResponse<T>(
      success: false,
      message: message,
      error: error,
    );
  }

  // Check if response is successful
  bool get isSuccess => success;

  // Check if response has error
  bool get hasError => !success || error != null;

  /// Get error message
  String get errorMessage {
    if (error != null) {
      if (error is String) return error;
      if (error is Map) return error.toString();
      return 'Unknown error occurred';
    }
    return message;
  }

  @override
  String toString() {
    return 'ApiResponse(success: $success, message: $message, data: $data, error: $error)';
  }
}

// Paginated response for list endpoints
class PaginatedResponse<T> {
  final List<T> items;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;

  PaginatedResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final itemsList = (json['items'] as List?)
            ?.map((item) => fromJsonT(item as Map<String, dynamic>))
            .toList() ??
        [];

    return PaginatedResponse<T>(
      items: itemsList,
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      pageSize: json['page_size'] ?? 10,
      hasMore: json['has_more'] ?? false,
    );
  }
}
