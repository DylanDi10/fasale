import 'dart:io';
import 'package:cotizaciones_app/db/supabase_service.dart';
import 'package:cotizaciones_app/models/client_model.dart';
import 'package:cotizaciones_app/utils/pdf_generator.dart';
import 'package:cotizaciones_app/widgets/empty_state.dart';
import 'package:flutter/material.dart';
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
  bool esAdmin = true;
  DateTime? _fechaFiltro; // Si es null, mostramos todas
  double _totalGanancias = 0.0;

  List<Cotizacion> _ventasOriginales = []; // Guarda TODO lo que llega de la BD
  List<Cotizacion> _listaVentas = []; // Lo que se muestra en pantalla
  bool _verSoloAprobadas = false;

  Map<int, String> _nombresClientes = {};

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  void _cargarDatos() async {
    final db = SupabaseService.instance;
    List<Cotizacion> ventas;

    // 1. BLINDAJE: Verificamos si hay un filtro de fecha activo
    if (_fechaFiltro != null) {
      // Si hay fecha, solo recargamos las de ese día específico
      ventas = await db.obtenerVentasPorDia(
        _fechaFiltro!,
        usuarioId: widget.usuarioIdExterno,
      );
    } else {
      // Si no hay fecha, traemos todo el historial normal
      ventas = await db.obtenerVentas(
        usuarioIdEspecifico: widget.usuarioIdExterno,
      );
    }

    final clientes = await db.obtenerClientes(
      verTodo: widget.usuarioIdExterno != null || widget.usuarioLogueado.rol == 'admin',
    );

    Map<int, String> mapaNombres = {};
    for (var c in clientes) {
      if (c.id != null) mapaNombres[c.id!] = c.nombre;
    }

    if (mounted) {
      setState(() {
        _nombresClientes = mapaNombres;
        _ventasOriginales = ventas; // Guardamos la data pura
      });
      _aplicarFiltrosLocales(); // Aplicamos los cálculos y el filtro de "Solo Aprobadas"
    }
  }

  // --- NUEVA FUNCIÓN MÁGICA DE FILTRADO ---
  void _aplicarFiltrosLocales() {
    List<Cotizacion> filtradas = _ventasOriginales;

    // Si el botón está activo, filtramos solo las ventas reales
    if (_verSoloAprobadas) {
      filtradas = filtradas
          .where((v) => v.estado.toLowerCase().startsWith('aprobad'))
          .toList();
    }

    // Recalculamos el dinero según lo que estemos viendo en pantalla
    double total = filtradas.fold(0.0, (sum, item) => sum + item.total);

    setState(() {
      _listaVentas = filtradas;
      _totalGanancias = total;
    });
  }

  // --- FUNCIÓN PARA FORMATEAR FECHAS ---
  String _obtenerTextoFecha(String fechaString) {
    try {
      // Cortamos solo la parte de la fecha (por si tiene hora)
      String soloFecha = fechaString.split(' ')[0];
      DateTime fecha = DateTime.parse(soloFecha);
      DateTime hoy = DateTime.now();
      DateTime ayer = hoy.subtract(const Duration(days: 1));

      // Comparamos los días
      if (fecha.year == hoy.year &&
          fecha.month == hoy.month &&
          fecha.day == hoy.day) {
        return "HOY";
      } else if (fecha.year == ayer.year &&
          fecha.month == ayer.month &&
          fecha.day == ayer.day) {
        return "AYER";
      } else {
        // Formato clásico: DD/MM/YYYY
        return "${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}";
      }
    } catch (e) {
      return fechaString.split(
        ' ',
      )[0]; // Fallback por si la fecha tiene otro formato
    }
  }

  @override
  Widget build(BuildContext context) {
    bool esModoAdmin = widget.usuarioIdExterno != null;
    String titulo = esModoAdmin
        ? "Cotizaciones de: ${widget.nombreVendedorExterno}"
        : "Mis Cotizaciones";
    Color colorTema = esModoAdmin ? Colors.orange : Colors.indigo;

    // --- 1. NUEVOS CÁLCULOS ESTADÍSTICOS ---
    int totalCotizaciones = _ventasOriginales.length;
    
    // Separamos las aprobadas para calcular el ticket promedio real
    Iterable<Cotizacion> ventasAprobadas = _ventasOriginales.where((v) => v.estado.toLowerCase().startsWith('aprobad'));
    int aprobadas = ventasAprobadas.length;
    
    double efectividad = totalCotizaciones > 0 ? (aprobadas / totalCotizaciones) * 100 : 0.0;
    
    // Dinero total real (solo aprobadas) dividido entre la cantidad de ventas cerradas
    double dineroTotalAprobado = ventasAprobadas.fold(0.0, (sum, item) => sum + item.total);
    double ticketPromedio = aprobadas > 0 ? (dineroTotalAprobado / aprobadas) : 0.0;

    // --- 2. REGLA DE VISIBILIDAD ---
    // Si el usuario es admin Y NO está viendo a un vendedor externo, ocultamos las estadísticas
    bool ocultarEstadisticas = widget.usuarioLogueado.rol == 'admin' && widget.usuarioIdExterno == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(titulo), // Usamos la variable título que ya tenías
        actions: [
          if (_fechaFiltro != null)
            IconButton(
              icon: Icon(Icons.clear),
              onPressed: () {
                setState(() => _fechaFiltro = null);
                _cargarDatos(); 
              },
            ),
          IconButton(
            icon: Icon(Icons.calendar_month),
            onPressed: () async {
              DateTime? fechaElegida = await showDatePicker(
                context: context,
                initialDate: _fechaFiltro ?? DateTime.now(),
                firstDate: DateTime(2024), 
                lastDate: DateTime.now(),  
              );

              // --- 🛡️ ESCUDO 1 ---
              // Si el usuario cerró la pantalla mientras el calendario estaba abierto
              if (!mounted) return;

              if (fechaElegida != null) {
                setState(() => _fechaFiltro = fechaElegida);
                
                final filtradasBD = await SupabaseService.instance.obtenerVentasPorDia(
                  fechaElegida,
                  usuarioId: widget.usuarioIdExterno, 
                );
                
                // --- 🛡️ ESCUDO 2 ---
                // Si el usuario salió de la pantalla mientras Supabase buscaba las ventas
                if (!mounted) return;

                setState(() {
                  _ventasOriginales = filtradasBD; 
                });
                _aplicarFiltrosLocales(); 
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // --- TARJETA PRINCIPAL (PANEL DE MANDO) ---
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
                  esModoAdmin ? "COTIZACIONES DEL USUARIO" : "POSIBLES INGRESOS",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    letterSpacing: 1.2,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  "USD ${_totalGanancias.toStringAsFixed(2)}",
                  style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 3),
                Text(
                  "${_listaVentas.length} items mostrados",
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                ),
                
                // --- INDICADORES ESTADÍSTICOS (SOLO PARA VENDEDORES) ---
                if (!ocultarEstadisticas) ...[
                  SizedBox(height: 15),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      // 1er Indicador: Efectividad
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bolt, color: Colors.yellowAccent, size: 18), 
                            SizedBox(width: 5),
                            Text(
                              "Efectividad: ${efectividad.toStringAsFixed(1)}%",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      
                      // 2do Indicador: Ticket Promedio
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.attach_money, color: Colors.greenAccent, size: 18), 
                            SizedBox(width: 2),
                            Text(
                              "Ticket Prom.: \$${ticketPromedio.toStringAsFixed(2)}",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ], // Fin del bloque de estadísticas
              ],
            ),
          ),

          // --- NUEVO BOTÓN DE FILTRADO RÁPIDO ---
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 0.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Filtrar vista:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                FilterChip(
                  label: Text("Solo Ventas (Aprobadas)"),
                  selected: _verSoloAprobadas,
                  selectedColor: Colors.green[100],
                  checkmarkColor: Colors.green[700],
                  labelStyle: TextStyle(
                    // LÓGICA DE COLOR DINÁMICO
                    color: _verSoloAprobadas 
                        ? Colors.green[900] 
                        : (Theme.of(context).brightness == Brightness.dark 
                            ? Colors.white 
                            : Colors.black87), 
                    fontWeight: _verSoloAprobadas ? FontWeight.bold : FontWeight.normal
                  ),
                  onSelected: (val) {
                    setState(() => _verSoloAprobadas = val);
                    _aplicarFiltrosLocales();
                  },
                )
              ],
            ),
          ),

          Divider(
            thickness: 1,
            indent: 20,
            endIndent: 20,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white10
                : Colors.grey[300],
          ),
          Expanded(
            child: _listaVentas.isEmpty
                ? EmptyState(
                    mensaje: "Aún no tienes cotizaciones.\n¡Empieza una ahora!",
                    icono: Icons.insert_drive_file_outlined,
                  )
                : ListView.builder(
                    itemCount: _listaVentas.length,
                    itemBuilder: (context, index) {
                      final venta = _listaVentas[index];
                      String nombreCliente =
                          _nombresClientes[venta.clienteId] ?? "Desconocido";

                      Color colorEstado =
                          (venta.estado.toLowerCase() == "aprobada" ||
                              venta.estado.toLowerCase() == "aprobado")
                          ? Colors.green
                          : (venta.estado.toLowerCase() == "rechazada" ||
                                venta.estado.toLowerCase() == "rechazado")
                          ? Colors.red
                          : Colors.orange;

                      // --- LÓGICA PARA LOS SEPARADORES DE FECHA ---
                      final String fechaActual = venta.fecha.split(' ')[0];
                      bool mostrarSeparador = false;

                      // Si es el primer elemento, siempre mostramos separador
                      if (index == 0) {
                        mostrarSeparador = true;
                      } else {
                        // Comparamos con el elemento anterior
                        final String fechaAnterior = _listaVentas[index - 1]
                            .fecha
                            .split(' ')[0];
                        if (fechaActual != fechaAnterior) {
                          mostrarSeparador =
                              true; // Cambió el día, mostramos separador
                        }
                      }

                      // Este es el Card original que ya tenías
                      Widget tarjetaVenta = Card(
                        margin: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        elevation: 0,
                        color: Theme.of(
                          context,
                        ).cardColor, // Respeta el modo oscuro
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(15),
                          leading: CircleAvatar(
                            backgroundColor: colorEstado.withOpacity(0.1),
                            child: Icon(Icons.description, color: colorEstado),
                          ),
                          title: Text(
                            nombreCliente,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "ID: #${venta.id} • ${venta.fecha.split(' ')[0]}",
                              ),
                              SizedBox(height: 5),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colorEstado.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  venta.estado,
                                  style: TextStyle(
                                    color: colorEstado,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "USD ${venta.total.toStringAsFixed(2)}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors
                                      .blue[700], // Azul a juego con tu UI
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                size: 18,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                          onTap: () => _mostrarDetalleVenta(context, venta),
                        ),
                      );

                      // Si debe mostrar separador, envolvemos la tarjeta en una columna
                      if (mostrarSeparador) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 24,
                                top: 20,
                                bottom: 5,
                              ),
                              child: Text(
                                _obtenerTextoFecha(fechaActual),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            tarjetaVenta,
                          ],
                        );
                      } else {
                        // Si es del mismo día que el anterior, solo devolvemos la tarjeta normal
                        return tarjetaVenta;
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // --- NUEVA FUNCIÓN DE WHATSAPP ---
  Future<void> _enviarWhatsAppSinGuardar(
    String numeroTelefono,
    String urlPdf,
  ) async {
    String numeroLimpio = numeroTelefono.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeroLimpio.length == 9) {
      numeroLimpio = '51$numeroLimpio';
    }

    // Si generas el PDF localmente, en vez de urlPdf enviamos un saludo
    final String mensaje =
        "Hola, le escribo de FASALE. Aquí tengo la cotización que solicitó.";
    final Uri url = Uri.parse(
      "https://wa.me/$numeroLimpio?text=${Uri.encodeComponent(mensaje)}",
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      print("No se pudo abrir WhatsApp");
    }
  }

  void _mostrarDialogoWhatsApp(BuildContext context, Cotizacion venta) async {
    TextEditingController _numeroController = TextEditingController();

    // Intentamos buscar el teléfono del cliente si ya existe en la BD
    Cliente? cliente = await SupabaseService.instance.obtenerClientePorId(
      venta.clienteId,
    );
    if (cliente != null && cliente.telefono != null) {
      _numeroController.text = cliente.telefono!;
    }

    showDialog(
      context: context,
      builder: (ctxDialog) => AlertDialog(
        title: const Text(
          "Enviar a WhatsApp",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: _numeroController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: "Ej: 999888777",
            labelText: "Número del cliente",
            prefixIcon: Icon(Icons.phone_android),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctxDialog),
            child: const Text("CANCELAR"),
          ),
          ElevatedButton(
            onPressed: () async {
              String numero = _numeroController.text;
              if (numero.isNotEmpty) {
                Navigator.pop(ctxDialog); // Cerramos el dialogo
                Navigator.pop(context); // Cerramos el modal de detalle

                // 1. Abrimos el chat de WhatsApp con el saludo
                await _enviarWhatsAppSinGuardar(numero, "");

                // 2. Un segundo después, disparamos tu función actual que abre el PDF
                // para que el vendedor solo le dé a "Compartir" hacia el chat que acaba de abrir.
                await Future.delayed(const Duration(seconds: 1));
                if (cliente != null) {
                  await PdfGenerator.generarYCompartirPDF(venta, cliente);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("ABRIR CHAT Y ENVIAR"),
          ),
        ],
      ),
    );
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
              // --- CABECERA ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Detalle #${venta.id}",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Divider(),

              // --- LISTA DE PRODUCTOS ---
              Expanded(
                child: ListView.builder(
                  itemCount: venta.productos.length,
                  itemBuilder: (ctx, i) {
                    final item = venta.productos[i];
                    return ListTile(
                      leading: Hero(
                        tag:
                            'p_${item['id']}_report_${venta.id}', // Tag único para evitar conflictos
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            // LÓGICA HÍBRIDA:
                            child:
                                (item['imagen'] != null &&
                                    item['imagen'].toString().isNotEmpty)
                                ? (item['imagen'].toString().startsWith('http')
                                      ? Image.network(
                                          item['imagen'],
                                          fit: BoxFit.cover,
                                          errorBuilder: (ctx, err, stack) =>
                                              Container(
                                                color: Colors.grey[300],
                                                child: Icon(
                                                  Icons.broken_image,
                                                  size: 20,
                                                ),
                                              ),
                                        )
                                      : Image.file(
                                          File(item['imagen']),
                                          fit: BoxFit.cover,
                                          errorBuilder: (ctx, err, stack) =>
                                              Container(
                                                color: Colors.grey[300],
                                                child: Icon(
                                                  Icons.folder_off,
                                                  size: 20,
                                                ),
                                              ),
                                        ))
                                : Container(
                                    color: Colors.indigo.withOpacity(0.1),
                                    child: Icon(
                                      Icons.shopping_bag_outlined,
                                      color: Colors.indigo,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      title: Text(item['nombre'] ?? 'Producto'),
                      subtitle: Text("Cantidad: ${item['cantidad']}"),
                      trailing: Text("USD ${item['precio_unitario']}"),
                    );
                  },
                ),
              ),
              Divider(),

              // --- TOTAL Y ESTADO ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "TOTAL:",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "USD ${venta.total}",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _botonEstado(ctx, venta, "Pendiente", Colors.orange),
                  _botonEstado(ctx, venta, "Aprobado", Colors.green),
                  _botonEstado(ctx, venta, "Rechazado", Colors.red),
                ],
              ),
              Divider(),

              // --- BOTONES DE ACCIÓN ---

              // 1. BOTÓN EDITAR (Igual que antes)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50),
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

              // 2. BOTÓN COMPARTIR PDF (NUEVO Y MEJORADO) ⚡
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.green[700], // Verde tipo WhatsApp/Share
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50),
                  ),
                  icon: Icon(
                    Icons.share_rounded,
                  ), // Icono universal de compartir
                  label: Text("COMPARTIR COTIZACIÓN (PDF)"),
                  onPressed: () async {
                    // Feedback visual: "Espere un momento"
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Generando PDF... por favor espere'),
                      ),
                    );

                    // 1. Buscamos al cliente en la BD para tener su nombre
                    // Buscamos al cliente directo en la nube
                    Cliente? cliente = await SupabaseService.instance
                        .obtenerClientePorId(venta.clienteId);

                    if (cliente != null) {
                      Navigator.pop(ctx); // Cerramos el modal

                      // LLAMAMOS A LA FUNCIÓN GENERAR Y COMPARTIR
                      await PdfGenerator.generarYCompartirPDF(venta, cliente);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Error: No se encontró al cliente asociado",
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
              SizedBox(height: 10), // Espacio final
              // 3. BOTÓN ENVIAR POR WHATSAPP DIRECTO ⚡
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.green[600], // Verde característico de WhatsApp
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50),
                  ),
                  // Usamos un icono representativo
                  icon: Icon(Icons.chat_outlined),
                  label: Text("ENVIAR POR WHATSAPP (SIN GUARDAR)"),
                  onPressed: () {
                    // Llama al cuadro de diálogo que armamos
                    _mostrarDialogoWhatsApp(context, venta);
                  },
                ),
              ),
              SizedBox(height: 10), // Espacio final
            ],
          ),
        );
      },
    );
  }

  Widget _botonEstado(
    BuildContext ctx,
    Cotizacion venta,
    String nuevoEstado,
    Color color,
  ) {
    // Blindaje: Comparamos todo en minúsculas y solo las primeras 7 letras
    // ("Aprobad") para ignorar si termina en A o en O.
    bool esEstadoActual = venta.estado.toLowerCase().startsWith(
      nuevoEstado.toLowerCase().substring(0, 7),
    );

    return InkWell(
      // Si ya está en ese estado, onTap es NULL y el botón queda desactivado
      onTap: esEstadoActual
          ? null
          : () async {
              // --- LÓGICA DE STOCK AQUÍ ---
              if (nuevoEstado.startsWith('Aprobad') &&
                  !venta.estado.toLowerCase().startsWith('aprobad')) {
                // Descuenta stock y cambia estado
                // Asegúrate de tener la variable esAdmin disponible en esa pantalla también
                // Llamamos a la función a través de la instancia de tu servicio
                await SupabaseService.instance.aprobarCotizacionYDescontarStock(
                  venta,
                  esAdmin: esAdmin,
                );
              } else {
                // Solo actualiza texto
                Cotizacion ventaActualizada = Cotizacion(
                  id: venta.id,
                  clienteId: venta.clienteId,
                  usuarioId: venta.usuarioId,
                  fecha: venta.fecha,
                  total: venta.total,
                  productos: venta.productos,
                  estado: nuevoEstado,
                );
                await SupabaseService.instance.actualizarCotizacion(
                  ventaActualizada,
                );
              }

              Navigator.pop(ctx);
              _cargarDatos();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Estado cambiado a $nuevoEstado"),
                  backgroundColor: color,
                ),
              );
            },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: esEstadoActual ? color : color.withOpacity(0.1),
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          nuevoEstado,
          style: TextStyle(
            color: esEstadoActual ? Colors.white : color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
