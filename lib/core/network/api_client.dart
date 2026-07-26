import 'dart:io';

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'api_exception.dart';

/// Thin wrapper over Dio that speaks this backend's dialect:
/// bearer tokens in `Authorization`, `{ error }` bodies on failure.
///
/// The mobile client talks to Express directly — the Next.js proxy and its
/// HttpOnly cookie only exist because a browser cannot hold a token safely.
/// On device the token lives in the platform keystore/keychain instead.
class ApiClient {
  ApiClient({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl = AppConfig.apiBaseUrl
      ..connectTimeout = const Duration(seconds: 20)
      ..receiveTimeout = const Duration(seconds: 90)
      ..sendTimeout = const Duration(minutes: 5)
      ..responseType = ResponseType.json
      // Never let Dio throw on status codes — errors are normalised in one
      // place below so every caller sees an ApiException with a real message.
      ..validateStatus = (_) => true;
  }

  final Dio _dio;

  /// Supplied by the session layer; returns the current bearer token.
  String? Function()? tokenProvider;

  /// Invoked when the API rejects a token so the app can log the user out.
  Future<void> Function()? onUnauthorized;

  Options _options({String? contentType, ResponseType? responseType}) {
    final token = tokenProvider?.call();
    return Options(
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        Headers.contentTypeHeader: ?contentType,
      },
      responseType: responseType,
    );
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    return _send(() => _dio.get(
          path,
          queryParameters: query,
          options: _options(),
        ));
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Object? body,
  }) async {
    return _send(() => _dio.post(
          path,
          data: body,
          options: _options(contentType: Headers.jsonContentType),
        ));
  }

  Future<Map<String, dynamic>> delete(String path) async {
    return _send(() => _dio.delete(path, options: _options()));
  }

  /// Multipart POST/PUT with byte-level upload progress, used by photo upload
  /// and profile image update.
  Future<Map<String, dynamic>> multipart(
    String path,
    FormData form, {
    String method = 'POST',
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    return _send(() => _dio.request(
          path,
          data: form,
          cancelToken: cancelToken,
          onSendProgress: onProgress,
          options: Options(
            method: method,
            headers: _options().headers,
          ),
        ));
  }

  /// Fetches a binary payload (the guest ZIP archive, a Cloudinary image).
  Future<List<int>> bytes(
    String path, {
    bool absoluteUrl = false,
    void Function(int received, int total)? onProgress,
  }) async {
    try {
      final response = await _dio.get<List<int>>(
        absoluteUrl ? path : '${AppConfig.apiBaseUrl}$path',
        onReceiveProgress: onProgress,
        options: Options(
          responseType: ResponseType.bytes,
          headers: absoluteUrl ? null : _options().headers,
          validateStatus: (_) => true,
        ),
      );

      final status = response.statusCode ?? 0;
      if (status >= 200 && status < 300 && response.data != null) {
        return response.data!;
      }
      if (status == 401) await onUnauthorized?.call();
      throw ApiException(
        _messageForStatus(status),
        statusCode: status,
      );
    } on DioException catch (error) {
      throw _fromDioException(error);
    }
  }

  Future<Map<String, dynamic>> _send(
    Future<Response<dynamic>> Function() request,
  ) async {
    late final Response<dynamic> response;
    try {
      response = await request();
    } on DioException catch (error) {
      throw _fromDioException(error);
    }

    final status = response.statusCode ?? 0;
    final data = response.data;
    final map = data is Map<String, dynamic>
        ? data
        : <String, dynamic>{'data': ?data};

    if (status >= 200 && status < 300) return map;

    if (status == 401) await onUnauthorized?.call();

    final message = (map['error'] ?? map['message']) as String?;
    throw ApiException(
      message?.trim().isNotEmpty == true
          ? message!.trim()
          : _messageForStatus(status),
      statusCode: status,
    );
  }

  ApiException _fromDioException(DioException error) {
    if (error.type == DioExceptionType.cancel) {
      return ApiException('Cancelled.');
    }

    final isTimeout = error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout;

    if (isTimeout) {
      return ApiException(
        'The server took too long to respond. Please try again.',
        isNetworkError: true,
      );
    }

    if (error.error is SocketException ||
        error.type == DioExceptionType.connectionError) {
      return ApiException(
        'Cannot reach FaceDeliver. Check your connection and try again.',
        isNetworkError: true,
      );
    }

    return ApiException(
      error.message ?? 'Something went wrong. Please try again.',
      isNetworkError: true,
    );
  }

  String _messageForStatus(int status) {
    return switch (status) {
      400 => 'That request was not valid.',
      401 => 'Your session has expired. Please sign in again.',
      403 => 'You do not have access to this.',
      404 => 'We could not find what you were looking for.',
      409 => 'That action is already in progress.',
      429 => 'Too many requests. Please wait a moment and try again.',
      503 => 'FaceDeliver is temporarily unavailable. Please try again shortly.',
      _ => 'Something went wrong. Please try again.',
    };
  }
}
