import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';
import 'local/database.dart';
import 'models/context.dart';
import 'platform_status.dart';
import 'providers.dart';
import 'sync/sync_engine.dart';

enum AuthStatus { booting, signedOut, needsDevice, ready }

class DeviceInfo {
  DeviceInfo({required this.id, required this.code, required this.branchId, required this.name});
  factory DeviceInfo.fromJson(Map<String, dynamic> j) =>
      DeviceInfo(id: j['id'] as String, code: j['device_code'] as String? ?? j['code'] as String, branchId: j['branch_id'] as String, name: (j['name'] as String?) ?? '');
  final String id, code, branchId, name;
  Map<String, dynamic> toJson() => {'id': id, 'code': code, 'branch_id': branchId, 'name': name};
}

@immutable
class SessionState {
  const SessionState({this.status = AuthStatus.booting, this.ctx, this.user, this.device, this.message});

  final AuthStatus status;
  final TenantContext? ctx;
  final Map<String, dynamic>? user; // super admins have a user but no tenant context
  final DeviceInfo? device;
  final String? message;

  bool get isAdmin => user?['role'] == 'super_admin';
  bool get ready => status == AuthStatus.ready;

  SessionState copyWith({AuthStatus? status, TenantContext? ctx, Map<String, dynamic>? user, DeviceInfo? device, String? message, bool clearMessage = false}) => SessionState(
        status: status ?? this.status,
        ctx: ctx ?? this.ctx,
        user: user ?? this.user,
        device: device ?? this.device,
        message: clearMessage ? null : (message ?? this.message),
      );
}

class SessionController extends Notifier<SessionState> {
  late final AppDatabase _db = ref.read(dbProvider);

  ApiClient get _api => ref.read(apiProvider);

  @override
  SessionState build() {
    // Boot asynchronously; the router shows a splash until we know where to send the user.
    Future.microtask(_boot);
    return const SessionState();
  }

  Future<void> _boot() async {
    final b = ref.read(bootstrapProvider);
    if (b.access == null && b.refresh == null) {
      state = const SessionState(status: AuthStatus.signedOut);
      return;
    }
    try {
      final userJson = await _db.kvGet('user');
      final ctxJson = await _db.kvGet('ctx');
      final devJson = await _db.kvGet('device');
      if (userJson == null) {
        state = const SessionState(status: AuthStatus.signedOut);
        return;
      }
      final user = jsonDecode(userJson) as Map<String, dynamic>;
      if (user['role'] == 'super_admin') {
        state = SessionState(status: AuthStatus.ready, user: user);
        return;
      }
      if (ctxJson == null) {
        state = const SessionState(status: AuthStatus.signedOut);
        return;
      }
      final ctx = TenantContext.decode(ctxJson);
      final device = devJson == null ? null : DeviceInfo.fromJson(jsonDecode(devJson) as Map<String, dynamic>);
      await _checkMaintenance();
      state = SessionState(status: device == null ? AuthStatus.needsDevice : AuthStatus.ready, ctx: ctx, user: user, device: device);
      if (device != null) ref.read(syncProvider.notifier).start();
      unawaited(refreshContext());
    } catch (_) {
      state = const SessionState(status: AuthStatus.signedOut);
    }
  }

  // ----------------------------------------------------------------------------------- sign in

  Future<void> login(String phone, String password) async {
    final data = await _api.post('/auth/login', body: {'phone': phone.trim(), 'password': password}, noAuth: true);
    await _checkMaintenance();
    await _acceptSession(data);
  }

  /// Learn whether the platform is in maintenance *before* the router picks a screen, so a business user lands on the
  /// maintenance page rather than flashing the one behind it. Never holds a till up for long: an unreachable server
  /// just means "unknown", and the app carries on offline.
  Future<void> _checkMaintenance() => ref.read(platformStatusProvider.notifier).refresh().timeout(const Duration(milliseconds: 1500), onTimeout: () {});

