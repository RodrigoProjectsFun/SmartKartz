// lib/main.dart

import 'package:flutter/material.dart';
import 'package:smart_carts/routes/routes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:smart_carts/widgets/AuthWrapper.dart'; 
import 'package:smart_carts/base_lifecycle_observer.dart';  
Future<void> main() async {
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
    return BaseLifecycleObserver(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Smart Cart',
        theme: ThemeData(
          primarySwatch: Colors.red,
        ),
        home: const AuthWrapper(),
        routes: AppRoutes.routes,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}
