import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../config/constants.dart';
import '../models/index.dart';
import '../providers/index.dart';
import '../services/chat_api_service.dart';

class FloatingChatOverlay extends StatefulWidget {
  const FloatingChatOverlay({super.key});

  @override
  State<FloatingChatOverlay> createState() => _FloatingChatOverlayState();
}

class _FloatingChatOverlayState extends State<FloatingChatOverlay> {
  static const Map<String, List<String>> _expenseCategoryOptions = {
    'cat1': [
      'Tiền thuê nhà/ Trả góp mua nhà',
      'Điện, nước, internet, truyền hình',
      'Phí bảo hiểm (y tế, xe, nhà)',
      'Học phí/ Phí dịch vụ định kỳ',
      'Thẻ tín dụng',
      'Khác',
    ],
    'cat2': [
      'Thực phẩm, nhu yếu phẩm',
      'Xăng xe, vé xe buýt...',
      'Quần áo cơ bản, giày dép',
      'Khám sức khỏe định kỳ',
      'Dụng cụ sinh hoạt',
      'Khác',
    ],
    'cat3': [
      'Quà tặng cho bạn bè/người thân',
      'Tiệc cưới, sinh nhật, lễ hội',
      'Sửa chữa đồ dùng hỏng hóc',
      'Đóng góp xã hội, từ thiện',
      'Khác',
    ],
    'cat4': [
      'Chi phí y tế khẩn cấp',
      'Hỗ trợ tài chính cho người thân',
      'Thiên tai hoặc sự cố bất khả kháng',
      'Khác',
    ],
    'cat5': [
      'Ăn uống ngoài, cà phê',
      'Du lịch, nghỉ dưỡng',
      'Mua sắm',
      'Giải trí: xem phim, concert, thể thao...',
      'Sở thích cá nhân',
      'Khác',
    ],
  };

  static const Map<String, List<String>> _incomeCategoryOptions = {
    'cat_income': ['Lương tháng', 'Lương làm thêm', 'Phụ cấp', 'Khác'],
    'cat_bonus': ['Thưởng hiệu suất', 'Thưởng lễ/tết', 'Hoa hồng', 'Khác'],
  };

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  final Set<String> _recentSavedFingerprints = <String>{};

  bool _isOpen = false;
  bool _isSending = false;
  bool _serviceReady = false;
  bool _showQuickHint = false;
  ParsedTransactionDraft? _pendingTimeDraft;
  Timer? _hintCycleTimer;
  Timer? _hintHideTimer;
  late ChatApiService _chatApiService;

  @override
  void initState() {
    super.initState();
    _chatApiService = ChatApiService(endpoint: 'http://localhost:8000/chat');

    _messages.add(
      const _ChatMessage(
        text: 'Xin chào! Bạn có thể chat và nhập giao dịch trực tiếp ở đây.',
        role: _ChatRole.assistant,
      ),
    );

    _startQuickHintLoop();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_serviceReady) return;

