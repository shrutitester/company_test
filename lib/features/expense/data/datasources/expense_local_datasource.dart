import 'package:hive/hive.dart';
import '../../../../core/error/failure.dart';
import '../models/expense_model.dart';

abstract class ExpenseLocalDataSource {
  Future<List<ExpenseModel>> getExpenses();
  Future<void> saveExpense(ExpenseModel model);
  Future<void> deleteExpense(String id);
  Future<List<ExpenseModel>> getUnsyncedExpenses();
  Future<void> cacheExpenses(List<ExpenseModel> models);
}

class ExpenseLocalDataSourceImpl implements ExpenseLocalDataSource {
  static const String _boxName = 'expenses';

  Future<Box<ExpenseModel>> get _box async =>
      await Hive.openBox<ExpenseModel>(_boxName);

  @override
  Future<List<ExpenseModel>> getExpenses() async {
    final box = await _box;
    // Return sorted by date descending
    final values = box.values.toList();
    values.sort((a, b) => b.date.compareTo(a.date));
    return values;
  }

  @override
  Future<void> saveExpense(ExpenseModel model) async {
    final box = await _box;
    await box.put(model.id, model);
  }

  @override
  Future<void> deleteExpense(String id) async {
    final box = await _box;
    await box.delete(id);
  }

  @override
  Future<List<ExpenseModel>> getUnsyncedExpenses() async {
    final box = await _box;
    return box.values.where((e) => !e.isSynced).toList();
  }

  @override
  Future<void> cacheExpenses(List<ExpenseModel> models) async {
    final box = await _box;
    final mapped = {for (final m in models) m.id: m};
    await box.putAll(mapped);
  }
}
