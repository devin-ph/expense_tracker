import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../models/enums.dart';

class ParsedTransactionDraft {
  final double amount;
  final TransactionType type;
  final String? note;
  final String? categoryHint;
  final DateTime? date;
  final bool needsTimeConfirmation;
  final String? confirmationQuestion;

  const ParsedTransactionDraft({
    required this.amount,
    required this.type,
    this.note,
    this.categoryHint,
    this.date,
    this.needsTimeConfirmation = false,
    this.confirmationQuestion,
  });

  ParsedTransactionDraft copyWith({
    double? amount,
    TransactionType? type,
    String? note,
    String? categoryHint,
    DateTime? date,
    bool? needsTimeConfirmation,
    String? confirmationQuestion,
  }) {
    return ParsedTransactionDraft(
      amount: amount ?? this.amount,
      type: type ?? this.type,
      note: note ?? this.note,
      categoryHint: categoryHint ?? this.categoryHint,
      date: date ?? this.date,
      needsTimeConfirmation:
          needsTimeConfirmation ?? this.needsTimeConfirmation,
      confirmationQuestion: confirmationQuestion ?? this.confirmationQuestion,
    );
  }
}

class ChatApiResponse {
  final String reply;
  final ParsedTransactionDraft? parsedTransaction;

  const ChatApiResponse({required this.reply, this.parsedTransaction});
}

class ChatApiService {
  static const String _envApiUrl = String.fromEnvironment('CHAT_API_URL');
  final String endpoint;
  final http.Client _client;

  ChatApiService({required this.endpoint, http.Client? client})
    : _client = client ?? http.Client();

  static String defaultEndpoint(TargetPlatform platform) {
    if (_envApiUrl.trim().isNotEmpty) {
      return _envApiUrl.trim();
    }
    if (kIsWeb) {
      return 'http://localhost:8000/classify_transaction';
    }
    if (platform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/classify_transaction';
    }
    return 'http://localhost:8000/classify_transaction';
  }

  Future<ChatApiResponse> sendMessage({
    required String message,
    required List<String> history,
    List<String> categories = const [],
    Map<String, dynamic> context = const {},
  }) async {
    final candidates = _candidateEndpoints(endpoint);
    final requestBodies = [
      {'text': message, 'categories': categories, 'context': context},
      {'message': message, 'history': history},
    ];

    int? lastStatusCode;
    for (final apiUrl in candidates) {
      for (final payload in requestBodies) {
        try {
          final response = await _client.post(
            Uri.parse(apiUrl),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          );

          lastStatusCode = response.statusCode;
          if (response.statusCode < 200 || response.statusCode >= 300) {
            continue;
          }

          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            final reply =
                _extractReply(decoded) ?? 'Mình đã nhận tin nhắn của bạn.';
            final fromApi =
                _parseDraftFromMap(
                  decoded['transaction'],
                  originalText: message,
                ) ??
                _parseDraftFromMap(decoded, originalText: message);

            return ChatApiResponse(
              reply: reply,
              parsedTransaction: fromApi ?? _parseDraftFromText(message),
            );
          }

          return ChatApiResponse(
            reply: decoded.toString(),
            parsedTransaction: _parseDraftFromText(message),
          );
        } catch (_) {
          continue;
        }
      }
    }

    final statusSuffix = lastStatusCode == null
        ? ''
        : ' (HTTP $lastStatusCode)';
    final endpointText = candidates.join(' | ');

