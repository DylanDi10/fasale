import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart'; // <--- IMPORTANTE
import 'package:share_plus/share_plus.dart';     // <--- IMPORTANTE
import '../models/quote_model.dart';
import '../models/client_model.dart';

class PdfGenerator {
  
  // Cambié el nombre a 'generarYCompartirPDF' para que sea más descriptivo
  static Future<void> generarYCompartirPDF(Cotizacion venta, Cliente cliente) async {
    final pdf = pw.Document();
    

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40), // Márgenes para que no salga cortado
        build: (pw.Context context) {
          return [
            _buildHeader(venta, cliente), // Tu header
            pw.SizedBox(height: 20),
            _buildTable(venta.productos), // Tu tabla
            pw.Divider(),
            _buildTotal(venta),           // Tu total
            pw.SizedBox(height: 40),
            _buildFooter(),               // Tus bancos
          ];
        },
      ),
    );

    // --- AQUÍ ESTÁ EL CAMBIO CLAVE ---
    
    // 1. Buscamos la carpeta temporal del celular
    final output = await getTemporaryDirectory();
    
    // 2. Creamos el archivo con un nombre único
    final file = File("${output.path}/Cotizacion_FASALE_${venta.id}.pdf");
    
    // 3. Escribimos los bytes del PDF en ese archivo
    await file.writeAsBytes(await pdf.save());

    // 4. Compartimos el archivo + el mensaje de texto
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Hola ${cliente.nombre}, adjunto la cotización #${venta.id} de FASALE. Quedo atento. ⚡',
    );
  }

  // --- TUS FUNCIONES DE DISEÑO (Las dejé igualitas) ---

  static pw.Widget _buildHeader(Cotizacion venta, Cliente cliente) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
             // Aquí podrías poner tu logo: pw.Image(pw.MemoryImage(imageBytes), width: 80),
            pw.Text("FASALE", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
            pw.Text("COTIZACIÓN #${venta.id}", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(color: PdfColors.green800, thickness: 2),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
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
                pw.Text("Cliente: ${cliente.nombre}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text("RUC/DNI: ${cliente.dniRuc ?? '---'}"),
                pw.Text("Fecha: ${venta.fecha.split(' ')[0]}"),
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
        // Aseguramos que los números sean double para evitar errores
        double cantidad = double.tryParse(item['cantidad'].toString()) ?? 0;
        double precio = double.tryParse(item['precio_unitario'].toString()) ?? 0;
        double subtotal = cantidad * precio;
        
        return [
          item['nombre'],
          item['cantidad'].toString(),
          "USD ${precio.toStringAsFixed(2)}",
          "USD ${subtotal.toStringAsFixed(2)}",
        ];
      }).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: pw.BoxDecoration(color: PdfColors.green800), // Color corporativo
      rowDecoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
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
        "TOTAL A PAGAR:USD ${venta.total.toStringAsFixed(2)}",
        style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.green900),
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
          ),
          child: pw.Column(
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
            ],
          ),
        ),
        pw.SizedBox(height: 20),
        pw.Text("TÉRMINOS Y CONDICIONES:", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
        pw.Bullet(text: "Precios válidos por 7 días calendario.", style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        pw.Bullet(text: "Tiempo de entrega: Inmediata (Sujeto a stock).", style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        pw.Bullet(text: "Garantía de 1 año en cabezal y motor.", style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
      ],
    );
  }
}