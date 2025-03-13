import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Center(
          child:Column(
            children: [
              const Text(
                'Estas In',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                user.email!,
                style: const TextStyle(fontSize: 16)
              ),
              const SizedBox(height: 20,),
              ElevatedButton.icon(
                onPressed: () => FirebaseAuth.instance.signOut(), 
                icon: const Icon(Icons.arrow_back,size: 32), 
                label: const Text(
                  'SignOut',
                  style: TextStyle(fontSize: 24)
                )
              )
            ],
          )
        )
    );
  }
}