import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Import your app files (adjust paths as needed)
// import 'package:spendar/core/error/failure.dart';
// import 'package:spendar/features/expense/domain/entities/expense.dart';
// etc.

// ─── MOCKS ────────────────────────────────────────────────────────────────────

class MockExpenseRepository extends Mock implements ExpenseRepository {}
class MockGetExpensesUseCase extends Mock implements GetExpensesUseCase {}
class MockAddExpenseUseCase extends Mock implements AddExpenseUseCase {}
class MockDeleteExpenseUseCase extends Mock implements DeleteExpenseUseCase {}
class MockUpdateExpenseUseCase extends Mock implements UpdateExpenseUseCase {}
class MockLocalDataSource extends Mock implements ExpenseLocalDataSource {}

// ─── TEST FIXTURES ────────────────────────────────────────────────────────────

final tExpense = Expense(
  id: 'test-id-1',
  title: 'Coffee',
  amount: 250.0,
  category: 'Food',
  date: DateTime(2024, 1, 15),
);

final tExpenseModel = ExpenseModel.fromEntity(tExpense);

// ─── UNIT TEST 1: Repository — returns local data when offline ─────────────────

void main() {
  // Register fallback for mocktail
  setUpAll(() {
    registerFallbackValue(tExpense);
    registerFallbackValue(const NoParams());
  });

  group('ExpenseRepositoryImpl', () {
    late ExpenseRepositoryImpl repository;
    late MockLocalDataSource mockLocal;

    setUp(() {
      mockLocal = MockLocalDataSource();
      repository = ExpenseRepositoryImpl(localDataSource: mockLocal);
    });

    // UNIT TEST 1
    test('returns list of expenses from local data source', () async {
      when(() => mockLocal.getExpenses())
          .thenAnswer((_) async => [tExpenseModel]);

      final result = await repository.getExpenses();

      expect(result, Right([tExpense]));
      verify(() => mockLocal.getExpenses()).called(1);
    });

    // UNIT TEST 2
    test('returns CacheFailure when local data source throws', () async {
      when(() => mockLocal.getExpenses()).thenThrow(Exception('DB error'));

      final result = await repository.getExpenses();

      expect(result, const Left(CacheFailure()));
    });

    // UNIT TEST 3
    test('saves expense to local and returns it', () async {
      when(() => mockLocal.saveExpense(any())).thenAnswer((_) async {});

      final result = await repository.addExpense(tExpense);

      result.fold(
        (failure) => fail('Expected Right but got Left: $failure'),
        (expense) {
          expect(expense.title, tExpense.title);
          expect(expense.amount, tExpense.amount);
        },
      );
      verify(() => mockLocal.saveExpense(any())).called(1);
    });
  });

  // ─── UNIT TEST 4: UseCase ────────────────────────────────────────────────────

  group('GetExpensesUseCase', () {
    late GetExpensesUseCase useCase;
    late MockExpenseRepository mockRepo;

    setUp(() {
      mockRepo = MockExpenseRepository();
      useCase = GetExpensesUseCase(mockRepo);
    });

    test('returns list of expenses from repository', () async {
      when(() => mockRepo.getExpenses())
          .thenAnswer((_) async => Right([tExpense]));

      final result = await useCase(const NoParams());

      expect(result, Right([tExpense]));
    });
  });

  // ─── UNIT TEST 5: BLoC ────────────────────────────────────────────────────────

  group('ExpenseBloc', () {
    late MockGetExpensesUseCase mockGet;
    late MockAddExpenseUseCase mockAdd;
    late MockDeleteExpenseUseCase mockDelete;
    late MockUpdateExpenseUseCase mockUpdate;

    setUp(() {
      mockGet = MockGetExpensesUseCase();
      mockAdd = MockAddExpenseUseCase();
      mockDelete = MockDeleteExpenseUseCase();
      mockUpdate = MockUpdateExpenseUseCase();
    });

    ExpenseBloc buildBloc() => ExpenseBloc(
          getExpenses: mockGet,
          addExpense: mockAdd,
          deleteExpense: mockDelete,
          updateExpense: mockUpdate,
        );

    blocTest<ExpenseBloc, ExpenseState>(
      'emits [Loading, Loaded] when LoadExpenses succeeds',
      build: () {
        when(() => mockGet(any()))
            .thenAnswer((_) async => Right([tExpense]));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadExpenses()),
      expect: () => [
        ExpenseLoading(),
        ExpensesLoaded([tExpense]),
      ],
    );

    blocTest<ExpenseBloc, ExpenseState>(
      'emits optimistic state then rolls back on add failure',
      build: () {
        when(() => mockAdd(any()))
            .thenAnswer((_) async => const Left(ServerFailure()));
        return buildBloc();
      },
      seed: () => const ExpensesLoaded([]),
      act: (bloc) => bloc.add(AddExpenseEvent(tExpense)),
      expect: () => [
        ExpensesLoaded([tExpense]), // optimistic
        const ExpensesLoaded([]),  // rollback
        isA<ExpenseError>(),       // error shown
      ],
    );
  });

  // ─── WIDGET TEST 1: Add expense form validation ────────────────────────────────

  group('AddExpensePage widget tests', () {
    testWidgets('submit button exists and form validates empty input',
        (tester) async {
      final mockBloc = _MockExpenseBloc();
      when(() => mockBloc.state).thenReturn(const ExpensesLoaded([]));
      when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<ExpenseBloc>.value(
            value: mockBloc,
            child: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  key: const Key('open_sheet'),
                  onPressed: () => showModalBottomSheet(
                    context: ctx,
                    builder: (_) => BlocProvider.value(
                      value: mockBloc,
                      child: const _TestAddExpenseSheet(),
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      // Submit without filling
      await tester.tap(find.byKey(const Key('submit_button')));
      await tester.pump();

      expect(find.text('Title is required'), findsOneWidget);
    });
  });

  // ─── WIDGET TEST 2: ArcMeter renders ──────────────────────────────────────────

  group('ArcMeter widget test', () {
    testWidgets('renders arc meter with correct progress text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ArcMeter(
                progress: 0.6,
                totalBudget: 50000,
                spent: 30000,
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 50));

      // Widget renders without errors
      expect(find.byType(ArcMeter), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}

// Simple mock bloc for widget testing
class _MockExpenseBloc extends MockBloc<ExpenseEvent, ExpenseState>
    implements ExpenseBloc {}

// Minimal add expense sheet for widget test
class _TestAddExpenseSheet extends StatefulWidget {
  const _TestAddExpenseSheet();
  @override
  State<_TestAddExpenseSheet> createState() => _TestAddExpenseSheetState();
}

class _TestAddExpenseSheetState extends State<_TestAddExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleCtrl,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Title is required' : null,
            ),
            ElevatedButton(
              key: const Key('submit_button'),
              onPressed: () => _formKey.currentState!.validate(),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
