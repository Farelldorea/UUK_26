import 'package:flutter/material.dart';
import '../utils/item.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/item_form.dart';

class EditItemScreen extends StatelessWidget {
  final Item item;
  const EditItemScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Alat')),
      body: ItemForm(
        initial: item,
        buttonText: 'PERBARUI',
        onSubmit: (data) async {
          await itemsRef.doc(item.id).update({
            ...data,
            // Jika status diubah ke Available, data peminjaman dikosongkan.
            if (data['status'] == 'Available') ...clearBorrowFields,
          });
          if (context.mounted) {
            showSnack(context, 'Data berhasil diperbarui');
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}