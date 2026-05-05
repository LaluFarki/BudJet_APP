enum BudgetPeriod { daily, weekly, monthly }

extension BudgetPeriodLabel on BudgetPeriod {
  String get label {
    switch (this) {
      case BudgetPeriod.daily:
        return 'Harian';
      case BudgetPeriod.weekly:
        return 'Mingguan';
      case BudgetPeriod.monthly:
        return 'Bulanan';
    }
  }
}

class BudgetCategory {
  final String id;
  final String name;
  final double amount;
  final BudgetPeriod period;
  final bool isAutoCategory;

  const BudgetCategory({
    required this.id,
    required this.name,
    required this.amount,
    required this.period,
    this.isAutoCategory = false,
  });

  BudgetCategory copyWith({
    String? id,
    String? name,
    double? amount,
    BudgetPeriod? period,
    bool? isAutoCategory,
  }) {
    return BudgetCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      isAutoCategory: isAutoCategory ?? this.isAutoCategory,
    );
  }
}

class BudgetTransaction {
  final String id;
  final String categoryId;
  final double amount;
  final DateTime date;
  final String? note;

  final String? donorCategoryId;
  final double donorAmount;

  const BudgetTransaction({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.date,
    this.note,
    this.donorCategoryId,
    this.donorAmount = 0,
  });
}

class CategoryBudgetSummary {
  final String categoryId;
  final String name;
  final double allocationAmount;
  final double monthlyEquivalent;
  final double spentAmount;
  final double remainingAmount;
  final BudgetPeriod period;
  final bool isMinus;
  final bool isAutoCategory;

  const CategoryBudgetSummary({
    required this.categoryId,
    required this.name,
    required this.allocationAmount,
    required this.monthlyEquivalent,
    required this.spentAmount,
    required this.remainingAmount,
    required this.period,
    required this.isMinus,
    required this.isAutoCategory,
  });
}

class BudgetSummary {
  final double monthlyBudget;
  final double totalMonthlyAllocation;
  final double totalSpent;
  final double remainingMainBalance;
  final double unallocatedBalance;
  final List<CategoryBudgetSummary> categories;

  const BudgetSummary({
    required this.monthlyBudget,
    required this.totalMonthlyAllocation,
    required this.totalSpent,
    required this.remainingMainBalance,
    required this.unallocatedBalance,
    required this.categories,
  });
}
