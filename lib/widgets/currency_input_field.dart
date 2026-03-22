import 'package:flutter/material.dart';

/// Currency input field widget
class CurrencyInputField extends StatefulWidget {
  final TextEditingController controller;
  final String Label;
  final String? hintText;
  final VoidCallback? onChanged;
  final FormFieldValidator<String>? validator;
  final bool isExpense;

  const CurrencyInputField({
    super.key,
    required this.controller,
    required this.Label,
    this.hintText,
    this.onChanged,
    this.validator,
    this.isExpense = true,
  });

  @override
  State<CurrencyInputField> createState() => _CurrencyInputFieldState();
}

class _CurrencyInputFieldState extends State<CurrencyInputField> {
  String _formatCurrency(String value) {
    if (value.isEmpty) return '';
    final numericValue = value.replaceAll(RegExp(r'[^\d]'), '');
    if (numericValue.isEmpty) return '';
    final number = int.parse(numericValue);
    return '${number.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}')} ₫';
  }

  String _getNumericValue(String formattedValue) {
    return formattedValue.replaceAll(RegExp(r'[^\d]'), '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.Label, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: widget.hintText ?? '0 ₫',
            suffixText: '₫',
            filled: true,
            fillColor: widget.isExpense
                ? Colors.red.withOpacity(0.05)
                : Colors.green.withOpacity(0.05),
          ),
          onChanged: (value) {
            if (value.isNotEmpty && value != '₫') {
              final numericValue = _getNumericValue(value);
              widget.controller.value = TextEditingValue(
                text: _formatCurrency(numericValue),
                selection: TextSelection.fromPosition(
                  TextPosition(
                    offset: _formatCurrency(numericValue).length - 2,
                  ),
                ),
              );
            }
            widget.onChanged?.call();
          },
          validator: widget.validator,
        ),
      ],
    );
  }
}
