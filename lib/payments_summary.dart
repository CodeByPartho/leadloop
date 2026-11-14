import 'models.dart';

/// Payment reporting. Totals are grouped by currency and never added
/// across currencies. All pure functions, unit tested.

class PaymentSummary {
  /// Unpaid amounts by currency.
  final Map<String, double> outstandingByCurrency;

  /// Overdue unpaid amounts by currency.
  final Map<String, double> overdueByCurrency;

  /// Paid this calendar month by currency.
  final Map<String, double> paidThisMonthByCurrency;

  /// Unpaid amounts due this calendar month by currency.
  final Map<String, double> dueThisMonthByCurrency;

  const PaymentSummary({
    required this.outstandingByCurrency,
    required this.overdueByCurrency,
    required this.paidThisMonthByCurrency,
    required this.dueThisMonthByCurrency,
  });
}

void _add(Map<String, double> totals, String currency, double amount) {
  totals[currency] = (totals[currency] ?? 0) + amount;
}

PaymentSummary paymentSummary(List<LeadPayment> payments, DateTime now) {
  final outstanding = <String, double>{};
  final overdue = <String, double>{};
  final paidThisMonth = <String, double>{};
  final dueThisMonth = <String, double>{};
  for (final p in payments) {
    if (p.isPaid) {
      if (p.paidAt!.year == now.year && p.paidAt!.month == now.month) {
        _add(paidThisMonth, p.currency, p.amount);
      }
    } else {
      _add(outstanding, p.currency, p.amount);
      if (p.isOverdue) _add(overdue, p.currency, p.amount);
      if (p.dueDate.year == now.year && p.dueDate.month == now.month) {
        _add(dueThisMonth, p.currency, p.amount);
      }
    }
  }
  return PaymentSummary(
    outstandingByCurrency: outstanding,
    overdueByCurrency: overdue,
    paidThisMonthByCurrency: paidThisMonth,
    dueThisMonthByCurrency: dueThisMonth,
  );
}
