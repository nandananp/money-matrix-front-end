import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:money_matrix/FinancialReportScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _errorMessage;


  //checking financial status
  Future<void> fetchFinancialReport() async {
    Map<String, dynamic>? financialData;
    const String apiUrl = 'http://localhost:8080/v1/user/game/status';
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');
    final response = await http
        .get(Uri.parse(apiUrl), headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode == 200) {
      setState(() {
        financialData = json.decode(response.body);
      });
      if(!mounted)return;
      Navigator.push(context,MaterialPageRoute(builder: (context) => const FinancialReportScreen()));
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(builder: (context) => const FinancialReportScreen()),
      // );

      // Check after fetching data
    } else {
      Navigator.pushReplacementNamed(context, '/instructions');
    }
  }

  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8080/v1/user/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _emailController.text,
          'password': _passwordController.text,
        }),
      );
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];

        // Save token for future API calls
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);

        if (!mounted) return; // Check again before navigation
          fetchFinancialReport();
      } else if (response.statusCode == 400) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Invalid credentials';
        });
      } else {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Login failed. Please try again later.';
        });
      }
    } catch (e) {
      print(e);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Username'),
                keyboardType: TextInputType.name,
                validator: (value) => value!.isEmpty ? 'Enter an email' : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) => value!.isEmpty ? 'Please enter a password' : null,
              ),
              const SizedBox(height: 20),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loginUser,
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
