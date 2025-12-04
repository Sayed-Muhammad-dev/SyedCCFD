import 'currency_conversion_service.dart';

/// Data structure representing the user's spending limits and preferences,
/// typically coming from Firestore.
class UserLimits {
  final double monthlySpending;
  final double usualTransactionAmount;
  final double maximumTransactionAmount;
  final String selectedCardCurrency;

  /// Optional: if any of these limits are stored in a different currency,
  /// you can specify that here and let the evaluator normalize them.
  final String? limitsCurrency;

  const UserLimits({
    required this.monthlySpending,
    required this.usualTransactionAmount,
    required this.maximumTransactionAmount,
    required this.selectedCardCurrency,
    this.limitsCurrency,
  });
}

/// Simple representation of a transaction as required by the fraud engine.
class TransactionData {
  final double transactionAmount;
  final String transactionCurrency;
  final String transactionCategory;
  final DateTime timestamp;

  /// Optional contextual information, such as recent monthly spending.
  /// This can be populated from a database or analytics layer.
  final double? currentMonthSpendingInCardCurrency;

  const TransactionData({
    required this.transactionAmount,
    required this.transactionCurrency,
    required this.transactionCategory,
    required this.timestamp,
    this.currentMonthSpendingInCardCurrency,
  });
}

/// Result object returned by the fraud detection flow.
class FraudCheckResult {
  final double originalTransactionAmount;
  final String originalTransactionCurrency;
  final double convertedAmountInCardCurrency;
  final String cardCurrency;

  /// Limit values after being normalized to [cardCurrency].
  final Map<String, double> limitValuesUsed;

  /// Human-readable flags for all triggered rules.
  final List<String> flagsTriggered;

  /// Final verdict: 'SAFE', 'SUSPICIOUS', or 'FRAUD'.
  final String finalVerdict;

  const FraudCheckResult({
    required this.originalTransactionAmount,
    required this.originalTransactionCurrency,
    required this.convertedAmountInCardCurrency,
    required this.cardCurrency,
    required this.limitValuesUsed,
    required this.flagsTriggered,
    required this.finalVerdict,
  });
}

class FraudDetectionService {
  FraudDetectionService._();

  /// Main entry point for fraud evaluation.
  ///
  /// This function:
  /// 1. Normalizes transaction amount into the user's card currency.
  /// 2. Normalizes limits into the same card currency (if needed).
  /// 3. Applies rule-based checks and collects flags.
  /// 4. Produces a structured [FraudCheckResult] usable by any UI.
  static FraudCheckResult evaluateTransaction({
    required TransactionData transaction,
    required UserLimits userLimits,
  }) {
    final cardCurrency = userLimits.selectedCardCurrency.toUpperCase().trim();

    // 1. Convert transaction amount into card currency.
    final cardCurrencyAmount = CurrencyConversionService.convert(
      amount: transaction.transactionAmount,
      sourceCurrency: transaction.transactionCurrency,
      targetCurrency: cardCurrency,
    );

    // 2. Normalize limits into the same currency as the card.
    final limitsCurrency =
        (userLimits.limitsCurrency ?? cardCurrency).toUpperCase().trim();

    double normalizeLimit(double limit) {
      return CurrencyConversionService.convert(
        amount: limit,
        sourceCurrency: limitsCurrency,
        targetCurrency: cardCurrency,
      );
    }

    final monthlyLimit = normalizeLimit(userLimits.monthlySpending);
    final usualLimit = normalizeLimit(userLimits.usualTransactionAmount);
    final maxLimit = normalizeLimit(userLimits.maximumTransactionAmount);

    final limitValuesUsed = <String, double>{
      'monthlySpending': monthlyLimit,
      'usualTransactionAmount': usualLimit,
      'maximumTransactionAmount': maxLimit,
    };

    // 3. Apply fraud rules.
    final List<String> flags = [];

    // Rule: Exceeds usual amount
    if (cardCurrencyAmount > usualLimit && usualLimit > 0) {
      flags.add('Exceeds usual amount');
    }

    // Rule: Exceeds maximum allowed amount
    if (cardCurrencyAmount > maxLimit && maxLimit > 0) {
      flags.add('Exceeds maximum allowed amount');
    }

    // Rule: Suspiciously high for this category
    // Simple heuristic: for certain categories, threshold is stricter.
    final lowerCategory = transaction.transactionCategory.toLowerCase().trim();
    final categoryMultiplier =
        _categoryMultiplier(lowerCategory); // <= 1.0 for risky categories
    if (cardCurrencyAmount >
        usualLimit * categoryMultiplier &&
        usualLimit > 0) {
      flags.add('Suspiciously high for this category');
    }

    // Rule: Sudden spending spike
    // If currentMonthSpending + this transaction > 1.5 * monthlyLimit.
    final monthSoFar = transaction.currentMonthSpendingInCardCurrency ?? 0.0;
    if (monthlyLimit > 0 &&
        (monthSoFar + cardCurrencyAmount) > (monthlyLimit * 1.5)) {
      flags.add('Sudden spending spike');
    }

    // Edge cases: extremely small or invalid amounts - typically SAFE.
    if (transaction.transactionAmount <= 0) {
      // No extra flag, but verdict logic will keep it safe.
    }

    // 4. Decide final verdict based on number and severity of flags.
    final verdict = _computeVerdict(flags);

    return FraudCheckResult(
      originalTransactionAmount: transaction.transactionAmount,
      originalTransactionCurrency: transaction.transactionCurrency,
      convertedAmountInCardCurrency: cardCurrencyAmount,
      cardCurrency: cardCurrency,
      limitValuesUsed: limitValuesUsed,
      flagsTriggered: flags,
      finalVerdict: verdict,
    );
  }

  static double _categoryMultiplier(String category) {
    // Lower multiplier => more strict compared to usual amount.
    switch (category) {
      case 'gambling':
      case 'betting':
        return 0.5;
      case 'luxury':
      case 'electronics':
        return 0.8;
      default:
        return 1.0;
    }
  }

  static String _computeVerdict(List<String> flags) {
    if (flags.isEmpty) {
      return 'SAFE';
    }
    if (flags.length == 1) {
      return 'SUSPICIOUS';
    }
    // 2 or more flags -> FRAUD.
    return 'FRAUD';
  }
}


