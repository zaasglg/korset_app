import 'package:flutter/material.dart';
import 'package:korset_app/onboarding.dart';
import 'services/service_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализация оптимизированных сервисов
  // Инициализация оптимизированных сервисов...
  await serviceManager.initialize();
  // Сервисы успешно инициализированы!
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Korset',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: false,
        fontFamily: "Atyp",
      ),
      home: const Onboarding(),
    );
  }
}
