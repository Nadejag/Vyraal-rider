import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'app.dart';

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  try {

    await Firebase.initializeApp();

  }
  catch (_){
    // Firebase config is optional for local/demo builds.
  }
  runApp(const VyraalRiderApp());
}