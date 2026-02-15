import 'package:cotizaciones_app/models/client_model.dart';
import 'package:cotizaciones_app/utils/pdf_generator.dart';
import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/quote_model.dart';
// import '../models/client_model.dart'; // Si quisieras mostrar el nombre del cliente, tendrías que hacer un JOIN o buscarlo, por ahora mostraremos ID.

class ReportsScreen extends StatefulWidget {
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  double _totalGanancias = 0.0;
  List<Cotizacion> _listaVentas = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  void _cargarDatos() async {
    // 1. Pedir el total de dinero
    double total = await DatabaseHelper.instance.obtenerTotalVentas();
    // 2. Pedir la lista de ventas
    List<Cotizacion> ventas = await DatabaseHelper.instance.obtenerVentas();

    setState(() {
      _totalGanancias = total;
      _listaVentas = ventas;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Reporte de Ventas"),
        backgroundColor: Colors.purple,
      ),
      body: Column(
        children: [
          // 1. TARJETA DE GANANCIAS TOTALES
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            color: Colors.purple[50],
            child: Column(
              children: [
                Text("Ingresos Totales", style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                SizedBox(height: 10),
                Text(
                  "S/ ${_totalGanancias.toStringAsFixed(2)}", // Muestra 2 decimales
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.purple[800]),
                ),
                Text("Acumulado histórico", style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          
          Divider(thickness: 5, color: Colors.grey[200]),

          // 2. LISTA DE VENTAS RECIENTES
          Expanded(
            child: _listaVentas.isEmpty 
              ? Center(child: Text("Aún no hay ventas registradas."))
              : ListView.builder(
                  itemCount: _listaVentas.length,
                  itemBuilder: (context, index) {
                    final venta = _listaVentas[index];
                    
                    // Formato simple de fecha (puedes usar el paquete intl para mejorarlo)
                    String fechaCorta = venta.fecha.toString().split(' ')[0]; 

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green[100],
                        child: Icon(Icons.attach_money, color: Colors.green),
                      ),
                      title: Text("Venta #${venta.id}"),
                      subtitle: Text("Fecha: $fechaCorta"),
                      trailing: Text(
                        "S/ ${venta.total}",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      onTap: () {
                        // AQUÍ PODRÍAS ABRIR UN DETALLE DE LA VENTA
                        // Mostrar qué productos se vendieron en esa ocasión
                        _mostrarDetalleVenta(context, venta);
                      },
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  // Ventana emergente para ver qué se vendió en esa fecha
  void _mostrarDetalleVenta(BuildContext context, Cotizacion venta) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite que ocupe más pantalla
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.all(20),
          height: 600, // Le damos altura fija
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Detalle de Venta #${venta.id}", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  )
                ],
              ),
              Divider(),
              
              // Lista de productos (igual que antes)
              Expanded(
                child: ListView.builder(
                  itemCount: venta.productos.length,
                  itemBuilder: (ctx, i) {
                    final item = venta.productos[i];
                    return ListTile(
                      leading: Icon(Icons.shopping_bag_outlined),
                      title: Text(item['nombre'] ?? 'Producto'),
                      subtitle: Text("Cantidad: ${item['cantidad']}"),
                      trailing: Text("S/ ${item['precio_unitario']}"),
                    );
                  },
                ),
              ),
              
              Divider(),
              
              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("TOTAL:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text("S/ ${venta.total}", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
              
              SizedBox(height: 20),

              // BOTÓN IMPRIMIR PDF
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700], // Color rojo PDF
                    foregroundColor: Colors.white,
                  ),
                  icon: Icon(Icons.picture_as_pdf),
                  label: Text("GENERAR PDF"),
                  onPressed: () async {
                    // 1. Necesitamos buscar los datos del cliente para ponerlos en el PDF
                    // Hacemos una consulta rápida a la BD
                    final db = await DatabaseHelper.instance.database;
                    final maps = await db.query(
                      'clientes',
                      where: 'id = ?',
                      whereArgs: [venta.clienteId],
                    );
                    
                    if (maps.isNotEmpty) {
                      Cliente cliente = Cliente.fromMap(maps.first);
                      
                      // 2. Llamamos a nuestra utilidad mágica
                      // Cerramos el modal primero para que se vea el PDF limpio
                      Navigator.pop(ctx); 
                      
                      await PdfGenerator.generarPDF(venta, cliente);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: No se encontró al cliente")));
                    }
                  },
                ),
              )
            ],
          ),
        );
      }
    );
  }
}