    return ChatApiResponse(
      reply:
          'Không gọi được FastAPI local$statusSuffix. Kiểm tra API đang chạy và endpoint: $endpointText',
      parsedTransaction: _parseDraftFromText(message),
    );
  }

  List<String> _candidateEndpoints(String rawEndpoint) {
    final trimmed = rawEndpoint.trim();
    final values = <String>[
      trimmed,
      _replacePath(trimmed, from: '/chat', to: '/classify_transaction'),
      _replacePath(trimmed, from: '/classify_transaction', to: '/chat'),
    ];

    final unique = <String>{};
    for (final value in values) {
      if (value.isNotEmpty) {
        unique.add(value);
      }
    }
    return unique.toList();
  }

  String _replacePath(
    String endpoint, {
    required String from,
    required String to,
  }) {
    if (!endpoint.endsWith(from)) return endpoint;
    return '${endpoint.substring(0, endpoint.length - from.length)}$to';
  }

  String? _extractReply(Map<String, dynamic> data) {
    const replyKeys = ['reply', 'answer', 'response', 'message'];
    for (final key in replyKeys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  ParsedTransactionDraft? _parseDraftFromMap(
    dynamic raw, {
    required String originalText,
  }) {
    if (raw is! Map) return null;

    final map = Map<String, dynamic>.from(raw);
    final isTransaction = map['is_transaction'];
    if (isTransaction is bool && !isTransaction) {
      return null;
    }

    final amountValue = map['amount'];
    final amount = amountValue is num
        ? amountValue.toDouble()
        : double.tryParse(amountValue?.toString() ?? '');

    if (amount == null || amount <= 0) return null;

    final typeText = (map['type'] ?? originalText).toString().toLowerCase();
    final type =
        typeText.contains('income') ||
            typeText.contains('thu') ||
            typeText.contains('in')
        ? TransactionType.income
        : TransactionType.expense;

    final dateRaw = map['date']?.toString();
    final timeContext = _extractDateContext(originalText);
    final parsedDate = dateRaw == null ? null : DateTime.tryParse(dateRaw);

    return ParsedTransactionDraft(
      amount: amount,
      type: type,
      note: map['note']?.toString() ?? _extractTransactionNote(originalText),
      categoryHint: map['category']?.toString(),
      date: parsedDate ?? timeContext.date,
      needsTimeConfirmation: timeContext.needsTimeConfirmation,
      confirmationQuestion: timeContext.confirmationQuestion,
    );
  }

  ParsedTransactionDraft? _parseDraftFromText(String text) {
    final normalized = text.toLowerCase();

    final amountMatch = RegExp(
      r'(\d[\d\.,]*)\s*([a-zA-ZÀ-ỹ]+)?',
      caseSensitive: false,
    ).firstMatch(text);
    if (amountMatch == null) return null;

    final amountText = (amountMatch.group(1) ?? '').trim();
    final unitText = (amountMatch.group(2) ?? '').trim().toLowerCase();

    final amount = _parseBaseAmount(amountText);
    if (amount == null || amount <= 0) return null;

    final unitMultiplier = _unitMultiplier(unitText);
    final finalAmount = amount * unitMultiplier;

    final incomeKeywords = [
      'thu',
      'lương',
      'thưởng',
      'nhận',
      'bán',
      'kiếm',
      'income',
    ];
    final expenseKeywords = [
      'chi',
      'mua',
      'ăn',
      'uống',
      'trả',
      'đóng',
      'xăng',
      'expense',
    ];

    final isIncome = incomeKeywords.any(normalized.contains);
    final isExpense = expenseKeywords.any(normalized.contains);

    if (!isIncome && !isExpense) {
      return null;
    }

    final type = isIncome ? TransactionType.income : TransactionType.expense;

    final timeContext = _extractDateContext(text);
    return ParsedTransactionDraft(
      amount: finalAmount,
      type: type,
      note: _extractTransactionNote(text),
      categoryHint: text,
      date: timeContext.date,
      needsTimeConfirmation: timeContext.needsTimeConfirmation,
      confirmationQuestion: timeContext.confirmationQuestion,
    );
  }

  double? _parseBaseAmount(String rawAmount) {
    final compact = rawAmount.replaceAll(' ', '');
    if (compact.isEmpty) return null;

    if (RegExp(r'^\d+[\.,]\d+$').hasMatch(compact)) {
      return double.tryParse(compact.replaceAll(',', '.'));
    }

    return double.tryParse(compact.replaceAll(RegExp(r'[\.,]'), ''));
  }

  double _unitMultiplier(String unit) {
    if (unit.isEmpty) return 1;

    const thousandUnits = {'k', 'nghin', 'nghìn', 'canh', 'cành', 'lua', 'lúa'};

    const hundredThousandUnits = {'lit', 'lít'};

    if (thousandUnits.contains(unit)) return 1000;
    const millionUnits = {'cu', 'củ'};
    if (millionUnits.contains(unit)) return 1000000;
    if (hundredThousandUnits.contains(unit)) return 100000;
    return 1;
  }

  _DateContext _extractDateContext(String text) {
    final normalized = text.toLowerCase();
    final now = DateTime.now();

    final hasToday =
        normalized.contains('hôm nay') || normalized.contains('hom nay');
    final hasYesterday =
        normalized.contains('hôm qua') || normalized.contains('hom qua');

    final hourMatch = RegExp(
      r'(\d{1,2})\s*(h|giờ|gio)',
      caseSensitive: false,
    ).firstMatch(normalized);

    int? explicitHour;
    if (hourMatch != null) {
      final parsed = int.tryParse(hourMatch.group(1) ?? '');
      if (parsed != null && parsed >= 0 && parsed <= 23) {
        explicitHour = parsed;
      }
    }

    final periodHour = _periodHour(normalized);
    final selectedHour = explicitHour ?? periodHour;

    DateTime baseDate = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    );

    if (hasYesterday) {
      final yesterday = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 1));
      if (selectedHour == null) {
        return _DateContext(
          date: DateTime(yesterday.year, yesterday.month, yesterday.day, 12),
          needsTimeConfirmation: true,
          confirmationQuestion:
              'Bạn nhắc “hôm qua”, bạn có nhớ thời gian cụ thể không (ví dụ 9h, buổi trưa, chiều, chiều tối) trước khi mình lưu?',
        );
      }

      return _DateContext(
        date: DateTime(
          yesterday.year,
          yesterday.month,
          yesterday.day,
          selectedHour,
        ),
      );
    }

    if (hasToday) {
      final today = DateTime(now.year, now.month, now.day);
      return _DateContext(
        date: DateTime(
          today.year,
          today.month,
          today.day,
          selectedHour ?? now.hour,
          selectedHour == null ? now.minute : 0,
        ),
      );
    }

    if (selectedHour != null) {
      final today = DateTime(now.year, now.month, now.day);
      return _DateContext(
        date: DateTime(today.year, today.month, today.day, selectedHour),
      );
    }

    return _DateContext(date: baseDate);
  }

  int? _periodHour(String normalized) {
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
    return null;
  }

  String _extractTransactionNote(String text) {
    var cleaned = text.trim();

    cleaned = cleaned.replaceAll(
      RegExp(
        r'\b(hôm nay|hom nay|hôm qua|hom qua|buổi trưa|buoi trua|trưa|trua|chiều tối|chieu toi|chiều|chieu)\b',
        caseSensitive: false,
      ),
      ' ',
    );

    cleaned = cleaned.replaceAll(
      RegExp(
        r'\d[\d\.,]*\s*(k|nghin|nghìn|canh|cành|lua|lúa|cu|củ|lit|lít|h|giờ|gio)?',
        caseSensitive: false,
      ),
      ' ',
    );

    cleaned = cleaned.replaceAll(
      RegExp(
        r'\b(tôi|toi|mình|minh|em|anh|chị|chi|vừa|moi|mới|đã|da|hết|het|mất|mat|chi|thu|nhập|nhap)\b',
        caseSensitive: false,
      ),
      ' ',
    );

    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned.isEmpty ? text.trim() : cleaned;
  }
}

class _DateContext {
  final DateTime date;
  final bool needsTimeConfirmation;
  final String? confirmationQuestion;

  const _DateContext({
    required this.date,
    this.needsTimeConfirmation = false,
    this.confirmationQuestion,
  });
}
