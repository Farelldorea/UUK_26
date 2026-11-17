import 'package:cloud_firestore/cloud_firestore.dart';
import 'item.dart';

/// Mengisi data dummy ke Firestore jika koleksi items masih kosong.
Future<void> seedDummyData() async {
  final check = await itemsRef.limit(1).get();
  if (check.docs.isNotEmpty) return;

  String img(String s) => 'https://picsum.photos/seed/$s/600/400';
  final data = [
    ['Mikroskop Binokuler', 'Optik', 'LAB-001', 'Available', 'Perbesaran 40x-1000x, lampu LED'],
    ['Multimeter Digital', 'Elektronik', 'LAB-002', 'Available', 'Ukur tegangan, arus, hambatan'],
    ['Oscilloscope 2 Channel', 'Elektronik', 'LAB-003', 'Borrowed', 'Bandwidth 100 MHz'],
    ['Laptop Praktikum', 'Komputer', 'LAB-004', 'Available', 'Core i5, RAM 8GB, SSD 256GB'],
    ['Router Cisco', 'Jaringan', 'LAB-005', 'Available', '4 port gigabit, support VLAN'],
    ['Crimping Tool RJ45', 'Jaringan', 'LAB-006', 'Borrowed', 'Untuk kabel UTP Cat5/Cat6'],
    ['Solder Station', 'Elektronik', 'LAB-007', 'Available', 'Suhu 200-480 C, 60 Watt'],
    ['Proyektor Epson', 'Multimedia', 'LAB-008', 'Available', '3600 lumens, XGA'],
  ];

  final batch = FirebaseFirestore.instance.batch();
  for (final d in data) {
    final ref = itemsRef.doc();
    batch.set(ref, {
      'item_id': ref.id,
      'item_name': d[0],
      'category': d[1],
      'code': d[2],
      'status': d[3],
      'image': img(d[2]),
      'spesification': d[4],
      'created_at': FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
}