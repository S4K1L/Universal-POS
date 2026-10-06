import '../../core/money/money.dart';
import '../../core/money/pricing.dart';
import '../repos/catalogue_repo.dart';

class CartLine {
  const CartLine({
    required this.key,
    required this.variantId,
    required this.productId,
    required this.name,
    this.nameLocal = '',
    this.variantLabel = '',
    this.sku = '',
    required this.baseUnit,
    this.allowFraction = false,
    required this.unit,
    this.unitFactorMilli = 1000,
    required this.qtyMilli,
    required this.baseListPriceP,
    this.priceOverrideP,
    this.discountP = 0,
    this.taxRateBp = 0,
    this.note = '',
    this.altUnits = const [],
    this.warrantyMonths = 0,
    this.stocked = true,
    this.availableBaseMilli = 0,
  });

  final String key, variantId, productId, name, nameLocal, variantLabel, sku, baseUnit, unit, note;

  /// The name to show: the Bangla one when the app is in Bangla and the product has one.
  String shownName(bool bangla) => bangla && nameLocal.isNotEmpty ? nameLocal : name;
  final bool allowFraction, stocked;
  final int unitFactorMilli; // base units per selling unit, ×1000
  final int qtyMilli; // in selling units
  final int baseListPriceP; // catalogue price per BASE unit
  final int? priceOverrideP; // per selling unit, set by a cashier allowed to override
  final int discountP;
  final int taxRateBp;
  final List<AltUnit> altUnits;
  final int warrantyMonths;
  final int availableBaseMilli;

  int get listPriceP => roundDiv(baseListPriceP * unitFactorMilli, 1000);
  int get unitPriceP => priceOverrideP ?? listPriceP;
  int get baseQtyMilli => qtyMilli * unitFactorMilli ~/ 1000;
  bool get overridden => priceOverrideP != null && priceOverrideP != listPriceP;
  LineInput get input => LineInput(unitPrice: unitPriceP, qtyMilli: qtyMilli, discount: discountP, taxRateBp: taxRateBp);

  /// How many selling units the shelf can still cover (milli).
  int get maxQtyMilli => unitFactorMilli == 0 ? 0 : availableBaseMilli * 1000 ~/ unitFactorMilli;

  CartLine copyWith({String? unit, int? unitFactorMilli, int? qtyMilli, int? priceOverrideP, bool clearOverride = false, int? discountP, String? note, int? availableBaseMilli}) => CartLine(
        key: key,
        variantId: variantId,
        productId: productId,
        name: name,
        nameLocal: nameLocal,
        variantLabel: variantLabel,
        sku: sku,
        baseUnit: baseUnit,
        allowFraction: allowFraction,
        unit: unit ?? this.unit,
        unitFactorMilli: unitFactorMilli ?? this.unitFactorMilli,
        qtyMilli: qtyMilli ?? this.qtyMilli,
        baseListPriceP: baseListPriceP,
        priceOverrideP: clearOverride ? null : (priceOverrideP ?? this.priceOverrideP),
        discountP: discountP ?? this.discountP,
        taxRateBp: taxRateBp,
        note: note ?? this.note,
        altUnits: altUnits,
        warrantyMonths: warrantyMonths,
        stocked: stocked,
        availableBaseMilli: availableBaseMilli ?? this.availableBaseMilli,
      );

  Map<String, dynamic> toJson() => {
        'key': key,
        'variantId': variantId,
        'productId': productId,
        'name': name,
        'nameLocal': nameLocal,
        'variantLabel': variantLabel,
        'sku': sku,
        'baseUnit': baseUnit,
        'allowFraction': allowFraction,
        'unit': unit,
        'unitFactorMilli': unitFactorMilli,
        'qtyMilli': qtyMilli,
        'baseListPriceP': baseListPriceP,
        'priceOverrideP': priceOverrideP,
        'discountP': discountP,
        'taxRateBp': taxRateBp,
        'note': note,
        'alt': [for (final a in altUnits) {'unit': a.unit, 'f': a.factorMilli}],
        'warranty': warrantyMonths,
        'stocked': stocked,
        'avail': availableBaseMilli,
      };

  factory CartLine.fromJson(Map<String, dynamic> j) => CartLine(
        key: j['key'] as String,
        variantId: j['variantId'] as String,
        productId: j['productId'] as String,
        name: j['name'] as String,
        nameLocal: (j['nameLocal'] as String?) ?? '',
        variantLabel: (j['variantLabel'] as String?) ?? '',
        sku: (j['sku'] as String?) ?? '',
        baseUnit: j['baseUnit'] as String,
        allowFraction: j['allowFraction'] == true,
        unit: j['unit'] as String,
        unitFactorMilli: j['unitFactorMilli'] as int,
        qtyMilli: j['qtyMilli'] as int,
        baseListPriceP: j['baseListPriceP'] as int,
        priceOverrideP: j['priceOverrideP'] as int?,
        discountP: (j['discountP'] as int?) ?? 0,
        taxRateBp: (j['taxRateBp'] as int?) ?? 0,
        note: (j['note'] as String?) ?? '',
        altUnits: [for (final a in (j['alt'] as List? ?? const [])) AltUnit((a as Map)['unit'] as String, a['f'] as int)],
        warrantyMonths: (j['warranty'] as int?) ?? 0,
        stocked: j['stocked'] != false,
        availableBaseMilli: (j['avail'] as int?) ?? 0,
      );
}

class CartCustomer {
  const CartCustomer(this.id, this.name, {this.balanceP = 0, this.creditLimitP = 0, this.phone = ''});
  final String id, name, phone;
  final int balanceP, creditLimitP;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'balance': balanceP, 'limit': creditLimitP, 'phone': phone};
  factory CartCustomer.fromJson(Map<String, dynamic> j) => CartCustomer(j['id'] as String, j['name'] as String, balanceP: (j['balance'] as int?) ?? 0, creditLimitP: (j['limit'] as int?) ?? 0, phone: (j['phone'] as String?) ?? '');
}

class CartState {
  const CartState({this.lines = const [], this.billDiscountP = 0, this.customer, this.note = '', this.heldId});
  final List<CartLine> lines;
  final int billDiscountP;
  final CartCustomer? customer;
  final String note;
  final String? heldId;

  bool get isEmpty => lines.isEmpty;
  int get lineCount => lines.length;

  CartState copyWith({List<CartLine>? lines, int? billDiscountP, CartCustomer? customer, bool clearCustomer = false, String? note, String? heldId, bool clearHeld = false}) => CartState(
        lines: lines ?? this.lines,
        billDiscountP: billDiscountP ?? this.billDiscountP,
        customer: clearCustomer ? null : (customer ?? this.customer),
        note: note ?? this.note,
        heldId: clearHeld ? null : (heldId ?? this.heldId),
      );

  Map<String, dynamic> toJson() => {
        'lines': [for (final l in lines) l.toJson()],
        'billDiscountP': billDiscountP,
        'customer': customer?.toJson(),
        'note': note,
      };

  factory CartState.fromJson(Map<String, dynamic> j) => CartState(
        lines: [for (final l in (j['lines'] as List)) CartLine.fromJson((l as Map).cast())],
        billDiscountP: (j['billDiscountP'] as int?) ?? 0,
        customer: j['customer'] == null ? null : CartCustomer.fromJson((j['customer'] as Map).cast()),
        note: (j['note'] as String?) ?? '',
      );
}
