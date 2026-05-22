import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/expense.dart';
import '../../domain/usecases/expense_usecases.dart';

// ─── EVENTS ───────────────────────────────────────────────────────────────────

abstract class ExpenseEvent extends Equatable {
  const ExpenseEvent();
}

class LoadExpenses extends ExpenseEvent {
  const LoadExpenses();
  @override
  List<Object?> get props => [];
}

class AddExpenseEvent extends ExpenseEvent {
  final Expense expense;
  const AddExpenseEvent(this.expense);
  @override
  List<Object?> get props => [expense];
}

class DeleteExpenseEvent extends ExpenseEvent {
  final String id;
  const DeleteExpenseEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class UpdateExpenseEvent extends ExpenseEvent {
  final Expense expense;
  const UpdateExpenseEvent(this.expense);
  @override
  List<Object?> get props => [expense];
}

// ─── STATES ───────────────────────────────────────────────────────────────────

abstract class ExpenseState extends Equatable {
  const ExpenseState();
}

class ExpenseInitial extends ExpenseState {
  @override
  List<Object?> get props => [];
}

class ExpenseLoading extends ExpenseState {
  @override
  List<Object?> get props => [];
}

class ExpensesLoaded extends ExpenseState {
  final List<Expense> expenses;
  const ExpensesLoaded(this.expenses);
  @override
  List<Object?> get props => [expenses];
}

class ExpenseError extends ExpenseState {
  final String message;
  const ExpenseError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── BLOC ─────────────────────────────────────────────────────────────────────

class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  final GetExpensesUseCase getExpenses;
  final AddExpenseUseCase addExpense;
  final DeleteExpenseUseCase deleteExpense;
  final UpdateExpenseUseCase updateExpense;

  ExpenseBloc({
    required this.getExpenses,
    required this.addExpense,
    required this.deleteExpense,
    required this.updateExpense,
  }) : super(ExpenseInitial()) {
    on<LoadExpenses>(_onLoadExpenses);
    on<AddExpenseEvent>(_onAddExpense);
    on<DeleteExpenseEvent>(_onDeleteExpense);
    on<UpdateExpenseEvent>(_onUpdateExpense);
  }

  Future<void> _onLoadExpenses(
    LoadExpenses event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(ExpenseLoading());
    final result = await getExpenses(const NoParams());
    result.fold(
      (failure) => emit(const ExpenseError('Failed to load expenses')),
      (expenses) => emit(ExpensesLoaded(expenses)),
    );
  }

  Future<void> _onAddExpense(
    AddExpenseEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    // Save previous state for rollback
    final previousState = state;

    // OPTIMISTIC UPDATE: show in UI immediately
    if (state is ExpensesLoaded) {
      final current = (state as ExpensesLoaded).expenses;
      emit(ExpensesLoaded([event.expense, ...current]));
    }

    final result = await addExpense(event.expense);

    result.fold(
      (failure) {
        // ROLLBACK: revert to previous state
        emit(previousState);
        emit(const ExpenseError('Failed to save expense. Please try again.'));
      },
      (expense) {
        // Replace temp expense with persisted one (in case ID changed)
        if (state is ExpensesLoaded) {
          final expenses = (state as ExpensesLoaded).expenses;
          final updated = expenses.map((e) {
            return e.id == event.expense.id ? expense : e;
          }).toList();
          emit(ExpensesLoaded(updated));
        }
      },
    );
  }

  Future<void> _onDeleteExpense(
    DeleteExpenseEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    final previousState = state;

    // OPTIMISTIC: remove from UI immediately
    if (state is ExpensesLoaded) {
      final current = (state as ExpensesLoaded).expenses;
      emit(ExpensesLoaded(current.where((e) => e.id != event.id).toList()));
    }

    final result = await deleteExpense(event.id);

    result.fold(
      (failure) {
        emit(previousState); // Rollback
        emit(const ExpenseError('Failed to delete expense'));
      },
      (_) {}, // Success — optimistic state is already correct
    );
  }

  Future<void> _onUpdateExpense(
    UpdateExpenseEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    final previousState = state;

    if (state is ExpensesLoaded) {
      final current = (state as ExpensesLoaded).expenses;
      emit(ExpensesLoaded(
        current.map((e) => e.id == event.expense.id ? event.expense : e).toList(),
      ));
    }

    final result = await updateExpense(event.expense);

    result.fold(
      (failure) {
        emit(previousState);
        emit(const ExpenseError('Failed to update expense'));
      },
      (_) {},
    );
  }
}
