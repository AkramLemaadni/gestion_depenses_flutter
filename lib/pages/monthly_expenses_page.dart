import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MonthlyExpensesPage extends StatefulWidget {
  const MonthlyExpensesPage({super.key});

  @override
  State<MonthlyExpensesPage> createState() => _MonthlyExpensesPageState();
}

class _MonthlyExpensesPageState extends State<MonthlyExpensesPage> {
  DateTime selectedMonth = DateTime.now();

  void changeMonth(DateTime date) {
    setState(() {
      selectedMonth = DateTime(date.year, date.month);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Utilisateur non connecté")),
      );
    }

    final startMonth =
        DateTime(selectedMonth.year, selectedMonth.month, 1);
    final endMonth =
        DateTime(selectedMonth.year, selectedMonth.month + 1, 1);

    final monthKey = DateFormat('yyyy-MM').format(selectedMonth);
    final monthLabel =
        DateFormat.yMMMM('fr_FR').format(selectedMonth);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dépenses mensuelles"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 📅 Sélecteur de mois
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => changeMonth(
                    DateTime(
                        selectedMonth.year, selectedMonth.month - 1),
                  ),
                ),
                Text(
                  monthLabel,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => changeMonth(
                    DateTime(
                        selectedMonth.year, selectedMonth.month + 1),
                  ),
                ),
              ],
            ),
          ),

          // 🔥 Dépenses + Salaire
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("expenses")
                  .where("userId", isEqualTo: user.uid)
                  .where("date",
                      isGreaterThanOrEqualTo:
                          Timestamp.fromDate(startMonth))
                  .where("date",
                      isLessThan: Timestamp.fromDate(endMonth))
                  .orderBy("date", descending: true)
                  .snapshots(),
              builder: (context, expenseSnap) {
                if (!expenseSnap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final expenses = expenseSnap.data!.docs;

                double totalExpenses = 0;
                for (var d in expenses) {
                  totalExpenses +=
                      (d["amount"] as num).toDouble();
                }

                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("salaries")
                      .doc("${user.uid}_$monthKey")
                      .snapshots(),
                  builder: (context, salarySnap) {
                    double salary = 0;

                    if (salarySnap.hasData &&
                        salarySnap.data!.exists) {
                      final data = salarySnap.data!.data()
                          as Map<String, dynamic>;
                      salary =
                          (data["amount"] as num).toDouble();
                    }

                    final remaining = salary - totalExpenses;

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // 💰 Cartes résumé
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            summaryCard(
                              "Salaire",
                              "${salary.toStringAsFixed(2)} MAD",
                              Icons.payments,
                              Colors.green,
                            ),
                            summaryCard(
                              "Dépenses",
                              "${totalExpenses.toStringAsFixed(2)} MAD",
                              Icons.trending_down,
                              Colors.redAccent,
                            ),
                          ],
                        ),
                       
                        // 📋 Liste des dépenses
                        if (expenses.isEmpty)
                          const Center(
                              child: Text(
                                  "Aucune dépense pour ce mois"))
                        else
                          ...expenses.map((doc) {
                            final date =
                                (doc["date"] as Timestamp)
                                    .toDate();
                            return Card(
                              child: ListTile(
                                leading:
                                    const Icon(Icons.payments),
                                title: Text(
                                    "${doc["amount"]} MAD - ${doc["category"]}"),
                                subtitle: Text(
                                  DateFormat('dd/MM/yyyy')
                                          .format(date) +
                                      (doc["notes"] != null &&
                                              doc["notes"]
                                                  .toString()
                                                  .isNotEmpty
                                          ? "\n${doc["notes"]}"
                                          : ""),
                                ),
                              ),
                            );
                          }),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================
  // Dialog salaire
  // ============================
  void showSalaryDialog(String userId, String monthKey) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Salaire du mois"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration:
              const InputDecoration(labelText: "Montant (MAD)"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount =
                  double.tryParse(controller.text) ?? 0;

              await FirebaseFirestore.instance
                  .collection("salaries")
                  .doc("${userId}_$monthKey")
                  .set({
                "userId": userId,
                "month": monthKey,
                "amount": amount,
              });

              Navigator.pop(context);
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  // ============================
  // UI helpers
  // ============================
  Widget summaryCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(label),
        ],
      ),
    );
  }
}
