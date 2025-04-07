import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

FirebaseFirestore db = FirebaseFirestore.instance;

Future<List> getPendingPriceOrdersByUser() async {
  List orders = [];

  CollectionReference collectionOrders =
      db.collection('city'); // Mantenemos 'city' para la consulta inicial
  QuerySnapshot queryOrders = await collectionOrders.get();
  queryOrders.docs.forEach((element) {
    orders.add(element.data());
  });
  return orders;
}

Stream<QuerySnapshot> getPendingPriceOrdersByUserToday(Map user) {
  var today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  var tomorrow = DateFormat('yyyy-MM-dd')
      .format(DateTime.now().add(const Duration(days: 1)));

  final list = [
    {"id": "eNyPUyFqo8SrwkKvDAgD", "nombre": "CREADA"},
    {"id": "rYPNu37CXYaD2EHDGS6u", "nombre": "EN PROGRESO"},
    {"id": "LT4ytmo1DoCbXR3cj8k2", "nombre": "INICIADA"}
  ];

  return db
      .collection('price-orders') // Cambiamos a 'price-orders'
      .where('estado', whereIn: list)
      .where('mercaderista', isEqualTo: user)
      .where('fechaVisita', isGreaterThan: today)
      .where('fechaVisita', isLessThan: tomorrow)
      .snapshots();
}

Stream<QuerySnapshot> getPendingPriceOrdersByUserNext(Map user) {
  var tomorrow = DateFormat('yyyy-MM-dd')
      .format(DateTime.now().add(const Duration(days: 1)));

  final list = [
    {"id": "eNyPUyFqo8SrwkKvDAgD", "nombre": "CREADA"},
    {"id": "rYPNu37CXYaD2EHDGS6u", "nombre": "EN PROGRESO"},
    {"id": "LT4ytmo1DoCbXR3cj8k2", "nombre": "INICIADA"}
  ];

  return db
      .collection('price-orders') // Cambiamos a 'price-orders'
      .where('estado', whereIn: list)
      .where('mercaderista', isEqualTo: user)
      .where('fechaVisita', isGreaterThan: tomorrow)
      .snapshots();
}

Future<Object> getPriceOrderById(String id) async {
  Map<String, dynamic> result = {};
  await db
      .collection('price-orders') // Cambiamos a 'price-orders'
      .doc(id)
      .get()
      .then((value) {
    result = value.data() as Map<String, dynamic>;
  });
  return result;
}

Future<bool> updatePriceOrderStatus(String id, Map data) async {
  final Map<String, dynamic> dataUpdate = {};
  dataUpdate["estado"] = data['estado'];
  if (data.containsKey('inprogress')) {
    dataUpdate["inprogress"] = data['inprogress'];
  }

  if (data.containsKey('finalizada')) {
    dataUpdate["finalizada"] = data['finalizada'];
  }

  return db
      .collection("price-orders") // Cambiamos a 'price-orders'
      .doc(id)
      .update(dataUpdate)
      .then((value) {
    return true;
  }).onError((error, stackTrace) {
    return false;
  });
}

Future<bool> updatePriceOrderPosition(String id, Map data) async {
  final Map<String, dynamic> dataUpdate = {};

  if (data.containsKey('geolocation_iniciada')) {
    dataUpdate["geolocation_iniciada"] = data['geolocation_iniciada'];
  }

  if (data.containsKey('geolocation_finalizada')) {
    dataUpdate["geolocation_finalizada"] = data['geolocation_finalizada'];
  }

  return db
      .collection("price-orders") // Cambiamos a 'price-orders'
      .doc(id)
      .update(dataUpdate)
      .then((value) {
    return true;
  }).onError((error, stackTrace) {
    return false;
  });
}

Future<bool> updatePriceOrderSku(String id, Map data) async {
  final dataUpdate = {"sku": data['sku'], "estado": data['estado']};
  return db
      .collection("price-orders") // Cambiamos a 'price-orders'
      .doc(id)
      .update(dataUpdate)
      .then((value) {
    return true;
  }).onError((error, stackTrace) {
    return false;
  });
}

Future<bool> updatePriceOrderPhoto(String id, Map data) async {
  final dataUpdate = {"fotos": data['fotos']};
  return db
      .collection("price-orders") // Cambiamos a 'price-orders'
      .doc(id)
      .update(dataUpdate)
      .then((value) {
    return true;
  }).onError((error, stackTrace) {
    return false;
  });
}
