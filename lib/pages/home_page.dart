import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'add_expense_page.dart';
import 'monthly_expenses_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final userId = user.uid;

    final now = DateTime.now();
    final startMonth = DateTime(now.year, now.month, 1);
    final endMonth = DateTime(now.year, now.month + 1, 1);
    final monthKey = DateFormat('yyyy-MM').format(now);
    final monthLabel = DateFormat('MMMM yyyy', 'fr_FR').format(now);

    final salaryDocId = "${userId}_$monthKey";

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      drawer: drawerMenu(userId),
      appBar: AppBar(
        title: const Text("Dashboard"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(userId)
            .snapshots(),

        builder: (context, userSnap) {
          if (!userSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = userSnap.data!.data() as Map<String, dynamic>;
          final firstName = userData["firstName"] ?? "";
          final baseSalaryProfile =
              (userData["baseSalary"] ?? 0).toDouble();

          // 🔥 garantir l’existence du salaire du mois
          FirebaseFirestore.instance
              .collection("salaries")
              .doc(salaryDocId)
              .set({
            "userId": userId,
            "month": monthKey,
            "baseSalary": baseSalaryProfile,
            "bonuses": [],
          }, SetOptions(merge: true));

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("expenses")
                .where("userId", isEqualTo: userId)
                .where("date",
                    isGreaterThanOrEqualTo:
                        Timestamp.fromDate(startMonth))
                .where("date",
                    isLessThan: Timestamp.fromDate(endMonth))
                .orderBy("date", descending: true)
                .snapshots(),

            builder: (context, expenseSnap) {
              if (!expenseSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final expenses = expenseSnap.data!.docs;
              double totalExpenses = 0;

              for (var e in expenses) {
                totalExpenses += (e["amount"] as num).toDouble();
              }

              final lastExpense =
                  expenses.isNotEmpty ? expenses.first : null;

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("salaries")
                    .doc(salaryDocId)
                    .snapshots(),

                builder: (context, salarySnap) {
                  double baseSalary = baseSalaryProfile;
                  double bonusesTotal = 0;

                  if (salarySnap.hasData && salarySnap.data!.exists) {
                    final data =
                        salarySnap.data!.data() as Map<String, dynamic>;
                    baseSalary = (data["baseSalary"] ?? baseSalary).toDouble();
                    final bonuses = data["bonuses"] ?? [];

                    for (var b in bonuses) {
                      bonusesTotal += (b["amount"] as num).toDouble();
                    }
                  }

                  final totalSalary = baseSalary + bonusesTotal;
                  final remaining = totalSalary - totalExpenses;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Bonjour, $firstName 👋",
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        Text(monthLabel,
                            style: const TextStyle(color: Colors.grey)),

                        const SizedBox(height: 25),

                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            statCard(
                              icon: Icons.payments,
                              label: "Salaire du mois",
                              value:
                                  "${totalSalary.toStringAsFixed(2)} MAD",
                              color: Colors.green,
                            ),
                            statCard(
                              icon: Icons.euro,
                              label: "Dépenses",
                              value:
                                  "${totalExpenses.toStringAsFixed(2)} MAD",
                              color: Colors.blueAccent,
                            ),
                            statCard(
                              icon: Icons.account_balance_wallet,
                              label: "Reste",
                              value:
                                  "${remaining.toStringAsFixed(2)} MAD",
                              color: remaining >= 0
                                  ? Colors.teal
                                  : Colors.red,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text("Ajouter une prime"),
                            onPressed: () =>
                                showBonusDialog(userId, monthKey),
                          ),
                        ),

                        const SizedBox(height: 30),

                        const Text(
                          "Dernière dépense du mois",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 10),

                        lastExpense == null
                            ? emptyLastExpense()
                            : lastExpenseCard(lastExpense),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // ============================
  // PRIME
  // ============================
  void showBonusDialog(String userId, String monthKey) {
    final amountCtrl = TextEditingController();
    final labelCtrl = TextEditingController();

    showDialog(
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
              decoration:
                  const InputDecoration(labelText: "Montant (MAD)"),
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
              final amount =
                  double.tryParse(amountCtrl.text) ?? 0;

              await FirebaseFirestore.instance
                  .collection("salaries")
                  .doc("${userId}_$monthKey")
                  .update({
                "bonuses": FieldValue.arrayUnion([
                  {
                    "label": labelCtrl.text,
                    "amount": amount,
                    "date": Timestamp.now(),
                  }
                ])
              });

              Navigator.pop(context);
            },
            child: const Text("Ajouter"),
          ),
        ],
      ),
    );
  }

  // ============================
  // UI HELPERS
  // ============================
  Widget statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: boxStyle(),
      child: Column(
        children: [
          Icon(icon, size: 34, color: color),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget lastExpenseCard(DocumentSnapshot doc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: boxStyle(),
      child: ListTile(
        leading: const Icon(Icons.shopping_cart),
        title: Text(doc["category"]),
        subtitle: Text("${doc["amount"]} MAD"),
      ),
    );
  }

  Widget emptyLastExpense() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: boxStyle(),
      child: const Text("Aucune dépense ce mois-ci"),
    );
  }

  Drawer drawerMenu(String userId) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.deepPurple),
            child:
                Center(child: Icon(Icons.person, size: 60, color: Colors.white)),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Profil"),
            onTap: () => goTo(const ProfilePage()),
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text("Ajouter dépense"),
            onTap: () => goTo(const AddExpensePage()),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month),
            title: const Text("Dépenses mensuelles"),
            onTap: () => goTo(const MonthlyExpensesPage()),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title:
                const Text("Se déconnecter", style: TextStyle(color: Colors.red)),
            onTap: logout,
          ),
        ],
      ),
    );
  }

  void goTo(Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  BoxDecoration boxStyle() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }
}
