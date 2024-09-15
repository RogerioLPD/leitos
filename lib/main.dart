import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:gestao_leitos/Pages/home_page.dart';
import 'firebase_options.dart'; // Importando as configurações do Firebase

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializando o Firebase com as opções corretas para Web/Android/iOS
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,  // Removendo a faixa de debug
    );
  }
}
