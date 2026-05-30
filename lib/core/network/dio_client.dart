// ─────────────────────────────────────────────────────────────────────────────
// DioClient - HTTP Client with Interceptors for Offline-First Architecture
//
// OFFLINE-FIRST: This client NEVER throws on network errors.
// Instead, it lets callers handle offline scenarios gracefully.
// All HTTP calls are wrapped to detect offline conditions.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

// ─── Custom Exceptions ─────────────────────────────────────────────────────────

/// Custom exception for offline errors
class OfflineException implements Exception {
  final String message;
  OfflineException([this.message = 'No internet connection']);

  @override
  String toString() => 'OfflineException: $message';
}

/// Custom exception for server errors
class ServerException implements Exception {
  final int? statusCode;
  final String? message;
  final dynamic data;

  ServerException({this.statusCode, this.message, this.data});

  @override
  String toString() => 'ServerException: $statusCode - $message';
}

/// Custom exception for auth errors (401)
class DioAuthException implements Exception {
  final String message;
  DioAuthException([this.message = 'Authentication required']);

  @override
  String toString() => 'DioAuthException: $message';
}

// ─── Token Storage ─────────────────────────────────────────────────────────────

/// Result of a token refresh attempt — lets callers tell a genuine session
/// expiry apart from a transient network failure.
enum RefreshOutcome {
  /// A new access token was obtained and stored.
  success,

  /// The server could not be reached (timeout, no connection) or returned 5xx.
  /// The session may still be valid — retry later, do NOT log the user out.
  networkError,

  /// The server rejected the refresh token (4xx) or none was stored.
  /// The session is genuinely over — the caller should log out.
  authFailed,
}

class TokenStorage {
  static const _authTokenKey = 'auth_token';
  static const _refreshTokenKey = 'refresh_token';

  Completer<RefreshOutcome>? _refreshCompleter;

  Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_authTokenKey);
    if (token == null || token.isEmpty) return null;
    return token;
  }

  Future<void> write(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authTokenKey, token);
  }

  Future<String?> readRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<void> writeRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_refreshTokenKey, token);
  }

  Future<bool> hasToken() async {
    return (await read()) != null;
  }

  /// Check if the current access token is about to expire (within 5 minutes).
  bool isTokenExpiringSoon(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final exp = data['exp'] as int?;
      if (exp == null) return true;
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      const buffer = Duration(minutes: 5);
      return DateTime.now().isAfter(expiresAt.subtract(buffer));
    } catch (_) {
      return false;
    }
  }

  /// Check if the token is already past its expiration time.
  bool isTokenFullyExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final exp = data['exp'] as int?;
      if (exp == null) return true;
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(expiresAt);
    } catch (_) {
      return true;
    }
  }

  /// Refresh the auth token using the refresh token.
  /// Concurrent calls are coalesced — only one refresh runs at a time.
  Future<RefreshOutcome> refreshToken(String refreshEndpoint) async {
    final inFlight = _refreshCompleter;
    if (inFlight != null) {
      return inFlight.future;
    }

    final completer = Completer<RefreshOutcome>();
    _refreshCompleter = completer;
    // Clear the reference only after every awaiter of this future has resumed,
    // so a late caller never spawns a second refresh against a rotated token.
    completer.future.whenComplete(() {
      if (identical(_refreshCompleter, completer)) {
        _refreshCompleter = null;
      }
    });

    RefreshOutcome outcome;
    try {
      final refreshTokenVal = await readRefreshToken();
      if (refreshTokenVal == null || refreshTokenVal.isEmpty) {
        outcome = RefreshOutcome.authFailed;
      } else {
        final dio = Dio();
        final response = await dio.post(
          refreshEndpoint,
          data: jsonEncode({'refresh_token': refreshTokenVal}),
          options: Options(
            headers: {'Content-Type': 'application/json'},
            // Inspect the status ourselves so 4xx surfaces as a value, not a throw.
            validateStatus: (status) => status != null && status < 500,
          ),
        );

        final status = response.statusCode ?? 0;
        if (status == 200) {
          final data = response.data as Map<String, dynamic>;
          final newToken =
              data['token'] as String? ?? data['access_token'] as String?;
          final newRefreshToken = data['refresh_token'] as String?;

          if (newToken != null) {
            await write(newToken);
            if (newRefreshToken != null) {
              await writeRefreshToken(newRefreshToken);
            }
            outcome = RefreshOutcome.success;
          } else {
            // 200 but malformed body — treat as transient, don't nuke the session.
            outcome = RefreshOutcome.networkError;
          }
        } else if (status >= 400 && status < 500) {
          // Server actively rejected the refresh token — session is over.
          outcome = RefreshOutcome.authFailed;
        } else {
          outcome = RefreshOutcome.networkError;
        }
      }
    } on DioException catch (e) {
      debugPrint('[TokenStorage] Token refresh network error: $e');
      outcome = RefreshOutcome.networkError;
    } catch (e) {
      debugPrint('[TokenStorage] Token refresh failed: $e');
      outcome = RefreshOutcome.networkError;
    }

    completer.complete(outcome);
    return outcome;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authTokenKey);
    await prefs.remove(_refreshTokenKey);
  }
}

