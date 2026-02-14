import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

part 'app_database.g.dart';

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // INCOME/EXPENSE/BOTH
  IntColumn get color => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()(); // INCOME/EXPENSE
  IntColumn get amountCents => integer()(); // Decimal-safe by storing cents
  DateTimeColumn get date => dateTime()();
  TextColumn get categoryId => text()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class FixedExpenses extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get amountCents => integer()();
  IntColumn get dayOfMonth => integer()();
  TextColumn get categoryId => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Installments extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get totalAmountCents => integer()();
  IntColumn get installmentsCount => integer()();
  IntColumn get installmentsPaid => integer().withDefault(const Constant(0))();
  DateTimeColumn get startDate => dateTime()();
  TextColumn get categoryId => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

QueryExecutor openConnection() {
  if (kIsWeb) {
    return driftDatabase(
      name: 'eightsteps_db',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }

  return driftDatabase(name: 'eightsteps_db');
}

@DriftDatabase(
  tables: [Categories, Transactions, FixedExpenses, Installments],
  daos: [
    CategoriesDao,
    TransactionsDao,
    FixedExpensesDao,
    InstallmentsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        beforeOpen: (details) async {
          if (details.wasCreated) {
            await _seedDefaultCategories();
          }
        },
      );

  Future<void> _seedDefaultCategories() async {
    final now = DateTime.now();
    const uuid = Uuid();

    final defaults = [
      CategoriesCompanion.insert(
        id: uuid.v4(),
        name: 'Comida',
        type: 'EXPENSE',
        createdAt: now,
      ),
      CategoriesCompanion.insert(
        id: uuid.v4(),
        name: 'Transporte',
        type: 'EXPENSE',
        createdAt: now,
      ),
      CategoriesCompanion.insert(
        id: uuid.v4(),
        name: 'Renta',
        type: 'EXPENSE',
        createdAt: now,
      ),
      CategoriesCompanion.insert(
        id: uuid.v4(),
        name: 'Servicios',
        type: 'EXPENSE',
        createdAt: now,
      ),
      CategoriesCompanion.insert(
        id: uuid.v4(),
        name: 'Sueldo',
        type: 'INCOME',
        createdAt: now,
      ),
      CategoriesCompanion.insert(
        id: uuid.v4(),
        name: 'Freelance',
        type: 'INCOME',
        createdAt: now,
      ),
    ];

    await batch((b) => b.insertAll(categories, defaults));
  }
}

class MonthlySummary {
  final int incomeCents;
  final int expenseCents;

  const MonthlySummary({required this.incomeCents, required this.expenseCents});

  int get balanceCents => incomeCents - expenseCents;
}

class CategoryExpense {
  final String category;
  final int cents;

  const CategoryExpense({required this.category, required this.cents});
}

@DriftAccessor(tables: [Categories])
class CategoriesDao extends DatabaseAccessor<AppDatabase>
    with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  Stream<List<Category>> watchAll() => select(categories).watch();

  Future<List<Category>> getAll() => select(categories).get();
}

@DriftAccessor(tables: [Transactions, Categories])
class TransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionsDaoMixin {
  TransactionsDao(super.db);

  Future<void> create(TransactionsCompanion tx) =>
      into(transactions).insert(tx);

  Future<void> updateById(String id, TransactionsCompanion tx) {
    return (update(transactions)..where((t) => t.id.equals(id))).write(tx);
  }

  Future<void> deleteById(String id) {
    return (delete(transactions)..where((t) => t.id.equals(id))).go();
  }

  Stream<List<Transaction>> watchByMonth(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    return (select(transactions)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(start) &
              t.date.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  Future<MonthlySummary> getMonthlySummary(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);

    final rows = await customSelect(
      '''
      SELECT
        COALESCE(SUM(CASE WHEN type = 'INCOME' THEN amount_cents ELSE 0 END), 0) AS income,
        COALESCE(SUM(CASE WHEN type = 'EXPENSE' THEN amount_cents ELSE 0 END), 0) AS expense
      FROM transactions
      WHERE date >= ? AND date < ?
      ''',
      variables: [Variable.withDateTime(start), Variable.withDateTime(end)],
      readsFrom: {transactions},
    ).getSingle();

    return MonthlySummary(
      incomeCents: rows.read<int>('income'),
      expenseCents: rows.read<int>('expense'),
    );
  }

  Future<List<CategoryExpense>> getMonthlyExpensesByCategory(
      DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);

    final rows = await customSelect(
      '''
      SELECT c.name AS category, COALESCE(SUM(t.amount_cents), 0) AS cents
      FROM transactions t
      JOIN categories c ON c.id = t.category_id
      WHERE t.type = 'EXPENSE' AND t.date >= ? AND t.date < ?
      GROUP BY c.name
      ORDER BY cents DESC
      ''',
      variables: [Variable.withDateTime(start), Variable.withDateTime(end)],
      readsFrom: {transactions, categories},
    ).get();

    return rows
        .map(
          (r) => CategoryExpense(
            category: r.read<String>('category'),
            cents: r.read<int>('cents'),
          ),
        )
        .toList();
  }
}

@DriftAccessor(tables: [FixedExpenses])
class FixedExpensesDao extends DatabaseAccessor<AppDatabase>
    with _$FixedExpensesDaoMixin {
  FixedExpensesDao(super.db);

  Stream<List<FixedExpense>> watchAll() {
    return (select(fixedExpenses)
          ..orderBy([(f) => OrderingTerm.asc(f.dayOfMonth)]))
        .watch();
  }

  Future<void> create(FixedExpensesCompanion item) =>
      into(fixedExpenses).insert(item);

  Future<void> updateById(String id, FixedExpensesCompanion item) {
    return (update(fixedExpenses)..where((f) => f.id.equals(id))).write(item);
  }

  Future<void> deleteById(String id) {
    return (delete(fixedExpenses)..where((f) => f.id.equals(id))).go();
  }
}

@DriftAccessor(tables: [Installments])
class InstallmentsDao extends DatabaseAccessor<AppDatabase>
    with _$InstallmentsDaoMixin {
  InstallmentsDao(super.db);

  Stream<List<Installment>> watchAll() {
    return (select(installments)
          ..orderBy([(i) => OrderingTerm.desc(i.createdAt)]))
        .watch();
  }

  Future<void> create(InstallmentsCompanion item) =>
      into(installments).insert(item);

  Future<void> updateById(String id, InstallmentsCompanion item) {
    return (update(installments)..where((i) => i.id.equals(id))).write(item);
  }

  Future<void> deleteById(String id) {
    return (delete(installments)..where((i) => i.id.equals(id))).go();
  }
}
