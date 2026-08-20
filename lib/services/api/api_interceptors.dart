import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Attaches the JWT Bearer token to every outgoing request and handles
/// atomic session token refresh to prevent concurrent refresh token collisions.
class AuthInterceptor extends Interceptor {
  static Completer<void>? _refreshCompleter;

  /// Thread-safe atomic session refresh mutex
  static Future<void> _atomicRefreshSession() async {
    if (_refreshCompleter != null) {
      debugPrint('API_MUTEX: Waiting for in-flight session refresh...');
      await _refreshCompleter!.future;
      return;
    }

    _refreshCompleter = Completer<void>();
    try {
      debugPrint('API_MUTEX: Executing atomic token refresh...');
      await Supabase.instance.client.auth.refreshSession();
      debugPrint('API_MUTEX: Token refresh completed successfully.');
    } catch (e) {
      debugPrint('API_MUTEX: Token refresh failed: $e');
    } finally {
      final completer = _refreshCompleter;
      _refreshCompleter = null;
      completer?.complete();
    }
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    var session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final expiresAt = session.expiresAt;
      final isExpiringSoon = session.isExpired || (expiresAt != null && expiresAt - nowSeconds < 120);

      if (isExpiringSoon) {
        debugPrint('API: Token expiring soon or expired. Triggering atomic refresh...');
        await _atomicRefreshSession();
        session = Supabase.instance.client.auth.currentSession;
      }
    }

    final token = session?.accessToken;

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    } else {
      debugPrint('API: No active session token found.');
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    // If request failed with 401, attempt one atomic refresh and retry
    if (err.response?.statusCode == 401 && err.requestOptions.extra['retried_401'] != true) {
      debugPrint('API: 401 Unauthorized received. Attempting auto-retry with atomic refresh...');
      try {
        await _atomicRefreshSession();
        final freshSession = Supabase.instance.client.auth.currentSession;
        final freshToken = freshSession?.accessToken;
        if (freshToken != null) {
          final options = err.requestOptions;
          options.extra['retried_401'] = true;
          options.headers['Authorization'] = 'Bearer $freshToken';

          final dio = Dio();
          final response = await dio.fetch(options);
          return handler.resolve(response);
        }
      } catch (e) {
        debugPrint('API: 401 recovery retry failed: $e');
      }
    }
    handler.next(err);
  }
}

/// Logs requests and responses in debug mode.
class LoggingInterceptor extends LogInterceptor {
  LoggingInterceptor()
    : super(requestBody: false, responseBody: false, error: true);
}

/// Transforms Dio errors into readable exception messages.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;
    final data = err.response?.data;
    String? message;

    if (data is Map) {
      message = data['message']?.toString();
    } else if (data is String && data.trim().isNotEmpty) {
      try {
        final parsed = jsonDecode(data);
        if (parsed is Map) {
          message = parsed['message']?.toString();
        }
      } catch (_) {
        if (data.length < 200) {
          message = data;
        }
      }
    }

    message ??= err.message;

    handler.next(err.copyWith(message: 'Error $statusCode: $message'));
  }
}
