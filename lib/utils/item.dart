import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  final String id, name, category, code, status, image, spec;
  final String borrowerUid, borrowerName, borrowerKelas, purpose, borrowId;
  final DateTime? borrowDate, dueDate;

  Item({
    required this.id,
    required this.name,
    required this.category,
    required this.code,
    required this.status,
    required this.image,
    required this.spec,
    this.borrowerUid = '',
    this.borrowerName = '',
    this.borrowerKelas = '',
    this.purpose = '',
    this.borrowId = '',
    this.borrowDate,
    this.dueDate,
  });

  static DateTime? _ts(dynamic v) => v is Timestamp ? v.toDate() : null;

  factory Item.fromDoc(DocumentSnapshot d) {
    final m = d.data() as Map<String, dynamic>;
    return Item(
      id: d.id,
      name: m['item_name'] ?? '',
      category: m['category'] ?? '',
      code: m['code'] ?? '',
      status: m['status'] ?? 'Available',
      image: m['image'] ?? '',
      spec: m['spesification'] ?? '',
      borrowerUid: m['borrower_uid'] ?? '',
      borrowerName: m['borrower_name'] ?? '',
      borrowerKelas: m['borrower_kelas'] ?? '',
      purpose: m['purpose'] ?? '',
      borrowId: m['borrow_id'] ?? '',
      borrowDate: _ts(m['borrow_date']),
      dueDate: _ts(m['due_date']),
    );
  }

  bool get available => status == 'Available';
}

final CollectionReference itemsRef =
    FirebaseFirestore.instance.collection('items');

/// Dipakai untuk mengosongkan data peminjaman saat alat dikembalikan.
final Map<String, dynamic> clearBorrowFields = {
  'borrower_uid': null,
  'borrower_name': null,
  'borrower_kelas': null,
  'purpose': null,
  'borrow_id': null,
  'borrow_date': null,
  'due_date': null,
};