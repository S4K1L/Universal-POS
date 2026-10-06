import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

// ---------------------------------------------------------------------------------------------------
// The device's own copy of the business. Money is whole paisa and quantities whole milli-units, so
// nothing that gets added up is ever a floating-point number.
// ---------------------------------------------------------------------------------------------------

/// Small key/value store: sync cursor, cached context, the open shift, device identity…
class Kv extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}

class LCategories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get parentId => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  @override
  Set<Column> get primaryKey => {id};
}

class LTaxClasses extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get rateBp => integer().withDefault(const Constant(0))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

class LProducts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get nameLocal => text().withDefault(const Constant(''))();
  TextColumn get categoryId => text().nullable()();
  TextColumn get type => text().withDefault(const Constant('stockable'))();
  TextColumn get baseUnit => text().withDefault(const Constant('pc'))();
  TextColumn get altUnits => text().withDefault(const Constant('[]'))(); // [{"unit","factor"}]
  BoolColumn get allowFraction => boolean().withDefault(const Constant(false))();
  TextColumn get tracking => text().withDefault(const Constant('none'))();
  BoolColumn get trackExpiry => boolean().withDefault(const Constant(false))();
  TextColumn get taxClassId => text().nullable()();
  TextColumn get attributes => text().withDefault(const Constant('{}'))();
  TextColumn get imageUrl => text().withDefault(const Constant(''))();
  IntColumn get reorderMilli => integer().withDefault(const Constant(0))();
  IntColumn get warrantyMonths => integer().withDefault(const Constant(0))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  TextColumn get search => text().withDefault(const Constant(''))(); // lower-cased name + local name + brand + skus + barcodes
  @override
  Set<Column> get primaryKey => {id};
}

class LVariants extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text()();
  TextColumn get sku => text().withDefault(const Constant(''))();
  TextColumn get label => text().withDefault(const Constant(''))();
  TextColumn get optionValues => text().withDefault(const Constant('{}'))();
  IntColumn get priceP => integer()();
  IntColumn get mrpP => integer().withDefault(const Constant(0))();
  IntColumn get costP => integer().nullable()(); // null on tills whose user may not see cost
  TextColumn get plu => text().nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  @override
  Set<Column> get primaryKey => {id};
}

class LBarcodes extends Table {
  TextColumn get code => text()();
  TextColumn get variantId => text()();
  TextColumn get productId => text()();
  TextColumn get unit => text().nullable()();
  IntColumn get qtyPerScanMilli => integer().withDefault(const Constant(1000))();
  @override
  Set<Column> get primaryKey => {code};
}

class LCustomers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().withDefault(const Constant(''))();
  TextColumn get address => text().withDefault(const Constant(''))();
  IntColumn get creditLimitP => integer().withDefault(const Constant(0))();
  IntColumn get balanceP => integer().withDefault(const Constant(0))(); // as of the last pull
  IntColumn get points => integer().withDefault(const Constant(0))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  @override
  Set<Column> get primaryKey => {id};
}

/// What this branch held at the last pull. What is *available* also subtracts sales still waiting to sync.
class LStock extends Table {
  TextColumn get variantId => text()();
  IntColumn get onHandMilli => integer()();
  @override
  Set<Column> get primaryKey => {variantId};
}

