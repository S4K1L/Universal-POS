import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/money/money.dart';
import '../../core/money/pricing.dart';

/// Everything the app needs to know about the signed-in business, from `GET /tenants/me/context`.
/// Cached on the device so a till can start with no connection.
class TenantContext {
  TenantContext(this.raw);

  factory TenantContext.fromJson(Map<String, dynamic> j) => TenantContext(j);
  factory TenantContext.decode(String s) => TenantContext(jsonDecode(s) as Map<String, dynamic>);

  final Map<String, dynamic> raw;
  String encode() => jsonEncode(raw);

  Map<String, dynamic> get _tenant => (raw['tenant'] as Map).cast();
  Map<String, dynamic> get _bt => (raw['business_type'] as Map).cast();
  Map<String, dynamic> get _settings => (raw['settings'] as Map).cast();
  Map<String, dynamic> get _sub => (raw['subscription'] as Map).cast();
  Map<String, dynamic> get _user => (raw['user'] as Map).cast();

  String get tenantId => _tenant['id'] as String;
  String get businessName => _tenant['name'] as String;
  String get businessAddress => (_tenant['address'] as String?) ?? '';
  String get businessPhone => (_tenant['phone'] as String?) ?? '';

  String get typeKey => _bt['key'] as String;
  String get typeLabel => _bt['label'] as String;
  String get family => (_bt['family'] as String?) ?? 'counter_retail';

  Color get accent {
    final hex = ((_bt['theme'] as Map?)?['accent'] as String?) ?? '#0E9F6E';
    return Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
  }

  String get iconName => (((_bt['theme'] as Map?)?['icon']) as String?) ?? 'store';

  Set<String> get capabilities => {...(raw['capabilities'] as List).cast<String>()};
  Set<String> get features => {...(raw['features'] as List).cast<String>()};
  bool cap(String c) => capabilities.contains(c);
  bool feature(String f) => features.contains(f);

  Map<String, int> get limits => (raw['limits'] as Map).map((k, v) => MapEntry(k as String, (v as num).toInt()));
  Map<String, int> get usage => (raw['usage'] as Map).map((k, v) => MapEntry(k as String, (v as num).toInt()));

  List<ModuleInfo> get modules => [for (final m in (raw['modules'] as List)) ModuleInfo.fromJson((m as Map).cast())];
  ModuleInfo? module(String id) {
    for (final m in modules) {
      if (m.id == id) return m;
    }
    return null;
  }

  Map<String, String> get terminology => (raw['terminology'] as Map).map((k, v) => MapEntry(k as String, v as String));

  /// The business's own word for something ("Patient" instead of "Customer").
  String term(String key, String fallback) => terminology[key] ?? fallback;

  List<AttributeDef> get attributes => [for (final a in (raw['attributes'] as List)) AttributeDef.fromJson((a as Map).cast())];
  List<Map<String, dynamic>> get variantAxes => [for (final a in (raw['variant_axes'] as List)) (a as Map).cast<String, dynamic>()];
  List<UnitDef> get units => [for (final u in (raw['units'] as List)) UnitDef.fromJson((u as Map).cast())];

  // ------------------------------------------------------------------ settings
  String get currencySymbol => (_settings['currency_symbol'] as String?) ?? '৳';
  String get language => (_settings['language'] as String?) ?? 'bn';
  TaxMode get taxMode => ((_settings['tax'] as Map?)?['mode'] == 'exclusive') ? TaxMode.exclusive : TaxMode.inclusive;
  bool get cashRounding => (_settings['tax'] as Map?)?['cash_rounding'] == 'nearest_1';
  bool get allowNegativeStock => ((_settings['stock'] as Map?)?['allow_negative'] as bool?) ?? false;
  String get stockAllocation => ((_settings['stock'] as Map?)?['allocation'] as String?) ?? 'none';
  List<int> get expiryAlertDays => [...(((_settings['stock'] as Map?)?['expiry_alert_days'] as List?) ?? const [90, 30]).cast<num>().map((e) => e.toInt())];
  Map<String, dynamic> get pos => ((_settings['pos'] as Map?) ?? {}).cast();
  bool get requireCustomer => pos['require_customer'] == true;
  String get posLayout => (pos['layout'] as String?) ?? 'counter';
  Map<String, dynamic> get loyalty => ((_settings['loyalty'] as Map?) ?? {}).cast();
  bool get loyaltyOn => cap('loyalty') && loyalty['enabled'] == true;
  num get pointsPer100 => (loyalty['points_per_100'] as num?) ?? 0;
  Map<String, dynamic> get receipt => ((_settings['receipt'] as Map?) ?? {}).cast();
  Map<String, dynamic> get scale => ((_settings['scale'] as Map?) ?? {}).cast();
  int get depositPercentMin => ((_settings['deposit_percent_min'] as num?) ?? 0).toInt();
  List<String> get dashboardWidgets => [...((_settings['dashboard'] as List?) ?? const []).cast<String>()];

