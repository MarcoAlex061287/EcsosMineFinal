import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:path_provider/path_provider.dart';

class PdfReportService {
  static Future<void> solicitarCorreoYEnviarPDF({
    required BuildContext context,
    required String username,
    required String rol,
    required int intentos,
    required int fallos,
    required int notaActual,
    required int notaFinal,
  }) async {
    final TextEditingController correoController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final String? correoDestino = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16222F),
          title: const Text('ENVIAR REPORTE PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: correoController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Correo destinatario', labelStyle: TextStyle(color: Colors.white60)),
              validator: (v) => (v == null || !v.contains('@')) ? 'Ingrese un correo válido' : null,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(dialogContext).pop(correoController.text.trim());
                }
              },
              child: const Text('ENVIAR'),
            ),
          ],
        );
      },
    );

    if (correoDestino == null || correoDestino.isEmpty) return;

    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context pdfContext) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(24),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('ECSOS MINE - REPORTES DE EVALUACIÓN', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900)),
                  pw.Divider(),
                  pw.SizedBox(height: 10),
                  pw.Text('ESTUDIANTE: $username'),
                  pw.Text('ROL EVALUADO: $rol'),
                  pw.SizedBox(height: 15),
                  pw.Table.fromTextArray(
                    headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                    headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                    headers: ['Métrica', 'Detalle / Puntuación'],
                    data: [
                      ['Intentos Acumulados', '$intentos'],
                      ['Total de Fallos', '$fallos'],
                      ['Módulo Simulacro de Crisis', '$notaActual / 50 pts'],
                      ['Módulo Exploración en RA', '${notaFinal - notaActual} / 50 pts'],
                      ['PUNTAJE TOTAL COMBINADO', '$notaFinal / 100 pts'],
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );

      final pdfBytes = await pdf.save();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/Reporte_${username.replaceAll(' ', '_')}.pdf');
      await file.writeAsBytes(pdfBytes);

      final Email email = Email(
        body: 'Reporte de rendimiento de $username.',
        subject: 'Reporte Calificación: $username',
        recipients: [correoDestino],
        attachmentPaths: [file.path],
      );

      await FlutterEmailSender.send(email);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
    }
  }
}