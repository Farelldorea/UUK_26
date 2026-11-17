import 'package:flutter/material.dart';
import '../utils/app_color.dart';
import '../utils/item.dart';
import '../widgets/item_card.dart';
import 'add_item_screen.dart';

class AllItemScreen extends StatelessWidget {
  final bool isAdmin;
  const AllItemScreen({super.key, this.isAdmin = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventaris')),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: AppColor.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Tambah'),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AddItemScreen())),
            )
          : null,
      body: StreamBuilder(
        stream: itemsRef.orderBy('created_at', descending: true).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data!.docs.map((d) => Item.fromDoc(d)).toList();
          if (items.isEmpty) {
            return const Center(
                child: Text('Belum ada data',
                    style: TextStyle(color: AppColor.grey)));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
            itemCount: items.length,
            itemBuilder: (_, i) => ItemTile(items[i], manage: isAdmin),
          );
        },
      ),
    );
  }
}