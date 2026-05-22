import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/expense.dart';

/// Abstract repository contract — defined in domain, implemented in data.
abstract class ExpenseRepository {
  Future<Either<Failure, List<Expense>>> getExpenses();
  Future<Either<Failure, Expense>> addExpense(Expense expense);
  Future<Either<Failure, Expense>> updateExpense(Expense expense);
  Future<Either<Failure, String>> deleteExpense(String id);
  Future<Either<Failure, List<Expense>>> getExpensesByCategory(String category);
}
