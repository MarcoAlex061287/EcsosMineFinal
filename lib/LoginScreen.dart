import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'MainMenuScreen.dart';
import 'UserSession.dart';

/// Pantalla de Login inmersiva con efecto Glassmorphism.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  /// Método para procesar y validar el ingreso de credenciales
  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      String nombreIngresado = _userController.text.trim();

      // REINICIO / INICIALIZACIÓN DE SESIÓN
      // Limpia los registros anteriores e inicia la sesión en limpio para este usuario
      UserSession.clearForNewUser(nombreIngresado);

      Timer(const Duration(seconds: 1), () {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });

        // Navegación enviando el nombre de usuario de forma directa
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainMenuScreen(
              username: nombreIngresado,
            ),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _userController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Imagen de fondo local de la mina
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/portada.png'), // <-- AQUÍ SE AGREGA LA FOTO LOCAL
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Capa de contraste con degradado de colores negros profundos
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.85),
                  Colors.black.withValues(alpha: 0.4),
                  Colors.black.withValues(alpha: 0.9),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              // ... El resto de tu código sigue exactamente igual
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Cabecera gráfica principal
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.construction_rounded,
                              size: 48, color: Color(0xFFFF823A)),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "ECSOS Mine",
                                style: TextStyle(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 2,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                "FUNDAMENTOS DE MINERIA I",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF38BDF8),
                                  letterSpacing: 3,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Badges identificativos de RA e IA
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF823A)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFFFF823A), width: 1),
                            ),
                            child: const Text(
                              "RA",
                              style: TextStyle(
                                  color: Color(0xFFFF823A),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text("+",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF38BDF8)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFF38BDF8), width: 1),
                            ),
                            child: const Text(
                              "IA",
                              style: TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 50),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            padding: const EdgeInsets.all(28.0),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  width: 1.5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Ingrese su Usuario:",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Entrada de texto con Validación de Nombre y Apellido
                                TextFormField(
                                  controller: _userController,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 16),
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.person_outline,
                                        color: Color(0xFF38BDF8)),
                                    hintText: "Ingrese su nombre y apellido",
                                    hintStyle: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.5)),
                                    filled: true,
                                    fillColor:
                                        Colors.black.withValues(alpha: 0.5),
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: Colors.white
                                              .withValues(alpha: 0.2)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: Colors.white
                                              .withValues(alpha: 0.2)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: Color(0xFFFF823A), width: 1.5),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'El nombre de usuario es requerido';
                                    }
                                    
                                    // Validar que se ingrese Nombre y Apellido (al menos 2 palabras)
                                    final partes = value.trim().split(RegExp(r'\s+'));
                                    if (partes.length < 2) {
                                      return 'Debe ingresar su Nombre y Apellido';
                                    }
                                    
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 55,
                                  child: ElevatedButton(
                                    onPressed:
                                        _isLoading ? null : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF823A),
                                      foregroundColor: Colors.white,
                                      elevation: 8,
                                      shadowColor: const Color(0xFFFF823A)
                                          .withValues(alpha: 0.5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const CircularProgressIndicator(
                                            color: Colors.white)
                                        : const Text(
                                            "INGRESAR",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.5,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Estación de Entrenamiento Virtual ISTS",
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}