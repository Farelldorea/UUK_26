import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils/item.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/item_form.dart';

class AddItemScreen extends StatelessWidget {
  const AddItemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Alat')),
      body: ItemForm(
        buttonText: 'SIMPAN',
        onSubmit: (data) async {
          final ref = itemsRef.doc();
          await ref.set({
            ...data,
            'item_id': ref.id,
            'created_at': FieldValue.serverTimestamp(),
          });
          if (context.mounted) {
            showSnack(context, 'Alat berhasil ditambahkan');
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}