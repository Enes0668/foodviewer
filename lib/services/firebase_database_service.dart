import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../firebase_options.dart';

class FirebaseDatabaseService {
  static final FirebaseDatabase _database = FirebaseDatabase.instance;

  static FirebaseDatabase get database => _database;
  static DatabaseReference get ref => _database.ref();
}
