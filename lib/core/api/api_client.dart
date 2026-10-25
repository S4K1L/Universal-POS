import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where the API lives. The web build talks to the host it was served from (so a till on the shop's LAN works
/// without configuration); a different server can be chosen in Settings and is remembered.
/// The default comes from `API_BASE` in `.env`, then a `--dart-define=API_BASE=…`, then a per-platform guess.
class ServerConfig {
  static const _fromDefine = String.fromEnvironment('API_BASE');

  static String get fallback {
    final fromEnv = dotenv.isInitialized ? dotenv.maybeGet('API_BASE')?.trim() : null;
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    if (_fromDefine.isNotEmpty) return _fromDefine;
    if (kIsWeb) return 'http://${Uri.base.host.isEmpty ? 'localhost' : Uri.base.host}:8000/api/v1';
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:8000/api/v1';
    return 'http://localhost:8000/api/v1';
  }
}

class SecureStore {
  SecureStore._();
  static final instance = SecureStore._();
  final _store = const FlutterSecureStorage(webOptions: WebOptions(dbName: 'universal_pos', publicKey: 'universal_pos'));
  final _mem = <String, String>{};

  Future<String?> read(String key) async {
    try {
      return await _store.read(key: key) ?? _mem[key];
    } catch (_) {
      return _mem[key];
    }
  }

  Future<void> write(String key, String? value) async {
    if (value == null) {
      _mem.remove(key);
      try {
        await _store.delete(key: key);
      } catch (_) {}
      return;
    }
    _mem[key] = value;
    try {
      await _store.write(key: key, value: value);
    } catch (_) {}
  }
}

class ApiError implements Exception {
  ApiError({required this.status, required this.message, this.code = 'error', this.extra = const {}, this.offline = false});

  final int status;
  final String message;
  final String code;
  final Map<String, dynamic> extra;

  /// The request never reached the server (no connection, timeout, DNS…).
  final bool offline;

  bool get unauthorized => status == 401;
  bool get lapsed => code == 'subscription_lapsed' || code == 'account_suspended';

  /// The platform owner switched maintenance on: every business route answers 503 until they switch it off.
  bool get maintenance => code == 'maintenance';
  bool get validation => status == 422 || status == 400;

  @override
  String toString() => message;
}

/// Thin Dio wrapper: bearer auth, one-shot silent refresh on 401, and errors reduced to [ApiError].
class ApiClient {
  ApiClient({required this.baseUrl, this.onSessionExpired, this.onTokens, this.onMaintenance}) {
    dio = Dio(BaseOptions(baseUrl: baseUrl, connectTimeout: const Duration(seconds: 8), receiveTimeout: const Duration(seconds: 30), sendTimeout: const Duration(seconds: 30), headers: {'Accept': 'application/json'}));
    _bare = Dio(BaseOptions(baseUrl: baseUrl, connectTimeout: const Duration(seconds: 8), receiveTimeout: const Duration(seconds: 20)));
    dio.interceptors.add(InterceptorsWrapper(onRequest: _onRequest, onError: _onError));
  }

  /// Swap the network layer (tests serve canned responses through a fake adapter).
  set adapter(HttpClientAdapter a) {
    dio.httpClientAdapter = a;
    _bare.httpClientAdapter = a;
  }

  final String baseUrl;
  final void Function()? onSessionExpired;
  final void Function(String access, String refresh)? onTokens;

  /// Any response that says the platform is in maintenance, with the admin's message.
  final void Function(String message)? onMaintenance;
  late final Dio dio;
  late final Dio _bare;

  /// Pretend the network is down (Sync Center "work offline" switch, and tests). Requests fail exactly the way a
  /// dead connection does, so the whole offline path can be exercised without pulling a cable.
  bool forceOffline = false;

  String? accessToken;
  String? refreshToken;
  Completer<bool>? _refreshing;

  void setTokens(String? access, String? refresh) {
    accessToken = access;
    refreshToken = refresh;
  }

  void _onRequest(RequestOptions o, RequestInterceptorHandler h) {
    if (forceOffline) {
      return h.reject(DioException(requestOptions: o, type: DioExceptionType.connectionError, error: 'offline (simulated)'));
    }
    if (accessToken != null && o.extra['noAuth'] != true) o.headers['Authorization'] = 'Bearer $accessToken';
    // Browsers ignore sendTimeout without a body, and Dio's web adapter then warns and forces a CORS preflight.
    if (kIsWeb && o.data == null) o.sendTimeout = null;
    h.next(o);
  }

  Future<void> _onError(DioException e, ErrorInterceptorHandler h) async {
    final r = e.response;
    final retried = e.requestOptions.extra['retried'] == true;
    final body = r?.data;
    if (r?.statusCode == 503 && body is Map && body['code'] == 'maintenance') onMaintenance?.call(body['detail'] is String ? body['detail'] as String : '');
    if (r?.statusCode == 401 && !retried && refreshToken != null && e.requestOptions.extra['noAuth'] != true) {
      final ok = await _refresh();
      if (ok) {
        final o = e.requestOptions..extra['retried'] = true;
        o.headers['Authorization'] = 'Bearer $accessToken';
        try {
          return h.resolve(await dio.fetch(o));
        } on DioException catch (e2) {
          return h.next(e2);
        }
      }
    }
    h.next(e);
  }

  /// Single-flight refresh: concurrent 401s share one call. A network failure is *not* a logout.
  Future<bool> _refresh() async {
    if (_refreshing != null) return _refreshing!.future;
    final c = _refreshing = Completer<bool>();
    try {
      final res = await _bare.post('/auth/refresh', data: {'refresh_token': refreshToken});
      accessToken = res.data['access_token'] as String;
      refreshToken = res.data['refresh_token'] as String;
      onTokens?.call(accessToken!, refreshToken!);
      c.complete(true);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) onSessionExpired?.call();
      c.complete(false);
    } catch (_) {
      c.complete(false);
    }
    final ok = await c.future;
    _refreshing = null;
    return ok;
  }

  ApiError wrap(Object e) {
    if (e is ApiError) return e;
    if (e is DioException) {
      final r = e.response;
      if (r == null) {
        final msg = switch (e.type) {
          DioExceptionType.connectionTimeout || DioExceptionType.receiveTimeout || DioExceptionType.sendTimeout => 'The server took too long to answer.',
          _ => 'No connection to the server.',
        };
        return ApiError(status: 0, message: msg, code: 'offline', offline: true);
      }
      final data = r.data;
      if (data is Map) {
        final map = data.cast<String, dynamic>();
        final detail = map['detail'];
        return ApiError(
          status: r.statusCode ?? 500,
          message: detail is String ? detail : 'Request failed (${r.statusCode})',
          code: (map['code'] as String?) ?? 'error',
          extra: map,
        );
      }
      return ApiError(status: r.statusCode ?? 500, message: 'Server error (${r.statusCode}). Try again.', code: 'server_error');
    }
    return ApiError(status: 0, message: e.toString());
  }

  Future<T> _run<T>(Future<Response<dynamic>> Function() call, T Function(dynamic) parse) async {
    try {
      final r = await call();
      return parse(r.data);
    } catch (e) {
      throw wrap(e);
    }
  }

  Future<Map<String, dynamic>> getMap(String path, {Map<String, dynamic>? query, bool noAuth = false, Duration? timeout}) =>
      _run(() => dio.get(path, queryParameters: query, options: Options(extra: {'noAuth': noAuth}, receiveTimeout: timeout, sendTimeout: timeout)), (d) => (d as Map).cast<String, dynamic>());

  Future<List<dynamic>> getList(String path, {Map<String, dynamic>? query}) => _run(() => dio.get(path, queryParameters: query), (d) => d as List);

  Future<Map<String, dynamic>> post(String path, {Object? body, bool noAuth = false}) =>
      _run(() => dio.post(path, data: body, options: Options(extra: {'noAuth': noAuth})), (d) => d is Map ? d.cast<String, dynamic>() : <String, dynamic>{});

  Future<Map<String, dynamic>> put(String path, {Object? body}) => _run(() => dio.put(path, data: body), (d) => d is Map ? d.cast<String, dynamic>() : <String, dynamic>{});

  Future<Map<String, dynamic>> patch(String path, {Object? body}) => _run(() => dio.patch(path, data: body), (d) => d is Map ? d.cast<String, dynamic>() : <String, dynamic>{});

  Future<Map<String, dynamic>> delete(String path) => _run(() => dio.delete(path), (d) => d is Map ? d.cast<String, dynamic>() : <String, dynamic>{});

  /// Reachability probe used by the sync engine — short timeout, no auth. `/health` lives at the server root.
  Future<bool> ping() async {
    if (forceOffline) return false;
    try {
      final uri = Uri.parse(baseUrl).replace(path: '/health');
      final r = await _bare.getUri(uri, options: Options(receiveTimeout: const Duration(seconds: 4), sendTimeout: kIsWeb ? null : const Duration(seconds: 4)));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
