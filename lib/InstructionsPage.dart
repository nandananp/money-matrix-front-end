import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class InstructionsPage extends StatefulWidget {
  const InstructionsPage({super.key});

  @override
  _InstructionsPageState createState() => _InstructionsPageState();
}

class _InstructionsPageState extends State<InstructionsPage> {
  List<dynamic> _instructions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchInstructions();
  }

  Future<void> _fetchInstructions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        setState(() {
          _errorMessage = "Authentication failed. Please log in again.";
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('http://localhost:8080/v1/user/info/levels'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _instructions = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Failed to load instructions.";
          _isLoading = false;
        });
      }
    } catch (e) {
      print(e);
      setState(() {
        _errorMessage = "An error occurred. Please try again.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Set black background
      appBar: AppBar(
        title: const Text('Instructions'),
        backgroundColor: Colors.deepOrange, // Dark AppBar
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _instructions.length,
              itemBuilder: (context, index) {
                final instruction = _instructions[index];
                return Card(
                  color: Colors.grey[850], // Dark card background
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue, // Accent color
                      child: Text(
                        instruction['level'].toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      instruction['instruction'],
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, "/startGame");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Button color
                padding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text("Start Level 1", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
