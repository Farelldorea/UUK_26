import 'package:flutter/material.dart';
import '../utils/app_color.dart';
import '../utils/categories.dart';
import '../utils/item.dart';
import 'custom_input.dart';

/// Form dipakai bersama oleh halaman Tambah dan Edit.
class ItemForm extends StatefulWidget {
  final Item? initial;
  final String buttonText;
  final Future<void> Function(Map<String, dynamic> data) onSubmit;
  const ItemForm(
      {super.key,
      this.initial,
      required this.buttonText,
      required this.onSubmit});

  @override
  State<ItemForm> createState() => _ItemFormState();
}

class _ItemFormState extends State<ItemForm> {
  final _key = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _code = TextEditingController(text: widget.initial?.code);
  late final _img = TextEditingController(text: widget.initial?.image);
  late final _spec = TextEditingController(text: widget.initial?.spec);
  late String _status = widget.initial?.status ?? 'Available';
  String? _category;
  late final List<String> _catOptions;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final old = widget.initial?.category ?? '';
    // Kategori lama (yang tidak ada di daftar) tetap dimasukkan agar tidak error.
    _catOptions = {...kCategories, if (old.isNotEmpty) old}.toList();
    _category = old.isNotEmpty ? old : null;
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColor.primary),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColor.soft)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColor.soft)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColor.primary, width: 2)),
      );

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await widget.onSubmit({
        'item_name': _name.text.trim(),
        'category': _category,
        'code': _code.text.trim(),
        'status': _status,
        'image': _img.text.trim(),
        'spesification': _spec.text.trim(),
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _key,
      child: ListView(padding: const EdgeInsets.all(20), children: [
        CustomInput(
            controller: _name, label: 'Nama Alat', icon: Icons.science),

        // Kategori (dropdown)
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: DropdownButtonFormField<String>(
            value: _category,
            isExpanded: true,
            borderRadius: BorderRadius.circular(16),
            hint: const Text('Pilih kategori'),
            items: _catOptions
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => _category = v),
            validator: (v) => v == null ? 'Kategori wajib dipilih' : null,
            decoration: _dec('Kategori', Icons.category),
          ),
        ),

        CustomInput(
            controller: _code, label: 'Kode Alat', icon: Icons.qr_code),

        // Status (dropdown)
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: DropdownButtonFormField<String>(
            value: _status,
            borderRadius: BorderRadius.circular(16),
            items: const ['Available', 'Borrowed']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => _status = v!),
            decoration: _dec('Status', Icons.info_outline),
          ),
        ),

        CustomInput(
            controller: _img,
            label: 'Link URL Gambar',
            icon: Icons.image,
            keyboard: TextInputType.url),
        CustomInput(
            controller: _spec,
            label: 'Spesifikasi',
            icon: Icons.notes,
            maxLines: 3),
        const SizedBox(height: 6),
        SizedBox(
          height: 54,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColor.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : Text(widget.buttonText,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ]),
    );
  }
}