import 'smart_budget_engine.dart';
import 'smart_budget_model.dart';

void main() {
  final engine = SmartBudgetEngine();

  const monthlyBudget = 2000000.0;

  final categories = <BudgetCategory>[
    BudgetCategory(
      id: 'makan',
      name: 'Makan',
      amount: 600000,
      period: BudgetPeriod.monthly,
    ),
    BudgetCategory(
      id: 'transportasi',
      name: 'Transportasi / Bensin',
      amount: 100000,
      period: BudgetPeriod.weekly,
    ),
    BudgetCategory(
      id: 'kost',
      name: 'Kost',
      amount: 800000,
      period: BudgetPeriod.monthly,
    ),
  ];

  final transactions = <BudgetTransaction>[];

  var summary = engine.calculateSummary(
    monthlyBudget: monthlyBudget,
    categories: categories,
    transactions: transactions,
  );

  printSummary('SETELAH SET BUDGET AWAL', summary);

  print('\nUser transaksi makan Rp650.000');
  print('Saldo makan hanya Rp600.000, maka butuh donor Rp50.000');

  final suggestedDonorId = engine.getSuggestedDonorCategoryId(summary);

  final transaction = engine.createTransaction(
    id: 'txn_001',
    categoryId: 'makan',
    amount: 650000,
    date: DateTime.now(),
    currentSummary: summary,
    donorCategoryId: suggestedDonorId,
    note: 'Makan bulanan melebihi alokasi',
  );

  transactions.add(transaction);

  summary = engine.calculateSummary(
    monthlyBudget: monthlyBudget,
    categories: categories,
    transactions: transactions,
  );

  printSummary('SETELAH TRANSAKSI DENGAN DONOR', summary);

  print('\nUser edit nama kategori Hiburan ke Self Reward:');
  print(
    'Ini cukup update field name di BudgetCategory, transaksi tetap aman selama categoryId tidak berubah.',
  );
}

void printSummary(String title, BudgetSummary summary) {
  print('\n==============================');
  print(title);
  print('==============================');

  print('Saldo bulanan: Rp${summary.monthlyBudget.toStringAsFixed(0)}');
  print(
    'Total alokasi bulanan: Rp${summary.totalMonthlyAllocation.toStringAsFixed(0)}',
  );
  print('Total pengeluaran: Rp${summary.totalSpent.toStringAsFixed(0)}');
  print(
    'Sisa saldo utama: Rp${summary.remainingMainBalance.toStringAsFixed(0)}',
  );

  print('\nKategori:');

  for (final category in summary.categories) {
    print(
      '- ${category.name} '
      '(${category.period.label}) | '
      'Alokasi input: Rp${category.allocationAmount.toStringAsFixed(0)} | '
      'Setara bulanan: Rp${category.monthlyEquivalent.toStringAsFixed(0)} | '
      'Terpakai: Rp${category.spentAmount.toStringAsFixed(0)} | '
      'Sisa: Rp${category.remainingAmount.toStringAsFixed(0)}',
    );
  }
}
