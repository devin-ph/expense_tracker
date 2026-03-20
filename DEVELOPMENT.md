# Expense Tracker - Developer Guide

## Project Overview

This is a comprehensive Flutter expense tracking application built for a team development project. The app is designed with a modern UI, proper state management, and a clean architecture that allows multiple developers to work on different features independently.

## Getting Started

### Prerequisites

- Flutter SDK (3.11.1 or higher)
- Dart 3.11.1 or higher
- Android Studio / VS Code
- Git for version control

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd expense_tracker
   ```

2. **Get dependencies**
   ```bash
   flutter clean
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

Or in release mode:
   ```bash
   flutter run --release
   ```

## Project Structure

```
lib/
├── config/              # App configuration
│   ├── theme.dart       # Light and dark themes
│   ├── constants.dart   # App constants and spacing
│   └── default_categories.dart # Default categories
├── models/              # Data models
│   ├── user.dart        # User model
│   ├── wallet.dart      # Wallet model
│   ├── transaction.dart  # Transaction model
│   ├── category.dart    # Category model
│   ├── spending_limit.dart # Spending limit model
│   └── enums.dart       # Enumerations
├── providers/           # State management (Provider pattern)
│   ├── auth_provider.dart
│   ├── wallet_provider.dart
│   ├── transaction_provider.dart
│   ├── category_provider.dart
│   ├── spending_limit_provider.dart
│   └── theme_provider.dart
├── screens/             # Application screens
│   ├── home/            # Home screen (Dashboard)
│   ├── transactions/    # Transaction history
│   ├── add_transaction/ # Add transaction bottom sheet
│   ├── statistics/      # Statistics with charts
│   └── auth/            # Login & Profile
├── widgets/             # Reusable widgets
│   ├── transaction_card.dart
│   ├── spending_progress_bar.dart
│   └── currency_input_field.dart
└── main.dart           # App entry point
```

## Team Responsibilities

### 1. Home Screen - Lê Tiến Minh
**Location**: `lib/screens/home/home_screen.dart`

**Features**:
- Wallet information card with balance
- Monthly income/expense summary
- Spending limits with progress bars
- Today's transactions list
- Wallet selector

**Key Components**:
- `_buildWalletCard()` - Main wallet information
- `_buildLimitsSection()` - Spending limits display
- `_buildTodayTransactionsSection()` - Transactions list

### 2. Transactions Screen - Đinh Phương Ly
**Location**: `lib/screens/transactions/transactions_screen.dart`

**Features**:
- Tabbed view (Income/Expense)
- Date range filtering
- Transaction statistics
- Transaction list with sorting

**Key Components**:
- `_buildDateFilter()` - Date range selector
- `_buildTransactionList()` - Main transactions list
- Tab controller for switching between types

### 3. Add Transaction Screen - Trần Quang Quân
**Location**: `lib/screens/add_transaction/add_transaction_sheet.dart`

**Features**:
- Bottom sheet for adding transactions
- Transaction type selector
- Amount input with formatting
- Category and wallet selection
- Date picker
- Note input
- Create new category functionality

**Key Components**:
- `_buildTypeSelector()` - Income/Expense toggle
- `_buildAmountInput()` - Currency input
- `_buildCategorySelection()` - Category picker
- `_showAddCategoryDialog()` - Category creation

### 4. Statistics Screen - Phạm Hoàng Thế Vinh
**Location**: `lib/screens/statistics/statistics_screen.dart`

**Features**:
- Line chart for monthly trends
- Pie chart for category breakdown
- Year/month selector
- Category statistics

**Key Components**:
- `_buildLineChart()` - Monthly spending trends
- `_buildPieChart()` - Category breakdown
- `_buildYearMonthSelector()` - Date selector

### 5. Login & Profile Screen - Phạm Ngọc Minh Nam
**Location**: `lib/screens/auth/auth_screen.dart`

**Features For AuthLoginScreen**:
- Email/password login
- Google login integration
- Form validation
- Error handling

**Features For ProfileScreen**:
- User profile display
- Wallet management (CRUD)
- Theme settings
- Password change
- Account switching
- Logout functionality

**Key Components**:
- `_handleLogin()` - Email/password authentication
- `_handleGoogleLogin()` - Google OAuth
- `_buildWalletSection()` - Wallet management
- `_buildSettingsSection()` - App settings

## State Management

The app uses the **Provider** package for state management. Each major data entity has its own notifier:

### Available Providers

1. **AuthNotifier** - User authentication
   - Login/logout
   - User data management
   - Authentication state

