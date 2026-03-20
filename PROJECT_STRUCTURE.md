# Expense Tracker App

A modern and comprehensive Flutter expense tracking application.

## Project Structure

```
lib/
├── config/              # Configuration, themes, constants
├── models/              # Data models (User, Wallet, Transaction, Category, SpendingLimit)
├── providers/           # State management using Provider
├── screens/             # Application screens
│   ├── home/           # Home Screen - Main dashboard (Lê Tiến Minh)
│   ├── transactions/   # Transaction History Screen (Đinh Phương Ly)
│   ├── add_transaction/ # Add Transaction Bottom Sheet (Trần Quang Quân)
│   ├── statistics/     # Statistics Screen with Charts (Phạm Hoàng Thế Vinh)
│   └── auth/           # Login & Profile Screens (Phạm Ngọc Minh Nam)
├── services/           # Business logic services
├── widgets/            # Reusable widgets
└── main.dart          # App entry point
```

## Team Assignment

- **Lê Tiến Minh** - Home Screen (Dashboard)
- **Đinh Phương Ly** - Transaction History Screen
- **Trần Quang Quân** - Add Transaction  Screen
- **Phạm Hoàng Thế Vinh** - Statistics Screen
- **Phạm Ngọc Minh Nam** - Login & Profile Screens

## Features

### Home Screen
- Displays wallet information with balance
- Shows monthly income and expense summary
- Displays spending limits with progress bars
- Lists today's transactions
- Color-coded budget status (<50% green, 50-80% orange, >80% red)

### Transaction History Screen
- Tabbed view for Income and Expense transactions
- Date range filtering
- Monthly summaries with totals
- Transaction cards with category icon, note, time, and amount

### Add Transaction Sheet
- Bottom sheet for adding new transactions
- Transaction type selector (Income/Expense)
- Amount input with automatic currency formatting
- Wallet and category dropdowns
- Date and note input
- Add new category functionality

### Statistics Screen
- Line chart showing monthly spending trends
- Pie chart showing spending by category
- Month selector to view category breakdown
- Total amount display in pie chart center

### Login & Profile Screen
- Email/password login
- Google login integration
- Profile page with user information
- Wallet management (add, edit, delete)
- Theme mode settings (Light/Dark/System)
- Password change option

## Dependencies

- **provider** - State management
- **intl** - Date and number formatting
- **fl_chart** - Charts for statistics
- **uuid** - Unique ID generation
- **google_fonts** - Typography
- **shared_preferences** - Local storage

## Getting Started

```bash
# Get dependencies
flutter pub get

# Run the app
flutter run
```

## Color Scheme

- **Primary**: Indigo (#6366F1)
- **Secondary**: Violet (#8B5CF6)
- **Accent**: Cyan (#06B6D4)
- **Income**: Green (#10B981)
- **Expense**: Red (#EF4444)
- **Warning**: Orange (#F97316)

## Currency

All transactions are displayed in VND (Vietnamese Dong) with automatic thousand separators.

## Notes

- The app uses local data for demonstration
- Real implementation would connect to Firebase or other backend service
- Each team member works on their assigned screen/functionality
- Shared widgets and providers ensure consistency across the app
