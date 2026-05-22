import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class GetExpensesUseCase implements UseCase<List<Expense>, NoParams> {
  final ExpenseRepository repository;
  GetExpensesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Expense>>> call(NoParams params) {
    return repository.getExpenses();
  }
}

class AddExpenseUseCase implements UseCase<Expense, Expense> {
  final ExpenseRepository repository;
  AddExpenseUseCase(this.repository);

  @override
  Future<Either<Failure, Expense>> call(Expense params) {
    return repository.addExpense(params);
  }
}

class DeleteExpenseUseCase implements UseCase<String, String> {
  final ExpenseRepository repository;
  DeleteExpenseUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(String id) {
    return repository.deleteExpense(id);
  }
}

class UpdateExpenseUseCase implements UseCase<Expense, Expense> {
  final ExpenseRepository repository;
  UpdateExpenseUseCase(this.repository);

  @override
  Future<Either<Failure, Expense>> call(Expense params) {
    return repository.updateExpense(params);
  }
}
