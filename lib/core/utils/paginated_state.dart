/// Generic state for paginated list with infinite scroll support.
class PaginatedState<T> {
  final List<T> items;
  final int currentPage;
  final int lastPage;
  final bool isLoadingMore;
  final bool isRefreshing;
  final bool isInitialized;
  final String? error;

  const PaginatedState({
    this.items = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.isInitialized = false,
    this.error,
  });

  bool get hasMore => currentPage < lastPage;
  bool get isEmpty => items.isEmpty;

  PaginatedState<T> copyWith({
    List<T>? items,
    int? currentPage,
    int? lastPage,
    bool? isLoadingMore,
    bool? isRefreshing,
    bool? isInitialized,
    String? error,
    bool clearError = false,
  }) {
    return PaginatedState<T>(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isInitialized: isInitialized ?? this.isInitialized,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Parses a paginated response from Laravel's paginate() JSON structure.
/// Returns (items, currentPage, lastPage).
({List<Map<String, dynamic>> items, int currentPage, int lastPage})
parsePaginatedResponse(dynamic response) {
  if (response == null) {
    return (items: [], currentPage: 1, lastPage: 1);
  }

  if (response is List) {
    return (
      items: response.cast<Map<String, dynamic>>(),
      currentPage: 1,
      lastPage: 1,
    );
  }

  if (response is! Map) {
    return (items: [], currentPage: 1, lastPage: 1);
  }

  final data = response['data'];

  if (data is List) {
    // paginate() wraps in { data: { data: [...], current_page, last_page } }
    // or { data: [...] } directly
    final meta = response;
    return (
      items: data.cast<Map<String, dynamic>>(),
      currentPage: (meta['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (meta['last_page'] as num?)?.toInt() ?? 1,
    );
  }

  if (data is Map) {
    final list = (data['data'] as List? ?? []).cast<Map<String, dynamic>>();
    return (
      items: list,
      currentPage: (data['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (data['last_page'] as num?)?.toInt() ?? 1,
    );
  }

  return (items: [], currentPage: 1, lastPage: 1);
}

/// Potong list utuh menjadi halaman lokal (untuk SSOT offline pagination).
/// Digunakan saat data sudah di-cache secara penuh (per_page=-1) dan perlu
/// dipaginasi secara lokal untuk infinite scroll.
Map<String, dynamic> paginateLocally(
  List<dynamic> data, {
  required int page,
  required int perPage,
}) {
  final totalItems = data.length;
  final totalPages = totalItems == 0 ? 1 : (totalItems / perPage).ceil();
  final startIndex = (page - 1) * perPage;

  var paginated = <dynamic>[];
  if (startIndex < totalItems) {
    paginated = data.skip(startIndex).take(perPage).toList();
  }

  return {
    'data': paginated,
    'current_page': page,
    'last_page': totalPages,
    'total': totalItems,
  };
}
