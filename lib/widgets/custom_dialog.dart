import 'package:flutter/material.dart';
import '../utils/app_color.dart';

Future<bool> confirmDialog(BuildContext context,
    {required String title,
    required String message,
    String okText = 'Ya'}) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title,
          style: const TextStyle(
              color: AppColor.text, fontWeight: FontWeight.bold)),
      content: Text(message, style: const TextStyle(color: AppColor.grey)),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColor.primary),
          onPressed: () => Navigator.pop(context, true),
          child: Text(okText),
        ),
      ],
    ),
  );
  return res ?? false;
}