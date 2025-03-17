import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:money_matrix/EventScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecondActivityScreen extends StatefulWidget {
  const SecondActivityScreen({super.key});

  @override
  State<SecondActivityScreen> createState() => _SecondActivityScreenState();
}

class _SecondActivityScreenState extends State<SecondActivityScreen> {
  int _countdown = 3;
  double _progress = 1.0;

  final List<String> options = [
    "STOCK",
    "MUTUAL_FUND",
    "DONATION",
    "CREDIT_CARD",
    "WATER_BILL",
    "CAR",
    "PHONE",
    "HOUSE"
  ];
  String selectedOption = "";
  final String apiUrl = "http://localhost:8080/v1/user/game/next-event";
  int targetIndex = 0;
  Map<String, dynamic>? eventDetails;



  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  Future<void> _startCountdown() async {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown == 1) {
        timer.cancel();
        _navigateToEventScreen();
      } else {
        setState(() {
          _countdown--;
          _progress = _countdown / 3; // Update progress for circular indicator
        });
      }
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );


    if (response.statusCode == 200) {
      eventDetails = jsonDecode(response.body);
      eventDetails?['LEVEL'] = 2;
      String eventType = eventDetails!["eventType"];
      setState(() {
        targetIndex = options.indexOf(eventType);
        selectedOption = options[targetIndex];
      });
    } else {
      setState(() {
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to fetch spin result")),
      );
    }
  }

  void _navigateToEventScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => EventScreen(eventDetails: eventDetails!)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark theme background
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text(
          "Level - 2",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 150,
              height: 150,
              child: CircularProgressIndicator(
                value: _progress,
                strokeWidth: 8,
                backgroundColor: Colors.grey[700],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _countdown == 3 ? Colors.red : _countdown == 2 ? Colors.orange : Colors.green,
                ),
              ),
            ),
            Text(
              "$_countdown",
              style: TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.bold,
                color: _countdown == 3 ? Colors.red : _countdown == 2 ? Colors.orange : Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


