import 'package:flutter/material.dart';
import 'package:scope_app/main.dart';
import 'package:scope_app/pages/orders.dart';
import 'package:scope_app/pages/pricing.dart';
import 'package:scope_app/pages/evaluation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NavDrawer extends StatelessWidget {
  const NavDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(100),
      ),
      child: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration:  BoxDecoration(
                  color: Colors.lightBlue.shade800,
                  image: const DecorationImage(
                      fit: BoxFit.fill,
                      image: AssetImage('assets/images/cover.jpg'))),
              child: Column(
                children: [
                  const Text(
                    'Scope Menu',
                    style: TextStyle(color: Colors.white, fontSize: 25),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.white,
                      ),
                      Column(
                        children: [
                          Center(
                            child: Text(
                              FirebaseAuth.instance.currentUser!.displayName!,
                              style: const TextStyle(color: Colors.white, fontSize: 15),
                            ),
                          ),
                          Center(
                            child: Text(
                              FirebaseAuth.instance.currentUser!.email!,
                              style: const TextStyle(color: Colors.white, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              
            ),
            ListTile(
              leading: const Icon(Icons.article),
              title: const Text('Ordenes'),
              onTap: () {
                Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const OrderPage()));
                // Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Precios'),
              onTap: () {
                Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const PricingPage()));
                //Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.checklist),
              title: const Text('Evaluación'),
              onTap: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (context) => const EvaluationPage ()));
                //Navigator.of(context).pop();
              },
            ),
            // ListTile(
            //   leading: const Icon(Icons.border_color),
            //   title: const Text('Feedback'),
            //   onTap: () => {Navigator.of(context).pop()},
            // ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Salir'),
              onTap: () { 
                FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (context) => const MyHomePage(title: '')));
              },
            ),
          ],
        ),
      )
    );
  }
}
