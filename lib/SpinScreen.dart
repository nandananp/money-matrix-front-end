import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:money_matrix/EventScreen.dart';
import 'package:money_matrix/WheelPainter.dart';

class SpinScreen extends StatefulWidget {
  const SpinScreen({super.key});

  @override
  _SpinScreenState createState() => _SpinScreenState();
}

class _SpinScreenState extends State<SpinScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
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
  final String apiUrl = "http://10.0.2.2:8080/v1/user/game/next-event";
  int targetIndex = 0;
  bool isSpinning = false;
  Map<String, dynamic>? eventDetails;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(_controller);
  }

  Future<void> spinWheel() async {
    if (isSpinning) return;
    setState(() {
      isSpinning = true;
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
      String eventType = eventDetails!["eventType"];
      setState(() {
        targetIndex = options.indexOf(eventType);
        isSpinning = true;
      });
      startSpin();
    } else {
      setState(() {
        isSpinning = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to fetch spin result")),
      );
    }
  }

  void startSpin() {
    final random = Random();
    int spins = 3 + random.nextInt(5);
    double targetRotation =
        spins * 2 * pi + (targetIndex * (2 * pi / options.length));

    _animation = Tween<double>(
      begin: 0,
      end: targetRotation,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ))
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            selectedOption = options[targetIndex];
            isSpinning = false;
          });
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventScreen(eventDetails: eventDetails!),
            ),
          );
        }
      });

    _controller.reset();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Spin Event"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  angle: _animation.value,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.pink,
                          Colors.blue,
                          Colors.green,
                          Colors.orange
                        ],
                        stops: [0.1, 0.4, 0.7, 1.0],
                      ),
                    ),
                    child: CustomPaint(
                      painter: WheelPainter(options),
                    ),
                  ),
                ),
                const Positioned(
                  top: 20,
                  child:
                  Icon(Icons.arrow_drop_down, size: 50, color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isSpinning ? null : spinWheel,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Spin",
                  style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
