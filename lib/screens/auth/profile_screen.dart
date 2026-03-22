import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/index.dart';
import '../../providers/index.dart';
import '../../config/constants.dart';
import 'dialogs/edit_profile_dialog.dart';

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
      appBar: AppBar(title: const Text('Tài khoản'), elevation: 0),
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
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfileHeader(user),
                  const SizedBox(height: AppSpacing.xxl),
                  _buildUserCard(user),
                  const SizedBox(height: AppSpacing.xl),
                  ElevatedButton.icon(
                    onPressed: () => _showEditProfileDialog(context, user),
                    icon: const Icon(Icons.edit),
                    label: const Text('Chỉnh sửa thông tin'),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _buildWalletSection(context),
                  const SizedBox(height: AppSpacing.xl),
                  _buildSettingsSection(context),
                  const SizedBox(height: AppSpacing.xl),
                  _buildLogoutButton(context),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(User user) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).primaryColor, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _buildAvatarContent(user),
        ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: Text(
            user.name,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: Text(
            user.email,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarContent(User user) {
    if (user.photoUrl != null && user.photoUrl!.isNotEmpty) {
      if (user.photoUrl!.startsWith('/') ||
          user.photoUrl!.startsWith('file://')) {
        try {
          return ClipOval(
            child: Image.file(
              File(user.photoUrl!),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildDefaultAvatar(user);
              },
            ),
          );
        } catch (e) {
          return _buildDefaultAvatar(user);
        }
      } else {
        return ClipOval(
          child: Image.network(
            user.photoUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultAvatar(user);
            },
          ),
        );
      }
    }
    return _buildDefaultAvatar(user);
  }

  Widget _buildDefaultAvatar(User user) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.7),
          ],
        ),
      ),
      child: Center(
        child: Text(
          user.name[0].toUpperCase(),
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(User user) {
    final theme = Theme.of(context);
    final surfaceColor = theme.brightness == Brightness.dark
        ? Colors.grey[850]
        : Colors.grey[100];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin cá nhân',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildInfoRow('Tên', user.name),
          const SizedBox(height: AppSpacing.md),
          _buildInfoRow('Email', user.email),
          const SizedBox(height: AppSpacing.md),
          _buildInfoRow('Ngày tạo tài khoản', _formatDate(user.createdAt)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildWalletSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
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
                  _showAddWalletDialog(context);
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
                  final canDelete = wallets.length > 1;
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: ListTile(
                      title: Text(wallet.name),
                      subtitle: Text(AppCurrency.format(wallet.balance)),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') {
                            _showEditWalletDialog(context, wallet);
                            return;
                          }

                          if (!canDelete) {
                            return;
                          }

                          final shouldDelete =
                              await _showDeleteWalletConfirmDialog(
                                context,
                                wallet.name,
                              );
                          if (!shouldDelete || !mounted) {
                            return;
                          }

                          walletNotifier.deleteWallet(wallet.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã xóa ví')),
                          );
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: Text('Chỉnh sửa'),
                          ),
                          PopupMenuItem<String>(
                            value: 'delete',
                            enabled: canDelete,
                            child: Text(
                              canDelete ? 'Xóa' : 'Xóa (cần ít nhất 2 ví)',
                            ),
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

  Widget _buildSettingsSection(BuildContext context) {
    return Column(
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
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Đăng xuất'),
              content: const Text('Bạn chắc chắn muốn đăng xuất?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                TextButton(
                  onPressed: () {
                    context.read<AuthNotifier>().logout();
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: const Text(
                    'Đăng xuất',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );
        },
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
        child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
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

  void _showEditProfileDialog(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (context) => EditProfileDialog(user: user),
    );
  }

  Future<void> _showAddWalletDialog(BuildContext context) async {
    final user = context.read<AuthNotifier>().currentUser;
    if (user == null || user.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không xác định được tài khoản hiện tại')),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final balanceController = TextEditingController(text: '0');
    final messenger = ScaffoldMessenger.of(context);
    final walletNotifier = context.read<WalletNotifier>();

    final result = await showDialog<_AddWalletResult>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Thêm ví mới'),
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
                    if ((value ?? '').trim().isEmpty) {
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
                  decoration: const InputDecoration(labelText: 'Số dư ban đầu'),
                  validator: (value) {
                    final parsed = double.tryParse(
                      (value ?? '').replaceAll(',', '').trim(),
                    );
                    if (parsed == null) {
                      return 'Số dư không hợp lệ';
                    }
                    if (parsed < 0) {
                      return 'Số dư phải >= 0';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) {
                  return;
                }
                final parsedBalance = double.parse(
                  balanceController.text.replaceAll(',', '').trim(),
                );
                Navigator.pop(
                  dialogContext,
                  _AddWalletResult(
                    name: nameController.text.trim(),
                    balance: parsedBalance,
                  ),
                );
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );

    if (result == null || !mounted) {
      nameController.dispose();
      balanceController.dispose();
      return;
    }

    try {
      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;

      walletNotifier.addWallet(
        Wallet(
          id: _uuid.v4(),
          userId: user.id,
          name: result.name,
          balance: result.balance,
          createdAt: DateTime.now(),
          isDefault: walletNotifier.wallets.isEmpty,
        ),
      );
    } catch (e) {
      nameController.dispose();
      balanceController.dispose();
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Lưu ví thất bại: $e')));
      return;
    }

    nameController.dispose();
    balanceController.dispose();

    messenger.showSnackBar(const SnackBar(content: Text('Đã thêm ví mới')));
  }

  Future<void> _showEditWalletDialog(
    BuildContext context,
    Wallet wallet,
  ) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: wallet.name);
    final balanceController = TextEditingController(
      text: wallet.balance.toStringAsFixed(0),
    );
    final messenger = ScaffoldMessenger.of(context);
    final walletNotifier = context.read<WalletNotifier>();

    final result = await showDialog<_AddWalletResult>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Chỉnh sửa ví'),
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
                    if ((value ?? '').trim().isEmpty) {
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
                    labelText: 'Số dư hiện tại',
                  ),
                  validator: (value) {
                    final parsed = double.tryParse(
                      (value ?? '').replaceAll(',', '').trim(),
                    );
                    if (parsed == null) {
                      return 'Số dư không hợp lệ';
                    }
                    if (parsed < 0) {
                      return 'Số dư phải >= 0';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) {
                  return;
                }
                final parsedBalance = double.parse(
                  balanceController.text.replaceAll(',', '').trim(),
                );
                Navigator.pop(
                  dialogContext,
                  _AddWalletResult(
                    name: nameController.text.trim(),
                    balance: parsedBalance,
                  ),
                );
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );

    if (result == null || !mounted) {
      nameController.dispose();
      balanceController.dispose();
      return;
    }

    try {
      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;

      walletNotifier.updateWallet(
        wallet.copyWith(name: result.name, balance: result.balance),
      );
    } catch (e) {
      nameController.dispose();
      balanceController.dispose();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Cập nhật ví thất bại: $e')),
      );
      return;
    }

    nameController.dispose();
    balanceController.dispose();

    messenger.showSnackBar(const SnackBar(content: Text('Đã cập nhật ví')));
  }

  Future<bool> _showDeleteWalletConfirmDialog(
    BuildContext context,
    String walletName,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận xóa ví'),
          content: Text('Bạn có chắc muốn xóa ví "$walletName" không?'),
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

    return result ?? false;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _AddWalletResult {
  final String name;
  final double balance;

  const _AddWalletResult({required this.name, required this.balance});
}
