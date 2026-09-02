import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:EcsosMine/database/database_helper.dart';
import 'package:EcsosMine/gemini_service.dart';

class VisorInspeccionPage extends StatefulWidget {
  const VisorInspeccionPage({super.key});

  @override
  State<VisorInspeccionPage> createState() => _VisorInspeccionPageState();
}

class _VisorInspeccionPageState extends State<VisorInspeccionPage> {
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  // Catálogo de equipos e imágenes para la inspección
  final List<Map<String, dynamic>> _catalogoEquipos = [
    {
      "nombre": "Casco con Lámpara",
      "icono": Icons.shield_outlined,
    },
    {
      "nombre": "Autorescatador de Oxígeno",
      "icono": Icons.masks_outlined,
    },
    {
      "nombre": "Arnés de Seguridad Anticaídas",
      "icono": Icons.accessibility_new_outlined,
    },
    {
      "nombre": "Detector Multigas Portátil",
      "icono": Icons.sensors_outlined,
    },
    {
      "nombre": "Botas Dieléctricas de Mina",
      "icono": Icons.do_not_step_outlined,
    },
  ];

  int _indiceEquipoActual = 0;
  
  // Lista dinámica de preguntas visibles
  List<String> _preguntasDisponibles = [];
  // Historial global para evitar repetir preguntas en la misma sesión
  final Set<String> _preguntasRespondidas = {};

  String? _preguntaSeleccionada;
  String _mensajeTutor = "Selecciona una pregunta para iniciar la evaluación.";
  bool _isLoading = true;
  bool _isListening = false;
  bool _evaluado = false;

  String get _equipoActual => _catalogoEquipos[_indiceEquipoActual]["nombre"];

  @override
  void initState() {
    super.initState();
    _initTts();
    _cargarPreguntasIniciales();
  }

  void _initTts() async {
    await _flutterTts.setLanguage("es-ES");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
  }

