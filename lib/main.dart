import 'package:flutter/material.dart';

// Importación relativa del archivo de login modular
import 'LoginScreen.dart';

void main() {
  runApp(const MineriaSmartApp());
}

/// Clase principal de la aplicación.
/// Configura el tema oscuro global y define la pantalla de inicio.
class MineriaSmartApp extends StatelessWidget {
  const MineriaSmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ECSOS Mine',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFFF823A), // Naranja Corporativo
        scaffoldBackgroundColor: const Color(0xFF0B0F19), // Azul Profundo
        fontFamily: 'Roboto',
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF823A),
          secondary: Color(0xFF38BDF8), // Azul IA
          surface: Color(0xFF1E293B),
        ),
      ),
      // Apuntamos directamente a tu pantalla de Login modular
      home: const LoginScreen(),
    );
  }
}