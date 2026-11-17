import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/app_color.dart';
import '../widgets/custom_dialog.dart';
import 'history_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snap) {
          final m = (snap.data?.data() as Map<String, dynamic>?) ?? {};
          final name = m['name'] ?? user.displayName ?? '-';
          return ListView(padding: const EdgeInsets.all(24), children: [
            Center(
              child: CircleAvatar(
                radius: 52,
                backgroundColor: AppColor.primary,
                child: Text(
                  name.toString().isEmpty
                      ? '?'
                      : name.toString()[0].toUpperCase(),
                  style: const TextStyle(
                      fontSize: 42,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(name,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColor.text)),
            ),
            const SizedBox(height: 24),
            _tile(Icons.email, 'Email', m['email'] ?? user.email ?? '-'),
            _tile(Icons.school, 'Kelas', m['kelas'] ?? '-'),
            _tile(
              Icons.admin_panel_settings,
              'Tipe Akun',
              m['role'] == 'admin'
                  ? 'Admin'
                  : m['role'] == 'pending_admin'
                      ? 'Menunggu persetujuan Admin'
                      : 'User',
            ),
            _tile(Icons.badge, 'User ID', user.uid),

            // Menu Riwayat Peminjaman
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen())),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColor.gradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColor.shadow,
                ),
                child: const Row(children: [
                  Icon(Icons.history, color: Colors.white),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text('Riwayat Peminjaman',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  Icon(Icons.chevron_right, color: Colors.white),
                ]),
              ),
            ),

            const SizedBox(height: 8),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                    backgroundColor: AppColor.text,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))),
                icon: const Icon(Icons.logout),
                label: const Text('Keluar'),
                onPressed: () async {
                  final ok = await confirmDialog(context,
                      title: 'Keluar?',
                      message: 'Kamu harus login lagi nanti.',
                      okText: 'Keluar');
                  if (ok) {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/login', (r) => false);
                    }
                  }
                },
              ),
            ),
          ]);
        },
      ),
    );
  }

  Widget _tile(IconData icon, String label, String value) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColor.shadow),
        child: Row(children: [
          Icon(icon, color: AppColor.primary),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: const TextStyle(color: AppColor.grey, fontSize: 12)),
              Text(value,
                  style: const TextStyle(
                      color: AppColor.text, fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      );
}
