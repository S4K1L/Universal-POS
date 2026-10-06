import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session.dart';

/// What the platform owner has said about the service as a whole (`GET /public/status`).
@immutable
class PlatformStatus {
  const PlatformStatus({this.maintenance = false, this.message = '', this.support = const {}});

  factory PlatformStatus.fromJson(Map<String, dynamic> j) => PlatformStatus(
        maintenance: j['maintenance'] == true,
        message: (j['message'] as String?) ?? '',
        support: {
          for (final e in ((j['support'] as Map?) ?? const {}).entries)
            if (e.value is String && (e.value as String).trim().isNotEmpty) e.key as String: (e.value as String).trim(),
        },
      );

  final bool maintenance;
  final String message;

  /// The contacts the admin filled in (`phone`, `whatsapp`, `email`) — empty ones are left out.
  final Map<String, String> support;
}

/// Knows whether the platform is in maintenance. Three things feed it: the poll below, the session (checked right
/// after sign-in and on launch) and any API call that comes back `503 maintenance`.
///
/// The server being *unreachable* never counts as maintenance — a till that is merely offline keeps selling.
class PlatformStatusController extends Notifier<PlatformStatus> {
  /// Tests switch this off: a periodic timer would outlive the widget tree.
  static bool autoPoll = true;

  static const _idle = Duration(seconds: 60);
  static const _whileDown = Duration(seconds: 10); // so the till comes back soon after maintenance ends

  Timer? _timer;
  Future<void>? _inflight;
  bool _disposed = false;

  @override
  PlatformStatus build() {
    ref.onDispose(() {
      _disposed = true;
      _timer?.cancel();
    });
    if (autoPoll) Future.microtask(refresh);
    return const PlatformStatus();
  }

  /// Ask the server now. Calls made while a check is running share it.
  Future<void> refresh() => _inflight ??= _fetch().whenComplete(() => _inflight = null);

  Future<void> _fetch() async {
    try {
      final j = await ref.read(apiProvider).getMap('/public/status', noAuth: true, timeout: const Duration(seconds: 6));
      if (!_disposed) state = PlatformStatus.fromJson(j);
    } catch (_) {
      // Unreachable or erroring: we do not know, so keep what we knew.
    }
    if (autoPoll && !_disposed) {
      _timer?.cancel();
      _timer = Timer(state.maintenance ? _whileDown : _idle, refresh);
    }
  }

  /// An API call just came back `503 maintenance`: show it at once, then confirm and pick up the support contacts.
  void enterMaintenance(String message) {
    if (_disposed) return;
    if (!state.maintenance || (message.isNotEmpty && message != state.message)) {
      state = PlatformStatus(maintenance: true, message: message, support: state.support);
    }
    unawaited(refresh());
  }
}

final platformStatusProvider = NotifierProvider<PlatformStatusController, PlatformStatus>(PlatformStatusController.new);
