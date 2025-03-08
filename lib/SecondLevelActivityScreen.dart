import 'package:flutter/material.dart';

class SecondActivityScreen extends StatefulWidget {
  const SecondActivityScreen({super.key});

  @override
  State<SecondActivityScreen> createState() => _SecondActivityScreenState();
}

class _SecondActivityScreenState extends State<SecondActivityScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Text("Second Activity screen"),
    );
  }
}
