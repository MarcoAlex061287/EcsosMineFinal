import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:EcsosMine/database/database_helper.dart';
import 'package:EcsosMine/floating_answer_card.dart';
import 'package:EcsosMine/gemini_service.dart';
import 'package:EcsosMine/UserSession.dart';

class CrisisSimulator extends StatefulWidget {
  const CrisisSimulator({super.key});

  @override
  State<CrisisSimulator> createState() => _CrisisSimulatorState();
}

class _CrisisSimulatorState extends State<CrisisSimulator> {
  final List<String> _roles = [
    'Supervisor HSEQ',
    'Jefe de Minas',
    'Geólogo de Mina',
    'Ingeniero de Planta',
  ];

  final Set<String> _rolesBloqueados = {};
  final Map<String, int> _puntajesPorRol = {};

  String _selectedRole = 'Jefe de Minas';
  int _currentNivel = 1;

  // Acumuladores globales
  int _intentosRestantes = 3;
  int _totalIntentosAcumulados = 0;
  int _totalFallosAcumulados = 0;

  bool _isRemediation = false;
  bool _isLoading = false;
  bool _evaluacionIniciada = false; // Controla la pantalla de inicio del módulo
  Map<String, dynamic>? _currentScenario;

  // TEMPORIZADOR
  Timer? _timer;
  int _secondsRemaining = 30;

