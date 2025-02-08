
import 'package:flutter/material.dart';
import 'package:money_matrix/SpinScreen.dart';

class FinancialReportScreen extends StatelessWidget {
  const FinancialReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Financial Report")),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SpinScreen()),
          ),
          child: const Text("Go to Spin Screen"),
        ),
      ),
    );
  }
}