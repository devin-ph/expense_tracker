import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/constants.dart';
import 'models/index.dart';
import 'providers/index.dart';
import 'screens/home/home_screen.dart';
import 'screens/transactions/transactions_screen.dart';
import 'screens/statistics/statistics_screen.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/add_transaction/add_transaction_sheet.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthNotifier()),
        ChangeNotifierProvider(create: (_) => WalletNotifier()),
        ChangeNotifierProvider(create: (_) => TransactionNotifier()),
        ChangeNotifierProvider(create: (_) => CategoryNotifier()),
        ChangeNotifierProvider(create: (_) => SpendingLimitNotifier()),
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
      ],
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, _) {
          ThemeMode themeMode = ThemeMode.light;
          switch (themeNotifier.themeMode) {
            case AppThemeMode.light:
              themeMode = ThemeMode.light;
              break;
            case AppThemeMode.dark:
              themeMode = ThemeMode.dark;
              break;
            case AppThemeMode.system:
              themeMode = ThemeMode.system;
              break;
          }

          return MaterialApp(
            title: 'Expense Tracker',
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode: themeMode,
            home: const MainApp(),
            routes: {
              '/home': (_) => const MainApp(),
              '/transactions': (_) => const TransactionsScreen(),
              '/statistics': (_) => const StatisticsScreen(),
              '/login': (_) => const AuthLoginScreen(),
              '/profile': (_) => const ProfileScreen(),
            },
          );
        },
      ),
    );
  }
}

/// Main app with bottom navigation
class MainApp extends StatefulWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialize auth
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthNotifier>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthNotifier>(
      builder: (context, authNotifier, _) {
        // If not authenticated, show login screen
        if (!authNotifier.isAuthenticated && !authNotifier.isLoading) {
          return const AuthLoginScreen();
        }

        return Scaffold(
          body: _buildBody(_selectedIndex),
          bottomNavigationBar: _buildBottomNavigationBar(),
          floatingActionButton: _buildFloatingActionButton(),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
        );
      },
    );
  }

  Widget _buildBody(int index) {
    switch (index) {
      case 0:
        return HomeScreen(
          onAvatarTap: () => setState(() => _selectedIndex = 3),
          onBalanceTap: () => setState(() => _selectedIndex = 2),
          onAllTransactionsTap: () => setState(() => _selectedIndex = 1),
        );
      case 1:
        return const TransactionsScreen();
      case 2:
        return const StatisticsScreen();
      case 3:
        return const ProfileScreen();
      default:
        return const HomeScreen();
    }
  }

  Widget _buildBottomNavigationBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      elevation: 8,
      child: SizedBox(
        height: 64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_outlined, 'Trang chủ'),
            _buildNavItem(1, Icons.receipt_outlined, 'Giao dịch'),
            const SizedBox(width: 48), // Space for FAB
            _buildNavItem(2, Icons.bar_chart_outlined, 'Thống kê'),
            _buildNavItem(3, Icons.person_outline, 'Tài khoản'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    final theme = Theme.of(context);

    // Use accent color for selected items in dark mode for better contrast
    final selectedColor = theme.brightness == Brightness.dark
        ? const Color(0xFF06B6D4) // Cyan accent
        : theme.primaryColor;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedIndex = index),
          splashColor: theme.primaryColor.withOpacity(0.1),
          highlightColor: theme.primaryColor.withOpacity(0.05),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? selectedColor : Colors.grey,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isSelected ? selectedColor : Colors.grey,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return SizedBox(
      width: 60,
      height: 60,
      child: FloatingActionButton(
        onPressed: _showAddTransactionSheet,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  void _showAddTransactionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppBorderRadius.xl),
            topRight: Radius.circular(AppBorderRadius.xl),
          ),
        ),
        child: AddTransactionSheet(
          onTransactionAdded: () {
            setState(() {});
          },
        ),
      ),
    );
  }
}