    _chatApiService = ChatApiService(
      endpoint: ChatApiService.defaultEndpoint(Theme.of(context).platform),
    );
    _serviceReady = true;
  }

  @override
  void dispose() {
    _hintCycleTimer?.cancel();
    _hintHideTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _isOpen
          ? Material(
              key: const ValueKey('chat_open'),
              elevation: 8,
              borderRadius: BorderRadius.circular(AppBorderRadius.xl),
              color: theme.cardColor,
              child: SizedBox(
                width: 340,
                height: 460,
                child: Column(
                  children: [
                    _buildHeader(theme),
                    const Divider(height: 1),
                    Expanded(child: _buildMessages(theme)),
                    _buildComposer(theme),
                  ],
                ),
              ),
            )
          : Column(
              key: const ValueKey('chat_closed'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AnimatedOpacity(
                  opacity: _showQuickHint ? 1 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: IgnorePointer(
                    ignoring: true,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Chat nhanh để lưu giao dịch',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      _isOpen = true;
                      _showQuickHint = false;
                    });
                  },
                  child: const Icon(Icons.chat_bubble_outline),
                ),
              ],
            ),
    );
  }

  void _startQuickHintLoop() {
    _hintCycleTimer?.cancel();
    _hintHideTimer?.cancel();

    _showQuickHintNow();

    _hintCycleTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _showQuickHintNow();
    });
  }

  void _showQuickHintNow() {
    if (!mounted || _isOpen) return;

    setState(() {
      _showQuickHint = true;
    });

    _hintHideTimer?.cancel();
    _hintHideTimer = Timer(const Duration(seconds: 8), () {
      if (!mounted || _isOpen) return;
      setState(() {
        _showQuickHint = false;
      });
    });
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Chat trợ lý',
              style: theme.textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _isOpen = false),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages(ThemeData theme) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isUser = message.role == _ChatRole.user;

        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            constraints: const BoxConstraints(maxWidth: 260),
            decoration: BoxDecoration(
              color: isUser
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            ),
            child: Text(message.text, style: theme.textTheme.bodyMedium),
          ),
        );
      },
    );
  }

  Widget _buildComposer(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !_isSending,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Nhập tin nhắn hoặc giao dịch...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                ),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            onPressed: _isSending ? null : _sendMessage,
            icon: _isSending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final message = _controller.text.trim();
    if (message.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _messages.add(_ChatMessage(text: message, role: _ChatRole.user));
      _controller.clear();
    });
    _scrollToBottom();

    if (_pendingTimeDraft != null) {
      _handlePendingTimeResponse(message);
      return;
    }

    final localReply = _buildSystemInsightReply(message);
    if (localReply != null) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatMessage(text: localReply, role: _ChatRole.assistant),
        );
        _isSending = false;
      });
      _scrollToBottom();
      return;
    }

    final categoryNotifier = context.read<CategoryNotifier>();
    final categories = categoryNotifier.categories
        .map((item) => item.name)
        .toList();

    final chatContext = _shouldAttachFinancialContext(message)
        ? _buildChatSystemContext(categoryNotifier: categoryNotifier)
        : const <String, dynamic>{};

    final response = await _chatApiService.sendMessage(
      message: message,
      history: _messages.map((item) => item.text).toList(),
      categories: categories,
      context: chatContext,
    );

    if (!mounted) return;

    setState(() {
      _messages.add(
        _ChatMessage(text: response.reply, role: _ChatRole.assistant),
      );
      _isSending = false;
    });

    final hasTransactionIntent = _isLikelyTransactionIntent(message);
    final draft = hasTransactionIntent ? response.parsedTransaction : null;
    if (draft != null && draft.needsTimeConfirmation) {
      _pendingTimeDraft = draft;
      setState(() {
        _messages.add(
          _ChatMessage(
            text:
                draft.confirmationQuestion ??
                'Bạn có nhớ thời gian cụ thể không trước khi mình lưu giao dịch hôm qua?',
            role: _ChatRole.assistant,
          ),
        );
      });
      _scrollToBottom();
      return;
    }

    final savedTransaction = _saveTransactionIfDetected(draft);
    if (savedTransaction != null && mounted) {
      final category = context.read<CategoryNotifier>().getCategoryById(
        savedTransaction.categoryId,
      );

      setState(() {
        _messages.add(
          _ChatMessage(
            text:
                'Đã lưu ${savedTransaction.type == TransactionType.income ? 'thu nhập' : 'chi tiêu'} ${AppCurrency.format(savedTransaction.amount)} (${category?.name ?? 'khác'}).',
            role: _ChatRole.system,
          ),
        );
      });
    }

    _scrollToBottom();
  }

  bool _isLikelyTransactionIntent(String input) {
    final normalized = input.toLowerCase().trim();
    if (normalized.isEmpty) return false;

    const exampleKeywords = [
      'ví dụ',
      'vi du',
      'chẳng hạn',
      'chang han',
      'vd',
      'example',
    ];
    if (exampleKeywords.any(normalized.contains)) {
      return false;
    }

    final hasAmount = RegExp(
      r'(\d[\d\.,]*)\s*(k|nghin|nghìn|canh|cành|lua|lúa|lit|lít|cu|củ|tr|triệu|trieu)?',
      caseSensitive: false,
    ).hasMatch(normalized);

    const transactionKeywords = [
      'chi',
      'mua',
      'ăn',
      'an ',
      'uống',
      'uong',
      'trả',
      'tra ',
      'đóng',
      'dong ',
      'thu',
      'lương',
      'luong',
      'thưởng',
      'thuong',
      'nhận',
      'nhan ',
      'bán',
      'ban ',
      'kiếm',
      'kiem ',
    ];
    final hasTransactionVerb = transactionKeywords.any(normalized.contains);

    return hasAmount && hasTransactionVerb;
  }

  bool _shouldAttachFinancialContext(String input) {
    final normalized = input.toLowerCase().trim();
    if (normalized.isEmpty) return false;

    final greetingOnly = RegExp(
      r'^(hi|hello|hey|alo|xin chào|chào|chao|ok|oke|okay|thanks|thank you|cảm ơn|cam on)[!,. ]*$',
      caseSensitive: false,
    );
    if (greetingOnly.hasMatch(normalized)) {
      return false;
    }

    const financeKeywords = [
      'số dư',
      'so du',
      'bao nhiêu tiền',
      'bao nhieu tien',
      'hạn mức',
      'han muc',
      'chi tiêu',
      'chi tieu',
      'thu nhập',
      'thu nhap',
      'giao dịch',
      'giao dich',
      'ví',
      'vi ',
      'mua',
      'chi ',
      'thu ',
      'nhận',
      'nhan ',
    ];

    return _isLikelyTransactionIntent(normalized) ||
        financeKeywords.any(normalized.contains);
  }

  void _handlePendingTimeResponse(String userMessage) {
    final pending = _pendingTimeDraft;
    if (pending == null) {
      if (!mounted) return;
      setState(() => _isSending = false);
      return;
    }

    final normalized = userMessage.toLowerCase();
    final cancelKeywords = ['hủy', 'huy', 'bỏ qua', 'bo qua', 'thôi', 'thoi'];
    if (cancelKeywords.any(normalized.contains)) {
      _pendingTimeDraft = null;
      if (!mounted) return;
      setState(() {
        _messages.add(
          const _ChatMessage(
            text: 'Đã hủy lưu giao dịch vừa rồi.',
            role: _ChatRole.system,
          ),
        );
        _isSending = false;
      });
      _scrollToBottom();
      return;
    }

    final resolvedHour = _resolveHourFromMessage(userMessage);
    if (resolvedHour == null) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          const _ChatMessage(
            text:
                'Mình chưa nhận ra giờ cụ thể. Bạn có thể nói dạng “9h”, “buổi trưa”, “chiều”, hoặc “chiều tối” nhé.',
            role: _ChatRole.assistant,
          ),
        );
        _isSending = false;
      });
      _scrollToBottom();
      return;
    }

    final base =
        pending.date ?? DateTime.now().subtract(const Duration(days: 1));
    final effectiveHour = resolvedHour == -1 ? 12 : resolvedHour;
    final updatedDraft = pending.copyWith(
      date: DateTime(base.year, base.month, base.day, effectiveHour),
      needsTimeConfirmation: false,
      confirmationQuestion: null,
      note: pending.note ?? userMessage,
    );

    _pendingTimeDraft = null;
    final saved = _saveTransactionIfDetected(updatedDraft);

    if (!mounted) return;
    setState(() {
      if (saved != null) {
        _messages.add(
          _ChatMessage(
            text:
                'Đã lưu giao dịch hôm qua lúc ${effectiveHour.toString().padLeft(2, '0')}:00.',
            role: _ChatRole.system,
          ),
        );
      } else {
        _messages.add(
          const _ChatMessage(
            text: 'Giao dịch này đã có rồi, mình không lưu trùng nữa.',
            role: _ChatRole.system,
          ),
        );
      }
      _isSending = false;
    });
    _scrollToBottom();
  }

  int? _resolveHourFromMessage(String input) {
    final normalized = input.toLowerCase();
    final hourMatch = RegExp(
      r'(\d{1,2})\s*(h|giờ|gio)',
      caseSensitive: false,
    ).firstMatch(normalized);

    if (hourMatch != null) {
      final parsed = int.tryParse(hourMatch.group(1) ?? '');
      if (parsed != null && parsed >= 0 && parsed <= 23) {
        return parsed;
      }
    }

    if (normalized.contains('chiều tối') || normalized.contains('chieu toi')) {
      return 19;
    }
    if (normalized.contains('buổi trưa') ||
        normalized.contains('buoi trua') ||
        normalized.contains('trưa') ||
        normalized.contains('trua')) {
      return 12;
    }
    if (normalized.contains('chiều') || normalized.contains('chieu')) {
      return 13;
    }

    final unknownKeywords = ['không nhớ', 'khong nho', 'ko nhớ', 'ko nho'];
    if (unknownKeywords.any(normalized.contains)) {
      return -1;
    }

    return null;
  }

  String? _buildSystemInsightReply(String message) {
    final normalized = message.toLowerCase();

    final asksBalance = [
      'còn bao nhiêu tiền',
      'con bao nhieu tien',
      'số dư',
      'so du',
      'bao nhiêu tiền',
      'bao nhieu tien',
    ].any(normalized.contains);

    if (asksBalance) {
      final walletNotifier = context.read<WalletNotifier>();
      final selected = walletNotifier.selectedWallet;
      final selectedBalance = selected?.balance ?? 0;
      final totalBalance = walletNotifier.wallets.fold<double>(
        0,
        (sum, item) => sum + item.balance,
      );
      return 'Số dư ví đang chọn: ${AppCurrency.format(selectedBalance)}. Tổng tất cả ví: ${AppCurrency.format(totalBalance)}.';
    }

    final asksMonthExpense = [
      'tháng này tiêu',
      'thang nay tieu',
      'tháng này chi',
      'thang nay chi',
      'chi tháng này',
      'chi thang nay',
    ].any(normalized.contains);

    if (asksMonthExpense) {
      final transactionNotifier = context.read<TransactionNotifier>();
      final now = DateTime.now();
      final monthExpense = transactionNotifier.transactions
          .where(
            (t) =>
                t.type == TransactionType.expense &&
                t.date.year == now.year &&
                t.date.month == now.month,
          )
          .fold<double>(0, (sum, item) => sum + item.amount);

      return 'Tổng chi tiêu tháng này của bạn là ${AppCurrency.format(monthExpense)}.';
    }

    final asksTodayExpense = [
      'hôm nay đã chi',
      'hom nay da chi',
      'hôm nay chi bao nhiêu',
      'hom nay chi bao nhieu',
      'chi hôm nay',
      'chi hom nay',
    ].any(normalized.contains);

    if (asksTodayExpense) {
      final transactionNotifier = context.read<TransactionNotifier>();
      final walletId = context.read<WalletNotifier>().selectedWallet?.id;
      final todayExpense = transactionNotifier
          .getTodayTransactions(walletId: walletId)
          .where((t) => t.type == TransactionType.expense)
          .fold<double>(0, (sum, item) => sum + item.amount);

      return 'Hôm nay bạn đã chi ${AppCurrency.format(todayExpense)}.';
    }

    final asksLimitRemaining = [
      'hạn mức còn lại',
      'han muc con lai',
      'còn lại hạn mức',
      'con lai han muc',
      'hạn mức',
      'han muc',
    ].any(normalized.contains);

    if (asksLimitRemaining) {
      final limitNotifier = context.read<SpendingLimitNotifier>();
      final transactionNotifier = context.read<TransactionNotifier>();
      final categoryNotifier = context.read<CategoryNotifier>();
      final walletId = context.read<WalletNotifier>().selectedWallet?.id;

      if (limitNotifier.limits.isEmpty) {
        return 'Hiện chưa có hạn mức chi tiêu nào. Bạn có thể thêm trong màn hình Trang chủ.';
      }

      final monthStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
      final monthEnd = DateTime(
        DateTime.now().year,
        DateTime.now().month + 1,
        0,
      );

      final rows = <String>[];
      for (final limit in limitNotifier.limits) {
        final category = categoryNotifier.getCategoryById(limit.categoryId);
        final effectiveStart =
            limit.lastResetAt != null && limit.lastResetAt!.isAfter(monthStart)
            ? limit.lastResetAt!
            : monthStart;
        final spent = transactionNotifier
            .getTransactionsByDateRange(
              effectiveStart,
              monthEnd,
              walletId: walletId,
            )
            .where(
              (t) =>
                  t.categoryId == limit.categoryId &&
                  t.type == TransactionType.expense,
            )
            .fold<double>(0, (sum, item) => sum + item.amount);

        final remaining = limit.limitAmount - spent;
        final categoryName = category?.name ?? 'Danh mục';
        rows.add(
          '$categoryName: tổng ${AppCurrency.format(limit.limitAmount)}, còn ${AppCurrency.format(remaining < 0 ? 0 : remaining)}',
        );
      }

      return 'Hạn mức tháng này: ${rows.join('; ')}.';
    }

    final asksDetailedInfo = [
      'chi tiết',
      'chi tiet',
      'phân tích',
      'phan tich',
      'xem sâu',
      'xem sau',
    ].any(normalized.contains);

    if (asksDetailedInfo) {
      return 'Bạn có thể vào tab Thống kê để xem chi tiết hơn theo ngày, tháng và danh mục.';
    }

    return null;
  }

  Map<String, dynamic> _buildChatSystemContext({
    required CategoryNotifier categoryNotifier,
  }) {
    final walletNotifier = context.read<WalletNotifier>();
    final transactionNotifier = context.read<TransactionNotifier>();
    final limitNotifier = context.read<SpendingLimitNotifier>();

    final selectedWallet = walletNotifier.selectedWallet;
    final selectedWalletId = selectedWallet?.id;

    final todayExpense = transactionNotifier
        .getTodayTransactions(walletId: selectedWalletId)
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0, (sum, item) => sum + item.amount);

    final monthStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final monthEnd = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

    final categoryLimits = limitNotifier.limits.map((limit) {
      final category = categoryNotifier.getCategoryById(limit.categoryId);
      final effectiveStart =
          limit.lastResetAt != null && limit.lastResetAt!.isAfter(monthStart)
          ? limit.lastResetAt!
          : monthStart;
      final spent = transactionNotifier
          .getTransactionsByDateRange(
            effectiveStart,
            monthEnd,
            walletId: selectedWalletId,
          )
          .where(
            (t) =>
                t.categoryId == limit.categoryId &&
                t.type == TransactionType.expense,
          )
          .fold<double>(0, (sum, item) => sum + item.amount);

      final remaining = limit.limitAmount - spent;
      return {
        'category': category?.name ?? 'Danh mục',
        'total_limit': limit.limitAmount,
        'remaining': remaining < 0 ? 0 : remaining,
      };
    }).toList();

    final categoryCatalog = categoryNotifier.categories.map((category) {
      final options = category.type == TransactionType.expense
          ? (_expenseCategoryOptions[category.id] ?? const <String>[])
          : (_incomeCategoryOptions[category.id] ?? const <String>[]);
      return {
        'id': category.id,
        'name': category.name,
        'type': category.type.name,
        'detail_options': options,
      };
    }).toList();

    return {
      'selected_wallet_balance': selectedWallet?.balance ?? 0,
      'total_balance': walletNotifier.wallets.fold<double>(
        0,
        (sum, item) => sum + item.balance,
      ),
      'today_expense': todayExpense,
      'category_limits': categoryLimits,
      'category_catalog': categoryCatalog,
    };
  }

  Transaction? _saveTransactionIfDetected(ParsedTransactionDraft? draft) {
    if (draft == null) return null;

    final walletNotifier = context.read<WalletNotifier>();
    final categoryNotifier = context.read<CategoryNotifier>();
    final authNotifier = context.read<AuthNotifier>();

    final wallet =
        walletNotifier.selectedWallet ??
        (walletNotifier.wallets.isNotEmpty
            ? walletNotifier.wallets.first
            : null);
    if (wallet == null) return null;

    final categories = categoryNotifier.getCategoriesByType(draft.type);
    if (categories.isEmpty) return null;

    final hint = (draft.categoryHint ?? '').toLowerCase();
    final categoryName = (draft.categoryName ?? '').toLowerCase().trim();
    final categoryDetail = (draft.categoryDetail ?? '').toLowerCase().trim();
    final note = (draft.note ?? '').toLowerCase().trim();
    final combinedText = _normalizeForMatching(
      '$categoryName $categoryDetail $note $hint',
    );

    final inferredCategoryId = draft.type == TransactionType.expense
        ? _inferExpenseCategoryId(combinedText)
        : null;

    Category chosenCategory = categories.first;
    if (inferredCategoryId != null) {
      final byRule = categories.where((item) => item.id == inferredCategoryId);
      if (byRule.isNotEmpty) {
        chosenCategory = byRule.first;
      }
    }

    for (final category in categories) {
      final categoryLower = category.name.toLowerCase();
      final exactNameMatched =
          categoryName.isNotEmpty &&
          (categoryLower == categoryName ||
              categoryLower.contains(categoryName) ||
              categoryName.contains(categoryLower));
      final hintMatched = hint.contains(categoryLower);
      if (inferredCategoryId != null && category.id != inferredCategoryId) {
        continue;
      }

      if (exactNameMatched || hintMatched) {
        chosenCategory = category;
        break;
      }
    }

    final contentText = (draft.note ?? '').trim();
    final detailText = _resolveCategoryDetail(
      categoryId: chosenCategory.id,
      draftDetail: draft.categoryDetail,
      textForInference: combinedText,
    );
    final composedNote = () {
      if (detailText.isEmpty && contentText.isEmpty) return null;
      if (detailText.isEmpty) return contentText;
      if (contentText.isEmpty) return detailText;
      return '$detailText | $contentText';
    }();

    final now = DateTime.now();
    final transactionDate = draft.date ?? now;
    final transaction = Transaction(
      id: const Uuid().v4(),
      userId: authNotifier.currentUser?.id ?? wallet.userId,
      walletId: wallet.id,
      categoryId: chosenCategory.id,
      type: draft.type,
      amount: draft.amount,
      note: composedNote,
      date: transactionDate,
      createdAt: now,
    );

    final fingerprint = _buildFingerprint(transaction);
    if (_recentSavedFingerprints.contains(fingerprint)) {
      return null;
    }

    final alreadyExists = context.read<TransactionNotifier>().transactions.any((
      t,
    ) {
      return _buildFingerprint(t) == fingerprint;
    });

    if (alreadyExists) {
      return null;
    }

    context.read<TransactionNotifier>().addTransaction(transaction);
    _recentSavedFingerprints.add(fingerprint);

    final newBalance = transaction.type == TransactionType.income
        ? wallet.balance + transaction.amount
        : wallet.balance - transaction.amount;

    walletNotifier.updateWallet(wallet.copyWith(balance: newBalance));
    return transaction;
  }

  String _normalizeForMatching(String value) {
    return value
        .toLowerCase()
        .replaceAll('đ', 'd')
        .replaceAll(RegExp(r'[^a-z0-9à-ỹ\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String? _inferExpenseCategoryId(String normalizedText) {
    const essentialFoodKeywords = [
      'an ',
      'an uong',
      'uong',
      'com',
      'bun',
      'pho',
      'do an',
      'thuc pham',
      'nhu yeu pham',
      'sieu thi',
      'cho',
      'tap hoa',
      'do sieu thi',
      'groceries',
      'food',
    ];

    const transportKeywords = ['xang', 'xe buyt', 'grab', 'taxi', 'di lai'];
    const clothingKeywords = ['quan ao', 'giay dep', 'quan', 'ao', 'giay'];
    const healthKeywords = ['kham', 'benh vien', 'thuoc', 'y te'];
    const emergencyKeywords = ['khan cap', 'cap cuu', 'thien tai', 'su co'];
    const fixedKeywords = [
      'tien nha',
      'thue nha',
      'dien',
      'nuoc',
      'internet',
      'bao hiem',
      'hoc phi',
      'tra gop',
      'the tin dung',
    ];

    bool hasAny(List<String> keywords) =>
        keywords.any((item) => normalizedText.contains(item));

    if (hasAny(essentialFoodKeywords) ||
        hasAny(transportKeywords) ||
        hasAny(clothingKeywords) ||
        hasAny(healthKeywords)) {
      return 'cat2';
    }
    if (hasAny(fixedKeywords)) return 'cat1';
    if (hasAny(emergencyKeywords)) return 'cat4';

    return null;
  }

  String _resolveCategoryDetail({
    required String categoryId,
    required String? draftDetail,
    required String textForInference,
  }) {
    final normalizedDetail = _normalizeForMatching(draftDetail ?? '');
    final options =
        _expenseCategoryOptions[categoryId] ??
        _incomeCategoryOptions[categoryId] ??
        const <String>[];

    for (final option in options) {
      final optionNormalized = _normalizeForMatching(option);
      if (optionNormalized.isNotEmpty &&
          (normalizedDetail == optionNormalized ||
              normalizedDetail.contains(optionNormalized) ||
              optionNormalized.contains(normalizedDetail))) {
        return option;
      }
    }

    if (categoryId == 'cat2') {
      if (RegExp(
        r'\b(an|uong|com|bun|pho|thuc pham|nhu yeu pham|sieu thi|tap hoa|food|groceries)\b',
      ).hasMatch(textForInference)) {
        return 'Thực phẩm, nhu yếu phẩm';
      }
      if (RegExp(
        r'\b(xang|xe buyt|grab|taxi|di lai)\b',
      ).hasMatch(textForInference)) {
        return 'Xăng xe, vé xe buýt...';
      }
      if (RegExp(
        r'\b(quan ao|giay dep|mua ao|mua quan|mua giay)\b',
      ).hasMatch(textForInference)) {
        return 'Quần áo cơ bản, giày dép';
      }
      if (RegExp(
        r'\b(kham|benh vien|thuoc|y te)\b',
      ).hasMatch(textForInference)) {
        return 'Khám sức khỏe định kỳ';
      }
      return 'Khác';
    }

    if (draftDetail != null && draftDetail.trim().isNotEmpty) {
      return draftDetail.trim();
    }

    return options.isNotEmpty ? options.first : '';
  }

  String _buildFingerprint(Transaction transaction) {
    final dayKey =
        '${transaction.date.year}-${transaction.date.month}-${transaction.date.day}';
    final noteKey = (transaction.note ?? '').trim().toLowerCase();
    return '${transaction.walletId}|${transaction.categoryId}|${transaction.type.name}|${transaction.amount.toStringAsFixed(0)}|$dayKey|$noteKey';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }
}

enum _ChatRole { user, assistant, system }

class _ChatMessage {
  final String text;
  final _ChatRole role;

  const _ChatMessage({required this.text, required this.role});
}
