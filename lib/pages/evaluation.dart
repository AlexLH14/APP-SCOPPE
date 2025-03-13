import 'package:flutter/material.dart';
import 'package:scope_app/navbar/navbar.dart';

class EvaluationPage extends StatefulWidget {
  const EvaluationPage({super.key});

  @override
  State<EvaluationPage> createState() => _EvaluationPageState();
}

class _EvaluationPageState extends State<EvaluationPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Scope Trade Management'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 15,
          shadowColor: Colors.blueAccent,
        ),
        body: const Center(
          child: Text('Evaluation Option'),
        ),
        drawer: const NavDrawer());
  }
}
