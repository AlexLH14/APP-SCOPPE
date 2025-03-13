import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:scope_app/firebase_options.dart';
import 'pages/login.dart';
import 'pages/orders.dart';
import 'pages/order_detail.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';

void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    runApp(const MainScope());
}

class MainScope extends StatelessWidget {
  const MainScope({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scope Trade Management',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routes: {
        OrderDetailPage.routeName: (context) => const OrderDetailPage(id: '', numero: '',)
      },
      home: AnimatedSplashScreen(
        splash: const CircleAvatar(
                  radius: 40.0,
                  backgroundColor: Colors.transparent,
                  backgroundImage: AssetImage('images/logo.png'),
                ), 
        duration: 2000,
        splashTransition: SplashTransition.fadeTransition,
        backgroundColor: Colors.lightBlue.shade700,
        nextScreen: const MyHomePage(title: 'Title')
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    
     return  Scaffold(
      //body: LoginPage(title: 'Login'),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(), 
        builder: (context, snapshot) {
          if(snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if(snapshot.hasError) {
            return const Center(child: Text('No se pudo conectar a Firebase'));
          }else if(snapshot.hasData) {
            return const OrderPage();
          } else {
            return const LoginPage(title: 'Titulo');
          }
        },
      ),
     );
  }
}

