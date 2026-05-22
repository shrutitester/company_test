import 'package:hive/hive.dart';
import '../../domain/entities/expense.dart';

part 'expense_model.g.dart';

@HiveType(typeId: 0)
class ExpenseModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final String category;

  @HiveField(4)
  final DateTime date;

  @HiveField(5)
  final String? note;

  @HiveField(6)
  bool isSynced;

  ExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
    this.isSynced = false,
  });

  factory ExpenseModel.fromEntity(Expense e, {bool isSynced = false}) {
    return ExpenseModel(
      id: e.id,
      title: e.title,
      amount: e.amount,
      category: e.category,
      date: e.date,
      note: e.note,
      isSynced: isSynced,
    );
  }

  Expense toEntity() => Expense(
        id: id,
        title: title,
        amount: amount,
        category: category,
        date: date,
        note: note,
      );

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
      isSynced: true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category,
        'date': date.toIso8601String(),
        'note': note,
      };
}
