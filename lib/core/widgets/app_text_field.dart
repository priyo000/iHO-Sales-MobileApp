import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

enum AppTextFieldType { text, email, password, phone, number, multiline, search }

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.type = AppTextFieldType.text,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.prefixIcon,
    this.suffix,
    this.maxLength,
    this.maxLines,
    this.minLines,
    this.readOnly = false,
    this.enabled = true,
    this.required = false,
    this.onTap,
    this.action,
    this.focusNode,
    this.inputFormatters,
    this.autofocus = false,
    this.initialValue,
    this.autovalidateMode,
    this.textCapitalization,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final AppTextFieldType type;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final IconData? prefixIcon;
  final Widget? suffix;
  final int? maxLength;
  final int? maxLines;
  final int? minLines;
  final bool readOnly;
  final bool enabled;
  final bool required;
  final VoidCallback? onTap;
  final TextInputAction? action;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;
  final String? initialValue;
  final AutovalidateMode? autovalidateMode;
  final TextCapitalization? textCapitalization;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscure = true;

  TextInputType get _keyboardType {
    switch (widget.type) {
      case AppTextFieldType.email:
        return TextInputType.emailAddress;
      case AppTextFieldType.phone:
        return TextInputType.phone;
      case AppTextFieldType.number:
        return const TextInputType.numberWithOptions(decimal: true);
      case AppTextFieldType.multiline:
        return TextInputType.multiline;
      case AppTextFieldType.search:
        return TextInputType.text;
      case AppTextFieldType.password:
      case AppTextFieldType.text:
        return TextInputType.text;
    }
  }

  bool get _isPassword => widget.type == AppTextFieldType.password;

  bool get _isMultiline => widget.type == AppTextFieldType.multiline;

  IconData? get _typePrefixIcon {
    if (widget.prefixIcon != null) return widget.prefixIcon;
    return switch (widget.type) {
      AppTextFieldType.email => Icons.email_outlined,
      AppTextFieldType.phone => Icons.phone_outlined,
      AppTextFieldType.search => Icons.search,
      AppTextFieldType.password => Icons.lock_outline,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final labelText = widget.required && widget.label != null
        ? '${widget.label} *'
        : widget.label;

    return TextFormField(
      controller: widget.controller,
      initialValue: widget.initialValue,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus,
      autovalidateMode: widget.autovalidateMode,
      keyboardType: _keyboardType,
      textInputAction: widget.action ??
          (_isMultiline ? TextInputAction.newline : TextInputAction.next),
      textCapitalization: widget.textCapitalization ?? TextCapitalization.none,
      obscureText: _isPassword && _obscure,
      maxLength: widget.maxLength,
      maxLines: _isPassword
          ? 1
          : (_isMultiline ? (widget.maxLines ?? 4) : (widget.maxLines ?? 1)),
      minLines: _isMultiline
          ? (widget.minLines ?? (widget.maxLines != null && widget.maxLines! < 3
              ? widget.maxLines
              : 3))
          : null,
      inputFormatters: widget.inputFormatters ??
          (widget.type == AppTextFieldType.number
              ? [FilteringTextInputFormatter.digitsOnly]
              : null),
      onTap: widget.onTap,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: widget.hint,
        helperText: widget.helperText,
        errorText: widget.errorText,
        prefixIcon: _typePrefixIcon != null
            ? Icon(_typePrefixIcon, size: 20, color: AppColors.textSecondary)
            : null,
        suffixIcon: _isPassword
            ? IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : widget.suffix,
      ),
    );
  }
}
