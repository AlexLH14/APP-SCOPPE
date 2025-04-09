import 'package:flutter/material.dart';
import 'package:scope_app/firestore/fire_price_orders.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scope_app/firestore/fire_user.dart';
import 'package:scope_app/navbar/navbar.dart';
import 'package:scope_app/pages/price_order_detail.dart';

class PriceOrdersPage extends StatefulWidget {
  const PriceOrdersPage({super.key});

  @override
  State<PriceOrdersPage> createState() => _PriceOrdersPageState();
}

class _PriceOrdersPageState extends State<PriceOrdersPage> {
  int _selectedIndex = 0;
  late Map userMap;
  List<Widget> _widgetOptions = <Widget>[const CircularProgressIndicator()];

  @override
  void initState() {
    super.initState();
    getUser();
  }

  getUser() async {
    final user = await getUserByEmail(
        FirebaseAuth.instance.currentUser!.email.toString()) as Map;
    setState(() {
      userMap = {"id": user['id'], "nombre": user['nombre']};

      _widgetOptions = <Widget>[
        // HOY
        Column(
          children: [
            StreamBuilder(
              stream: getPendingPriceOrdersByUserToday(userMap),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return const Center(
                      child: Text("Error al cargar las órdenes"));
                } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_rounded,
                              size: 80, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            "No hay órdenes de precios para hoy",
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  return Expanded(
                    child: ListView(
                      children: snapshot.data!.docs.map((e) {
                        final tipo = e['tipoPrecio'] ?? '';
                        final cardColor = (tipo == 'competencia')
                            ? Colors.lightBlue.shade50
                            : Colors.green.shade50;
                        final tipoColor = (tipo == 'competencia')
                            ? Colors.blue
                            : Colors.green.shade800;

                        return Card(
                          color: cardColor,
                          child: ListTile(
                            leading: Icon(Icons.attach_money_rounded,
                                color: tipoColor),
                            title: Text(
                                "${e['cadena']['nombre']} | ${e['local']['nombre']}"),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    "${e['mercaderista']['nombre']} | Hoy ${e['fechaVisita'].substring(10)}"),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: tipoColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    tipo.toUpperCase(),
                                    style: TextStyle(
                                      color: tipoColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PriceOrderDetailPage(
                                    id: e.id,
                                    numero: e['numero'],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }
              },
            ),
          ],
        ),

        // PRÓXIMAS
        Column(
          children: [
            StreamBuilder(
              stream: getPendingPriceOrdersByUserNext(userMap),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return const Center(
                      child: Text("Error al cargar las órdenes"));
                } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, size: 80, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            "No hay órdenes de precios próximas",
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  return Expanded(
                    child: ListView(
                      children: snapshot.data!.docs.map((e) {
                        final tipo = e['tipoPrecio'] ?? '';
                        final cardColor = (tipo == 'competencia')
                            ? Colors.lightBlue.shade50
                            : Colors.green.shade50;
                        final tipoColor = (tipo == 'competencia')
                            ? Colors.blue
                            : Colors.green.shade800;

                        return Card(
                          color: cardColor,
                          child: ListTile(
                            leading: Icon(Icons.attach_money_rounded,
                                color: tipoColor),
                            title: Text(
                                "${e['cadena']['nombre']} | ${e['local']['nombre']}"),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    "${e['mercaderista']['nombre']} | ${e['fechaVisita']}"),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: tipoColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    tipo.toUpperCase(),
                                    style: TextStyle(
                                      color: tipoColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }
              },
            ),
          ],
        ),
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
        title: const Text('Órdenes de Precios'),
        backgroundColor: Colors.lightBlue.shade800,
      ),
      drawer: const NavDrawer(),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.check),
            label: 'Hoy',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Próximas',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}
