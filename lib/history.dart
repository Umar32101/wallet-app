import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('User not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Transaction History', style: GoogleFonts.poppins()),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('transactions')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text('No transaction history found.',
                  style: GoogleFonts.poppins(fontSize: 16)),
            );
          }

          final transactions = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final data = transactions[index].data() as Map<String, dynamic>;
              final type = data['type'];
              final amount = data['amount'];
              final timestamp = (data['timestamp'] as Timestamp).toDate();

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 3,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                    type == 'income' ? Colors.green : Colors.redAccent,
                    child: Icon(
                      type == 'income' ? Icons.arrow_downward : Icons.arrow_upward,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    type == 'income' ? 'Income' : 'Expense',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: type == 'income' ? Colors.green : Colors.redAccent,
                    ),
                  ),
                  subtitle: Text(
                    '${timestamp.toLocal()}'.split('.')[0],
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  trailing: Text(
                    '₹$amount',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: type == 'income' ? Colors.green : Colors.redAccent,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
