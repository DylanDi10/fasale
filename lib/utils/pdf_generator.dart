import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart'
    as pw;
import 'package:printing/printing.dart';
import '../models/quote_model.dart';
import '../models/client_model.dart';
import 'package:intl/intl.dart';

class PdfGenerator {
  // Función principal que llamaremos desde la pantalla
  static Future<void> generarPDF(Cotizacion venta, Cliente cliente) async {
    final pdf = pw.Document();

    // Cargamos una fuente (opcional, pero se ve mejor)
    // Usamos la fuente estándar de Android/iOS
    final font = await PdfGoogleFonts.nunitoExtraLight();

    // Agregamos una página al documento
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font),
        build: (pw.Context context) {
          return [
            //  CABECERA 
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  "FASALE",
                  style: pw.TextStyle(
                    fontSize: 40,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text("Recibo de Venta #${venta.id}"),
                    pw.Text(
                      "Fecha: ${DateFormat('dd/MM/yyyy').format(venta.fecha)}",
                    ),
                  ],
                ),
              ],
            ),
            pw.Divider(),

            //  DATOS DEL CLIENTE
            pw.Container(
              margin: const pw.EdgeInsets.symmetric(vertical: 20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "Cliente:",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(cliente.nombre),
                  pw.Text("DNI/RUC: ${cliente.dniRuc}"),
                  pw.Text("Teléfono: ${cliente.telefono}"),
                  if (cliente.direccion != null)
                    pw.Text("Dirección: ${cliente.direccion}"),
                ],
              ),
            ),

            //  TABLA DE PRODUCTOS
            pw.Table.fromTextArray(
              context: context,
              headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
              headerHeight: 25,
              cellHeight: 30,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center, 
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight, 
              },
              headers: ['Producto', 'Cant.', 'Precio Unit.', 'Total'],
              data: venta.productos.map((item) {
                final nombre = item['nombre'];
                final cantidad = item['cantidad'];
                final precio = item['precio_unitario'];
                final totalRow = cantidad * precio;

                return [
                  nombre,
                  cantidad.toString(),
                  "S/ ${precio.toStringAsFixed(2)}",
                  "S/ ${totalRow.toStringAsFixed(2)}",
                ];
              }).toList(),
            ),

            pw.SizedBox(height: 20),

            // 4. TOTAL FINAL
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  "TOTAL A PAGAR:",
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(width: 20),
                pw.Text(
                  "S/ ${venta.total.toStringAsFixed(2)}",
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green900,
                  ),
                ),
              ],
            ),

            pw.Spacer(), // Empuja lo siguiente al final de la hoja
            // 5. PIE DE PÁGINA
            pw.Center(
              child: pw.Text(
                "Gracias por su compra - Generado por Sistema FASALE",
                style: pw.TextStyle(color: PdfColors.grey),
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
