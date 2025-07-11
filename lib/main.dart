  import 'package:flutter/material.dart';
  import 'package:firebase_core/firebase_core.dart';
  import 'package:get/get_navigation/src/root/get_material_app.dart';
  import 'firebase_options.dart';
  import 'package:untitled4/wraper.dart';

  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const MyApp());
  }

  class MyApp extends StatelessWidget {
    const MyApp({super.key});

    @override
    Widget build(BuildContext context) {
      return GetMaterialApp(
        debugShowCheckedModeBanner: false,
        home: Wrapper(),
      );
    }
  }
