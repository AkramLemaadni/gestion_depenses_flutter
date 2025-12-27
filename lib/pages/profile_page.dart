import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();
  final baseSalaryController = TextEditingController();

  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();

  bool loading = true;
  bool isEditing = false;

  String email = "";
  String photoPath = "";
  File? selectedImage;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  // ============================
  // Load profile
  // ============================
  Future<void> loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection("users").doc(user.uid).get();
    final data = doc.data();

    setState(() {
      firstNameController.text = data?["firstName"] ?? "";
      lastNameController.text = data?["lastName"] ?? "";
      phoneController.text = data?["phone"] ?? "";
      baseSalaryController.text = (data?["baseSalary"] ?? "").toString();
      photoPath = data?["photoPath"] ?? "";
      email = user.email ?? "";
      loading = false;
    });
  }

  // ============================
  // Pick local image
  // ============================
  Future<void> pickImage() async {
    if (!isEditing) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        selectedImage = File(picked.path);
        photoPath = picked.path;
      });
    }
  }

  // ============================
  // Utils: parse salary safely
  // ============================
  double parseMoney(String raw) {
    // supports: "15000", "15 000", "15,000", "15000.50"
    final cleaned = raw
        .trim()
        .replaceAll(' ', '')
        .replaceAll(',', '.'); // if user types 15000,50
    return double.tryParse(cleaned) ?? 0.0;
  }

  // ============================
  // Save profile + salary
  // ============================
  Future<void> saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 🔐 password change
      if (newPasswordController.text.isNotEmpty) {
        if (currentPasswordController.text.isEmpty) {
          throw "Mot de passe actuel requis";
        }

        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPasswordController.text.trim(),
        );

        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(newPasswordController.text.trim());
      }

      final baseSalary = parseMoney(baseSalaryController.text);

      // ✅ Use set(merge:true) so it works even if doc doesn't exist
      await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
        "uid": user.uid,
        "firstName": firstNameController.text.trim(),
        "lastName": lastNameController.text.trim(),
        "phone": phoneController.text.trim(),
        "photoPath": photoPath,
        "baseSalary": baseSalary, // ✅ numeric
        "updatedAt": Timestamp.now(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() {
        isEditing = false;
        selectedImage = null;
        currentPasswordController.clear();
        newPasswordController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil et salaire mis à jour ✅")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    }
  }

  // ============================
  // Add bonus for current month (from Profile)
  // ============================
  Future<void> showBonusDialog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final monthKey = DateFormat('yyyy-MM').format(DateTime.now());

    final labelCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Ajouter une prime"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              decoration: const InputDecoration(labelText: "Libellé"),
            ),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Montant (MAD)"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = parseMoney(amountCtrl.text);

              final ref = FirebaseFirestore.instance
                  .collection("salaries")
                  .doc("${user.uid}_$monthKey");

              await ref.set({
                "userId": user.uid,
                "month": monthKey,
                "bonuses": FieldValue.arrayUnion([
                  {
                    "label": labelCtrl.text.trim(),
                    "amount": amount,
                    "date": Timestamp.now(),
                  }
                ]),
                "updatedAt": Timestamp.now(),
              }, SetOptions(merge: true));

              if (mounted) Navigator.pop(context);
            },
            child: const Text("Ajouter"),
          ),
        ],
      ),
    );
  }

  // ============================
  // UI
  // ============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: pickImage,
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.deepPurple.shade100,
                      backgroundImage: photoPath.isNotEmpty ? FileImage(File(photoPath)) : null,
                      child: photoPath.isEmpty
                          ? const Icon(Icons.person, size: 50, color: Colors.deepPurple)
                          : null,
                    ),
                  ),

                  const SizedBox(height: 30),

                  profileField("Prénom", firstNameController, isEditing, Icons.person),
                  profileField("Nom", lastNameController, isEditing, Icons.person_outline),
                  profileInfo("Email", email, Icons.email),
                  profileField("Téléphone", phoneController, isEditing, Icons.phone),

                  profileField(
                    "Salaire mensuel de base (MAD)",
                    baseSalaryController,
                    isEditing,
                    Icons.payments,
                    keyboard: TextInputType.number,
                  ),

                  if (isEditing) ...[
                    profileField(
                      "Mot de passe actuel",
                      currentPasswordController,
                      true,
                      Icons.lock,
                      obscure: true,
                    ),
                    profileField(
                      "Nouveau mot de passe",
                      newPasswordController,
                      true,
                      Icons.lock_outline,
                      obscure: true,
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ✅ prime button (always available)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text("Ajouter une prime (ce mois)"),
                      onPressed: showBonusDialog,
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (!isEditing)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => setState(() => isEditing = true),
                        child: const Text("Modifier le profil"),
                      ),
                    ),

                  if (isEditing)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                isEditing = false;
                                selectedImage = null;
                              });
                            },
                            child: const Text("Annuler"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: saveProfile,
                            child: const Text("Enregistrer"),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
    );
  }

  // ============================
  // Widgets
  // ============================
  Widget profileField(
    String label,
    TextEditingController controller,
    bool enabled,
    IconData icon, {
    bool obscure = false,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        enabled: enabled,
        obscureText: obscure,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }

  Widget profileInfo(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        enabled: false,
        decoration: InputDecoration(
          labelText: label,
          hintText: value,
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }
}
