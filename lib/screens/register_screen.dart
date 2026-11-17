import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/app_color.dart';
import '../widgets/custom_input.dart';
import '../widgets/custom_snackbar.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _key = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _kelas = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  String _requestedRole = 'user';
  bool _loading = false;

  Future<void> _register() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _email.text.trim(), password: _pass.text.trim());
      final uid = cred.user!.uid;
      await cred.user!.updateDisplayName(_name.text.trim());
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'user_id': uid,
        'name': _name.text.trim(),
        'kelas': _kelas.text.trim(),
        'email': _email.text.trim(),
        'foto': '',
        'role': _requestedRole,
      });
      if (mounted) {
        showSnack(
          context,
          _requestedRole == 'pending_admin'
              ? 'Permintaan akun Admin dikirim. Menunggu persetujuan.'
              : 'Registrasi berhasil',
        );
        Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) showSnack(context, e.message ?? 'Gagal daftar', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Akun')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _key,
          child: Column(children: [
            const CircleAvatar(
                radius: 38,
                backgroundColor: AppColor.soft,
                child:
                    Icon(Icons.person_add, size: 38, color: AppColor.primary)),
            const SizedBox(height: 24),
            CustomInput(controller: _name, label: 'Nama', icon: Icons.person),
            CustomInput(controller: _kelas, label: 'Kelas', icon: Icons.school),
            CustomInput(
                controller: _email,
                label: 'Email',
                icon: Icons.email,
                keyboard: TextInputType.emailAddress),
            CustomInput(
              controller: _pass,
              label: 'Password',
              icon: Icons.lock,
              obscure: true,
              validator: (v) =>
                  (v == null || v.length < 6) ? 'Minimal 6 karakter' : null,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tipe Akun',
                style: const TextStyle(
                  color: AppColor.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'user',
                    label: Text('User'),
                    icon: Icon(Icons.person_outline),
                  ),
                  ButtonSegment(
                    value: 'pending_admin',
                    label: Text('Admin'),
                    icon: Icon(Icons.admin_panel_settings_outlined),
                  ),
                ],
                selected: {_requestedRole},
                onSelectionChanged: _loading
                    ? null
                    : (selection) =>
                        setState(() => _requestedRole = selection.first),
              ),
            ),
            if (_requestedRole == 'pending_admin')
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Akses Admin aktif setelah permintaan disetujui.',
                  style: TextStyle(color: AppColor.grey, fontSize: 12),
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))),
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('DAFTAR',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
