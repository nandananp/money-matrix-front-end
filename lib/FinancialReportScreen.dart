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
        if ((financialData?["passiveIncome"] ?? 0) >= 15000) {
          Future.delayed(Duration.zero, () => _showLevelUpDialog(context));
        }
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
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.celebration, color: Colors.orange, size: 50),
                const SizedBox(height: 15),
                const Text(
                  "Congratulations!",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  "You have successfully completed Level One by making your liabilities zero. Let's build passive incomes now!",
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.popAndPushNamed(context, '/second_activity'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Continue", style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text("New Month Salary Report",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReportRow("New Month Salary", financialData?["salaryReport"]?["SALARY"]),
              _buildReportRow("EMIs Deducted", financialData?["salaryReport"]?["EMI'S"]),
              _buildReportRow("SIP Amount Deducted", financialData?["salaryReport"]?["SIP AMOUNT"]),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text("Close", style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReportRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          Text("₹${value ?? 0}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
        ],
      ),
    );
  }

  void _showLevelUpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // Rounded corners
        ),
        title: const Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber, size: 28), // Trophy icon
            SizedBox(width: 10),
            Text(
              "Congratulations!",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.deepPurple, // Professional color
              ),
            ),
          ],
        ),
        content: const Text(
          "You have completed Level - 2 🎉 , now you have successfully escaped from 'Rat-Race' and you are financially free now",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.deepPurple,
              ),
              child: const Text(
                "OK",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
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
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Job: ${financialData?["jobName"]}",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                  const SizedBox(height: 6),
                  Text("Salary: ₹${financialData?["salary"]}", style: const TextStyle(fontSize: 16)),

                  // Passive Income Section with Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Passive Income: ₹${financialData?["passiveIncome"] ?? 0}",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Stack(
                        alignment: Alignment.centerRight,
                        children: [
                          Container(
                            width: double.infinity, // Ensures it spans the available space
                            height: 12, // Adjust height for better visibility
                            decoration: BoxDecoration(
                              color: Colors.grey[300], // Background color
                              borderRadius: BorderRadius.circular(6), // Rounded corners
                            ),
                          ),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              double progress = (financialData?["passiveIncome"] ?? 0) / 15000;
                              return Container(
                                width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              );
                            },
                          ),
                          Positioned(
                            right: 10,
                            child: Text(
                              "${(financialData?["passiveIncome"] ?? 0)}/15000",
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),


                  Text("Game Status: ${financialData?["gameStatus"]}", style: const TextStyle(fontSize: 16)),
                  Text("Savings: ₹${financialData?["savings"]}", style: const TextStyle(fontSize: 16)),
                ],


              ),
            ),
          ),

          const SizedBox(height: 12),

          // Mutual Funds Section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text("Mutual Funds",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
          ),
          ...?financialData?["mutualFunds"]?.map<Widget>(
                (fund) => Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: ListTile(
                title: Text(fund["mutualFundName"] ?? "Unknown",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                subtitle: Text("Total Return: ₹${fund["totalReturn"]}, SIP: ₹${fund["sipAmount"]}"),
              ),
            ),
          ),

          // Stocks Section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text("Stocks",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
          ),
          ...?financialData?["stocks"]?.map<Widget>(
                (stock) => Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: ListTile(
                title: Text(stock["stockName"],
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                subtitle: Text("Stock Count: ${stock["stockCount"]}, Invested: ₹${stock["investedAmount"]}"),
              ),
            ),
          ),

          // Liabilities Section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text("Liabilities",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
          ),
          ...?financialData?["liabilities"]?.map<Widget>(
                (liability) => Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              child: ListTile(
                title: Text(liability["liabilityName"].toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Text("EMI: ₹${liability["emi"]}, Full Amount: ₹${liability["fullAmount"]}"),
                trailing: ElevatedButton(
                  onPressed: () => showSettlementDialog(
                    liability["liabilityId"],
                    liability["fullAmount"],
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Settle"),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Go to Next Month Button
          _buildActionButton("Go to the Next Month", Icons.arrow_forward, Colors.blueAccent, checkAndShowLevelCompletionPopup),

          const SizedBox(height: 16),

          // View Salary Report Button
          _buildActionButton("View Salary Report", Icons.bar_chart, Colors.green, showSalaryReportPopup),
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
