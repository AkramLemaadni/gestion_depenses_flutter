import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  String selectedCategory = "Nourriture";

  final List<String> categories = [
    "Nourriture",
    "Transport",
    "Shopping",
    "Loisirs",
    "Santé",
    "Autre",
  ];

  // ============================
  // 🔥 Enregistrer une dépense
  // ============================
  Future<void> saveExpense() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (amountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez entrer un montant")),
      );
      return;
    }

    final amount = double.tryParse(amountController.text.trim());
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Montant invalide")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection("expenses").add({
      "userId": user.uid,
      "amount": amount,
      "category": selectedCategory,
      "notes": notesController.text.trim(),
      "date": Timestamp.now(),
    });

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  void dispose() {
    amountController.dispose();
    notesController.dispose();
    super.dispose();
  }

  // ============================
  // UI
  // ============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ajouter une dépense"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Montant (MAD)",
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: selectedCategory,
              items: categories
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(c),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value!;
                });
              },
              decoration: const InputDecoration(
                labelText: "Catégorie",
                prefixIcon: Icon(Icons.category),
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: "Notes (optionnel)",
                prefixIcon: Icon(Icons.note),
              ),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saveExpense,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  "Enregistrer",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
