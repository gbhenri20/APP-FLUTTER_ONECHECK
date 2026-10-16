import 'dart:async';

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../errors/app_exception.dart';
import '../security/token_storage.dart';
import 'api_response.dart';

typedef OnSessionExpired = void Function();

/// Cliente HTTP centralizado com interceptors de auth, refresh e erros.
class DioClient {
  DioClient({
    required AppConfig config,
    required TokenStorage tokenStorage,
    this.onSessionExpired,
    Dio? dio,
  })  : _config = config,
        _tokenStorage = tokenStorage,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: config.apiRoot,
                connectTimeout: Duration(milliseconds: config.connectTimeoutMs),
                receiveTimeout: Duration(milliseconds: config.receiveTimeoutMs),
                headers: {
                  'Accept': 'application/json',
                  'Content-Type': 'application/json',
                },
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );
  }

  final AppConfig _config;
  final TokenStorage _tokenStorage;
  final OnSessionExpired? onSessionExpired;
  final Dio _dio;

  Completer<void>? _refreshLock;

  Dio get raw => _dio;
  AppConfig get config => _config;

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final skipAuth = options.extra['skipAuth'] == true;
    if (!skipAuth) {
      final token = await _tokenStorage.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final skipRefresh = err.requestOptions.extra['skipRefresh'] == true;
    final alreadyRetried = err.requestOptions.extra['retried'] == true;

    if (status == 401 && !skipRefresh && !alreadyRetried) {
      try {
        await _refreshTokensOnce();
        final token = await _tokenStorage.readAccessToken();
        final opts = err.requestOptions;
        opts.extra['retried'] = true;
        if (token != null) {
          opts.headers['Authorization'] = 'Bearer $token';
        }
        final response = await _dio.fetch(opts);
        return handler.resolve(response);
      } catch (_) {
        await _tokenStorage.clearSession();
        onSessionExpired?.call();
        return handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: const SessionExpiredException(),
            type: DioExceptionType.badResponse,
            response: err.response,
          ),
        );
      }
    }
    handler.next(err);
  }

  Future<void> _refreshTokensOnce() async {
    if (_refreshLock != null) {
      return _refreshLock!.future;
    }
    _refreshLock = Completer<void>();
    try {
      final refresh = await _tokenStorage.readRefreshToken();
      if (refresh == null || refresh.isEmpty) {
        throw const SessionExpiredException();
      }
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refresh},
        options: Options(
          extra: {'skipAuth': true, 'skipRefresh': true},
        ),
      );
      final api = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data ?? {},
        mapData: (raw) => Map<String, dynamic>.from(raw as Map),
      );
      if (!api.sucesso || api.dados == null) {
        throw AppException(api.erro ?? 'Falha ao renovar sessão', statusCode: 401);
      }
      final access = api.dados!['access_token'] as String?;
      final newRefresh = api.dados!['refresh_token'] as String?;
      if (access == null || newRefresh == null) {
        throw const SessionExpiredException();
      }
      await _tokenStorage.updateTokens(
        accessToken: access,
        refreshToken: newRefresh,
      );
      _refreshLock!.complete();
    } catch (e, st) {
      _refreshLock!.completeError(e, st);
      rethrow;
    } finally {
      _refreshLock = null;
    }
  }

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? query,
    T Function(Object? raw)? parser,
    bool skipAuth = false,
  }) {
    return _request(
      () => _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: query,
        options: Options(extra: {'skipAuth': skipAuth}),
      ),
      parser: parser,
    );
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    T Function(Object? raw)? parser,
    bool skipAuth = false,
    bool skipRefresh = false,
  }) {
    return _request(
      () => _dio.post<Map<String, dynamic>>(
        path,
        data: data,
        queryParameters: query,
        options: Options(extra: {
          'skipAuth': skipAuth,
          'skipRefresh': skipRefresh,
        }),
      ),
      parser: parser,
    );
  }

  Future<ApiResponse<T>> put<T>(
    String path, {
    Object? data,
    T Function(Object? raw)? parser,
  }) {
    return _request(
      () => _dio.put<Map<String, dynamic>>(path, data: data),
      parser: parser,
    );
  }

  Future<ApiResponse<T>> patch<T>(
    String path, {
    Object? data,
    T Function(Object? raw)? parser,
  }) {
    return _request(
      () => _dio.patch<Map<String, dynamic>>(path, data: data),
      parser: parser,
    );
  }

  Future<ApiResponse<T>> delete<T>(
    String path, {
    Object? data,
    T Function(Object? raw)? parser,
  }) {
    return _request(
      () => _dio.delete<Map<String, dynamic>>(path, data: data),
      parser: parser,
    );
  }

  Future<ApiResponse<T>> upload<T>(
    String path, {
    required FormData formData,
    T Function(Object? raw)? parser,
  }) {
    return _request(
      () => _dio.post<Map<String, dynamic>>(
        path,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      ),
      parser: parser,
    );
  }

  Future<ApiResponse<T>> _request<T>(
    Future<Response<Map<String, dynamic>>> Function() call, {
    T Function(Object? raw)? parser,
  }) async {
    try {
      final response = await call();
      final body = response.data ?? <String, dynamic>{};
      final api = ApiResponse<T>.fromJson(body, mapData: parser);
      if (!api.sucesso) {
        throw AppException(
          api.erro ?? 'Operação recusada pela API',
          statusCode: response.statusCode,
          code: 'api_fail',
        );
      }
      return api;
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw mapDioException(e);
    } catch (e) {
      throw AppException('Erro inesperado', cause: e, code: 'unknown');
    }
  }

  static AppException mapDioException(DioException e) {
    if (e.error is AppException) {
      return e.error as AppException;
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const AppException(
          'Tempo esgotado. Verifique sua conexão.',
          code: 'timeout',
        );
      case DioExceptionType.connectionError:
        return const AppException(
          'Sem conexão com o servidor.',
          code: 'network',
        );
      default:
        break;
    }
    final status = e.response?.statusCode;
    final data = e.response?.data;
    String message = 'Falha na comunicação com a API';
    if (data is Map && data['erro'] is String) {
      message = data['erro'] as String;
    } else if (data is Map && data['detail'] is String) {
      message = data['detail'] as String;
    } else {
      switch (status) {
        case 400:
          message = 'Requisição inválida';
        case 401:
          message = 'Não autenticado ou sessão expirada';
        case 403:
          message = 'Acesso não autorizado';
        case 404:
          message = 'Recurso não encontrado';
        case 409:
          message = 'Conflito de dados';
        case 422:
          message = 'Dados rejeitados pela validação';
        case 429:
          message = 'Muitas tentativas. Aguarde e tente novamente';
        default:
          if ((status ?? 0) >= 500) {
            message = 'Falha no servidor. Tente novamente mais tarde';
          }
      }
    }
    return AppException(message, statusCode: status, cause: e);
  }
}
