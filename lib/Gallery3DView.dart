import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'gemini_service.dart';
import 'package:EcsosMine/database/visor_inspection_page.dart';

class Gallery3DView extends StatefulWidget {
  const Gallery3DView({super.key});

  @override
  State<Gallery3DView> createState() => _Gallery3DViewState();
}

class _Gallery3DViewState extends State<Gallery3DView> {
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  int _currentIndex = 0;
  bool _isListening = false;
  bool _isLoadingIA = false;
  
  String _iaResponse = "¡Hola! Selecciona una de las preguntas generadas abajo para poner a prueba tus conocimientos sobre este equipo.";
  String _preguntaActiva = "";
  List<String> _preguntasSugeridas = [];

  final List<Map<String, String>> _items = [
    {
      'name': 'Casco con Lámpara',
      'model': 'assets/models/casco.glb',
      'desc': 'Elemento de protección personal e iluminación para minería subterránea.',
    },
    {
      'name': 'Perforadora Jumbo',
      'model': 'assets/models/jumbo.glb',
      'desc': 'Equipo mecanizado para la perforación de frentes en minería subterránea.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
    _generarPreguntasIniciales();
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

  // Solicita a Gemini generar 3 preguntas sobre el objeto actual
  Future<void> _generarPreguntasIniciales() async {
    setState(() => _isLoadingIA = true);
    final currentItem = _items[_currentIndex];

    final prompt = '''
Eres el Tutor Virtual de Minería del IST Superarse.
Genera EXACTAMENTE 3 preguntas técnicas de evaluación cortas para un estudiante sobre el equipo minero: "${currentItem['name']}".
Devuelve ÚNICAMENTE un arreglo JSON estricto de strings con las 3 preguntas, sin introducciones ni marcas markdown de código.
Ejemplo de formato esperado: ["¿Pregunta 1?", "¿Pregunta 2?", "¿Pregunta 3?"]
''';

    try {
      final respuestaRaw = await GeminiService.generarRespuesta(prompt);
      final jsonLimpio = respuestaRaw.replaceAll('```json', '').replaceAll('```', '').trim();
      List<dynamic> listaParsed = jsonDecode(jsonLimpio);

      setState(() {
        _preguntasSugeridas = listaParsed.map((e) => e.toString()).toList();
        _iaResponse = "He generado 3 preguntas para ti sobre ${currentItem['name']}. Selecciona un chip abajo para responder.";
        _preguntaActiva = "";
        _isLoadingIA = false;
      });
    } catch (e) {
      setState(() {
        _preguntasSugeridas = [
          "¿Cuál es la función principal de este equipo?",
          "¿Qué equipo de EPP se requiere para operarlo?",
          "¿Qué protocolo de seguridad aplica antes de usarlo?"
        ];
        _iaResponse = "Selecciona una pregunta para iniciar la evaluación.";
        _isLoadingIA = false;
      });
    }
  }

  // Cuando el alumno presiona un Chip de pregunta
  void _seleccionarPregunta(String pregunta) {
    setState(() {
      _preguntaActiva = pregunta;
      _iaResponse = "Pregunta seleccionada: \"$pregunta\"\n\nPresiona el botón verde de micrófono abajo y da tu respuesta.";
    });
    _speak(pregunta);
  }

  // Evalúa la respuesta hablada por el estudiante
  void _evaluarRespuestaEstudiante(String respuestaAlumno) async {
    if (_preguntaActiva.isEmpty) {
      setState(() {
        _iaResponse = "Por favor, selecciona primero una pregunta (Chip) antes de dar tu respuesta.";
      });
      return;
    }

    setState(() => _isLoadingIA = true);
    final currentItem = _items[_currentIndex];

    final prompt = '''
Eres el Tutor Virtual de Minería del IST Superarse.
Equipo evaluado: "${currentItem['name']}".
Pregunta realizada al estudiante: "$_preguntaActiva".
Respuesta dada por el estudiante por voz: "$respuestaAlumno".

Evalúa si la respuesta del estudiante es técnicamente correcta, incompleta o incorrecta. 
Proporciona una retroalimentación breve, constructiva y educativa (máximo 3 oraciones).
''';

    try {
      final evaluacion = await GeminiService.generarRespuesta(prompt);
      setState(() {
        _iaResponse = evaluacion;
        _isLoadingIA = false;
      });
      _speak(evaluacion);
    } catch (e) {
      setState(() {
        _iaResponse = "No pude evaluar tu respuesta por un problema de conexión. Inténtalo de nuevo.";
        _isLoadingIA = false;
      });
    }
  }

  void _escucharVoz() async {
    await _flutterTts.stop();
    bool available = await _speech.initialize(
      onError: (val) => setState(() => _isListening = false),
      onStatus: (val) {
        if (val == 'done' || val == 'notListening') {
          setState(() => _isListening = false);
        }
      },
    );

    if (available) {
      setState(() => _isListening = true);
      await _speech.listen(
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        onResult: (val) {
          if (val.finalResult && val.recognizedWords.isNotEmpty) {
            setState(() => _isListening = false);
            _evaluarRespuestaEstudiante(val.recognizedWords);
          }
        },
      );
    } else {
      setState(() => _isListening = false);
    }
  }

  void _cambiarModelo(int nuevoIndex) {
    setState(() {
      _currentIndex = nuevoIndex;
    });
    _generarPreguntasIniciales();
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = _items[_currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF0D131A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16222F),
        elevation: 0,
        title: const Text(
          'GALERÍA 3D DE EQUIPOS',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        // BOTÓN EN LA BARRA SUPERIOR PARA ABRIR EL VISOR DE INSPECCIÓN
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment_turned_in, color: Color(0xFF10B981)),
            tooltip: 'Ir al Visor de Inspección',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => VisorInspeccionPage()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            children: [
              // 1. VISOR DE MODELO 3D
              Expanded(
                flex: 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF16222F),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: ModelViewer(
                          key: ValueKey(currentItem['model']),
                          src: currentItem['model']!,
                          alt: currentItem['name']!,
                          ar: true,
                          autoRotate: true,
                          cameraControls: true,
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                      Positioned(
                        left: 8,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: IconButton(
                            style: IconButton.styleFrom(backgroundColor: Colors.black54),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.amberAccent),
                            onPressed: () {
                              int prev = (_currentIndex - 1 + _items.length) % _items.length;
                              _cambiarModelo(prev);
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: IconButton(
                            style: IconButton.styleFrom(backgroundColor: Colors.black54),
                            icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.amberAccent),
                            onPressed: () {
                              int next = (_currentIndex + 1) % _items.length;
                              _cambiarModelo(next);
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            currentItem['name']!,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 2. BOTÓN DE ACCESO DIRECTO AL VISOR DE INSPECCIÓN
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF10B981)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.fact_check_outlined, color: Color(0xFF10B981)),
                  label: const Text(
                    'IR A MODO INSPECCIÓN / EVALUACIÓN COMPLETA',
                    style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => VisorInspeccionPage()),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              // 3. SECCIÓN TUTOR VIRTUAL DE MINERÍA CON AVATAR
              Expanded(
                flex: 4,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16222F),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                  ),
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
                              border: Border.all(color: const Color(0xFF10B981), width: 2),
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
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          child: _isLoadingIA
                              ? const Padding(
                                  padding: EdgeInsets.only(top: 20),
                                  child: Center(
                                    child: CircularProgressIndicator(color: Color(0xFF10B981)),
                                  ),
                                )
                              : Text(
                                  '"$_iaResponse"',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    height: 1.35,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 4. CHIPS CON LAS PREGUNTAS GENERADAS POR LA IA
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _preguntasSugeridas.length,
                  itemBuilder: (context, index) {
                    final pregunta = _preguntasSugeridas[index];
                    final isSelected = pregunta == _preguntaActiva;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ActionChip(
                        backgroundColor: isSelected
                            ? const Color(0xFF10B981)
                            : const Color(0xFF16222F),
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFF10B981)
                              : Colors.white24,
                        ),
                        label: Text(
                          pregunta,
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        onPressed: () => _seleccionarPregunta(pregunta),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              // 5. BOTÓN PARA RESPONDER POR VOZ
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isListening ? Colors.redAccent : const Color(0xFF10B981),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none_rounded, color: Colors.black),
                  label: Text(
                    _isListening ? 'ESCUCHANDO TU RESPUESTA...' : 'RESPONDER AL TUTOR POR VOZ',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  onPressed: _escucharVoz,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}