  // MOTORES DE AUDIO Y VOZ
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechInitialized = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initAudioEngines();
  }

  void _initAudioEngines() async {
    await _flutterTts.setLanguage("es-ES");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);

    _speechInitialized = await _speech.initialize(
      onError: (val) {
        if (mounted) setState(() => _isListening = false);
      },
      onStatus: (val) {
        if (val == 'done' || val == 'notListening') {
          if (mounted) setState(() => _isListening = false);
        }
      },
    );
  }

  Future<void> _hablarTexto(String texto) async {
    await _flutterTts.stop();
    await _flutterTts.speak(texto);
  }

  int _obtenerTiempoLimite() {
    if (_isRemediation) return 30;
    return _currentNivel <= 2 ? 40 : 30;
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsRemaining = _obtenerTiempoLimite());

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
        _alAgotarTiempo();
      }
    });
  }

  Future<void> _cargarEscenario({bool esRemediacion = false}) async {
    _timer?.cancel();
    _flutterTts.stop();

    setState(() {
      _isLoading = true;
      _isRemediation = esRemediacion;
      _currentScenario = null;
      _isProcessing = false;
    });

    Map<String, dynamic> scenarioCargado =
        await DatabaseHelper.instance.getRandomScenarioByRoleAndLevel(_selectedRole, _currentNivel);

    if (esRemediacion) {
      scenarioCargado = Map<String, dynamic>.from(scenarioCargado);
      scenarioCargado['title'] = "REMEDIACIÓN: ${scenarioCargado['title']}";
    }

    setState(() {
      _currentScenario = scenarioCargado;
      _isLoading = false;
    });

    _startTimer();
    _hablarTexto("${_currentScenario!['title']}. ${_currentScenario!['description']}.");
  }

  Future<String> _obtenerRetroalimentacionBot({
    required String opcionSeleccionada,
    required String opcionCorrecta,
  }) {
    return GeminiService.getFeedback(
      role: _selectedRole,
      nivel: _currentNivel,
      tituloCaso: _currentScenario?['title'] ?? 'Caso Práctico',
      opcionSeleccionada: opcionSeleccionada,
      opcionCorrecta: opcionCorrecta,
      feedbackLocal: _currentScenario?['feedback'] as String?,
    );
  }

  int _calcularNotaGlobal() {
    if (_puntajesPorRol.isEmpty) return 0;
    int sumaNotas = _puntajesPorRol.values.reduce((a, b) => a + b);
    double promedio = sumaNotas / _puntajesPorRol.length;
    return promedio.round().clamp(0, 50);
  }

  void _alAgotarTiempo() async {
    _stopListening();
    setState(() {
      _isLoading = true;
      _intentosRestantes--;
      _totalIntentosAcumulados++;
      _totalFallosAcumulados++;
    });

    await DatabaseHelper.instance.guardarIntento(
      unidad: 'Simulacro Crisis - $_selectedRole',
      titulo: _currentScenario?['title'] ?? 'Caso Práctico',
      nivel: _currentNivel,
      calificacion: 0,
    );

    final String correctText = _obtenerTextoOpcionCorrecta();
    String feedbackBot = await _obtenerRetroalimentacionBot(
      opcionSeleccionada: 'Tiempo Agotado',
      opcionCorrecta: correctText,
    );

    setState(() => _isLoading = false);

    _mostrarBotTutorDialog(
      esCorrecto: false,
      tituloModal: _intentosRestantes > 0 ? '¡TIEMPO AGOTADO!' : '¡ROL BLOQUEADO!',
      mensajeBot: _intentosRestantes > 0
          ? "$feedbackBot\n\n⚠️ Te quedan $_intentosRestantes intento(s). A continuación realizarás la PREGUNTA DE REMEDIACIÓN."
          : "Has agotado tus 3 intentos en el rol de $_selectedRole. El rol ha sido calificado con 0 pts y bloqueado.",
      onContinuar: () {
        Navigator.pop(context);
        setState(() => _isProcessing = false);
        if (_intentosRestantes > 0) {
          _cargarEscenario(esRemediacion: true);
        } else {
          _puntajesPorRol[_selectedRole] = 0;
          _bloquearRolActualYReiniciar();
        }
      },
    );
  }

  String _obtenerTextoOpcionCorrecta() {
    final int correctIndex = _currentScenario?['correct_option'] ?? 0;
    if (correctIndex == 0) return _currentScenario?['option_a'] ?? '';
    if (correctIndex == 1) return _currentScenario?['option_b'] ?? '';
    return _currentScenario?['option_c'] ?? '';
  }

  void _seleccionarOpcion(int index) async {
    if (_currentScenario == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _totalIntentosAcumulados++;
    });

    _timer?.cancel();
    _stopListening();

    final List<String> opciones = [
      _currentScenario!['option_a'] ?? '',
      _currentScenario!['option_b'] ?? '',
      _currentScenario!['option_c'] ?? '',
    ];

    final int correctOption = _currentScenario!['correct_option'] ?? 0;
    final bool esCorrecto = (index == correctOption);

    if (esCorrecto) {
      bool esUltimoNivel = _currentNivel >= 5;

      if (esUltimoNivel) {
        int puntajeRol = (50 - (_totalFallosAcumulados * 2)).clamp(10, 50);
        _puntajesPorRol[_selectedRole] = puntajeRol;

        await DatabaseHelper.instance.guardarIntento(
          unidad: 'Simulacro Crisis - $_selectedRole',
          titulo: _currentScenario?['title'] ?? 'Caso Práctico',
          nivel: _currentNivel,
          calificacion: puntajeRol,
        );
      }

      _mostrarBotTutorDialog(
        esCorrecto: true,
        tituloModal: '¡RESPUESTA CORRECTA!',
        mensajeBot: esUltimoNivel
            ? "🎉 ¡Felicidades! Has completado exitosamente todos los niveles para $_selectedRole.\nEste rol ha sido CALIFICADO y BLOQUEADO."
            : "${_currentScenario!['feedback']}\n\n🎉 ¡Avanzas al Nivel ${_currentNivel + 1}!",
        onContinuar: () {
          Navigator.pop(context);
          setState(() => _isProcessing = false);
          if (!esUltimoNivel) {
            setState(() {
              _currentNivel++;
              _intentosRestantes = 3;
            });
            _cargarEscenario(esRemediacion: false);
          } else {
            _bloquearRolActualYReiniciar();
          }
        },
      );
    } else {
      setState(() {
        _isLoading = true;
        _intentosRestantes--;
        _totalFallosAcumulados++;
      });

      await DatabaseHelper.instance.guardarIntento(
        unidad: 'Simulacro Crisis - $_selectedRole',
        titulo: _currentScenario?['title'] ?? 'Caso Práctico',
        nivel: _currentNivel,
        calificacion: 0,
      );

      String feedbackBot = await _obtenerRetroalimentacionBot(
        opcionSeleccionada: opciones[index],
        opcionCorrecta: opciones[correctOption],
      );

      setState(() => _isLoading = false);

      _mostrarBotTutorDialog(
        esCorrecto: false,
        tituloModal: _intentosRestantes > 0 ? '¡RESPUESTA INCORRECTA!' : '¡ROL BLOQUEADO!',
        mensajeBot: _intentosRestantes > 0
            ? "$feedbackBot\n\n⚠️ Te quedan $_intentosRestantes intento(s). Pasarás a REMEDIACIÓN."
            : "$feedbackBot\n\n❌ Has agotado tus 3 intentos. El rol $_selectedRole ha sido CALIFICADO (0 pts) y BLOQUEADO.",
        onContinuar: () {
          Navigator.pop(context);
          setState(() => _isProcessing = false);
          if (_intentosRestantes > 0) {
            _cargarEscenario(esRemediacion: true);
          } else {
            _puntajesPorRol[_selectedRole] = 0;
            _bloquearRolActualYReiniciar();
          }
        },
      );
    }
  }

  void _bloquearRolActualYReiniciar() {
    setState(() {
      _rolesBloqueados.add(_selectedRole);
      _currentScenario = null;
      _evaluacionIniciada = false;
      _intentosRestantes = 3;
      _currentNivel = 1;

      final rolesDisponibles = _roles.where((r) => !_rolesBloqueados.contains(r)).toList();
      if (rolesDisponibles.isNotEmpty) {
        _selectedRole = rolesDisponibles.first;
      }
    });

    if (_rolesBloqueados.length == _roles.length) {
      _mostrarFinSimulacro();
    }
  }

  void _mostrarFinSimulacro() {
    int notaFinalGlobal = _calcularNotaGlobal();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16222F),
        title: const Text('EVALUACIÓN FINALIZADA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Has completado todos los roles evaluables.\n\n'
          '• Roles Calificados: ${_rolesBloqueados.length} / ${_roles.length}\n'
          '• Total Fallos: $_totalFallosAcumulados\n'
          '• NOTA GLOBAL FINAL: $notaFinalGlobal / 50 pts',
          style: const TextStyle(color: Colors.white70, height: 1.4, fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('VOLVER AL MENÚ PRINCIPAL', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _mostrarBotTutorDialog({
    required bool esCorrecto,
    required String tituloModal,
    required String mensajeBot,
    required VoidCallback onContinuar,
  }) {
    _hablarTexto("$tituloModal. $mensajeBot");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF16222F),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: esCorrecto ? Colors.greenAccent : Colors.redAccent, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(tituloModal, style: TextStyle(color: esCorrecto ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Text(mensajeBot, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent, foregroundColor: Colors.black),
                    onPressed: onContinuar,
                    child: const Text('CONTINUAR', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _escucharRespuesta() async {
    if (_isProcessing) return;

    if (_isListening) {
      _stopListening();
      return;
    }

    await _flutterTts.stop();

    bool disponible = _speechInitialized;
    if (!disponible) {
      disponible = await _speech.initialize(
        onError: (val) {
          if (mounted) setState(() => _isListening = false);
        },
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
      );
      _speechInitialized = disponible;
    }

    if (disponible) {
      setState(() => _isListening = true);

      await _speech.listen(
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        onResult: (result) {
          String texto = result.recognizedWords.toLowerCase().trim();

          if (texto.contains("opcion a") || texto.contains("la a") || texto == "a") {
            _stopListening();
            _seleccionarOpcion(0);
          } else if (texto.contains("opcion b") || texto.contains("la b") || texto == "b") {
            _stopListening();
            _seleccionarOpcion(1);
          } else if (texto.contains("opcion c") || texto.contains("la c") || texto == "c") {
            _stopListening();
            _seleccionarOpcion(2);
          }
        },
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    if (mounted) setState(() => _isListening = false);
  }

  Widget _buildScenarioCard() {
    final scenario = _currentScenario!;
    final List<String> options = [
      scenario['option_a'] ?? '',
      scenario['option_b'] ?? '',
      scenario['option_c'] ?? '',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          scenario['title'] ?? '',
          style: const TextStyle(color: Colors.amberAccent, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          scenario['description'] ?? '',
          style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.3),
        ),
        const SizedBox(height: 16),

        // Control de Micrófono ubicado ANTES de las preguntas
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF16222F).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isListening ? Colors.redAccent : Colors.amberAccent.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: _escucharRespuesta,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: _isListening ? Colors.redAccent : Colors.amberAccent,
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _isListening
                      ? 'Escuchando... Di "OPCIÓN A", "OPCIÓN B" u "OPCIÓN C"'
                      : 'Presiona el micrófono y di OPCIÓN A, OPCIÓN B o OPCIÓN C',
                  style: TextStyle(
                    color: _isListening ? Colors.redAccent : Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Opciones de Respuesta
        ...List.generate(options.length, (index) {
          return FloatingAnswerCard(
            texto: '${String.fromCharCode(65 + index)}) ${options[index]}',
            isSelected: false,
            onTap: () => _seleccionarOpcion(index),
          );
        }),
      ],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _flutterTts.stop();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0D131A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16222F).withValues(alpha: 0.9),
        elevation: 0,
        title: const Text(
          'SIMULACRO DE CRISIS',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/simulacro_crisis2.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF0D131A)),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.80)),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildHeaderSelectionCard(),
                            const SizedBox(height: 16),
                            if (!_evaluacionIniciada)
                              _buildPantallaInicialEvaluacion()
                            else if (_isLoading)
                              const CircularProgressIndicator(color: Colors.amberAccent)
                            else if (_currentScenario == null)
                              _buildStartPrompt()
                            else
                              _buildScenarioCard(),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSelectionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16222F).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Usuario: ${UserSession.userName}', style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13)),
              Text('Nivel: $_currentNivel / 5', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Intentos en rol: $_intentosRestantes / 3', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Row(
                children: [
                  const Icon(Icons.timer_outlined, color: Colors.amberAccent, size: 16),
                  const SizedBox(width: 4),
                  Text('$_secondsRemaining s', style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedRole,
              isExpanded: true,
              dropdownColor: const Color(0xFF16222F),
              items: _roles.map((r) {
                bool estaBloqueado = _rolesBloqueados.contains(r);
                return DropdownMenuItem(
                  value: r,
                  enabled: !estaBloqueado,
                  child: Text(
                    estaBloqueado ? '$r (BLOQUEADO)' : r,
                    style: TextStyle(color: estaBloqueado ? Colors.white30 : Colors.white),
                  ),
                );
              }).toList(),
              onChanged: (newRole) {
                if (newRole != null && !_rolesBloqueados.contains(newRole)) {
                  setState(() {
                    _selectedRole = newRole;
                    _currentNivel = 1;
                    _intentosRestantes = 3;
                    _currentScenario = null;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPantallaInicialEvaluacion() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16222F).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/simulacro_crisis.png',
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.crisis_alert, size: 80, color: Colors.amberAccent),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'EVALUACIÓN DE CRISIS EN MINERÍA',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Responde los casos críticos para cada rol operativo antes de que finalice el tiempo. Puedes seleccionar la respuesta en pantalla o utilizar el micrófono.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amberAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('INICIAR EVALUACIÓN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              onPressed: () {
                setState(() => _evaluacionIniciada = true);
                _cargarEscenario(esRemediacion: false);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartPrompt() {
    bool todosBloqueados = _rolesBloqueados.length == _roles.length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF16222F).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            todosBloqueados ? 'TODOS LOS ROLES EVALUADOS' : 'Rol: $_selectedRole - Nivel $_currentNivel',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (!todosBloqueados)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent, foregroundColor: Colors.black),
              onPressed: () => _cargarEscenario(esRemediacion: false),
              child: const Text('CONTINUAR CON EL ROL', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}