import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/index.dart';
import '../../providers/index.dart';
import '../../config/constants.dart';

/// Authentication Screen - Login and Signup
/// Profile Screen - User profile and settings
/// Implemented by: Phạm Ngọc Minh Nam
class AuthLoginScreen extends StatefulWidget {
  const AuthLoginScreen({super.key});

  @override
  State<AuthLoginScreen> createState() => _AuthLoginScreenState();
}

class _AuthLoginScreenState extends State<AuthLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xxl),
                // Logo/Title
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            AppBorderRadius.xl,
                          ),
                        ),
                        child: Icon(
                          Icons.wallet,
                          size: 40,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Expense Tracker',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Quản lý chi tiêu của bạn',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                // Email field
                Text('Email', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Nhập email',
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Password field
                Text(
                  'Mật khẩu',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    hintText: 'Nhập mật khẩu',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(
                          () => _isPasswordVisible = !_isPasswordVisible,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Login button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Đăng nhập'),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Divider
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: Theme.of(context).dividerColor),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: Text('hoặc'),
                    ),
                    Expanded(
                      child: Divider(color: Theme.of(context).dividerColor),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                // Google login
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleLogin,
                  icon: const Text('🔍', style: TextStyle(fontSize: 20)),
                  label: const Text('Tiếp tục với Google'),
                ),
                const SizedBox(height: AppSpacing.xl),
                // Signup link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Chưa có tài khoản? '),
                      TextButton(
                        onPressed: () {
                          // Navigate to signup
                        },
                        child: const Text('Đăng ký ngay'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await context.read<AuthNotifier>().login(
        _emailController.text,
        _passwordController.text,
      );
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);

    try {
      await context.read<AuthNotifier>().loginWithGoogle();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

/// Profile and Settings Screen
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _uuid = const Uuid();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cá nhân'), elevation: 0),
      body: Consumer<AuthNotifier>(
        builder: (context, authNotifier, _) {
          final user = authNotifier.currentUser;
          if (user == null) {
            return Center(
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/login'),
                child: const Text('Đăng nhập'),
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildUserCard(user),
                const SizedBox(height: AppSpacing.xl),
                _buildWalletSection(context),
                const SizedBox(height: AppSpacing.xl),
                _buildSettingsSection(context),
                const SizedBox(height: AppSpacing.xl),
                _buildLogoutButton(context),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserCard(User user) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppBorderRadius.xl),
            ),
            child: Icon(
              Icons.person,
              size: 40,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // User info
          Text(user.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(user.email, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.lg),
          // Edit button
          ElevatedButton(
            onPressed: () {
              // Edit profile
            },
            child: const Text('Chỉnh sửa thông tin'),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: () {
              // Change password
            },
            child: const Text('Đổi mật khẩu'),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quản lý Ví',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  _showWalletDialog(context);
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Consumer<WalletNotifier>(
            builder: (context, walletNotifier, _) {
              final wallets = walletNotifier.wallets;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: wallets.length,
                itemBuilder: (context, index) {
                  final wallet = wallets[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: ListTile(
                      title: Text(wallet.name),
                      subtitle: Text(AppCurrency.format(wallet.balance)),
                      leading: wallet.isDefault
                          ? Icon(
                              Icons.star,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : const Icon(Icons.account_balance_wallet_outlined),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showWalletDialog(context, wallet: wallet);
                            return;
                          }
                          _confirmDeleteWallet(context, wallet);
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: Text('Chỉnh sửa'),
                          ),
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Text('Xóa'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showWalletDialog(BuildContext context, {Wallet? wallet}) async {
    final authNotifier = context.read<AuthNotifier>();
    final user = authNotifier.currentUser;

    if (user == null) {
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: wallet?.name ?? '');
    final balanceController = TextEditingController(
      text: wallet == null ? '' : wallet.balance.toStringAsFixed(0),
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(wallet == null ? 'Thêm ví mới' : 'Chỉnh sửa ví'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên ví',
                    hintText: 'Ví tiền mặt',
                  ),
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) {
                      return 'Vui lòng nhập tên ví';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: balanceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Số dư ban đầu',
                    hintText: '0',
                  ),
                  validator: (value) {
                    final parsed = double.tryParse(
                      (value ?? '').replaceAll(',', '').trim(),
                    );
                    if (parsed == null) {
                      return 'Số dư không hợp lệ';
                    }
                    if (parsed < 0) {
                      return 'Số dư phải lớn hơn hoặc bằng 0';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) {
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );

    if (result != true || !mounted) {
      nameController.dispose();
      balanceController.dispose();
      return;
    }

    final walletNotifier = context.read<WalletNotifier>();
    final balance = double.parse(
      balanceController.text.replaceAll(',', '').trim(),
    );

    if (wallet == null) {
      walletNotifier.addWallet(
        Wallet(
          id: _uuid.v4(),
          userId: user.id,
          name: nameController.text.trim(),
          balance: balance,
          createdAt: DateTime.now(),
          isDefault: walletNotifier.wallets.isEmpty,
        ),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã thêm ví mới')));
    } else {
      walletNotifier.updateWallet(
        wallet.copyWith(name: nameController.text.trim(), balance: balance),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã cập nhật ví')));
    }

    nameController.dispose();
    balanceController.dispose();
  }

  Future<void> _confirmDeleteWallet(BuildContext context, Wallet wallet) async {
    final walletNotifier = context.read<WalletNotifier>();
    final transactionNotifier = context.read<TransactionNotifier>();

    if (walletNotifier.wallets.length <= 1) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cần giữ lại ít nhất 1 ví')));
      return;
    }

    final linkedTransactions = transactionNotifier.getTransactionsByWallet(
      wallet.id,
    );
    if (linkedTransactions.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Không thể xóa ví này vì có ${linkedTransactions.length} giao dịch liên quan',
          ),
        ),
      );
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xóa ví'),
          content: Text('Bạn có chắc muốn xóa "${wallet.name}" không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    walletNotifier.deleteWallet(wallet.id);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã xóa ví')));
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cài đặt', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.lg),
          Consumer<ThemeNotifier>(
            builder: (context, themeNotifier, _) {
              return Card(
                child: ListTile(
                  title: const Text('Chế độ giao diện'),
                  subtitle: Text(themeNotifier.themeMode.label),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showThemeSelector(context, themeNotifier);
                  },
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: ListTile(
              title: const Text('Thông báo'),
              trailing: Switch(value: true, onChanged: (value) {}),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: ListTile(
              title: const Text('Về ứng dụng'),
              subtitle: const Text('Phiên bản 1.0.0'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            context.read<AuthNotifier>().logout();
            Navigator.pushReplacementNamed(context, '/login');
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Đăng xuất'),
        ),
      ),
    );
  }

  void _showThemeSelector(BuildContext context, ThemeNotifier themeNotifier) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Chế độ giao diện',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            ...AppThemeMode.values.map((mode) {
              final isSelected = themeNotifier.themeMode == mode;
              return ListTile(
                title: Text(mode.label),
                leading: Radio(
                  value: mode,
                  groupValue: themeNotifier.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      themeNotifier.setThemeMode(value);
                      Navigator.pop(context);
                    }
                  },
                ),
                onTap: () {
                  themeNotifier.setThemeMode(mode);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
