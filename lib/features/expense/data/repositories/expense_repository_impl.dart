import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_local_datasource.dart';
import '../models/expense_model.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseLocalDataSource localDataSource;

  ExpenseRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<Expense>>> getExpenses() async {
    try {
      // Offline-first: always load from local immediately
      final local = await localDataSource.getExpenses();
      return Right(local.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Expense>> addExpense(Expense expense) async {
    try {
      final model = ExpenseModel.fromEntity(
        // Assign ID if not already set
        expense.id.isEmpty
            ? expense.copyWith(id: const Uuid().v4())
            : expense,
        isSynced: false,
      );
      await localDataSource.saveExpense(model);
      return Right(model.toEntity());
    } catch (e) {
      return  Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Expense>> updateExpense(Expense expense) async {
    try {
      final model = ExpenseModel.fromEntity(expense, isSynced: false);
      await localDataSource.saveExpense(model);
      return Right(expense);
    } catch (e) {
      return  Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, String>> deleteExpense(String id) async {
    try {
      await localDataSource.deleteExpense(id);
      return Right(id);
    } catch (e) {
      return  Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, List<Expense>>> getExpensesByCategory(
      String category) async {
    try {
      final all = await localDataSource.getExpenses();
      final filtered = all
          .where((m) => m.category == category)
          .map((m) => m.toEntity())
          .toList();
      return Right(filtered);
    } catch (e) {
      return  Left(CacheFailure());
    }
  }
}
