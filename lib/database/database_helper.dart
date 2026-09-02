import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:EcsosMine/models/tipos_escenarios.dart';

class DatabaseHelper {
  // Instancia Singleton que soluciona el llamado DatabaseHelper.instance
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('superarse_mineria.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE intentos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        unidad TEXT NOT NULL,
        titulo TEXT NOT NULL,
        nivel INTEGER NOT NULL,
        calificacion INTEGER NOT NULL,
        fecha TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS intentos_3d (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        esCorrecto INTEGER NOT NULL,
        nota INTEGER NOT NULL,
        fecha TEXT NOT NULL
      )
    ''');
  }

  /// Registra el resultado del intento en la base de datos
  Future<void> guardarIntento({
    required String unidad,
    required String titulo,
    required int nivel,
    required int calificacion,
  }) async {
    final db = await instance.database;
    await db.insert('intentos', {
      'unidad': unidad,
      'titulo': titulo,
      'nivel': nivel,
      'calificacion': calificacion,
      'fecha': DateTime.now().toIso8601String(),
    });
  }

  /// Registra la evaluación realizada desde el Visor de Inspección 3D
  Future<int> registrarIntento3D({
    required bool esCorrecto,
    required int nota,
  }) async {
    final db = await database;

    // Crear la tabla automáticamente si la BD ya existía previamente
    await db.execute('''
      CREATE TABLE IF NOT EXISTS intentos_3d (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        esCorrecto INTEGER NOT NULL,
        nota INTEGER NOT NULL,
        fecha TEXT NOT NULL
      )
    ''');

    return await db.insert('intentos_3d', {
      'esCorrecto': esCorrecto ? 1 : 0,
      'nota': nota,
      'fecha': DateTime.now().toIso8601String(),
    });
  }

  /// Calcula las métricas acumuladas para la pantalla MainMenuScreen
  Future<Map<String, dynamic>> obtenerResumenRendimiento() async {
    final db = await instance.database;

    final totalIntentosRes = await db.rawQuery('SELECT COUNT(*) as total FROM intentos');
    int totalIntentos = totalIntentosRes.first['total'] as int? ?? 0;

    final totalFallosRes = await db.rawQuery('SELECT COUNT(*) as fallos FROM intentos WHERE calificacion = 0');
    int totalFallos = totalFallosRes.first['fallos'] as int? ?? 0;

    final promedioRes = await db.rawQuery('SELECT AVG(calificacion) as promedio FROM intentos');
    double promedio = (promedioRes.first['promedio'] as num?)?.toDouble() ?? 0.0;

    int notaActual = promedio.round();
    int notaFinal = totalIntentos > 0 ? (notaActual > 0 ? notaActual : 0) : 0;

    return {
      'intentos': totalIntentos,
      'fallos': totalFallos,
      'notaActual': notaActual,
      'notaFinal': notaFinal,
    };
  }

  Future<List<Map<String, dynamic>>> getIntentos() async {
    final db = await database;
    return await db.query('intentos'); 
  }

  /// Selecciona un escenario aleatorio filtrado por rol y nivel desde ScenariosBank
  Future<Map<String, dynamic>> getRandomScenarioByRoleAndLevel(String role, int level) async {
    final candidatos = ScenariosBank.todosLosEscenarios.where((s) {
      return s['role'] == role && s['nivel'] == level;
    }).toList();

    final random = Random();

    if (candidatos.isNotEmpty) {
      return Map<String, dynamic>.from(candidatos[random.nextInt(candidatos.length)]);
    }

    final candidatosRol = ScenariosBank.todosLosEscenarios.where((s) {
      return s['role'] == role;
    }).toList();

    if (candidatosRol.isNotEmpty) {
      return Map<String, dynamic>.from(candidatosRol[random.nextInt(candidatosRol.length)]);
    }

    return Map<String, dynamic>.from(ScenariosBank.todosLosEscenarios[random.nextInt(ScenariosBank.todosLosEscenarios.length)]);
  }
}