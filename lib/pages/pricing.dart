import 'package:flutter/material.dart';
import 'package:scope_app/navbar/navbar.dart';

class PricingPage extends StatefulWidget {
  const PricingPage({super.key});

  @override
  State<PricingPage> createState() => _PricingPageState();
}

class _PricingPageState extends State<PricingPage> {
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
          child: Text('Pricing Option'),
        ),
        drawer: const NavDrawer());
  }
}
