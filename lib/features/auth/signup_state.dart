import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/session.dart';

/// A signup that is waiting for the platform owner. The password is only held in memory: it lets this screen ask
/// "has it been approved?" and then sign in the moment it is — it is never written to disk.
class PendingSignup {
  const PendingSignup({required this.phone, required this.password, this.businessName = '', this.typeLabel = ''});
  final String phone, password, businessName, typeLabel;

  PendingSignup copyWith({String? businessName, String? typeLabel}) =>
      PendingSignup(phone: phone, password: password, businessName: businessName ?? this.businessName, typeLabel: typeLabel ?? this.typeLabel);
}

class PendingSignupController extends Notifier<PendingSignup?> {
  @override
  PendingSignup? build() => null;

  void set(PendingSignup p) => state = p;
  void clear() => state = null;
}

final pendingSignupProvider = NotifierProvider<PendingSignupController, PendingSignup?>(PendingSignupController.new);

/// The business types a new shop can start as (public — no sign-in needed).
final publicBusinessTypesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return (await ref.watch(apiProvider).getList('/public/business-types')).cast<Map<String, dynamic>>();
});
