import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/app_color.dart';
import '../utils/format.dart';
import '../utils/item.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/custom_input.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/item_card.dart';
import 'edit_item_screen.dart';

class DetailItemScreen extends StatefulWidget {
  final Item item;

  /// true  = dibuka dari tab Inventaris (hanya Edit & Hapus)
  /// false = dibuka dari Beranda (hanya Pinjam / Kembalikan)
  final bool manage;
  const DetailItemScreen({super.key, required this.item, this.manage = false});

  @override
  State<DetailItemScreen> createState() => _DetailItemScreenState();
}

class _DetailItemScreenState extends State<DetailItemScreen> {
  final _purpose = TextEditingController();
  late DateTime _due = _defaultDue();
  bool _loading = false;

  static DateTime _defaultDue() {
    final n = DateTime.now().add(const Duration(hours: 2));
    return DateTime(n.year, n.month, n.day, n.hour, 0);
  }

  @override
  void dispose() {
    _purpose.dispose();
    super.dispose();
  }

  Future<void> _pickDue() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _due.isBefore(now) ? now : _due,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 30)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(_due));
    if (t == null) return;
    setState(() => _due = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  Future<void> _borrow(Item i) async {
    if (_purpose.text.trim().isEmpty) {
      showSnack(context, 'Isi keperluan peminjaman dulu', error: true);
      return;
    }
    if (!_due.isAfter(DateTime.now())) {
      showSnack(context, 'Tenggat harus setelah waktu sekarang', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final db = FirebaseFirestore.instance;
      final u = (await db.collection('users').doc(user.uid).get()).data() ?? {};
      final ref =
          db.collection('users').doc(user.uid).collection('borrowings').doc();
      final batch = db.batch();
      batch.set(ref, {
        'borrow_id': ref.id,
        'item_id': i.id,
        'item_name': i.name,
        'item_code': i.code,
        'item_image': i.image,
        'purpose': _purpose.text.trim(),
        'borrow_date': Timestamp.now(),
        'due_date': Timestamp.fromDate(_due),
      });
      batch.update(itemsRef.doc(i.id), {
        'status': 'Borrowed',
        'borrower_uid': user.uid,
        'borrower_name': u['name'] ?? user.displayName ?? '-',
        'borrower_kelas': u['kelas'] ?? '-',
        'purpose': _purpose.text.trim(),
        'borrow_id': ref.id,
        'borrow_date': Timestamp.now(),
        'due_date': Timestamp.fromDate(_due),
      });
      await batch.commit();
      _purpose.clear();
      if (mounted) showSnack(context, 'Berhasil meminjam ${i.name}!');
    } catch (e) {
      if (mounted) showSnack(context, 'Gagal meminjam: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _return(Item i) async {
    final ok = await confirmDialog(context,
        title: 'Kembalikan alat?',
        message: '${i.name} akan ditandai sudah dikembalikan.',
        okText: 'Kembalikan');
    if (!ok) return;
    setState(() => _loading = true);
    try {
      final db = FirebaseFirestore.instance;
      final batch = db.batch();
      batch.update(
          itemsRef.doc(i.id), {'status': 'Available', ...clearBorrowFields});
      if (i.borrowerUid.isNotEmpty && i.borrowId.isNotEmpty) {
        batch.update(
            db
                .collection('users')
                .doc(i.borrowerUid)
                .collection('borrowings')
                .doc(i.borrowId),
            {'returned_at': Timestamp.now()});
      }
      await batch.commit();
      if (mounted) showSnack(context, 'Alat berhasil dikembalikan');
    } catch (e) {
      if (mounted) showSnack(context, 'Gagal mengembalikan: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    // Realtime: detail ikut berubah saat data di Firestore berubah.
    return StreamBuilder<DocumentSnapshot>(
      stream: itemsRef.doc(widget.item.id).snapshots(),
      builder: (context, snap) {
        final i = (snap.hasData && snap.data!.exists)
            ? Item.fromDoc(snap.data!)
            : widget.item;
        final overdue = !i.available &&
            i.dueDate != null &&
            DateTime.now().isAfter(i.dueDate!);
        return Scaffold(
          body: Column(children: [
            Stack(children: [
              Hero(
                tag: 'img_${widget.item.id}',
                child: ItemImage(i.image,
                    height: 260, width: double.infinity, radius: 0),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 12,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColor.primary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ]),
            Expanded(
              child: Container(
                width: double.infinity,
                transform: Matrix4.translationValues(0, -28, 0),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                decoration: const BoxDecoration(
                  color: AppColor.bg,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(i.name,
                                    style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: AppColor.text)),
                              ),
                              StatusBadge(i.status),
                            ]),
                        const SizedBox(height: 16),
                        _row(Icons.qr_code, 'Kode', i.code),
                        _row(Icons.category, 'Kategori', i.category),
                        const SizedBox(height: 8),
                        const Text('Spesifikasi',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColor.text)),
                        const SizedBox(height: 6),
                        Text(i.spec,
                            style: const TextStyle(
                                color: AppColor.grey, height: 1.5)),
                        if (!i.available) ...[
                          const SizedBox(height: 18),
                          _borrowInfo(i, overdue),
                        ],
                        const SizedBox(height: 22),
                        if (widget.manage)
                          _manageButtons(i)
                        else
                          _borrowSection(i, uid),
                      ]),
                ),
              ),
            ),
          ]),
        );
      },
    );
  }

  // ---------- Mode Beranda: pinjam / kembalikan ----------
  Widget _borrowSection(Item i, String? uid) {
    if (i.available) {
      return Column(children: [
        CustomInput(
            controller: _purpose,
            label: 'Keperluan Peminjaman',
            icon: Icons.edit_note),
        GestureDetector(
          onTap: _pickDue,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColor.soft),
            ),
            child: Row(children: [
              const Icon(Icons.event_available, color: AppColor.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tenggat Pengembalian',
                          style: TextStyle(color: AppColor.grey, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text(fmtDateTime(_due),
                          style: const TextStyle(
                              color: AppColor.text,
                              fontWeight: FontWeight.w700)),
                    ]),
              ),
              const Icon(Icons.edit_calendar, color: AppColor.light),
            ]),
          ),
        ),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColor.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(27)),
            ),
            onPressed: _loading ? null : () => _borrow(i),
            icon: _loading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.shopping_bag),
            label: const Text('Pinjam Alat Ini',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ]);
    }

    // Sedang dipinjam
    if (uid != null && i.borrowerUid == uid) {
      return SizedBox(
        width: double.infinity,
        height: 54,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColor.primary,
            side: const BorderSide(color: AppColor.primary, width: 1.5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
          ),
          onPressed: _loading ? null : () => _return(i),
          icon: const Icon(Icons.assignment_return),
          label: const Text('Kembalikan Alat',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColor.soft, borderRadius: BorderRadius.circular(16)),
      child: const Text('Sedang digunakan peminjam',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColor.grey, fontStyle: FontStyle.italic)),
    );
  }

  // ---------- Mode Inventaris: hanya Edit & Hapus ----------
  Widget _manageButtons(Item i) {
    return Row(children: [
      Expanded(
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColor.primary,
            minimumSize: const Size(0, 52),
            side: const BorderSide(color: AppColor.primary),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          icon: const Icon(Icons.edit),
          label: const Text('Edit'),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => EditItemScreen(item: i))),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColor.text,
            minimumSize: const Size(0, 52),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          icon: const Icon(Icons.delete),
          label: const Text('Hapus'),
          onPressed: () async {
            final ok = await confirmDialog(context,
                title: 'Hapus alat?',
                message: '${i.name} akan dihapus permanen.',
                okText: 'Hapus');
            if (ok) {
              await itemsRef.doc(i.id).delete();
              if (mounted) {
                showSnack(context, 'Alat dihapus');
                Navigator.pop(context);
              }
            }
          },
        ),
      ),
    ]);
  }

  // ---------- Info peminjam ----------
  Widget _borrowInfo(Item i, bool overdue) {
    String v(String s) => s.isEmpty ? '-' : s;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColor.shadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(
            child: Text('Info Peminjaman',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: AppColor.text)),
          ),
          if (overdue)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColor.text,
                  borderRadius: BorderRadius.circular(20)),
              child: const Text('Terlambat',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
        ]),
        const SizedBox(height: 12),
        _row(Icons.person, 'Peminjam', v(i.borrowerName)),
        _row(Icons.school, 'Kelas', v(i.borrowerKelas)),
        _row(Icons.description, 'Keperluan', v(i.purpose)),
        _row(Icons.access_time, 'Dipinjam',
            i.borrowDate == null ? '-' : fmtDateTime(i.borrowDate!)),
        _row(Icons.event_available, 'Tenggat',
            i.dueDate == null ? '-' : fmtDateTime(i.dueDate!)),
      ]),
    );
  }

  Widget _row(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 20, color: AppColor.primary),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(color: AppColor.grey)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: AppColor.text)),
          ),
        ]),
      );
}