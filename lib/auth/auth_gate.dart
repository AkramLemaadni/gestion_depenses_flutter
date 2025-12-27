import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/login_page.dart';
import '../pages/home_page.dart';
import '../utils/animated_route.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        
        // ⏳ EN COURS DE CHARGEMENT
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 🟢 UTILISATEUR CONNECTÉ
        if (snapshot.hasData) {
          return const HomePage();
        }

        // 🔴 PAS CONNECTÉ
        return const LoginPage();
      },
    );
  }
}
