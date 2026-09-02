import 'package:flutter/material.dart';

class FloatingAnswerCard extends StatelessWidget {
  final String textoRespuesta;
  final bool isSelected;
  final VoidCallback onTap;

  const FloatingAnswerCard({
    super.key,
    required String texto,
    required this.isSelected,
    required this.onTap,
  }) : textoRespuesta = texto;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF253548) : const Color(0xFF1A2634),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isSelected ? Colors.blueAccent.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.2),
            blurRadius: isSelected ? 10 : 4,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isSelected ? Colors.blueAccent : Colors.white10,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? Colors.blueAccent : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? Colors.blueAccent : Colors.white38,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    textoRespuesta,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}