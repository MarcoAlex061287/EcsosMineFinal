class UserSession {
  
  static String userName = "Estudiante";
  static String selectedRole = "Jefe de Minas";

  static int crisisFailures = 0;
  static int arFailures = 0;
  static double currentScore = 10.0;
  
  static List<int> answeredQuestionIds = [];

  static void setSelectedRole(String role) {
    selectedRole = role;
  }

  static void incrementCrisisFailures() {
    crisisFailures++;
    currentScore = (currentScore - 0.5).clamp(0.0, 10.0);
  }

  static double calculateFinalScore() {
    return currentScore;
  }

  /// Limpia la sesión únicamente para un usuario completamente NUEVO
  static void clearForNewUser(String nombre, {String rol = "Jefe de Minas"}) {
    userName = nombre.isNotEmpty ? nombre : "Estudiante";
    selectedRole = rol;
    crisisFailures = 0;
    arFailures = 0;
    currentScore = 10.0;
    answeredQuestionIds.clear();
  }

  /// Carga la información en memoria si el usuario YA EXISTE
  static void loadExistingUser({
    required String nombre,
    required String rol,
    required double score,
    required int fallosCrisis,
  }) {
    userName = nombre;
    selectedRole = rol;
    currentScore = score;
    crisisFailures = fallosCrisis;
  }
}