import 'package:get_it/get_it.dart';
import 'features/expense/data/datasources/expense_local_datasource.dart';
import 'features/expense/data/repositories/expense_repository_impl.dart';
import 'features/expense/domain/repositories/expense_repository.dart';
import 'features/expense/domain/usecases/expense_usecases.dart';
import 'features/expense/presentation/bloc/expense_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ─── BLoC ────────────────────────────────────────────────────────────────
  // registerFactory: new instance every time (important for BLoC)
  sl.registerFactory(
    () => ExpenseBloc(
      getExpenses: sl(),
      addExpense: sl(),
      deleteExpense: sl(),
      updateExpense: sl(),
    ),
  );

  // ─── UseCases ────────────────────────────────────────────────────────────
  // registerLazySingleton: created on first use, same instance after
  sl.registerLazySingleton(() => GetExpensesUseCase(sl()));
  sl.registerLazySingleton(() => AddExpenseUseCase(sl()));
  sl.registerLazySingleton(() => DeleteExpenseUseCase(sl()));
  sl.registerLazySingleton(() => UpdateExpenseUseCase(sl()));

  // ─── Repository ──────────────────────────────────────────────────────────
  sl.registerLazySingleton<ExpenseRepository>(
    () => ExpenseRepositoryImpl(localDataSource: sl()),
  );

  // ─── Data Sources ────────────────────────────────────────────────────────
  sl.registerLazySingleton<ExpenseLocalDataSource>(
    () => ExpenseLocalDataSourceImpl(),
  );
}
