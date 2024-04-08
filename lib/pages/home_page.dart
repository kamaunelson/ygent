import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final GenerativeModel _model;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(),
    );
  }
}