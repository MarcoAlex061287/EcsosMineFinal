import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:EcsosMine/database/database_helper.dart';

class ARInspectionView extends StatefulWidget {
  const ARInspectionView({super.key});

  @override
  State<ARInspectionView> createState() => _ARInspectionViewState();
}

class _ARInspectionViewState extends State<ARInspectionView> {
  CameraController? _cameraController;
  bool _isCameraReady = false;
  bool _isInitializing = true;
  String? _cameraError;

  Timer? _timer;
  int _secondsElapsed = 0;
  bool _inspectionStarted = false;
  bool _inspectionFinished = false;

  final List<_HerramientaMinera> _herramientas = [
    _HerramientaMinera(
      nombre: 'Casco de seguridad',
      descripcion: 'Protección craneal obligatoria en frente de trabajo.',
      icono: Icons.construction_rounded,
    ),
    _HerramientaMinera(
      nombre: 'Lámpara frontal',
      descripcion: 'Iluminación personal para galerías subterráneas.',
      icono: Icons.flashlight_on_rounded,
    ),
    _HerramientaMinera(
      nombre: 'Detector multigas',
      descripcion: 'Monitorea CO, CH4 y niveles de oxígeno.',
      icono: Icons.sensors_rounded,
    ),
    _HerramientaMinera(
      nombre: 'Barra de rescate',
      descripcion: 'Herramienta para verificar estabilidad del sostenimiento.',
      icono: Icons.straighten_rounded,
    ),
    _HerramientaMinera(
      nombre: 'Extintor PQS',
      descripcion: 'Equipo contra incendios clase ABC en operaciones mineras.',
      icono: Icons.local_fire_department_rounded,
    ),
  ];

  int get _encontradas => _herramientas.where((h) => h.encontrada).length;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _cameraError = 'No se detectó ninguna cámara en el dispositivo.';
          _isInitializing = false;
        });
        return;
      }

      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _isCameraReady = true;
        _isInitializing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cameraError = 'No se pudo iniciar la cámara. Verifica los permisos.';
        _isInitializing = false;
      });
    }
  }

  void _iniciarInspeccion() {
    setState(() {
      _inspectionStarted = true;
      _secondsElapsed = 0;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsElapsed++);
    });
  }

  void _marcarHerramienta(int index) {
    if (!_inspectionStarted || _inspectionFinished) return;
    if (_herramientas[index].encontrada) return;

    setState(() => _herramientas[index].encontrada = true);

    if (_encontradas == _herramientas.length) {
      _finalizarInspeccion(exito: true);
    }
  }

  Future<void> _finalizarInspeccion({required bool exito}) async {
    _timer?.cancel();

    final int calificacion = exito
        ? (100 - (_secondsElapsed > 120 ? 20 : 0)).clamp(60, 100)
        : ((_encontradas / _herramientas.length) * 100).round();

    await DatabaseHelper.instance.guardarIntento(
      unidad: 'Exploración RA',
      titulo: exito ? 'Inspección completada' : 'Inspección parcial',
      nivel: _encontradas,
      calificacion: calificacion,
    );

    if (!mounted) return;

    setState(() => _inspectionFinished = true);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16222F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: exito ? Colors.greenAccent : Colors.amberAccent,
          ),
        ),
        title: Text(
          exito ? '¡INSPECCIÓN COMPLETADA!' : 'INSPECCIÓN FINALIZADA',
          style: TextStyle(
            color: exito ? Colors.greenAccent : Colors.amberAccent,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        content: Text(
          exito
              ? 'Encontraste las ${_herramientas.length} herramientas en $_secondsElapsed segundos.\nCalificación: $calificacion/100.'
              : 'Identificaste $_encontradas de ${_herramientas.length} herramientas.\nCalificación: $calificacion/100.',
          style: const TextStyle(color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text(
              'VOLVER AL MENÚ',
              style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmarSalida() async {
    if (!_inspectionStarted || _inspectionFinished) return true;

    final salir = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16222F),
        title: const Text(
          '¿Salir de la inspección?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Perderás el progreso actual de la exploración en RA.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CONTINUAR', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SALIR', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    return salir ?? false;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _confirmarSalida() && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D131A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF16222F),
          elevation: 0,
          title: const Text(
            'MÓDULO RA - ECSOS MINE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.amberAccent),
            onPressed: () async {
              if (await _confirmarSalida() && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            if (_inspectionStarted && !_inspectionFinished)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amberAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amberAccent),
                    ),
                    child: Text(
                      '$_encontradas/${_herramientas.length}',
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: _isInitializing
            ? const Center(
                child: CircularProgressIndicator(color: Colors.amberAccent),
              )
            : _cameraError != null
                ? _buildCameraError()
                : Column(
                    children: [
                      Expanded(flex: 5, child: _buildCameraPreview()),
                      Expanded(flex: 4, child: _buildChecklistPanel()),
                    ],
                  ),
      ),
    );
  }

  Widget _buildCameraError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off_rounded, color: Colors.redAccent, size: 56),
            const SizedBox(height: 16),
            Text(
              _cameraError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amberAccent,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                setState(() {
                  _cameraError = null;
                  _isInitializing = true;
                });
                _initCamera();
              },
              child: const Text('REINTENTAR', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_isCameraReady && _cameraController != null)
          CameraPreview(_cameraController!)
        else
          Container(color: const Color(0xFF0D131A)),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.35),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.55),
              ],
            ),
          ),
        ),
        if (!_inspectionStarted)
          Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF16222F).withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.4)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.view_in_ar_rounded, color: Colors.amberAccent, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'Inspección en Realidad Aumentada',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Usa la cámara para explorar el entorno y marca cada herramienta minera que identifiques.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amberAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text(
                      'INICIAR INSPECCIÓN',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: _iniciarInspeccion,
                  ),
                ],
              ),
            ),
          ),
        if (_inspectionStarted && !_inspectionFinished)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_outlined, color: Colors.amberAccent, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${_secondsElapsed}s',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChecklistPanel() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF16222F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'HERRAMIENTAS A IDENTIFICAR',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                if (_inspectionStarted && !_inspectionFinished)
                  TextButton(
                    onPressed: () => _finalizarInspeccion(exito: false),
                    child: const Text(
                      'FINALIZAR',
                      style: TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              itemCount: _herramientas.length,
              itemBuilder: (context, index) {
                final herramienta = _herramientas[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: herramienta.encontrada
                        ? Colors.greenAccent.withValues(alpha: 0.12)
                        : const Color(0xFF0D131A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: herramienta.encontrada ? Colors.greenAccent : Colors.white10,
                    ),
                  ),
                  child: ListTile(
                    enabled: _inspectionStarted && !_inspectionFinished,
                    leading: Icon(
                      herramienta.icono,
                      color: herramienta.encontrada ? Colors.greenAccent : Colors.amberAccent,
                    ),
                    title: Text(
                      herramienta.nombre,
                      style: TextStyle(
                        color: herramienta.encontrada ? Colors.greenAccent : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      herramienta.descripcion,
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    trailing: Icon(
                      herramienta.encontrada
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: herramienta.encontrada ? Colors.greenAccent : Colors.white38,
                    ),
                    onTap: () => _marcarHerramienta(index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HerramientaMinera {
  final String nombre;
  final String descripcion;
  final IconData icono;
  bool encontrada = false;

  _HerramientaMinera({
    required this.nombre,
    required this.descripcion,
    required this.icono,
  });
}
