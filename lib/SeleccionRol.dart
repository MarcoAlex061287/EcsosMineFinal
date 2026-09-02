import 'package:flutter/material.dart';
import 'UserSession.dart';

class RoleSelection extends StatelessWidget {
  final Function(String) onRoleSelected;

  RoleSelection({super.key, required this.onRoleSelected});

  final List<Map<String, dynamic>> roles = [
    {
      'title': 'Jefe de Minas',
      'icon': Icons.engineering,
      'color': Colors.amber,
      'desc': 'Operaciones subterráneas y rajo abierto'
    },
    {
      'title': 'Supervisor HSEQ',
      'icon': Icons.health_and_safety,
      'color': Colors.greenAccent,
      'desc': 'Seguridad, salud y medio ambiente'
    },
    {
      'title': 'Geólogo de Mina',
      'icon': Icons.terrain,
      'color': Colors.orangeAccent,
      'desc': 'Control de leyes y exploración'
    },
    {
      'title': 'Ingeniero de Planta',
      'icon': Icons.factory,
      'color': Colors.cyanAccent,
      'desc': 'Procesamiento y conminución'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: const Color(0xFF1E2638),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.badge, size: 40, color: Colors.cyanAccent),
            const SizedBox(height: 10),
            const Text(
              "SELECCIONAR ROL",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              "Elige el perfil técnico para la simulación",
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 15),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: roles.map((r) {
                    final bool isSelected = UserSession.selectedRole == r['title'];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? r['color'].withOpacity(0.2) : Colors.white.withValues(alpha: 0.05),
                        border: Border.all(
                          color: isSelected ? r['color'] : Colors.white24,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: r['color'].withOpacity(0.2),
                          child: Icon(r['icon'], color: r['color']),
                        ),
                        title: Text(
                          r['title'],
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          r['desc'],
                          style: const TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: r['color'])
                            : const Icon(Icons.chevron_right, color: Colors.white30),
                        onTap: () {
                          UserSession.setSelectedRole(r['title']);
                          onRoleSelected(r['title']);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}