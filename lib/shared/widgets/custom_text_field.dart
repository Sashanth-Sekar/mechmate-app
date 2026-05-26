import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? prefixWidget;
  final bool obscureText;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final void Function(String)? onChanged;
  final int? maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final String? initialValue;

  const AppTextField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.prefixWidget,
    this.obscureText = false,
    this.suffix,
    this.validator,
    this.keyboardType,
    this.onChanged,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.textInputAction,
    this.inputFormatters,
    this.focusNode,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      obscureText: obscureText,
      validator: validator,
      keyboardType: keyboardType,
      onChanged: onChanged,
      maxLines: obscureText ? 1 : maxLines,
      readOnly: readOnly,
      onTap: onTap,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixWidget ?? (prefixIcon != null ? Icon(prefixIcon) : null),
        suffixIcon: suffix,
      ),
    );
  }
}
