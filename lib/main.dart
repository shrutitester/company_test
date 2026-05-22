import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/expense/data/models/expense_model.dart';
import 'features/expense/presentation/bloc/expense_bloc.dart';
import 'features/expense/presentation/pages/expense_list_page.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(ExpenseModelAdapter());

  // Initialize dependency injection
  await di.init();

  runApp(const SpendArcApp());
}

class SpendArcApp extends StatelessWidget {
  const SpendArcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpendArc',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: BlocProvider(
        create: (_) => di.sl<ExpenseBloc>(),
        child: const ExpenseListPage(),
      ),
    );
  }
}
