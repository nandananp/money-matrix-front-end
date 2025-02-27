import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'SpinScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FinancialReportScreen extends StatefulWidget {
  const FinancialReportScreen({super.key});

  @override
  _FinancialReportScreenState createState() => _FinancialReportScreenState();
}

class _FinancialReportScreenState extends State<FinancialReportScreen> {
  Map<String, dynamic>? financialData;

  @override
  void initState() {
    super.initState();
    fetchFinancialReport();
  }

  Future<void> fetchFinancialReport() async {
    const String apiUrl = 'http://10.0.2.2:8080/v1/user/game/status';
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');
    final response = await http
        .get(Uri.parse(apiUrl), headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode == 200) {
      setState(() {
        financialData = json.decode(response.body);
      });
      checkLevelCompletion();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to fetch financial data")));
    }
  }

  void checkLevelCompletion() {
    if (financialData?['level'] == 1 && (financialData?['liabilities']?.isEmpty ?? true)) {
      showLevelCompletionPopup();
    }
  }

  void showLevelCompletionPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Congratulations!"),
          content: const Text(
              "You have successfully completed Level One by making your liabilities zero. Let's build passive incomes now!"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Continue"),
            ),
          ],
        );
      },
    );
  }

  void settleLiability(String liabilityId, String fullAmount) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');
    int savings = int.parse(financialData?['savings'].toString() ?? '0');
    int amountToPay = int.parse(fullAmount);

    if (savings < amountToPay) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You don't have enough money!")));
      return;
    }

    final response = await http.post(
      Uri.parse("http://10.0.2.2:8080/v1/user/update/$liabilityId"),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      fetchFinancialReport();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Liability settled successfully!")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to settle liability")));
    }
  }

  void showSettlementDialog(String liabilityId, String fullAmount) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Settle Liability"),
          content: const Text("Do you want to pay this liability?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                settleLiability(liabilityId, fullAmount);
              },
              child: const Text("Pay"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Financial Report")),
      body: financialData == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text("Job: ${financialData?["jobName"]}",
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          Text("Salary: \$${financialData?["salary"]}"),
          Text("Passive Income: \$${financialData?["passiveIncome"]}"),
          Text("Game Status: ${financialData?["gameStatus"]}"),
          Text("Savings: \$${financialData?["savings"]}"),
          const SizedBox(height: 16),

          // Mutual Funds Section
          const Text("Mutual Funds",
              style:
              TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ...?financialData?["mutualFunds"]
              ?.map<Widget>((fund) => ListTile(
            title: Text(fund["mutualFundName"] ?? "Unknown"),
            subtitle: Text(
                "Total Return: \$${fund["totalReturn"]}, SIP: \$${fund["sipAmount"]}"),
          )),
          const SizedBox(height: 16),

          // Stocks Section
          const Text("Stocks",
              style:
              TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ...?financialData?["stocks"]?.map<Widget>((stock) => ListTile(
            title: Text(stock["stockName"]),
            subtitle: Text(
                "Stock Count: ${stock["stockCount"]}, Invested: \$${stock["investedAmount"]}"),
          )),
          const SizedBox(height: 16),

          // Liabilities Section
          const Text("Liabilities",
              style:
              TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ...?financialData?["liabilities"]
              ?.map<Widget>((liability) => ListTile(
            title: Text(liability["liabilityName"].toUpperCase()),
            subtitle: Text(
                "EMI: \$${liability["emi"]}, Full Amount: \$${liability["fullAmount"]}"),
            trailing: ElevatedButton(
              onPressed: () => showSettlementDialog(
                  liability["liabilityId"],
                  liability["fullAmount"]),
              child: const Text("Settle"),
            ),
          )),
          const SizedBox(height: 16),

          // Go to Spin Screen Button
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SpinScreen()),
            ),
            child: const Text("next month event"),
          ),
        ],
      ),
    );
  }
}
