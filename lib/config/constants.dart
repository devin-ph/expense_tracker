// App route names
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String transactions = '/transactions';
  static const String addTransaction = '/add-transaction';
  static const String statistics = '/statistics';
  static const String profile = '/profile';
}

// Spacing
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
}

// Border radius
class AppBorderRadius {
  static const double xs = 2.0;
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double full = 9999.0;
}

// Icon sizes
class AppIconSize {
  static const double xs = 12.0;
  static const double sm = 16.0;
  static const double md = 24.0;
  static const double lg = 32.0;
  static const double xl = 48.0;
  static const double xxl = 64.0;
}

// Currency
class AppCurrency {
  static const String symbol = '₫';
  static const String code = 'VND';
  static const String locale = 'vi_VN';

  static String format(double amount) {
    final formatted = amount.toStringAsFixed(0);
    final parts = formatted.split('');
    final result = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      result.write(parts[i]);
      final remainingDigits = parts.length - i - 1;
      if (remainingDigits > 0 && remainingDigits % 3 == 0) {
        result.write(',');
      }
    }
    return '$result $symbol';
  }
}

// Date formats
class AppDateFormat {
  static const String dateTime = 'dd/MM/yyyy HH:mm';
  static const String date = 'dd/MM/yyyy';
  static const String time = 'HH:mm';
  static const String monthYear = 'MM/yyyy';
  static const String monthYearFull = 'MMMM yyyy';
}
