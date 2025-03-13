import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.title});
  final String title;
  
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class LinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.lightBlue.shade900
      ..strokeWidth = 1;

    Offset start = Offset(0, size.height / 2);
    Offset end = Offset(size.width, size.height / 2);

    canvas.drawLine(start, end, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

class _LoginPageState extends State<LoginPage> {
  
  final myOutput = TextEditingController();
  final userInput = TextEditingController();
  final passwordInput = TextEditingController();
  int idDriverLogin = 0;
  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    myOutput.dispose();
    userInput.dispose();
    passwordInput.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Future<void> showAlertDialog(String title, String message) async {
      return showDialog<void>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog( // <-- SEE HERE
            title: Text(title),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(message),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

    Future loginAction() async {
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: userInput.text.trim(), 
          password: passwordInput.text.trim()
        );
      } on FirebaseAuthException catch  (e) {
        showAlertDialog("Login Alert!","No se pudo autenticar: ${e.message}");
      }
    }
    
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                
                const CircleAvatar(
                  radius: 80.0,
                  backgroundColor: Colors.transparent,
                  backgroundImage: AssetImage('images/logo.png'),
                ),
                //const Image(image: AssetImage('images/logo.png')),
                const SizedBox(height: 10,),
                const Text(
                  'Hola...',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 34,
                  ),
                ),
                const SizedBox(height: 10),
                 Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Bienvenido a  ',
                      style: TextStyle(
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      'Scope App V2',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:  FontWeight.bold,
                        color: Colors.lightBlue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12)
                    ), 
                    child:  Padding(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: TextField(
                        controller:userInput,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.person_outline),
                          border: InputBorder.none,
                          hintText: 'Email',
                          hintStyle: TextStyle(color: Colors.grey),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12)
                    ), 
                    child:  Padding(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: TextField(
                        controller: passwordInput,
                        obscureText: true,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.lock_outline_rounded),
                          border: InputBorder.none,
                          hintText: 'Password',
                          hintStyle: TextStyle(color: Colors.grey),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50.0),
                  child: TextButton(
                    onPressed: loginAction,
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(Colors.lightBlue.shade700),
                    ),           
                    child: const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('INGRESAR',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          )
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                CustomPaint(
                  size: const Size(300, 20),
                  painter: LinePainter(),
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      IconButton(
                        onPressed: () {
                          launchUrlString('https://www.facebook.com/scope.com.ec/');
                        },
                        icon: Icon(
                          Icons.facebook_outlined,
                          size: 30,
                          color: Colors.lightBlue.shade900,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          launchUrlString('https://www.instagram.com/scope.com.ec/');
                        },
                        icon: Icon(
                          Icons.photo_camera_outlined,
                          size: 30,
                          color: Colors.lightBlue.shade900,
                        ),
                      ),
                   ], 
                  ),
                )
                //const Text('Not a member? Register Now'),
                // Padding(
                //   padding: const EdgeInsets.all(16),
                //   child: TextField(
                //     controller: myOutput,
                //   ),
                // ),
              ]
            ),
          ),
        ),
    );
 
  }
}
