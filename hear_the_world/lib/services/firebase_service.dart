import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();

  Future<String?> fetchDescription() async {
    try {
      final snapshot = await _databaseRef.child('description').get();
      if (snapshot.exists) {
        return snapshot.value as String?;
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching description: $e');
      return null;
    }
  }
}