  void _speak(String text) async {
    await _flutterTts.stop();
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  // Carga o regenera 3 preguntas al cambiar de equipo o iniciar
  Future<void> _cargarPreguntasIniciales() async {
    setState(() => _isLoading = true);
    _preguntasDisponibles.clear();
    
    await _generarNuevaPreguntaIA();
    await _generarNuevaPreguntaIA();
    await _generarNuevaPreguntaIA();
    
    setState(() => _isLoading = false);
  }

  // Cambia de imagen/equipo dinámicamente y recarga las preguntas con IA
  void _cambiarEquipo(int direccion) {
    setState(() {
      _indiceEquipoActual = (_indiceEquipoActual + direccion) % _catalogoEquipos.length;
      if (_indiceEquipoActual < 0) {
        _indiceEquipoActual = _catalogoEquipos.length - 1;
      }
      
      _preguntaSeleccionada = null;
      _evaluado = false;
      _mensajeTutor = "Has cambiado a: $_equipoActual.\nSelecciona una pregunta para iniciar la evaluación.";
    });

    _cargarPreguntasIniciales();
  }

  // Genera pregunta individual inédita vía Gemini
  Future<void> _generarNuevaPreguntaIA() async {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final prompt = '''
Eres el Tutor Virtual de Minería del IST Superarse.
Genera UNA sola pregunta técnica corta y directa sobre el equipo de protección/minería: "$_equipoActual".

Reglas:
- Semilla única: $timestamp.
- Preguntas que NO debes repetir: ${_preguntasRespondidas.join(', ')}.
- Responde ÚNICAMENTE en texto plano con la pregunta, sin comillas ni aclaraciones.
''';

    try {
      final raw = await GeminiService.generarRespuesta(prompt);
      
      // Limpieza exhaustiva de marcas markdown y comillas
      final nuevaPregunta = raw
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .replaceAll('"', '')
          .replaceAll('\n', ' ')
          .trim();

      if (nuevaPregunta.isNotEmpty && 
        !nuevaPregunta.startsWith("Error al comunicarse") &&
        !_preguntasRespondidas.contains(nuevaPregunta) && 
        !_preguntasDisponibles.contains(nuevaPregunta)) {
      setState(() {
        _preguntasDisponibles.add(nuevaPregunta);
      });
    } else {
      _usarPreguntaLocalRespaldo();
    }
  } catch (e) {
    _usarPreguntaLocalRespaldo();
  }
}

  void _usarPreguntaLocalRespaldo() {
    final bancoRespaldo = [
      "¿Cuál es la función principal de este equipo: $_equipoActual?",
      "¿Qué tipo de mantenimiento preventivo requiere el equipo $_equipoActual?",
      "¿Qué norma de seguridad regula el uso de $_equipoActual?",
      "¿Qué riesgo específico mitiga $_equipoActual en minería?",
      "¿Cómo se realiza la inspección pre-operacional de $_equipoActual?"
    ];

    for (var p in bancoRespaldo) {
      if (!_preguntasRespondidas.contains(p) && !_preguntasDisponibles.contains(p)) {
        setState(() {
          _preguntasDisponibles.add(p);
        });
        break;
      }
    }
  }

  void _seleccionarPregunta(String pregunta) {
    setState(() {
      _preguntaSeleccionada = pregunta;
      _mensajeTutor = 'Has seleccionado:\n"$pregunta"\n\nPresiona el botón de micrófono abajo y dicta tu respuesta por voz.';
      _evaluado = false;
    });
    _speak(pregunta);
  }

  void _evaluarRespuestaVoz(String respuestaAlumno) async {
    if (_preguntaSeleccionada == null) return;

    final preguntaUsada = _preguntaSeleccionada!;
    setState(() => _isLoading = true);

    final prompt = '''
Eres el Tutor Virtual de Minería del IST Superarse.
Equipo evaluado: "$_equipoActual".
Pregunta formulada: "$preguntaUsada".
Respuesta dictada por el estudiante: "$respuestaAlumno".

Evalúa si la respuesta es correcta técnicamente según estándares mineros.
Devuelve ÚNICAMENTE un formato JSON estricto:
{
  "esCorrecto": true/false,
  "nota": nota entera de 0 a 100,
  "retroalimentacion": "Explicación breve del tutor (máximo 2 frases)"
}
''';

    try {
      final raw = await GeminiService.generarRespuesta(prompt);

      if (raw.startsWith("Error al comunicarse")) {
      throw Exception(raw);
      }
      final jsonStr = raw.replaceAll('```json', '').replaceAll('```', '').trim();
      final Map<String, dynamic> res = jsonDecode(jsonStr);

      final bool esCorrecto = res['esCorrecto'] ?? false;
      final int nota = res['nota'] ?? 0;
      final String feedback = res['retroalimentacion'] ?? "";

      await DatabaseHelper.instance.registrarIntento3D(
        esCorrecto: esCorrecto,
        nota: nota,
      );

      // 1. Agregar a historial de preguntas usadas
      _preguntasRespondidas.add(preguntaUsada);
      
      // 2. ELIMINAR LA PREGUNTA USADA DE LA LISTA VISIBLE
      _preguntasDisponibles.remove(preguntaUsada);

      // 3. GENERAR UNA NUEVA PREGUNTA PARA EL MISMO EQUIPO
      await _generarNuevaPreguntaIA();

      setState(() {
        _mensajeTutor = "Nota: $nota/100\n\n$feedback";
        _preguntaSeleccionada = null;
        _evaluado = true;
        _isLoading = false;
      });

      _speak(feedback);
    } catch (e) {
      setState(() {
        //_mensajeTutor = "Error al conectar con la IA de evaluación. Inténtalo de nuevo.";
        _mensajeTutor = "Error detallado: $e";
        _isLoading = false;
      });

      debugPrint("=== ERROR REAL EN EVALUACIÓN ===: $e");
  }
}


  void _escucharRespuestaVoz() async {
    if (_preguntaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona primero una pregunta.')),
      );
      return;
    }

    await _flutterTts.stop();
    bool available = await _speech.initialize(
      onError: (_) => setState(() => _isListening = false),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
    );

    if (available) {
      setState(() => _isListening = true);
      await _speech.listen(
        listenFor: const Duration(seconds: 12),
        pauseFor: const Duration(seconds: 3),
        onResult: (val) {
          if (val.finalResult && val.recognizedWords.isNotEmpty) {
            setState(() => _isListening = false);
            _evaluarRespuestaVoz(val.recognizedWords);
          }
        },
      );
    } else {
      setState(() => _isListening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D131A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D131A),
        elevation: 0,
        title: const Text(
          'VISOR DE INSPECCIÓN',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              // 1. VISOR DE EQUIPO / IMAGEN
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF16222F),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Stack(
                  children: [
                    // Nombre del equipo actual
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.amber, width: 0.8),
                        ),
                        child: Text(
                          _equipoActual,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                    // Flechas para cambiar de equipo/imagen
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left, color: Colors.white70, size: 36),
                            onPressed: () => _cambiarEquipo(-1),
                          ),
                          Icon(
                            _catalogoEquipos[_indiceEquipoActual]["icono"],
                            size: 80,
                            color: Colors.amberAccent,
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right, color: Colors.white70, size: 36),
                            onPressed: () => _cambiarEquipo(1),
                          ),
                        ],
                      ),
                    ),
                    // Icono Visor AR/3D
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: CircleAvatar(
                        backgroundColor: Colors.white12,
                        child: IconButton(
                          icon: const Icon(Icons.view_in_ar, color: Colors.white),
                          onPressed: () {},
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 2. SECCIÓN TUTOR VIRTUAL DE MINERÍA CON AVATAR
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16222F),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _evaluado ? const Color(0xFF00E676) : Colors.white10),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF00E676), width: 2),
                                image: const DecorationImage(
                                  image: AssetImage('assets/images/assistant/avatar_idle.png'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'TUTOR VIRTUAL DE MINERÍA',
                              style: TextStyle(
                                color: Color(0xFF00E676),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _mensajeTutor,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                            height: 1.4,
                            fontStyle: _preguntaSeleccionada == null && !_evaluado ? FontStyle.italic : FontStyle.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 3. SECCIÓN DE PREGUNTAS DINÁMICAS (SE REMUEVEN Y REPONEN AL RESPONDER)
              SizedBox(
                height: 48,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E676)))
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _preguntasDisponibles.length,
                        itemBuilder: (context, index) {
                          final pregunta = _preguntasDisponibles[index];
                          final isSelected = _preguntaSeleccionada == pregunta;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ActionChip(
                              backgroundColor: isSelected ? const Color(0xFF00E676) : const Color(0xFF16222F),
                              side: BorderSide(
                                color: isSelected ? const Color(0xFF00E676) : Colors.white24,
                              ),
                              label: Text(
                                pregunta,
                                style: TextStyle(
                                  color: isSelected ? Colors.black : Colors.white,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                              onPressed: () => _seleccionarPregunta(pregunta),
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 12),

              // 4. BOTÓN RESPONDER POR VOZ
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isListening ? Colors.redAccent : const Color(0xFF00E676),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none_rounded,
                    color: _isListening ? Colors.white : Colors.black,
                  ),
                  label: Text(
                    _isListening ? 'ESCUCHANDO RESPUESTA...' : 'RESPONDER AL TUTOR POR VOZ',
                    style: TextStyle(
                      color: _isListening ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  onPressed: _escucharRespuestaVoz,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}