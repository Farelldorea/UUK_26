import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/app_color.dart';
import '../utils/format.dart';
import '../widgets/item_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filter = 'Semua';

  DateTime? _ts(dynamic v) => v is Timestamp ? v.toDate() : null;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Peminjaman')),
      body: Column(children: [
        // Filter
        SizedBox(
          height: 60,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: ['Semua', 'Dipinjam', 'Dikembalikan']
                .map((f) => Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ChoiceChip(
                        label: Text(f),
                        selected: _filter == f,
                        selectedColor: AppColor.primary,
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppColor.soft),
                        labelStyle: TextStyle(
                            color: _filter == f ? Colors.white : AppColor.text,
                            fontWeight: FontWeight.w600),
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _filter = f),
                      ),
                    ))
                .toList(),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('borrowings')
                .snapshots(),
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(child: Text('Error: ${snap.error}'));
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              var list = snap.data!.docs
                  .map((d) => d.data() as Map<String, dynamic>)
                  .toList();

              // Urutkan terbaru di atas
              list.sort((a, b) {
                final da = _ts(a['borrow_date']) ?? DateTime(2000);
                final db = _ts(b['borrow_date']) ?? DateTime(2000);
                return db.compareTo(da);
              });

              if (_filter == 'Dipinjam') {
                list = list.where((m) => m['returned_at'] == null).toList();
              } else if (_filter == 'Dikembalikan') {
                list = list.where((m) => m['returned_at'] != null).toList();
              }

              if (list.isEmpty) {
                return const Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: AppColor.light),
                        SizedBox(height: 10),
                        Text('Belum ada riwayat',
                            style: TextStyle(color: AppColor.grey)),
                      ]),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                itemCount: list.length,
                itemBuilder: (_, i) => _card(list[i]),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _card(Map<String, dynamic> m) {
    final borrow = _ts(m['borrow_date']);
    final due = _ts(m['due_date']);
    final back = _ts(m['returned_at']);
    final now = DateTime.now();

    String label;
    Color color;
    if (back != null) {
      final late = due != null && back.isAfter(due);
      label = late ? 'Terlambat' : 'Dikembalikan';
      color = late ? AppColor.text : AppColor.primary;
    } else if (due != null && now.isAfter(due)) {
      label = 'Terlambat';
      color = AppColor.text;
    } else {
      label = 'Dipinjam';
      color = AppColor.borrowed;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColor.shadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          ItemImage(m['item_image'] ?? '', height: 54, width: 54, radius: 14),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m['item_name'] ?? '-',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColor.text)),
                  if ((m['item_code'] ?? '').toString().isNotEmpty)
                    Text(m['item_code'],
                        style: const TextStyle(
                            color: AppColor.grey, fontSize: 12)),
                ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(label,
                style: TextStyle(
                    color: color, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ]),
        const Divider(height: 22, color: AppColor.soft),
        _line(Icons.description, 'Keperluan', m['purpose'] ?? '-'),
        _line(Icons.access_time, 'Dipinjam',
            borrow == null ? '-' : fmtDateTime(borrow)),
        _line(Icons.event_available, 'Tenggat',
            due == null ? '-' : fmtDateTime(due)),
        _line(Icons.assignment_turned_in, 'Dikembalikan',
            back == null ? 'Belum dikembalikan' : fmtDateTime(back)),
      ]),
    );
  }

  Widget _line(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 17, color: AppColor.primary),
          const SizedBox(width: 8),
          Text('$label: ',
              style: const TextStyle(color: AppColor.grey, fontSize: 13)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: AppColor.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ),
        ]),
      );
}