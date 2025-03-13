
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';


FirebaseFirestore db = FirebaseFirestore.instance;

Future<List> getPendingsOrdersByUser() async {
  List orders = [];

    CollectionReference collectionOrders = db.collection('city');
    QuerySnapshot queryOrders = await collectionOrders.get();
    queryOrders.docs.forEach((element) {
      orders.add(element.data());
    });
  return orders;
}

Stream<QuerySnapshot> getPendingsOrdersByUserToday(Map user)  {
    var today = DateFormat('yyyy-MM-dd').format(DateTime.now()); 
    
    var tomorrow =  DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 1))); 
    final list = [
      {"id": "eNyPUyFqo8SrwkKvDAgD", "nombre": "CREADA"},
      {"id": "rYPNu37CXYaD2EHDGS6u", "nombre": "EN PROGRESO"},
      {"id": "LT4ytmo1DoCbXR3cj8k2", "nombre": "INICIADA"}
    ];

    return db.collection('work-orders')
              .where ('estado', whereIn: list)
              .where('mercaderista', isEqualTo: user)
              .where('visita', isGreaterThan: today)
              .where('visita', isLessThan: tomorrow)
              .snapshots();
}

Stream<QuerySnapshot> getPendingsOrdersByUserNext(Map user)  {
    var tomorrow =  DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 1)));
    final list = [
      {"id": "eNyPUyFqo8SrwkKvDAgD", "nombre": "CREADA"},
      {"id": "rYPNu37CXYaD2EHDGS6u", "nombre": "EN PROGRESO"},
      {"id": "LT4ytmo1DoCbXR3cj8k2", "nombre": "INICIADA"}
    ];

    return db.collection('work-orders')
              .where ('estado', whereIn: list)
              .where('mercaderista', isEqualTo: user)
              .where('visita', isGreaterThan: tomorrow)
              .snapshots();
}

Future<Object> getOrderById(String id) async {
    Map<String, dynamic> result = {};
     await db.collection('work-orders').doc(id).get().then((value) {
       result = value.data() as Map<String, dynamic>;
    });
    return result;
}

Future<bool> updateSkuOrder(String id, Map data) async {
   final dataUpdate = {
    "sku": data['sku'],
    "estado": data['estado']
   };
   return FirebaseFirestore.instance
    .collection("work-orders")
    .doc(id)
    .update(dataUpdate)
    .then((value) {
      return true;
    })
    .onError((error, stackTrace) {
      return false;
    });
}

Future<bool> updatePhotoOrder(String id, Map data) async {
   final dataUpdate = {
    "fotos": data['fotos']
   };
   return FirebaseFirestore.instance
    .collection("work-orders")
    .doc(id)
    .update(dataUpdate)
    .then((value) {
      return true;
    })
    .onError((error, stackTrace) {
      return false;
    });
}

Future<bool> updateStatusOrder(String id, Map data) async {
  final Map<String, dynamic> dataUpdate = {};
   dataUpdate["estado"] = data['estado'];
   if(data.containsKey('inprogress')) {
    dataUpdate["inprogress"] = data['inprogress'];
   }

   if(data.containsKey('finalizada')) {
    dataUpdate["finalizada"] = data['finalizada'];
   }
   
   return FirebaseFirestore.instance
    .collection("work-orders")
    .doc(id)
    .update(dataUpdate)
    .then((value) {
      return true;
    })
    .onError((error, stackTrace) {
      return false;
    });
}

Future<bool> updatePositionOrder(String id, Map data) async {
  //var dataUpdate;
  final Map<String, dynamic> dataUpdate = {};

  if(data.containsKey('geolocation_iniciada')) {
    dataUpdate["geolocation_iniciada"] = data['geolocation_iniciada'];
  }

  if(data.containsKey('geolocation_finalizada')) {
    dataUpdate["geolocation_finalizada"] = data['geolocation_finalizada'];
  }
   
  return FirebaseFirestore.instance
    .collection("work-orders")
    .doc(id)
    .update(dataUpdate)
    .then((value) {
      return true;
  })
    .onError((error, stackTrace) {
      return false;
  });
}

// Stream<QuerySnapshot> getOrderById(String id)  {
//   return db.collection('work-orders').where(
//         FieldPath.documentId,
//         isEqualTo: id
//     ).snapshots();
// }

/*Future<DocumentSnapshot> getOrderById(String id) async {
 return await db.collection('work-orders').doc(id).get();
}*/