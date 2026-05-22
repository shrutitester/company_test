import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spendar/features/expense/domain/entities/expense.dart' as expense_entity;
import '../bloc/expense_bloc.dart';
import '../widgets/arc_meter.dart';
import '../widgets/line_chart.dart';
import '../widgets/particle_burst.dart';

class ExpenseListPage extends StatefulWidget {
  const ExpenseListPage({super.key});

  @override
  State<ExpenseListPage> createState() => _ExpenseListPageState();
}

class _ExpenseListPageState extends State<ExpenseListPage> {
  bool _showParticles = false;

  @override
  void initState() {
    super.initState();
    context.read<ExpenseBloc>().add(const LoadExpenses());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('SpendArc'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddExpenseSheet(context),
          ),
        ],
      ),
      body: BlocConsumer<ExpenseBloc, ExpenseState>(
        listener: (context, state) {
          if (state is ExpenseError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ExpenseLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ExpensesLoaded) {
            final expenses = state.expenses;
            final total = expenses.fold(0.0, (s, e) => s + e.amount);
            const budget = 50000.0;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildDashboard(total, budget, expenses
                      .map((e) => e.amount)
                      .take(7)
                      .toList()
                      .reversed
                      .toList()),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _buildExpenseItem(context, expenses[i]),
                    childCount: expenses.length,
                  ),
                ),
              ],
            );
          }

          return const Center(child: Text('No expenses yet'));
        },
      ),
    );
  }

  Widget _buildDashboard(double total, double budget, List<double> chartData) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Arc meter
          ParticleBurst(
            animate: _showParticles,
            onComplete: () => setState(() => _showParticles = false),
            child: ArcMeter(
              progress: (total / budget).clamp(0.0, 1.0),
              totalBudget: budget,
              spent: total,
            ),
          ),
          const SizedBox(height: 24),
          // Line chart
          if (chartData.length >= 2)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last 7 expenses',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                SpendArcLineChart(
                  data: chartData,
                  labels: const ['1', '2', '3', '4', '5', '6', '7'],
                ),
              ],
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildExpenseItem(BuildContext context, expense) {
    return Dismissible(
      key: ValueKey(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        color: Colors.red,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (_) {
        context.read<ExpenseBloc>().add(DeleteExpenseEvent(expense.id));
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _categoryColor(expense.category).withOpacity(0.15),
          child: Text(
            _categoryEmoji(expense.category),
            style: const TextStyle(fontSize: 18),
          ),
        ),
        title: Text(expense.title),
        subtitle: Text(
          '${expense.category} · ${_formatDate(expense.date)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Text(
          '₹${expense.amount.toStringAsFixed(0)}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }

  void _showAddExpenseSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<ExpenseBloc>(),
        child: const _AddExpenseSheet(),
      ),
    ).then((_) => setState(() => _showParticles = true));
  }

  Color _categoryColor(String category) {
    const colors = {
      'Food': Colors.orange,
      'Transport': Colors.blue,
      'Shopping': Colors.purple,
      'Health': Colors.green,
      'Entertainment': Colors.pink,
    };
    return colors[category] ?? Colors.grey;
  }

  String _categoryEmoji(String category) {
    const emojis = {
      'Food': '🍔',
      'Transport': '🚗',
      'Shopping': '🛍',
      'Health': '💊',
      'Entertainment': '🎬',
    };
    return emojis[category] ?? '💰';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _AddExpenseSheet extends StatefulWidget {
  const _AddExpenseSheet();

  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCategory = 'Food';
  final _formKey = GlobalKey<FormState>();

  final _categories = ['Food', 'Transport', 'Shopping', 'Health', 'Entertainment'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Expense',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('title_field'),
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                border: OutlineInputBorder(),
                prefixText: '₹ ',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Amount is required';
                if (double.tryParse(v) == null) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('submit_button'),
                onPressed: _submit,
                child: const Text('Add Expense'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<ExpenseBloc>().add(
          AddExpenseEvent(
            expense_entity.Expense(
              id: '', // will be assigned in repository
              title: _titleController.text.trim(),
              amount: double.parse(_amountController.text),
              category: _selectedCategory,
              date: DateTime.now(),
            ),
          ),
        );
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}
