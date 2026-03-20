/// Transaction types enum
enum TransactionType {
  income('Thu nhập'),
  expense('Chi tiêu');

  final String label;
  const TransactionType(this.label);
}

/// Theme modes
enum AppThemeMode {
  system('Hệ thống'),
  light('Sáng'),
  dark('Tối');

  final String label;
  const AppThemeMode(this.label);
}
