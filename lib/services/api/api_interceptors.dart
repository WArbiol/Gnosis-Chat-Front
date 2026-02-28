import 'package:dio/dio.dart';
import 'package:gnosis_chat/services/storage/secure_storage.dart';

/// Attaches the JWT Bearer token to every outgoing request.
class AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await SecureStorage.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

/// Logs requests and responses in debug mode.
class LoggingInterceptor extends LogInterceptor {
  LoggingInterceptor()
      : super(
          requestBody: false,
          responseBody: false,
          error: true,
        );
}

/// Transforms Dio errors into readable exception messages.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;
    final message = err.response?.data?['message'] ?? err.message;

    // Pass through with enriched message
    handler.next(
      err.copyWith(
        message: 'Error $statusCode: $message',
      ),
    );
  }
}
