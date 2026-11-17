import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/app_color.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      final logged = FirebaseAuth.instance.currentUser != null;
      Navigator.pushReplacementNamed(context, logged ? '/home' : '/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColor.gradient),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutBack,
          builder: (_, v, child) =>
              Opacity(opacity: v.clamp(0, 1), child: Transform.scale(scale: v, child: child)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.biotech,
                  size: 80, color: AppColor.primary),
            ),
            const SizedBox(height: 24),
            const Text('Inventaris Lab',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
            const SizedBox(height: 6),
            const Text('Kelola alat laboratorium SMK Telkom Malang',
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.white),
          ]),
        ),
      ),
    );
  }
}