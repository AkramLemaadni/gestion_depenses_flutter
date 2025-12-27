import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/animated_route.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool showPassword = false;
  bool showConfirmPassword = false;

  bool isPasswordSecure(String password) {
    final secureRegex =
        RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%^&*]).{8,}$');
    return secureRegex.hasMatch(password);
  }

  Future<void> register() async {
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if ([firstName, lastName, email, phone, password, confirmPassword]
        .any((x) => x.isEmpty)) {
      showError("Tous les champs sont obligatoires.");
      return;
    }

    if (password != confirmPassword) {
      showError("Les mots de passe ne correspondent pas.");
      return;
    }

    if (!isPasswordSecure(password)) {
      showError(
        "Mot de passe faible !\n"
        "- 8 caractères minimum\n"
        "- 1 majuscule\n"
        "- 1 minuscule\n"
        "- 1 chiffre\n"
        "- 1 symbole",
      );
      return;
    }

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'photoUrl': '',
        'createdAt': Timestamp.now(),
      });

      showSuccess("Compte créé avec succès !");
      Navigator.pushReplacement(
          context, animatedRoute(const LoginPage()));
    } catch (e) {
      showError("Erreur : ${e.toString()}");
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: Colors.red, content: Text(message)),
    );
  }

  void showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: Colors.green, content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                children: [
                  const Text("Créer un compte",
                      style:
                          TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 22),

                  buildTextField(firstNameController, "Nom", Icons.person),
                  const SizedBox(height: 12),
                  buildTextField(
                      lastNameController, "Prénom", Icons.person_outline),
                  const SizedBox(height: 12),
                  buildTextField(emailController, "Email", Icons.email),
                  const SizedBox(height: 12),
                  buildTextField(phoneController, "Téléphone", Icons.phone),
                  const SizedBox(height: 12),

                  buildPasswordField(
                    controller: passwordController,
                    label: "Mot de passe",
                    show: showPassword,
                    onToggle: () =>
                        setState(() => showPassword = !showPassword),
                  ),
                  const SizedBox(height: 12),

                  buildPasswordField(
                    controller: confirmPasswordController,
                    label: "Confirmer le mot de passe",
                    show: showConfirmPassword,
                    onToggle: () => setState(
                        () => showConfirmPassword = !showConfirmPassword),
                  ),

                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: register,
                      child: const Text("Créer mon compte",
                          style: TextStyle(fontSize: 18)),
                    ),
                  ),

                  const SizedBox(height: 16),

                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                          context, animatedRoute(const LoginPage()));
                    },
                    child: const Text("J'ai déjà un compte",
                        style: TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget buildTextField(
    TextEditingController controller, String label, IconData icon) {
  return TextField(
    controller: controller,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

Widget buildPasswordField({
  required TextEditingController controller,
  required String label,
  required bool show,
  required VoidCallback onToggle,
}) {
  return TextField(
    controller: controller,
    obscureText: !show,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: const Icon(Icons.lock),
      suffixIcon: IconButton(
        icon: Icon(show ? Icons.visibility : Icons.visibility_off),
        onPressed: onToggle,
      ),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
