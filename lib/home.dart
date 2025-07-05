import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled4/history.dart' show HistoryPage;
import 'package:fl_chart/fl_chart.dart';

class MyHomePage extends StatefulWidget {
  final String username;
  const MyHomePage({super.key, required this.username});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController incomeController = TextEditingController();
  final TextEditingController expenseController = TextEditingController();

  int a = 0; // Income
  int b = 0; // Expense
  int get balance => a - b;
  List<FlSpot> incomeSpots = [];
  List<FlSpot> expenseSpots = [];

  @override
  void initState() {
    super.initState();
    loadUserData();
    loadTransactionSpots();
  }

  Future<void> loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (doc.exists) {
      final data = doc.data();
      setState(() {
        a = data?['income'] ?? 0;
        b = data?['expense'] ?? 0;
      });
    }
  }

  Future<void> loadTransactionSpots() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .orderBy('timestamp')
        .get();

    List<FlSpot> tempIncome = [];
    List<FlSpot> tempExpense = [];
    double incomeSum = 0;
    double expenseSum = 0;
    int index = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final type = data['type'];
      final amount = (data['amount'] as num).toDouble();

      if (type == 'income') {
        incomeSum += amount;
        tempIncome.add(FlSpot(index.toDouble(), incomeSum));
      } else if (type == 'expense') {
        expenseSum += amount;
        tempExpense.add(FlSpot(index.toDouble(), expenseSum));
      }
      index++;
    }

    setState(() {
      incomeSpots = tempIncome;
      expenseSpots = tempExpense;
    });
  }

  Future<void> saveUserData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'income': a,
      'expense': b,
    }, SetOptions(merge: true));
  }

  Future<void> addTransaction(String type, int amount) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .add({
      'type': type,
      'amount': amount,
      'timestamp': DateTime.now(),
    });
    await loadTransactionSpots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Wallet App', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 0,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(widget.username.split('@')[0], style: GoogleFonts.poppins()),
              accountEmail: Text(widget.username, style: GoogleFonts.poppins(fontSize: 12)),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Colors.deepPurpleAccent, size: 40),
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurpleAccent, Colors.purpleAccent],
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text('History', style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryPage()));
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout', style: GoogleFonts.poppins()),
              onTap: () async {
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirm Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout')),
                    ],
                  ),
                );
                if (shouldLogout == true) {
                  await FirebaseAuth.instance.signOut();
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('login_timestamp');
                  Navigator.pushReplacementNamed(context, '/');
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings', style: GoogleFonts.poppins()),
              onTap: () {},
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: ListTile(
                contentPadding: EdgeInsets.all(16),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.deepPurpleAccent,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(widget.username.split('@')[0], style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                subtitle: Text('Student', style: GoogleFonts.poppins(fontSize: 12)),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Text('Balance', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold)),
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: 400),
                    child: Text(
                      '₹$balance',
                      key: ValueKey<int>(balance),
                      style: GoogleFonts.poppins(fontSize: 36, color: Colors.green, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text('Income', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.green)),
                          const SizedBox(height: 8),
                          Text('₹$a', style: GoogleFonts.poppins(fontSize: 20)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: incomeController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(hintText: 'Enter amount'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              if (incomeController.text.isNotEmpty) {
                                final income = int.tryParse(incomeController.text) ?? 0;
                                setState(() {
                                  a += income;
                                  incomeController.clear();
                                });
                                await saveUserData();
                                await addTransaction('income', income);
                              }
                            },
                            icon: Icon(Icons.add),
                            label: Text('Add'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade300),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text('Expense', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                          const SizedBox(height: 8),
                          Text('₹$b', style: GoogleFonts.poppins(fontSize: 20)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: expenseController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(hintText: 'Enter amount'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final enteredExpense = int.tryParse(expenseController.text) ?? 0;
                              if (enteredExpense > 0) {
                                if (enteredExpense <= a - b) {
                                  setState(() {
                                    b += enteredExpense;
                                    expenseController.clear();
                                  });
                                  await saveUserData();
                                  await addTransaction('expense', enteredExpense);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Insufficient balance. You can't spend more than your income."),
                                      backgroundColor: Colors.redAccent,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              }
                            },
                            icon: Icon(Icons.remove),
                            label: Text('Add'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.shade100),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
        SizedBox(height: 20),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: (incomeSpots.length > expenseSpots.length
                ? incomeSpots.length
                : expenseSpots.length) * 80.0,
            height: 300,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Text('₹${value.toInt()}'),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Text('${value.toInt() + 1}'),
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true),
                minX: 0,
                maxX: (incomeSpots.length > expenseSpots.length
                    ? incomeSpots.length
                    : expenseSpots.length)
                    .toDouble(),
                minY: 0,
                maxY: ((a > b ? a : b) + 50).toDouble(),
                lineBarsData: [
                  LineChartBarData(
                    spots: incomeSpots,
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 4,
                    dotData: FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: expenseSpots,
                    isCurved: true,
                    color: Colors.redAccent,
                    barWidth: 4,
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),

            ),
          ],
        ),
      ),
    );
  }
}