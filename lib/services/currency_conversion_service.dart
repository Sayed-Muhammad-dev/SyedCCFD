class CurrencyConversionService {
  CurrencyConversionService._();

  /// Static conversion rate table.
  ///
  /// Keys are in the form `SOURCE_TARGET`, for example: `USD_PKR`.
  /// Values are simple demo rates (not real FX rates).
  ///
  /// Ensure every currency in your dropdown is covered here.
  static const Map<String, double> _rates = {
    // PKR base conversions
    'PKR_PKR': 1.0,
    'PKR_USD': 0.0036,
    'PKR_EUR': 0.0033,
    'PKR_GBP': 0.0028,

    // USD base conversions
    'USD_USD': 1.0,
    'USD_PKR': 280.0,
    'USD_EUR': 0.92,
    'USD_GBP': 0.80,

    // EUR base conversions
    'EUR_EUR': 1.0,
    'EUR_USD': 1.08,
    'EUR_PKR': 300.0,
    'EUR_GBP': 0.87,

    // GBP base conversions
    'GBP_GBP': 1.0,
    'GBP_USD': 1.25,
    'GBP_EUR': 1.15,
    'GBP_PKR': 340.0,

    // Add more currencies here if your dropdown supports them.
  };

  /// Convert [amount] from [sourceCurrency] to [targetCurrency].
  ///
  /// - If currencies are the same, returns the original [amount].
  /// - If a direct conversion rate exists, returns `amount * rate`.
  /// - If the rate is missing or input is invalid, returns the original [amount].
  ///
  /// This method never throws and is fully synchronous.
  static double convert({
    required double amount,
    required String sourceCurrency,
    required String targetCurrency,
  }) {
    // Safe guards for invalid amounts (NaN, infinite, negative)
    if (amount.isNaN || amount.isInfinite) {
      return 0.0;
    }

    // Zero or negative amounts: just return as-is; fraud logic can interpret.
    if (amount == 0.0 || amount < 0.0) {
      return amount;
    }

    final src = sourceCurrency.toUpperCase().trim();
    final tgt = targetCurrency.toUpperCase().trim();

    // If currency codes are unknown or empty, fall back to original amount.
    if (src.isEmpty || tgt.isEmpty) {
      return amount;
    }

    // Same currency: no conversion needed.
    if (src == tgt) {
      return amount;
    }

    final key = '${src}_$tgt';
    final rate = _rates[key];

    if (rate == null) {
      // Missing rate: safe fallback, return original amount unchanged.
      // You can hook in logging here if needed.
      return amount;
    }

    return amount * rate;
  }
}


