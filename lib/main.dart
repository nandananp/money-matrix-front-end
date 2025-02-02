import 'package:flutter/material.dart';
import 'package:money_matrix/SpinScreen.dart';
import 'package:money_matrix/SplashScreen.dart';
import 'package:money_matrix/registration.dart';
import 'package:money_matrix/LoginPage.dart';
import 'package:money_matrix/secondScreen.dart';
import 'package:money_matrix/InstructionsPage.dart';
import 'package:money_matrix/StartGamePage.dart';
import 'package:money_matrix/SpinScreen.dart';

void main() {
    runApp(const MoneyMatrixApp());
}
class MoneyMatrixApp extends StatelessWidget {
  const MoneyMatrixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Money Matrix',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/option': (context) => const SecondScreen(),
        '/register': (context) => const RegistrationPage(),
        '/login': (context) => const LoginPage(),
        '/instructions': (context) => const InstructionsPage(),
        '/startGame': (context) => const StartGamePage(),
        '/spin': (context) => const SpinScreen(),
      },
    );
  }
}
