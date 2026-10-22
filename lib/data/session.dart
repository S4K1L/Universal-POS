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

enum AuthStatus { booting, signedOut, ready }

@immutable
class SessionState {
  const SessionState({this.status = AuthStatus.booting, this.ctx, this.user, this.message});

  final AuthStatus status;
  final TenantContext? ctx;
  final Map<String, dynamic>? user; // super admins have a user but no tenant context
  final String? message;

  /// The branch this till sells for: the main branch, or the first one a branch-restricted user may work in.
  String? get branchId => ctx?.mainBranch?.id;

  bool get isAdmin => user?['role'] == 'super_admin';
  bool get ready => status == AuthStatus.ready;

  SessionState copyWith({AuthStatus? status, TenantContext? ctx, Map<String, dynamic>? user, String? message, bool clearMessage = false}) => SessionState(
        status: status ?? this.status,
        ctx: ctx ?? this.ctx,
        user: user ?? this.user,
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
      await _checkMaintenance();
      state = SessionState(status: AuthStatus.ready, ctx: ctx, user: user);
      ref.read(syncProvider.notifier).start();
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
    state = SessionState(status: AuthStatus.ready, ctx: ctx, user: user);
    ref.read(syncProvider.notifier).start();
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

/// How long a screen's data is kept after the screen is left. Tests set it to zero.
final cacheWindowProvider = Provider<Duration>((ref) => const Duration(seconds: 60));

/// Keeps an auto-disposed provider's state for a while after its screen is left, so a quick trip to another page and
/// back shows the last result at once. Never outlives the session: signing out (or in as someone else) drops it, so
/// one business's numbers can never appear for another. With [revalidate] the data is quietly re-fetched on return
/// while the cached copy stays on screen.
extension CacheForSession on Ref {
  void cacheForSession({Duration? duration, bool revalidate = false}) {
    final Duration window = duration ?? read(cacheWindowProvider);
    if (window == Duration.zero) return; // caching switched off (tests): no keep-alive, no timers
    final link = keepAlive();
    Timer? timer;
    onCancel(() => timer = Timer(window, link.close)); // nobody is looking any more: start the clock
    onResume(() {
      timer?.cancel();
      timer = null;
      if (revalidate) invalidateSelf();
    });
    onDispose(() => timer?.cancel());
    listen(sessionProvider.select((s) => '${s.status.name}|${s.user?['id']}'), (_, __) {
      timer?.cancel();
      link.close();
    });
  }
}
