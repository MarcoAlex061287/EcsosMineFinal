import 'package:flutter/material.dart';
import 'package:EcsosMine/database/database_helper.dart';
import 'CrisisSimulator.dart';
import 'LoginScreen.dart';
import 'ARInspectionView.dart';
import 'Gallery3DView.dart'; 
import 'package:EcsosMine/Pdf/pdf_report_service.dart';

class MainMenuScreen extends StatefulWidget {
  final String username;

  const MainMenuScreen({
    super.key,
    this.username = 'Marco Chicaiza',
  });

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  int _totalIntentos = 0;
  int _totalFallos = 0;
  int _notaActual = 0;
  int _notaFinal = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarRendimiento();
  }

  Future<void> _cargarRendimiento() async {
    setState(() => _isLoading = true);

    final resumen = await DatabaseHelper.instance.obtenerResumenRendimiento();

    setState(() {
      _totalIntentos = resumen['intentos'] ?? 0;
      _totalFallos = resumen['fallos'] ?? 0;
      _notaActual = resumen['notaActual'] ?? 0;
      _notaFinal = resumen['notaFinal'] ?? 0;
      _isLoading = false;
    });
  }

  void _confirmarCerrarSesion() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16222F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.amberAccent, width: 1),
          ),
          title: const Text(
            '¿DESEA CERRAR SESIÓN?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'Saldrás de la plataforma y volverás a la pantalla de ingreso.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'CANCELAR',
                style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: const Text(
                'ACEPTAR',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D131A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16222F).withValues(alpha: 0.9),
        elevation: 0,
        title: const Text(
          'PÁGINA PRINCIPAL',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF38BDF8)),
            tooltip: 'Generar y Enviar PDF',
            onPressed: () {
              PdfReportService.solicitarCorreoYEnviarPDF(
                context: context,
                username: widget.username,
                rol: 'General/Todos',
                intentos: _totalIntentos,
                fallos: _totalFallos,
                notaActual: _notaActual,
                notaFinal: _notaFinal,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Cerrar Sesión',
            onPressed: _confirmarCerrarSesion,
          ),
        ],
      ),    
      body: Stack(
        children: [
          // 1. Imagen de fondo
          Positioned.fill(
            child: Image.asset(
              'assets/images/pagina_principal.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: const Color(0xFF0D131A));
              },
            ),
          ),

          // 2. Capa oscura de contraste
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.82),
            ),
          ),

          // 3. Contenido principal
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _cargarRendimiento,
              color: Colors.amberAccent,
              backgroundColor: const Color(0xFF16222F),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderUser(widget.username),
                    const SizedBox(height: 20),
                    const Text(
                      'RESUMEN DE RENDIMIENTO',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _isLoading
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: CircularProgressIndicator(color: Colors.amberAccent),
                            ),
                          )
                        : _buildMetricsGrid(),
                    const SizedBox(height: 24),
                    const Text(
                      'MÓDULOS PRÁCTICOS',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSimulatorBanner(),
                    const SizedBox(height: 16),
                    _buildRABanner(),
                    const SizedBox(height: 16),
                    // 3. NUEVO BANNER PARA LA GALERÍA 3D INTERACTIVA
                    _buildGallery3DBanner(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Encabezado Dinámico con Avatar por Iniciales
  Widget _buildHeaderUser(String nombreCompleto) {
    String obtenerIniciales(String nombre) {
      if (nombre.trim().isEmpty) return 'U';
      List<String> partes = nombre.trim().split(RegExp(r'\s+'));
      if (partes.length >= 2) {
        return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
      } else if (partes.isNotEmpty && partes[0].isNotEmpty) {
        return partes[0][0].toUpperCase();
      }
      return 'U';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16222F).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.amberAccent.withValues(alpha: 0.15),
              border: Border.all(color: Colors.amberAccent, width: 1.5),
            ),
            child: Center(
              child: Text(
                obtenerIniciales(nombreCompleto),
                style: const TextStyle(
                  color: Colors.amberAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenido, $nombreCompleto',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                const Text(
                  'IST Superarse • Fundamentos de Minería I',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _buildMetricCard(
          titulo: 'INTENTOS',
          valor: '$_totalIntentos',
          icono: Icons.touch_app_rounded,
          colorIcono: Colors.blueAccent,
        ),
        _buildMetricCard(
          titulo: 'FALLOS',
          valor: '$_totalFallos',
          icono: Icons.warning_amber_rounded,
          colorIcono: Colors.redAccent,
        ),
        _buildMetricCard(
          titulo: 'NOTA ACTUAL',
          valor: '$_notaActual / 100',
          icono: Icons.grade_rounded,
          colorIcono: Colors.amberAccent,
        ),
        _buildMetricCard(
          titulo: 'NOTA FINAL',
          valor: '$_notaFinal / 100',
          icono: Icons.military_tech_rounded,
          colorIcono: Colors.greenAccent,
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String titulo,
    required String valor,
    required IconData icono,
    required Color colorIcono,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF16222F).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(icono, color: colorIcono, size: 20),
            ],
          ),
          Text(
            valor,
            style: TextStyle(
              color: colorIcono,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulatorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16222F).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFF823A).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF823A).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.crisis_alert_rounded,
                  color: Color(0xFFFF823A),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Simulador de Crisis',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Disfruta mucho de la experiencia mucha suerte en la evaluación',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF823A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text(
                'INGRESAR AL SIMULADOR',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CrisisSimulator(),
                  ),
                );
                _cargarRendimiento();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRABanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16222F).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.view_in_ar_rounded,
                  color: Color(0xFF38BDF8),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Exploración en RA',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Explora e interactúa con el entorno virtual y sus elementos en RA.',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38BDF8),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text(
                'INGRESAR A REALIDAD AUMENTADA',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ARInspectionView(),
                  ),
                );
                _cargarRendimiento();
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Nuevo Banner Estilizado para la Galería 3D Interactiva
  Widget _buildGallery3DBanner() {
    const Color emeraldColor = Color(0xFF10B981); // Verde Esmeralda

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16222F).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: emeraldColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: emeraldColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.threed_rotation,
                  color: emeraldColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Galería 3D Interactiva',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Inspecciona modelos 3D en 360° con asistencia y voz de IA.',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: emeraldColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.explore_rounded),
              label: const Text(
                'ABRIR GALERÍA 3D',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Gallery3DView(),
                  ),
                );
                _cargarRendimiento();
              },
            ),
          ),
        ],
      ),
    );
  }
}