2. **WalletNotifier** - Wallet management
   - Add/edit/delete wallets
   - Select active wallet
   - Update balance

3. **TransactionNotifier** - Transaction management
   - Add/edit/delete transactions
   - Filter by type, date, wallet
   - Calculate totals

4. **CategoryNotifier** - Category management
   - Predefined categories
   - Custom category creation
   - Filter by type

5. **SpendingLimitNotifier** - Budget management
   - Create/edit spending limits
   - Calculate progress percentage
   - Limit validation

6. **ThemeNotifier** - Theme management
   - Light/Dark/System modes
   - Theme persistence

### Using Providers in Widgets

```dart
// Read provider
final walletNotifier = context.read<WalletNotifier>();

// Watch provider (rebuilds on change)
final wallet = context.watch<WalletNotifier>().selectedWallet;

// Consumer widget
Consumer<TransactionNotifier>(
  builder: (context, transactionNotifier, _) {
    final transactions = transactionNotifier.transactions;
    return ListView(...);
  },
)
```

## Data Models

All data models include:
- JSON serialization (toJson/fromJson)
- Copy constructors for immutability
- Proper date/time handling

### Model Relationships
```
User
├── Wallets (1:Many)
├── Categories (1:Many)
├── Transactions (1:Many)
└── SpendingLimits (1:Many)
```

## Key Features Implementation

### Currency Formatting

```dart
AppCurrency.format(1500000) // Returns: "1,500,000 ₫"
```

### Date Formatting

```dart
DateFormat(AppDateFormat.date).format(date) // "dd/MM/yyyy"
DateFormat(AppDateFormat.time).format(date) // "HH:mm"
```

### Color Scheme

- **Primary**: #6366F1 (Indigo)
- **Secondary**: #8B5CF6 (Violet)
- **Income**: #10B981 (Green)
- **Expense**: #EF4444 (Red)
- **Warning**: #F97316 (Orange)

## Best Practices

### Development Guidelines

1. **File Organization**
   - Keep screens in their respective folders
   - Group related models together
   - Use index.dart for clean exports

2. **Code Style**
   - Follow Dart conventions
   - Use meaningful variable names
   - Add comments for complex logic

3. **State Management**
   - Use providers for shared state
   - Keep business logic in notifiers
   - Avoid direct state mutations

4. **UI Components**
   - Use Theme.of(context) for consistency
   - Leverage reusable widgets
   - Maintain spacing constants

5. **Error Handling**
   - Show user-friendly error messages
   - Use try-catch appropriately
   - Log errors for debugging

### Git Workflow

1. Create feature branch: `git checkout -b feature/your-feature-name`
2. Make changes and commit: `git commit -m "feat: description"`
3. Push to remote: `git push origin feature/your-feature-name`
4. Create pull request
5. Merge after review

### Commit Message Format

```
feat: add new feature
fix: fix bug
docs: update documentation
style: code formatting
refactor: code refactoring
test: add tests
chore: maintenance
```

## Troubleshooting

### Common Issues

1. **Pub get issues**
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Build cache problems**
   ```bash
   flutter clean
   rm -rf build/
   flutter pub get
   flutter run
   ```

3. **Provider errors**
   - Ensure all providers are registered in `main.dart`
   - Check context.read/watch is within proper widget tree
   - Verify ChangeNotifier.notifyListeners() is called

4. **Theme not updating**
   - Rebuild app (not hot reload)
   - Check ThemeNotifier.notifyListeners() is called

## Testing

### Unit Tests
```bash
flutter test
```

### Widget Tests
```bash
flutter test lib/widgets/
```

### Integration Tests
```bash
flutter test integration_test/
```

## Performance Optimization

1. Use `const` constructors when possible
2. Implement efficient list rendering with `ListView.builder()`
3. Minimize rebuild with consumer selectors
4. Lazy load data when appropriate

## Future Enhancements

- [ ] Firebase integration for backend
- [ ] Cloud backup and sync
- [ ] Advanced reporting and analytics
- [ ] Budget recommendations
- [ ] Expense categorization AI
- [ ] Multi-currency support
- [ ] Offline mode with sync
- [ ] Export functionality (PDF, CSV)

## Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Provider Package](https://pub.dev/packages/provider)
- [Material Design](https://material.io/design)
- [Dart Guide](https://dart.dev/guides)

## Support

For questions or issues:
1. Check existing issues in the repository
2. Create a detailed issue with reproduction steps
3. Reach out to the team via Slack/Teams
4. Reference relevant documentation

---

**Last Updated**: March 2026
**Project Version**: 1.0.0
