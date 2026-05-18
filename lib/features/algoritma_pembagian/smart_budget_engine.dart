import 'smart_budget_model.dart';

class SmartBudgetEngine {
  static const String sisaDanaId = 'sisa_dana';

  double convertToMonthly(double amount, BudgetPeriod period) {
    return amount;
  }

  List<BudgetCategory> applySisaDanaCategory({
    required double monthlyBudget,
    required List<BudgetCategory> categories,
  }) {
    final categoriesWithoutSisaDana = categories
        .where((c) => c.id != sisaDanaId)
        .toList();

    final totalAllocation = categoriesWithoutSisaDana.fold<double>(
      0,
      (sum, category) =>
          sum + convertToMonthly(category.amount, category.period),
    );

    final remaining = monthlyBudget - totalAllocation;

    if (remaining <= 0) {
      return categoriesWithoutSisaDana;
    }

    return [
      ...categoriesWithoutSisaDana,
      BudgetCategory(
        id: sisaDanaId,
        name: 'Sisa Dana',
        amount: remaining,
        period: BudgetPeriod.monthly,
        isAutoCategory: true,
      ),
    ];
  }

  BudgetSummary calculateSummary({
    required double monthlyBudget,
    required List<BudgetCategory> categories,
    required List<BudgetTransaction> transactions,
  }) {
    final normalizedCategories = applySisaDanaCategory(
      monthlyBudget: monthlyBudget,
      categories: categories,
    );

    final categorySummaries = normalizedCategories.map((category) {
      final monthlyEquivalent = convertToMonthly(
        category.amount,
        category.period,
      );

      final directSpent = transactions
          .where((t) => t.categoryId == category.id)
          .fold<double>(0, (sum, t) => sum + t.amount);

      final donorSpent = transactions
          .where((t) => t.donorCategoryId == category.id)
          .fold<double>(0, (sum, t) => sum + t.donorAmount);

      final totalSpentFromCategory = directSpent + donorSpent;
      final remaining = monthlyEquivalent - totalSpentFromCategory;

      return CategoryBudgetSummary(
        categoryId: category.id,
        name: category.name,
        allocationAmount: category.amount,
        monthlyEquivalent: monthlyEquivalent,
        spentAmount: totalSpentFromCategory,
        remainingAmount: remaining,
        period: category.period,
        isMinus: remaining < 0,
        isAutoCategory: category.isAutoCategory,
      );
    }).toList();

    final totalAllocation = categorySummaries.fold<double>(
      0,
      (sum, c) => sum + c.monthlyEquivalent,
    );

    final totalSpent = transactions.fold<double>(0, (sum, t) => sum + t.amount);

    final remainingMainBalance = monthlyBudget - totalSpent;
    final unallocatedBalance = monthlyBudget - totalAllocation;

    return BudgetSummary(
      monthlyBudget: monthlyBudget,
      totalMonthlyAllocation: totalAllocation,
      totalSpent: totalSpent,
      remainingMainBalance: remainingMainBalance,
      unallocatedBalance: unallocatedBalance,
      categories: categorySummaries,
    );
  }

  bool needsDonorCategory({
    required String categoryId,
    required double transactionAmount,
    required BudgetSummary summary,
  }) {
    final category = summary.categories.firstWhere(
      (c) => c.categoryId == categoryId,
    );

    return transactionAmount > category.remainingAmount;
  }

  double calculateShortage({
    required String categoryId,
    required double transactionAmount,
    required BudgetSummary summary,
  }) {
    final category = summary.categories.firstWhere(
      (c) => c.categoryId == categoryId,
    );

    final shortage = transactionAmount - category.remainingAmount;

    if (shortage <= 0) return 0;

    return shortage;
  }

  BudgetTransaction createTransaction({
    required String id,
    required String categoryId,
    required double amount,
    required DateTime date,
    required BudgetSummary currentSummary,
    String? note,
    String? donorCategoryId,
  }) {
    final shortage = calculateShortage(
      categoryId: categoryId,
      transactionAmount: amount,
      summary: currentSummary,
    );

    if (shortage <= 0) {
      return BudgetTransaction(
        id: id,
        categoryId: categoryId,
        amount: amount,
        date: date,
        note: note,
      );
    }

    if (donorCategoryId == null) {
      throw Exception(
        'Saldo kategori tidak cukup. Pilih 1 kategori donor untuk menutup kekurangan.',
      );
    }

    final donorCategory = currentSummary.categories.firstWhere(
      (c) => c.categoryId == donorCategoryId,
    );

    if (donorCategory.remainingAmount < shortage) {
      throw Exception(
        'Saldo kategori donor tidak cukup untuk menutup kekurangan.',
      );
    }

    return BudgetTransaction(
      id: id,
      categoryId: categoryId,
      amount: amount,
      date: date,
      note: note,
      donorCategoryId: donorCategoryId,
      donorAmount: shortage,
    );
  }

  String getSuggestedDonorCategoryId(BudgetSummary summary) {
    final hasSisaDana = summary.categories.any(
      (c) => c.categoryId == sisaDanaId,
    );

    if (hasSisaDana) return sisaDanaId;

    final availableCategories =
        summary.categories.where((c) => c.remainingAmount > 0).toList()
          ..sort((a, b) => b.remainingAmount.compareTo(a.remainingAmount));

    if (availableCategories.isEmpty) {
      throw Exception('Tidak ada kategori yang bisa menjadi donor.');
    }

    return availableCategories.first.categoryId;
  }
}