class LSales extends Table {
  TextColumn get id => text()();
  TextColumn get invoiceNo => text()();
  DateTimeColumn get soldAt => dateTime()();
  TextColumn get status => text().withDefault(const Constant('completed'))();
  TextColumn get customerId => text().nullable()();
  TextColumn get customerName => text().withDefault(const Constant('Walk-in'))();
  IntColumn get subtotalP => integer()();
  IntColumn get discountP => integer().withDefault(const Constant(0))();
  IntColumn get taxP => integer().withDefault(const Constant(0))();
  IntColumn get roundingP => integer().withDefault(const Constant(0))();
  IntColumn get totalP => integer()();
  IntColumn get paidP => integer()();
  TextColumn get taxMode => text().withDefault(const Constant('inclusive'))();
  BoolColumn get cashRounding => boolean().withDefault(const Constant(false))();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get cashierId => text()();
  TextColumn get cashierName => text().withDefault(const Constant(''))();
  TextColumn get branchId => text()();
  TextColumn get shiftId => text().nullable()();
  IntColumn get pointsEarned => integer().withDefault(const Constant(0))();
  /// pending (waiting to sync) | synced | failed (the server refused it — see Sync Center)
  TextColumn get syncState => text().withDefault(const Constant('pending'))();
  TextColumn get flags => text().withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

class LSaleLines extends Table {
  TextColumn get id => text()();
  TextColumn get saleId => text()();
  IntColumn get position => integer().withDefault(const Constant(0))();
  TextColumn get variantId => text()();
  TextColumn get productId => text()();
  TextColumn get productName => text()();
  TextColumn get variantLabel => text().withDefault(const Constant(''))();
  TextColumn get sku => text().withDefault(const Constant(''))();
  TextColumn get unit => text().withDefault(const Constant('pc'))();
  IntColumn get unitFactorMilli => integer().withDefault(const Constant(1000))();
  IntColumn get qtyMilli => integer()();
  IntColumn get unitPriceP => integer()();
  IntColumn get discountP => integer().withDefault(const Constant(0))();
  IntColumn get taxRateBp => integer().withDefault(const Constant(0))();
  IntColumn get taxAmountP => integer().withDefault(const Constant(0))();
  IntColumn get netP => integer()();
  IntColumn get chargedP => integer()();
  IntColumn get returnedQtyMilli => integer().withDefault(const Constant(0))();
  IntColumn get warrantyMonths => integer().withDefault(const Constant(0))();
  TextColumn get note => text().withDefault(const Constant(''))();
  @override
  Set<Column> get primaryKey => {id};
}

class LSalePayments extends Table {
  TextColumn get id => text()();
  TextColumn get saleId => text()();
  TextColumn get method => text()();
  IntColumn get amountP => integer()();
  TextColumn get reference => text().withDefault(const Constant(''))();
  TextColumn get kind => text().withDefault(const Constant('sale'))(); // sale | due | return
  DateTimeColumn get paidAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

class LExpenses extends Table {
  TextColumn get id => text()();
  TextColumn get branchId => text()();
  TextColumn get category => text()();
  IntColumn get amountP => integer()();
  TextColumn get method => text().withDefault(const Constant('cash'))();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get spentAt => dateTime()();
  TextColumn get syncState => text().withDefault(const Constant('pending'))();
  @override
  Set<Column> get primaryKey => {id};
}

/// Everything the device has done that the server has not yet confirmed. Events are replayed in order and
/// carry a client-generated id, so a retry after a dropped connection can never double-book anything.
class Outbox extends Table {
  IntColumn get seq => integer().autoIncrement()();
  TextColumn get id => text().unique()();
  TextColumn get type => text()();
  TextColumn get payload => text()();
  TextColumn get actorId => text().nullable()();
  DateTimeColumn get occurredAt => dateTime()();
  /// pending | sending | failed | done
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get errorCode => text().nullable()();
  TextColumn get lastError => text().nullable()();
  TextColumn get summary => text().withDefault(const Constant(''))(); // human label for the Sync Center
  DateTimeColumn get createdAt => dateTime()();
}

class HeldCarts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get json => text()();
  DateTimeColumn get createdAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Kv, LCategories, LTaxClasses, LProducts, LVariants, LBarcodes, LCustomers, LStock, LSales, LSaleLines, LSalePayments, LExpenses, Outbox, HeldCarts])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ??
            driftDatabase(
              name: 'universal_pos',
              web: DriftWebOptions(sqlite3Wasm: Uri.parse('sqlite3.wasm'), driftWorker: Uri.parse('drift_worker.js')),
            ));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = OFF');
          await customStatement('CREATE INDEX IF NOT EXISTS ix_products_search ON l_products(search)');
          await customStatement('CREATE INDEX IF NOT EXISTS ix_variants_product ON l_variants(product_id)');
          await customStatement('CREATE INDEX IF NOT EXISTS ix_lines_sale ON l_sale_lines(sale_id)');
          await customStatement('CREATE INDEX IF NOT EXISTS ix_payments_sale ON l_sale_payments(sale_id)');
          await customStatement('CREATE INDEX IF NOT EXISTS ix_sales_time ON l_sales(sold_at)');
          await customStatement('CREATE INDEX IF NOT EXISTS ix_outbox_status ON outbox(status, seq)');
        },
      );

  // ----------------------------------------------------------------------------- key/value

  Future<String?> kvGet(String key) async =>
      (await (select(kv)..where((t) => t.key.equals(key))).getSingleOrNull())?.value;

  Future<void> kvSet(String key, String value) => into(kv).insertOnConflictUpdate(KvData(key: key, value: value));

  Future<void> kvDelete(String key) => (delete(kv)..where((t) => t.key.equals(key))).go();

  /// Forget a business's data — used when a different business signs in on this device.
  Future<void> wipeBusinessData() async {
    await transaction(() async {
      for (final t in allTables) {
        await delete(t).go();
      }
    });
  }
}
