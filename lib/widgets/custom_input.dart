import 'package:flutter/material.dart';
import '../utils/app_color.dart';

class CustomInput extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final int maxLines;
  final TextInputType? keyboard;
  final String? Function(String?)? validator;

  const CustomInput({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.maxLines = 1,
    this.keyboard,
    this.validator,
  });

  @override
  State<CustomInput> createState() => _CustomInputState();
}

class _CustomInputState extends State<CustomInput> {
  late bool _hide = widget.obscure;

  OutlineInputBorder _border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c, width: w),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: widget.controller,
        obscureText: _hide,
        maxLines: widget.obscure ? 1 : widget.maxLines,
        keyboardType: widget.keyboard,
        validator: widget.validator ??
            (v) => (v == null || v.trim().isEmpty)
                ? '${widget.label} wajib diisi'
                : null,
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: Icon(widget.icon, color: AppColor.primary),
          suffixIcon: widget.obscure
              ? IconButton(
                  icon: Icon(
                      _hide ? Icons.visibility_off : Icons.visibility,
                      color: AppColor.grey),
                  onPressed: () => setState(() => _hide = !_hide),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: _border(AppColor.soft),
          enabledBorder: _border(AppColor.soft),
          focusedBorder: _border(AppColor.primary, 2),
        ),
      ),
    );
  }
}