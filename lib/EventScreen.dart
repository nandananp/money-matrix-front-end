import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:money_matrix/FinancialReportScreen.dart';

class EventScreen extends StatefulWidget {
  final Map<String, dynamic> eventDetails;

  const EventScreen({super.key, required this.eventDetails});

  @override
  _EventScreenState createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  final TextEditingController _eventCountController = TextEditingController(text: "0");
  bool _canSellStock = false;

  @override
  void initState() {
    super.initState();
    if (widget.eventDetails["eventType"] == "STOCK") {
      checkUserStock();
    }
  }

  Future<void> checkUserStock() async {
    const String apiUrl = "http://localhost:8080/v1/user/game/status";
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) return;

    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<dynamic> stocks = data['stocks'] ?? [];
      String currentStockName = widget.eventDetails['eventName'];

      bool ownsStock = stocks.any((stock) =>
      stock['stockName'] == currentStockName && stock['stockCount'] > 0);

      setState(() {
        _canSellStock = ownsStock;
      });
    }
  }

  Future<void> submitDecision(BuildContext context, String decision) async {
    const String apiUrl = "http://localhost:8080/v1/user/game/event-decision";
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Authentication error: No token found")),
      );
      return;
    }

    int eventCount = int.tryParse(_eventCountController.text) ?? 0;

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "eventId": widget.eventDetails["eventId"],
        "eventType": widget.eventDetails["eventType"],
        "eventDecision": decision,
        "eventCount": eventCount
      }),
    );

    if (response.statusCode == 200 && context.mounted) {
      var level = widget.eventDetails['LEVEL'];
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => FinancialReportScreen(level: level,)),
      );
    } else {
      if(widget.eventDetails["eventType"] == "STOCK") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("currently you can't buy same stock twice..")),
        );
      } else if(widget.eventDetails["eventType"] == "MUTUAL_FUND"){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("currently you can't start same mutual fund twice..")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to submit")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMandatory = widget.eventDetails["eventMandatory"] == true;
    bool isStockEvent = widget.eventDetails["eventType"] == "STOCK";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your decision depends on your financial knowledge!"),
        backgroundColor: Colors.white,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${widget.eventDetails["eventName"]}",
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                    ),
                    const SizedBox(height: 10),
                    Text("Type: ${widget.eventDetails["eventType"]}", style: const TextStyle(fontSize: 18)),
                    Text("Description: ${widget.eventDetails["eventDescription"]}", style: const TextStyle(fontSize: 16)),
                    Text("Mandatory: ${widget.eventDetails["eventMandatory"]}", style: const TextStyle(fontSize: 16)),
                    if (widget.eventDetails["eventFixedAmount"] != null)
                      Text("Fixed Amount: ₹${widget.eventDetails["eventFixedAmount"]}", style: const TextStyle(fontSize: 16)),
                    if (widget.eventDetails["eventMinimumAmount"] != null && widget.eventDetails["eventMaximumAmount"] != null)
                      Text("Amount Range: ₹${widget.eventDetails["eventMinimumAmount"]} - ₹${widget.eventDetails["eventMaximumAmount"]}", style: const TextStyle(fontSize: 16)),
                    if (widget.eventDetails["eventCurrentPrice"] != null)
                      Text("Current Price: ₹${widget.eventDetails["eventCurrentPrice"]}", style: const TextStyle(fontSize: 16)),
                    if (isStockEvent)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 15),
                          const Text("Enter Stock Quantity:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          TextField(
                            controller: _eventCountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: "Enter a number",
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty && int.tryParse(value) == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Please enter a valid number")),
                                );
                                _eventCountController.text = "0";
                              }
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            if (isMandatory)
              ElevatedButton(
                onPressed: () => submitDecision(context, "ACCEPT"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Pay", style: TextStyle(fontSize: 18, color: Colors.white)),
              )
            else ...[
              ElevatedButton(
                onPressed: () => submitDecision(context, "ACCEPT"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Accept", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: () => submitDecision(context, "REJECT"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Reject", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
              const SizedBox(height: 15),
              if (_canSellStock && isStockEvent) ...[
                const SizedBox(height: 25),
                ElevatedButton(
                  onPressed: () => submitDecision(context, "SELL"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Sell",
                      style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ]
            ]
          ],
        ),
      ),
    );
  }
}
