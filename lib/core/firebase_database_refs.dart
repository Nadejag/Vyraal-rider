import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

const vyraalDatabaseUrl =
    'https://vyraal-default-rtdb.asia-southeast1.firebasedatabase.app';

FirebaseDatabase get vyraalDatabase => FirebaseDatabase.instanceFor(
  app: Firebase.app(),
  databaseURL: vyraalDatabaseUrl,
);
