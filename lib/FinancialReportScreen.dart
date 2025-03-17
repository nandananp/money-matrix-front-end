import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'SpinScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:money_matrix/SecondLevelActivityScreen.dart';

class FinancialReportScreen extends StatefulWidget {
  int level ;
   FinancialReportScreen({super.key ,required this.level });

  @override
  _FinancialReportScreenState createState() => _FinancialReportScreenState();
}

class _FinancialReportScreenState extends State<FinancialReportScreen> {
  Map<String, dynamic>? financialData;
  bool hasShownPopup = false; // To ensure popup is shown only once

  @override
  void initState() {
    super.initState();
    fetchFinancialReport();
    checkLevelStatus(1); // Fetch level status
  }

  Future<void> fetchFinancialReport() async {
    const String apiUrl = 'http://localhost:8080/v1/user/game/status';
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');
    final response = await http
        .get(Uri.parse(apiUrl), headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode == 200) {
      setState(() {
        financialData = json.decode(response.body);
      });
      // Check after fetching data
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to fetch financial data")));
    }
  }

  Future<void> checkLevelStatus(int levelNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');
    final response = await http.get(
      Uri.parse('http://localhost:8080/v1/user/status/level/$levelNumber'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final levelData = json.decode(response.body);
      var level = widget.level;
      if (levelData['levelFlag'] == true && level == 1) {
        showLevelCompletionPopup();
      }
    }
  }

  void checkAndShowLevelCompletionPopup() {
    if (!hasShownPopup && financialData?['liabilities'] != null) {
      bool allSettled = financialData!['liabilities'].isEmpty;
      var level = widget.level;
      if (allSettled ) {
        hasShownPopup = true; // Mark popup as shown
        if(level == 2){
          Navigator.push(context, MaterialPageRoute(builder: (context) => const SecondActivityScreen()));
        }else {
          showLevelCompletionPopup();
        }

      }else{
        Navigator.push(context, MaterialPageRoute(builder: (context) => const SpinScreen()));
      }
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
              onPressed: () => Navigator.popAndPushNamed(context,'/second_activity'),
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
      showTopSnackBar(context, "You don't have enough money!", Colors.red);
    }

    final response = await http.post(
      Uri.parse("http://localhost:8080/v1/user/update/$liabilityId"),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      fetchFinancialReport();
      showTopSnackBar(context, "Liability settled successfully!", Colors.green);
    } else {
      showTopSnackBar(context, "You don't have enough money!", Colors.red);
    }
  }

  void showTopSnackBar(BuildContext context, String message, Color bgColor) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50, // Adjust top margin
        left: MediaQuery.of(context).size.width * 0.1,
        width: MediaQuery.of(context).size.width * 0.8,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 4, spreadRadius: 2),
              ],
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Remove the overlay after 2 seconds
    Future.delayed(const Duration(seconds: 1), () {
      overlayEntry.remove();
    });
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
  void showSalaryReportPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("New Month Salary Report"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("New Month Salary: ₹${financialData?["salaryReport"]?["SALARY"] ?? 0}"),
              Text("EMIs deducted : ₹${financialData?["salaryReport"]?["EMI'S"] ?? 0}"),
              Text("SIP Amount deducted : ₹${financialData?["salaryReport"]?["SIP AMOUNT"] ?? 0}"),

            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Your financial Report is here"),backgroundColor: Colors.deepPurple,),
      body: financialData == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text("Job: ${financialData?["jobName"]}",
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          Text("Salary: ₹${financialData?["salary"]}"),
          Text("Passive Income: ₹${financialData?["passiveIncome"]}"),
          Text("Game Status: ${financialData?["gameStatus"]}"),
          Text("Savings: ₹${financialData?["savings"]}"),
          const SizedBox(height: 16),

          // Mutual Funds Section
          const Text("Mutual Funds",
              style:
              TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ...?financialData?["mutualFunds"]
              ?.map<Widget>((fund) => ListTile(
            title: Text(fund["mutualFundName"] ?? "Unknown"),
            subtitle: Text(
                "Total Return: ₹${fund["totalReturn"]}, SIP: ₹${fund["sipAmount"]}"),
          )),
          const SizedBox(height: 16),

          // Stocks Section
          const Text("Stocks",
              style:
              TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ...?financialData?["stocks"]?.map<Widget>((stock) => ListTile(
            title: Text(stock["stockName"]),
            subtitle: Text(
                "Stock Count: ${stock["stockCount"]}, Invested: ₹${stock["investedAmount"]}"),
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
                "EMI: ₹${liability["emi"]}, Full Amount: ₹${liability["fullAmount"]}"),
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
            onPressed: () => checkAndShowLevelCompletionPopup(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent, // Professional blue shade
              foregroundColor: Colors.white, // White text for contrast
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8), // Slightly rounded corners
              ),
            ),
            child: _buildActionButton(
                "Go to the next Month", Icons.arrow_forward, Colors.blueAccent,
                checkAndShowLevelCompletionPopup),
          ),
          const SizedBox(height: 25),
          ElevatedButton(
                    onPressed: showSalaryReportPopup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      // A balanced green for financial themes
                      foregroundColor: Colors.white,
                      // White text for readability
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _buildActionButton("View Salary Report",
                        Icons.bar_chart, Colors.green, showSalaryReportPopup)),
              ],
            ),
    );
  }

  // Widget for action buttons
  Widget _buildActionButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(text, style: const TextStyle(fontSize: 16, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
