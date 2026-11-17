import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/app_color.dart';
import '../widgets/custom_input.dart';
import '../widgets/custom_snackbar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _key = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _email.text.trim(), password: _pass.text.trim());
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      if (mounted) showSnack(context, e.message ?? 'Login gagal', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(children: [
          Container(
            height: 280,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppColor.gradient,
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(48)),
            ),
            child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.biotech,
                          size: 44, color: AppColor.primary)),
                  SizedBox(height: 14),
                  Text('Selamat Datang',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold)),
                  Text('Masuk untuk melanjutkan',
                      style: TextStyle(color: Colors.white70)),
                ]),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _key,
              child: Column(children: [
                const SizedBox(height: 10),
                CustomInput(
                    controller: _email,
                    label: 'Email',
                    icon: Icons.email,
                    keyboard: TextInputType.emailAddress),
                CustomInput(
                    controller: _pass,
                    label: 'Password',
                    icon: Icons.lock,
                    obscure: true),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16))),
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('MASUK',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('Belum punya akun? ',
                      style: TextStyle(color: AppColor.grey)),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/register'),
                    child: const Text('Daftar',
                        style: TextStyle(
                            color: AppColor.primary,
                            fontWeight: FontWeight.bold)),
                  ),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}