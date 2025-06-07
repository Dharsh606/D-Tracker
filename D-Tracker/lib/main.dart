// D Tracker - Advanced Personal Finance App

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

void main() => runApp(DTrackerApp());

class DTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'D Tracker',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.tealAccent,
        textTheme: TextTheme(bodyMedium: TextStyle(color: Colors.white)),
      ),
      home: DTrackerHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Transaction {
  String type;
  String category;
  String description;
  double amount;
  String date;

  Transaction(
      {required this.type,
        required this.category,
        required this.description,
        required this.amount,
        required this.date});

  Map<String, dynamic> toJson() => {
    'type': type,
    'category': category,
    'description': description,
    'amount': amount,
    'date': date,
  };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    type: json['type'],
    category: json['category'],
    description: json['description'],
    amount: json['amount'],
    date: json['date'],
  );
}

class DTrackerHomePage extends StatefulWidget {
  @override
  _DTrackerHomePageState createState() => _DTrackerHomePageState();
}

class _DTrackerHomePageState extends State<DTrackerHomePage> {
  List<Transaction> transactions = [];
  String selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> jsonList =
    transactions.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('transactions', jsonList);
  }

  void loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? jsonList = prefs.getStringList('transactions');
    if (jsonList != null) {
      transactions =
          jsonList.map((e) => Transaction.fromJson(jsonDecode(e))).toList();
      setState(() {});
    }
  }

  void addTransaction(Transaction txn) {
    setState(() {
      transactions.add(txn);
      saveData();
    });
  }

  void deleteTransaction(int index) {
    setState(() {
      transactions.removeAt(index);
      saveData();
    });
  }

  double getTotal(String type) {
    return transactions
        .where((txn) => txn.type == type)
        .fold(0, (sum, txn) => sum + txn.amount);
  }

  double getBalance() => getTotal("Income") - getTotal("Expense");

  List<Transaction> getFilteredTransactions() {
    if (selectedCategory == 'All') return transactions;
    return transactions
        .where((txn) => txn.category == selectedCategory)
        .toList();
  }

  void openAddTransactionDialog() {
    String selectedType = 'Expense';
    String selectedCategory = 'Food';
    TextEditingController amountController = TextEditingController();
    TextEditingController descController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text("Add Transaction"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: selectedType,
                items: ['Income', 'Expense']
                    .map((e) => DropdownMenuItem(
                    child: Text(e), value: e))
                    .toList(),
                onChanged: (value) => selectedType = value!,
                dropdownColor: Colors.black,
              ),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: ['Food', 'Rent', 'Salary', 'Shopping', 'Misc']
                    .map((e) => DropdownMenuItem(
                    child: Text(e), value: e))
                    .toList(),
                onChanged: (value) => selectedCategory = value!,
                dropdownColor: Colors.black,
              ),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Amount'),
              ),
              TextField(
                controller: descController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              double? amt = double.tryParse(amountController.text);
              if (amt != null && descController.text.isNotEmpty) {
                addTransaction(Transaction(
                  type: selectedType,
                  category: selectedCategory,
                  description: descController.text,
                  amount: amt,
                  date: DateFormat.yMMMd().format(DateTime.now()),
                ));
                Navigator.pop(context);
              }
            },
            child: Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double balance = getBalance();
    double income = getTotal("Income");
    double expense = getTotal("Expense");

    return Scaffold(
      appBar: AppBar(
        title: Text("💰 D Tracker"),
        centerTitle: true,
        actions: [
          DropdownButton<String>(
            value: selectedCategory,
            dropdownColor: Colors.grey,
            underline: SizedBox(),
            items: ['All', 'Food', 'Rent', 'Salary', 'Shopping', 'Misc']
                .map((e) => DropdownMenuItem(
                child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(e)),
                value: e))
                .toList(),
            onChanged: (value) => setState(() => selectedCategory = value!),
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal, Colors.tealAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text("Balance", style: TextStyle(fontSize: 18)),
                Text("₹${balance.toStringAsFixed(2)}",
                    style:
                    TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text("Income"),
                        Text("+ ₹${income.toStringAsFixed(2)}",
                            style: TextStyle(color: Colors.greenAccent)),
                      ],
                    ),
                    Column(
                      children: [
                        Text("Expense"),
                        Text("- ₹${expense.toStringAsFixed(2)}",
                            style: TextStyle(color: Colors.redAccent)),
                      ],
                    ),
                  ],
                )
              ],
            ),
          ),
          if (income > 0 || expense > 0)
            SizedBox(
              height: 150,
              child: PieChart(PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: income,
                      color: Colors.greenAccent,
                      title: 'Income',
                    ),
                    PieChartSectionData(
                      value: expense,
                      color: Colors.redAccent,
                      title: 'Expense',
                    )
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 40)),
            ),
          Divider(color: Colors.tealAccent),
          Expanded(
            child: ListView.builder(
              itemCount: getFilteredTransactions().length,
              itemBuilder: (_, i) {
                final txn = getFilteredTransactions()[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                    txn.type == 'Income' ? Colors.green : Colors.red,
                    child: Icon(
                        txn.type == 'Income'
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        color: Colors.white),
                  ),
                  title: Text(txn.description),
                  subtitle: Text("${txn.category} • ${txn.date}"),
                  trailing: Text("₹${txn.amount.toStringAsFixed(2)}"),
                  onLongPress: () => deleteTransaction(i),
                );
              },
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: openAddTransactionDialog,
        child: Icon(Icons.add),
        backgroundColor: Colors.tealAccent,
      ),
    );
  }
}
