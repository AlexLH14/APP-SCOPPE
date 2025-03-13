import 'package:cloud_firestore/cloud_firestore.dart';

FirebaseFirestore db = FirebaseFirestore.instance;

Future<Object> getUserByEmail(String email) async {
    Map<String, dynamic> result = {};
     await db.collection('users').where('email', isEqualTo: email).get().then((value) {
      for (var doc in value.docs) {
        result = doc.data();
      }
    });
    return result;
}