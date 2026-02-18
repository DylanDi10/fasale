import 'package:cotizaciones_app/models/client_model.dart';
import 'package:cotizaciones_app/utils/pdf_generator.dart';
import 'package:cotizaciones_app/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../db/database_helper.dart';
import '../models/quote_model.dart';
import '../models/user_model.dart';
import 'nueva_venta_screen.dart';

class ReportsScreen extends StatefulWidget {
  final Usuario usuarioLogueado;
  final int? usuarioIdExterno;
  final String? nombreVendedorExterno;

  const ReportsScreen({
    Key? key,
    required this.usuarioLogueado,
    this.usuarioIdExterno,
    this.nombreVendedorExterno,
  }) : super(key: key);

  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  double _totalGanancias = 0.0;
  List<Cotizacion> _listaVentas = [];
  Map<int, String> _nombresClientes = {};

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  void _cargarDatos() async {
    final db = DatabaseHelper.instance;
    double total = await db.obtenerTotalVentas(
      usuarioIdEspecifico: widget.usuarioIdExterno,
    );
    List<Cotizacion> ventas = await db.obtenerVentas(
      usuarioIdEspecifico: widget.usuarioIdExterno,
    );
    final clientes = await db.obtenerClientes(
      verTodo: widget.usuarioIdExterno != null || widget.usuarioLogueado.rol == 'admin',
    );

    Map<int, String> mapaNombres = {};
    for (var c in clientes) {
      if (c.id != null) mapaNombres[c.id!] = c.nombre;
    }

    if (mounted) {
      setState(() {
        _totalGanancias = total;
        _listaVentas = ventas;
        _nombresClientes = mapaNombres;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool esModoAdmin = widget.usuarioIdExterno != null;
    String titulo = esModoAdmin
        ? "Cotizaciones de: ${widget.nombreVendedorExterno}"
        : "Mis Cotizaciones";
    Color colorTema = esModoAdmin ? Colors.orange : Colors.purple;

    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        backgroundColor: colorTema,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(25),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: esModoAdmin
                    ? [Colors.orange[700]!, Colors.orange[400]!]
                    : [Colors.indigo[800]!, Colors.indigo[500]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (esModoAdmin ? Colors.orange : Colors.indigo).withOpacity(0.3),
                  blurRadius: 15,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  esModoAdmin ? "COTIZACIONES DE USUARIO" : "POSIBLES INGRESOS",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    letterSpacing: 1.2,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  "S/ ${_totalGanancias.toStringAsFixed(2)}",
                  style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 3),
                Text(
                  "${_listaVentas.length} cotizaciones activas",
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                ),
              ],
            ),
          ),
            Divider(
              thickness: 1, // Más delgado se ve más profesional
              indent: 20,   // Un pequeño margen a los lados lo hace ver "premium"
              endIndent: 20,
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white10  // Un blanco casi transparente para modo oscuro
                  : Colors.grey[300], // Gris suave para modo claro
            ),          Expanded(
            child: _listaVentas.isEmpty
                ? EmptyState(
                    mensaje: "Aún no tienes cotizaciones.\n¡Empieza una ahora!",
                    icono: Icons.insert_drive_file_outlined,
                  )
                : ListView.builder(
                    itemCount: _listaVentas.length,
                    itemBuilder: (context, index) {
                      final venta = _listaVentas[index];
                      String nombreCliente = _nombresClientes[venta.clienteId] ?? "Desconocido";
                      Color colorEstado = venta.estado == "Aprobada"
                          ? Colors.green
                          : venta.estado == "Rechazada"
                              ? Colors.red
                              : Colors.orange;

                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(color: Colors.grey[200]!),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(15),
                          leading: CircleAvatar(
                            backgroundColor: colorEstado.withOpacity(0.1),
                            child: Icon(Icons.description, color: colorEstado),
                          ),
                          title: Text(nombreCliente, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("ID: #${venta.id} • ${venta.fecha.split(' ')[0]}"),
                              SizedBox(height: 5),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorEstado.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  venta.estado,
                                  style: TextStyle(color: colorEstado, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "S/ ${venta.total.toStringAsFixed(2)}",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo[900]),
                              ),
                              Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                            ],
                          ),
                          onTap: () => _mostrarDetalleVenta(context, venta),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _enviarAWhatsApp(Cotizacion venta) async {
    final prefs = await SharedPreferences.getInstance();
    String nombreVendedor = prefs.getString('nombre_vendedor') ?? "Tu Asesor";
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('clientes', where: 'id = ?', whereArgs: [venta.clienteId]);

    if (maps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: Cliente no encontrado")));
      return;
    }

    final cliente = Cliente.fromMap(maps.first);
    String telefono = cliente.telefono ?? "";
    if (telefono.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("El cliente no tiene teléfono")));
      return;
    }

    String mensaje = "Hola *${cliente.nombre}*! , te saluda *$nombreVendedor* 👋\nAquí tienes el detalle de tu cotización #${venta.id}:\n\n";
    for (var item in venta.productos) {
      mensaje += "▪ ${item['nombre']} (x${item['cantidad']}) = S/ ${item['precio_unitario']}\n";
    }
    mensaje += "\n*TOTAL: S/ ${venta.total}*\n\n_Gracias por tu preferencia_ 🤝";

    String telefonoFinal = telefono.replaceAll(RegExp(r'[^0-9]'), '');
    if (telefonoFinal.length == 9) telefonoFinal = "51$telefonoFinal";
    final Uri url = Uri.parse("https://wa.me/$telefonoFinal?text=${Uri.encodeComponent(mensaje)}");

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) throw 'No se pudo lanzar';
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No se pudo abrir WhatsApp: $e")));
    }
  }

  void _mostrarDetalleVenta(BuildContext context, Cotizacion venta) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.all(20),
          height: 650,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Detalle de la Cotización #${venta.id}", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(icon: Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: venta.productos.length,
                  itemBuilder: (ctx, i) {
                    final item = venta.productos[i];
                    return ListTile(
                      // --- AQUÍ ESTÁ EL HERO (PASO FINAL) ---
                      leading: Hero(
                        tag: 'p_${item['id']}', // Tag idéntico al de NuevaVentaScreen
                        child: Icon(Icons.shopping_bag_outlined, color: Colors.indigo),
                      ),
                      title: Text(item['nombre'] ?? 'Producto'),
                      subtitle: Text("Cantidad: ${item['cantidad']}"),
                      trailing: Text("S/ ${item['precio_unitario']}"),
                    );
                  },
                ),
              ),
              Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("TOTAL:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text("S/ ${venta.total}", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
              SizedBox(height: 10),
              Text("Estado Actual: ${venta.estado}", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _botonEstado(ctx, venta, "Pendiente", Colors.orange),
                  _botonEstado(ctx, venta, "Aprobada", Colors.green),
                  _botonEstado(ctx, venta, "Rechazada", Colors.red),
                ],
              ),
              Divider(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50), // Uso de minimumSize para evitar error de height
                  ),
                  icon: Icon(Icons.edit),
                  label: Text("EDITAR PRODUCTOS / CLIENTE"),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NuevaVentaScreen(
                          usuarioActual: widget.usuarioLogueado,
                          cotizacionAEditar: venta,
                        ),
                      ),
                    ).then((value) {
                      if (value == true) _cargarDatos();
                    });
                  },
                ),
              ),
              SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50),
                  ),
                  icon: Icon(Icons.send),
                  label: Text("ENVIAR POR WHATSAPP"),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _enviarAWhatsApp(venta);
                  },
                ),
              ),
              SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50),
                  ),
                  icon: Icon(Icons.picture_as_pdf),
                  label: Text("GENERAR PDF"),
                  onPressed: () async {
                    final db = await DatabaseHelper.instance.database;
                    final maps = await db.query('clientes', where: 'id = ?', whereArgs: [venta.clienteId]);
                    if (maps.isNotEmpty) {
                      Cliente cliente = Cliente.fromMap(maps.first);
                      Navigator.pop(ctx);
                      await PdfGenerator.generarPDF(venta, cliente);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: No se encontró al cliente")));
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _botonEstado(BuildContext ctx, Cotizacion venta, String nuevoEstado, Color color) {
    return InkWell(
      onTap: () async {
        Cotizacion ventaActualizada = Cotizacion(
          id: venta.id,
          clienteId: venta.clienteId,
          usuarioId: venta.usuarioId,
          fecha: venta.fecha,
          total: venta.total,
          productos: venta.productos,
          estado: nuevoEstado,
        );
        await DatabaseHelper.instance.actualizarCotizacion(ventaActualizada);
        Navigator.pop(ctx);
        _cargarDatos();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Estado cambiado a $nuevoEstado"), backgroundColor: color));
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(nuevoEstado, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ),
    );
  }
}