  Future<void> _acceptSession(Map<String, dynamic> data) async {
    final access = data['access_token'] as String;
    final refresh = data['refresh_token'] as String;
    final user = (data['user'] as Map).cast<String, dynamic>();
    final ctxJson = (data['context'] as Map?)?.cast<String, dynamic>();

    if (ctxJson != null) {
      final newTenant = (ctxJson['tenant'] as Map)['id'] as String;
      final oldTenant = await _db.kvGet('tenant_id');
      if (oldTenant != null && oldTenant != newTenant) {
        final pending = await (_db.select(_db.outbox)..where((t) => t.status.isNotValue('done'))).get();
        if (pending.isNotEmpty) {
          throw ApiError(
            status: 409,
            code: 'unsynced_data',
            message: 'This device still has ${pending.length} sale${pending.length == 1 ? '' : 's'} waiting to sync for another business. Connect to the internet and sync before switching businesses.',
          );
        }
        await _db.wipeBusinessData();
      }
      await _db.kvSet('tenant_id', newTenant);
      await _db.kvSet('ctx', jsonEncode(ctxJson));
    }
    await _db.kvSet('user', jsonEncode(user));
    _api.setTokens(access, refresh);
    await SecureStore.instance.write('access', access);
    await SecureStore.instance.write('refresh', refresh);

    if (user['role'] == 'super_admin') {
      state = SessionState(status: AuthStatus.ready, user: user);
      return;
    }
    final ctx = TenantContext.fromJson(ctxJson!);
    final devJson = await _db.kvGet('device');
    final device = devJson == null ? null : DeviceInfo.fromJson(jsonDecode(devJson) as Map<String, dynamic>);
    state = SessionState(status: device == null ? AuthStatus.needsDevice : AuthStatus.ready, ctx: ctx, user: user, device: device);
    if (device != null) ref.read(syncProvider.notifier).start();
  }

  /// Register this till with the server. It gets a short code that prefixes every invoice number it issues
  /// offline, so two tills can never mint the same number.
  Future<void> registerDevice({required String name, required String branchId}) async {
    final res = await _api.post('/devices/register', body: {'name': name, 'branch_id': branchId, 'platform': _platformLabel(), 'app_version': '1.0.0'});
    final device = DeviceInfo.fromJson(res);
    await _db.kvSet('device', jsonEncode(device.toJson()));
    await _db.kvSet('invoice_seq', '0');
    state = state.copyWith(status: AuthStatus.ready, device: device, clearMessage: true);
    ref.read(syncProvider.notifier).start();
  }

  String _platformLabel() => kIsWeb ? 'web' : defaultTargetPlatform.name;

  /// The server no longer knows this device (removed in the console). Ask to register again.
  Future<void> deviceRemoved() async {
    await _db.kvDelete('device');
    state = SessionState(status: AuthStatus.needsDevice, ctx: state.ctx, user: state.user, message: 'This device was removed. Register it again to keep selling.');
  }

  // ------------------------------------------------------------------------------------ context

  /// Re-read the business context (plan, permissions, settings). Silent when offline.
  Future<void> refreshContext() async {
    if (state.ctx == null) return;
    try {
      final j = await _api.getMap('/tenants/me/context');
      final ctx = TenantContext.fromJson(j);
      await _db.kvSet('ctx', jsonEncode(j));
      await _db.kvSet('user', jsonEncode(j['user']));
      state = state.copyWith(ctx: ctx, user: (j['user'] as Map).cast<String, dynamic>());
    } on ApiError catch (e) {
      if (e.unauthorized) await expire();
    }
  }

  void applyContext(Map<String, dynamic> j) {
    unawaited(_db.kvSet('ctx', jsonEncode(j)));
    state = state.copyWith(ctx: TenantContext.fromJson(j));
  }

  // ------------------------------------------------------------------------------------ sign out

  Future<void> expire() async {
    ref.read(syncProvider.notifier).stop();
    await _clearTokens();
    state = const SessionState(status: AuthStatus.signedOut, message: 'Your session expired. Please sign in again.');
  }

  Future<void> logout() async {
    final refresh = _api.refreshToken;
    ref.read(syncProvider.notifier).stop();
    if (refresh != null) {
      try {
        await _api.post('/auth/logout', body: {'refresh_token': refresh}, noAuth: true);
      } catch (_) {}
    }
    await _clearTokens();
    state = const SessionState(status: AuthStatus.signedOut);
  }

  Future<void> _clearTokens() async {
    _api.setTokens(null, null);
    await SecureStore.instance.write('access', null);
    await SecureStore.instance.write('refresh', null);
    await _db.kvDelete('user');
  }
}

final sessionProvider = NotifierProvider<SessionController, SessionState>(SessionController.new);

/// Convenience: the context of a signed-in tenant user (never null inside the tenant shell).
final ctxProvider = Provider<TenantContext>((ref) {
  final c = ref.watch(sessionProvider).ctx;
  if (c == null) throw StateError('No tenant context');
  return c;
});

/// The API client. Tokens come from the boot-time store; a refresh the server rejects ends the session.
final apiProvider = Provider<ApiClient>((ref) {
  final url = ref.watch(serverUrlProvider);
  final b = ref.read(bootstrapProvider);
  final client = ApiClient(
    baseUrl: url,
    onSessionExpired: () => ref.read(sessionProvider.notifier).expire(),
    onMaintenance: (message) => ref.read(platformStatusProvider.notifier).enterMaintenance(message),
    onTokens: (a, r) {
      SecureStore.instance.write('access', a);
      SecureStore.instance.write('refresh', r);
    },
  );
  client.setTokens(b.access, b.refresh);
  return client;
});