  List<PayMethod> get paymentMethods => [for (final m in ((_settings['payment_methods'] as List?) ?? const [])) PayMethod.fromJson((m as Map).cast())];
  List<PayMethod> get enabledPaymentMethods => paymentMethods.where((m) => m.enabled).toList();

  // -------------------------------------------------------------- subscription
  String get planKey => ((_sub['plan'] as Map)['key']) as String;
  String get planName => ((_sub['plan'] as Map)['name']) as String;
  String get subState => _sub['state'] as String;
  bool get lapsed => _sub['lapsed'] == true;
  DateTime get periodEnd => DateTime.parse(_sub['period_end'] as String);
  DateTime get validUntil => DateTime.parse(_sub['valid_until'] as String);
  int get daysLeft => ((_sub['days_left'] as num?) ?? 0).toInt();
  String? get notice => _sub['notice'] as String?;

  /// The till keeps selling offline until the date the server last told it the subscription is good for.
  bool get sellingAllowed => !lapsed && DateTime.now().isBefore(validUntil);

  // ---------------------------------------------------------------------- user
  String get userId => _user['id'] as String;
  String get userName => _user['name'] as String;
  String get userRole => _user['role'] as String;
  String get roleLabel => (_user['role_label'] as String?) ?? userRole;
  Set<String> get permissions => {...(_user['permissions'] as List).cast<String>()};
  bool can(String p) => permissions.contains(p);
  List<String>? get userBranchIds => (_user['branch_ids'] as List?)?.cast<String>();

  List<BranchInfo> get branches => [for (final b in (raw['branches'] as List)) BranchInfo.fromJson((b as Map).cast())];
  BranchInfo? get mainBranch {
    for (final b in branches) {
      if (b.isMain) return b;
    }
    return branches.isEmpty ? null : branches.first;
  }
}

class ModuleInfo {
  ModuleInfo(this.id, this.label, this.available, this.lockedReason);
  factory ModuleInfo.fromJson(Map<String, dynamic> j) => ModuleInfo(j['id'] as String, j['label'] as String, j['available'] == true, j['locked_reason'] as String?);
  final String id, label;
  final bool available;
  final String? lockedReason; // plan | capability | permission
}

class BranchInfo {
  BranchInfo(this.id, this.name, this.code, this.isMain);
  factory BranchInfo.fromJson(Map<String, dynamic> j) => BranchInfo(j['id'] as String, j['name'] as String, (j['code'] as String?) ?? '', j['is_main'] == true);
  final String id, name, code;
  final bool isMain;
}

class UnitDef {
  UnitDef(this.code, this.label, this.labelBn, this.allowFraction);
  factory UnitDef.fromJson(Map<String, dynamic> j) => UnitDef(j['code'] as String, j['label'] as String, (j['label_bn'] as String?) ?? '', j['allow_fraction'] == true);
  final String code, label, labelBn;
  final bool allowFraction;
}

class PayMethod {
  PayMethod(this.code, this.label, this.labelBn, this.kind, this.enabled);
  factory PayMethod.fromJson(Map<String, dynamic> j) => PayMethod(j['code'] as String, j['label'] as String, (j['label_bn'] as String?) ?? '', (j['kind'] as String?) ?? 'other', j['enabled'] != false);
  final String code, label, labelBn, kind;
  final bool enabled;

  IconData get icon => switch (kind) {
        'cash' => Icons.payments_rounded,
        'mobile' => Icons.phone_android_rounded,
        'card' => Icons.credit_card_rounded,
        'bank' => Icons.account_balance_rounded,
        _ => Icons.wallet_rounded,
      };

  bool get needsReference => kind == 'mobile' || kind == 'card' || kind == 'bank';

  Color get color => switch (code) {
        'bkash' => const Color(0xFFE2136E),
        'nagad' => const Color(0xFFF26A21),
        'rocket' => const Color(0xFF8C3494),
        'upay' => const Color(0xFF1B8C47),
        'card' => const Color(0xFF3B82F6),
        'cash' => const Color(0xFF1FA971),
        _ => const Color(0xFF64748B),
      };
}

class AttributeDef {
  AttributeDef({required this.key, required this.label, required this.labelBn, required this.type, required this.required, required this.options, this.unit, required this.group, required this.flags});
  factory AttributeDef.fromJson(Map<String, dynamic> j) => AttributeDef(
        key: j['key'] as String,
        label: j['label'] as String,
        labelBn: (j['label_bn'] as String?) ?? '',
        type: (j['type'] as String?) ?? 'text',
        required: j['required'] == true,
        options: [...((j['options'] as List?) ?? const []).cast<String>()],
        unit: j['unit'] as String?,
        group: (j['group'] as String?) ?? 'Details',
        flags: ((j['flags'] as Map?) ?? {}).cast<String, dynamic>(),
      );
  final String key, label, labelBn, type, group;
  final bool required;
  final List<String> options;
  final String? unit;
  final Map<String, dynamic> flags;
  bool get showInPos => flags['show_in_pos'] == true;
  bool get filterable => flags['filterable'] == true;
}

/// The signed-in user as returned by login.
int toPaisa(Object? v) => parsePaisa(v);
