import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/quote_model.dart';
import '../models/client_model.dart';

class PdfGenerator {
  static Future<void> generarPDF(Cotizacion venta, Cliente cliente) async {
    final pdf = pw.Document();
    
    // Cargamos una fuente y un logo (opcional, aquí uso íconos básicos)
    final font = await PdfGoogleFonts.nunitoExtraLight();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            _buildHeader(venta, cliente),
            pw.SizedBox(height: 20),
            _buildTable(venta.productos),
            pw.Divider(),
            _buildTotal(venta),
            pw.SizedBox(height: 40),
            _buildFooter(), // <--- AQUÍ ESTÁN LOS BANCOS Y TYC
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static pw.Widget _buildHeader(Cotizacion venta, Cliente cliente) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text("COTIZACIÓN #${venta.id}", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("EMPRESA DE MAQUINARIA TEXTIL", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text("RUC: 20123456789"),
                pw.Text("Dirección: Av. Gamarra 123, La Victoria"),
                pw.Text("Teléfono: 999 999 999"),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text("Cliente: ${cliente.nombre}"),
                pw.Text("RUC/DNI: ${cliente.dniRuc ?? '---'}"),
                pw.Text("Fecha: ${venta.fecha.split(' ')[0]}"),
                pw.Text("Estado: ${venta.estado.toUpperCase()}", style: pw.TextStyle(color: PdfColors.red)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTable(List<Map<String, dynamic>> productos) {
    return pw.Table.fromTextArray(
      headers: ['Producto', 'Cant.', 'Precio Unit.', 'Subtotal'],
      data: productos.map((item) {
        double subtotal = item['cantidad'] * item['precio_unitario'];
        return [
          item['nombre'],
          item['cantidad'],
          "S/ ${item['precio_unitario']}",
          "S/ ${subtotal.toStringAsFixed(2)}",
        ];
      }).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
      },
    );
  }

  static pw.Widget _buildTotal(Cotizacion venta) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        "TOTAL A PAGAR: S/ ${venta.total.toStringAsFixed(2)}",
        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  // BANCOS Y TÉRMINOS ---
  static pw.Widget _buildFooter() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text("CUENTAS BANCARIAS:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text("BCP SOLES: 191-12345678-0-99"),
              pw.Text("CCI: 002-191-12345678099-55"),
              pw.Text("Titular: Juan Pérez"),
            ]),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text("BBVA SOLES: 0011-0123-456789"),
              pw.Text("YAPE / PLIN: 999 999 999"),
            ]),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Text("TÉRMINOS Y CONDICIONES:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Bullet(text: "Precios válidos por 7 días calendario."),
        pw.Bullet(text: "Tiempo de entrega: Inmediata (Sujeto a stock)."),
        pw.Bullet(text: "Garantía de 1 año en cabezal y motor."),
        pw.Bullet(text: "No se aceptan devoluciones después de 24 horas."),
      ],
    );
  }
}