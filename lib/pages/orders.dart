import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:scope_app/navbar/navbar.dart';
import 'package:scope_app/firestore/fire_order.dart';
import 'package:scope_app/firestore/fire_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scope_app/pages/order_detail.dart';
//import 'package:scope_app/arguments/OrderDetailsArguments.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  int _selectedIndex = 0;
  late Map userMap;
  List<Widget> _widgetOptions = <Widget>[const CircularProgressIndicator()];

  @override
  void initState() {
    super.initState();
    //WidgetsBinding.instance.addPostFrameCallback((_){
     getUser();
    // });
  }

  getUser() async {
    final user = await getUserByEmail(FirebaseAuth.instance.currentUser!.email.toString()) as Map;
    setState(() {
        userMap = {
          "id": user['id'],
          "nombre": user['nombre']
        };
        
        _widgetOptions = <Widget>[
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StreamBuilder(
                stream: getPendingsOrdersByUserToday(userMap),
                builder: (context, snapshot) {
                  if(snapshot.hasData) {
                    return Container(
                        height: MediaQuery.of(context).size.height,
                        width: MediaQuery.of(context).size.width,
                        child: ListView(
                          children: (snapshot.data!.docs.isNotEmpty)? snapshot.data!.docs.map((e) => Card(
                              margin: const EdgeInsets.all(1),
                              color: Colors.white,
                              shadowColor: Colors.lightBlue.shade800,
                              child: ListTile(
                                leading: Icon (
                                    Icons.article_outlined,
                                    color:  (DateTime.parse(e['visita']).compareTo(DateTime.now())<0)?Colors.red.shade700 : Colors.lightBlue.shade800,
                                    size: 45
                                ),
                                title: Text("${e['cadena']['nombre'].toString()} | ${e['local']['nombre'].toString()}"),
                                subtitle: Text("${e['mercaderista']['nombre'].toString()} | Hoy${e['visita'].substring(10)}"),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => OrderDetailPage(id: e.id, numero: e['numero'],)),
                                  );
                                },
                              ))
                          ).toList() : <Widget> [
                            const SizedBox(height: 20),
                            Center(
                              child: Text("No existen ordenes! ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())} ${(DateTime.parse("2023-09-18 01:00").compareTo(DateTime.now()))}",style: const TextStyle(fontSize: 15,))
                            )
                          ]
                        ),
                      );
                  } else {
                    return const Center(child: CircularProgressIndicator(),);
                  } 
                }
              )
            ]
          ), 
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StreamBuilder(
                stream: getPendingsOrdersByUserNext(userMap),
                builder: (context, snapshot) {
                  if(snapshot.hasData) {
                    return  Container(
                        height: MediaQuery.of(context).size.height,
                        width: MediaQuery.of(context).size.width,
                        child: ListView(
                          children: (snapshot.data!.docs.isNotEmpty)? snapshot.data!.docs.map((e) => Card(
                              margin: const EdgeInsets.all(1),
                              color: Colors.white,
                              shadowColor: Colors.blueGrey[800],
                              child: ListTile(
                                leading: const Icon (
                                    Icons.access_time,
                                    color: Colors.blueGrey,
                                    size: 45
                                ),
                                title: Text("${e['cadena']['nombre'].toString()} | ${e['local']['nombre'].toString()}"),
                                subtitle: Text("${e['mercaderista']['nombre'].toString()} | ${e['visita']}"),
                              ))
                          ).toList() : <Widget> [
                            const SizedBox(height: 20),
                            const Center(
                              child: Text('No existen ordenes!',style: TextStyle(fontSize: 15,))
                            )
                          ]
                        ),
                      );
                  } else {
                    return const Center(child: CircularProgressIndicator(),);
                  } 
                }
              )
            ]
          ) 
        ];
    });    
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Scope Trade Management'),
          backgroundColor: Colors.lightBlue.shade800,
          foregroundColor: Colors.white,
          elevation: 10,
          shadowColor: Colors.blueAccent,
        ),
      body:  Center(
        child: _widgetOptions.elementAt(_selectedIndex),
       ),
      drawer: const NavDrawer(),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.check),
            label: 'Hoy',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Proximas',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}