// ─── Dio Client ─────────────────────────────────────────────────────────────

class DioClient {
  late final Dio _dio;
  final TokenStorage _tokenStorage;

  DioClient({
    TokenStorage? tokenStorage,
    VoidCallback? onAuthFailure,
  }) : _tokenStorage = tokenStorage ?? TokenStorage() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 30),
        // Allow all status codes so we can handle them in interceptors
        validateStatus: (status) => true,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors in order
    _dio.interceptors.addAll([
      // 1. Auth interceptor (add token, handle 401)
      AuthInterceptor(
        _tokenStorage,
        _dio,
        onAuthFailure: onAuthFailure,
      ),

      // 2. Retry interceptor (linear backoff: 1s, 2s, 3s)
      RetryInterceptor(parentDio: _dio),

      // 3. Logging interceptor (debug only — avoids leaking tokens/PII in production)
      if (kDebugMode)
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => debugPrint('[Dio] $obj'),
        ),
    ]);
  }

  // ─── HTTP Methods ─────────────────────────────────────────────────────────

  /// GET request - returns decoded JSON or throws
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// POST request
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT request
  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE request
  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Multipart POST for file uploads (photos, etc.)
  Future<dynamic> uploadFile(
    String path, {
    required FormData formData,
    String method = 'POST',
    void Function(int, int)? onSendProgress,
  }) async {
    try {
      final options = Options(headers: {'Content-Type': 'multipart/form-data'});
      late final Response response;
      if (method == 'PUT') {
        response = await _dio.put(
          path,
          data: formData,
          onSendProgress: onSendProgress,
          options: options,
        );
      } else {
        response = await _dio.post(
          path,
          data: formData,
          onSendProgress: onSendProgress,
          options: options,
        );
      }
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── Response Handlers ─────────────────────────────────────────────────────

  dynamic _handleResponse(Response response) {
    // Success (2xx)
    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      return response.data;
    }

    // Error response (4xx, 5xx)
    throw ServerException(
      statusCode: response.statusCode,
      message: response.statusMessage,
      data: response.data,
    );
  }

  Exception _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return OfflineException(
          'Connection failed. Please check your internet connection.',
        );

      case DioExceptionType.badCertificate:
        return OfflineException('Security certificate error.');

      case DioExceptionType.cancel:
        return ServerException(message: 'Request cancelled');

      case DioExceptionType.badResponse:
        // Handle 401 specially
        if (e.response?.statusCode == 401) {
          return DioAuthException(
            'Token expired or invalid. Please login again.',
          );
        }
        return ServerException(
          statusCode: e.response?.statusCode,
          message: e.message,
          data: e.response?.data,
        );

      case DioExceptionType.unknown:
        if (e.error != null && e.error.toString().contains('SocketException')) {
          return OfflineException('No internet connection.');
        }
        return ServerException(message: e.message ?? 'Unknown error');
    }
  }
}

// ─── Auth Interceptor ─────────────────────────────────────────────────────

class AuthInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;
  final Dio _dio;

  /// Invoked once when a refresh is genuinely rejected by the server (session
  /// over). Left null in the background isolate so background sync never wipes
  /// the session — only the foreground app, which can show UI, logs the user out.
  final VoidCallback? _onAuthFailure;

  bool _failureNotified = false;

  AuthInterceptor(
    this._tokenStorage,
    this._dio, {
    VoidCallback? onAuthFailure,
  }) : _onAuthFailure = onAuthFailure;

  void _notifyAuthFailure() {
    if (_failureNotified) return;
    _failureNotified = true;
    final cb = _onAuthFailure;
    if (cb != null) {
      Future.microtask(cb);
    }
  }

  bool _isAuthExempt(String path) =>
      path.contains('/login') || path.contains('/auth/refresh');

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isAuthExempt(options.path)) {
      handler.next(options);
      return;
    }

    final token = await _tokenStorage.read();
    if (token == null || token.isEmpty) {
      debugPrint('[AuthInterceptor] No token available, rejecting request');
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.cancel,
          error: 'No auth token available',
        ),
      );
      return;
    }

    if (_tokenStorage.isTokenExpiringSoon(token)) {
      debugPrint('[AuthInterceptor] Token expiring soon, proactive refresh...');
      final outcome = await _tokenStorage.refreshToken(
        '${ApiConstants.baseUrl}/auth/refresh',
      );
      switch (outcome) {
        case RefreshOutcome.success:
          final newToken = await _tokenStorage.read();
          options.headers['Authorization'] = 'Bearer $newToken';
        case RefreshOutcome.authFailed:
          // Only give up if the current access token is also dead. If it still
          // has life left, use it — refresh-token revocation shouldn't kill an
          // otherwise-valid in-flight session early.
          if (_tokenStorage.isTokenFullyExpired(token)) {
            debugPrint('[AuthInterceptor] Refresh rejected & token expired → logout');
            _notifyAuthFailure();
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.cancel,
                error: 'Session expired',
              ),
            );
            return;
          }
          options.headers['Authorization'] = 'Bearer $token';
        case RefreshOutcome.networkError:
          // Transient — proceed with the existing token if it hasn't expired,
          // otherwise fail as a connection error (retryable, NOT a logout).
          if (_tokenStorage.isTokenFullyExpired(token)) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionError,
                error: 'Token refresh unreachable',
              ),
            );
            return;
          }
          options.headers['Authorization'] = 'Bearer $token';
      }
    } else {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    if (response.statusCode == 401 &&
        !_isAuthExempt(response.requestOptions.path)) {
      debugPrint('[AuthInterceptor] 401 response, attempting token refresh...');

      final outcome = await _tokenStorage.refreshToken(
        '${ApiConstants.baseUrl}/auth/refresh',
      );

      if (outcome == RefreshOutcome.success) {
        debugPrint('[AuthInterceptor] Token refreshed, retrying request');
        final opts = response.requestOptions;
        final token = await _tokenStorage.read();
        opts.headers['Authorization'] = 'Bearer $token';

        try {
          final retryResponse = await _dio.fetch(opts);
          return handler.next(retryResponse);
        } catch (e) {
          return handler.reject(
            e is DioException
                ? e
                : DioException(requestOptions: opts, error: e),
          );
        }
      }

      if (outcome == RefreshOutcome.networkError) {
        // Couldn't reach the refresh endpoint — surface as a retryable
        // connection error, do NOT log the user out.
        return handler.reject(
          DioException(
            requestOptions: response.requestOptions,
            type: DioExceptionType.connectionError,
            error: 'Token refresh unreachable',
          ),
        );
      }

      // authFailed → genuine session expiry.
      _notifyAuthFailure();
      return handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Session expired',
        ),
      );
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 &&
        !_isAuthExempt(err.requestOptions.path)) {
      debugPrint('[AuthInterceptor] 401 error, attempting token refresh...');

      final outcome = await _tokenStorage.refreshToken(
        '${ApiConstants.baseUrl}/auth/refresh',
      );

      if (outcome == RefreshOutcome.success) {
        final opts = err.requestOptions;
        final token = await _tokenStorage.read();
        opts.headers['Authorization'] = 'Bearer $token';

        try {
          final response = await _dio.fetch(opts);
          return handler.resolve(response);
        } catch (e) {
          return handler.next(e is DioException ? e : err);
        }
      }

      if (outcome == RefreshOutcome.authFailed) {
        _notifyAuthFailure();
      }
    }

    handler.next(err);
  }
}

// ─── Retry Interceptor ───────────────────────────────────────────────────────

class RetryInterceptor extends Interceptor {
  final int maxRetries;
  final List<int> retryableStatusCodes;
  final Dio _parentDio;

  RetryInterceptor({
    required Dio parentDio,
    this.maxRetries = 3,
    this.retryableStatusCodes = const [408, 429, 500, 502, 503, 504],
  }) : _parentDio = parentDio;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      handler.next(err);
      return;
    }

    if (_shouldRetry(err)) {
      final retries = err.requestOptions.extra['retryCount'] ?? 0;

      if (retries < maxRetries) {
        err.requestOptions.extra['retryCount'] = retries + 1;

        final delay = Duration(
          milliseconds: (1000 * (retries + 1)).clamp(1000, 30000).toInt(),
        );

        debugPrint(
          '[RetryInterceptor] Retrying request (attempt ${retries + 1}/$maxRetries) after ${delay.inSeconds}s',
        );
        await Future.delayed(delay);

        try {
          final response = await _parentDio.fetch(err.requestOptions);
          return handler.resolve(response);
        } catch (e) {
          return handler.next(e as DioException);
        }
      }
    }

    handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    // Retry on network errors
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return true;
    }

    // Retry on specific status codes
    if (err.response?.statusCode != null) {
      return retryableStatusCodes.contains(err.response!.statusCode);
    }

    return false;
  }
}
