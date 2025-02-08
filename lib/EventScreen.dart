import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:money_matrix/FinancialReportScreen.dart';

class EventScreen extends StatelessWidget {
  final Map<String, dynamic> eventDetails;

  const EventScreen({super.key, required this.eventDetails});

  Future<void> submitDecision(BuildContext context, String decision) async {
    const String apiUrl = "http://10.0.2.2:8080/v1/user/game/event-decision";
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Authentication error: No token found")),
      );
      return;
    }

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "eventId": eventDetails["eventId"],
        "eventType": eventDetails["eventType"],
        "eventDecision": decision,
        "eventCount": 0
      }),
    );

    if (response.statusCode == 200 && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FinancialReportScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to submit decision")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMandatory = eventDetails["eventMandatory"] == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Event Decision"),
        backgroundColor: Colors.deepPurple,
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
                      "${eventDetails["eventName"]}",
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                    ),
                    const SizedBox(height: 10),
                    Text("Type: ${eventDetails["eventType"]}", style: const TextStyle(fontSize: 18)),
                    Text("Description: ${eventDetails["eventDescription"]}", style: const TextStyle(fontSize: 16)),
                    Text("Mandatory: ${eventDetails["eventMandatory"]}", style: const TextStyle(fontSize: 16)),
                    if (eventDetails["eventFixedAmount"] != null)
                      Text("Fixed Amount: \$${eventDetails["eventFixedAmount"]}", style: const TextStyle(fontSize: 16)),
                    if (eventDetails["eventMinimumAmount"] != null && eventDetails["eventMaximumAmount"] != null)
                      Text("Amount Range: \$${eventDetails["eventMinimumAmount"]} - \$${eventDetails["eventMaximumAmount"]}", style: const TextStyle(fontSize: 16)),
                    if (eventDetails["eventCurrentPrice"] != null)
                      Text("Current Price: \$${eventDetails["eventCurrentPrice"]}", style: const TextStyle(fontSize: 16)),
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
            ]
          ],
        ),
      ),
    );
  }
}
