import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/client_model.dart';
import '../models/product_model.dart';
import '../models/quote_model.dart';
import '../models/user_model.dart'; // Necesitamos saber quién vendió (el usuario logueado)

class NuevaVentaScreen extends StatefulWidget {
  final Usuario usuarioActual; // El vendedor

  const NuevaVentaScreen({Key? key, required this.usuarioActual}) : super(key: key);

  @override
  _NuevaVentaScreenState createState() => _NuevaVentaScreenState();
}

class _NuevaVentaScreenState extends State<NuevaVentaScreen> {
  // ESTADO DE LA VENTA
  Cliente? _clienteSeleccionado;
  List<Map<String, dynamic>> _carrito = []; // Aquí guardamos: { 'producto': Producto, 'cantidad': 2 }
  double _total = 0.0;

  // Listas para los selectores
  List<Cliente> _listaClientes = [];
  List<Producto> _listaProductos = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  void _cargarDatos() async {
    final clientes = await DatabaseHelper.instance.obtenerClientes();
    final productos = await DatabaseHelper.instance.obtenerProductos();
    setState(() {
      _listaClientes = clientes;
      _listaProductos = productos;
    });
  }

  // --- LÓGICA DEL CARRITO ---

  void _agregarAlCarrito(Producto producto) {
    // 1. Revisar si ya está en el carrito
    int index = _carrito.indexWhere((item) => item['producto'].id == producto.id);

    if (index != -1) {
      // Si ya está, solo sumamos 1 a la cantidad
      // VALIDAR STOCK: No vender más de lo que hay
      if (_carrito[index]['cantidad'] < producto.stock) {
        setState(() {
          _carrito[index]['cantidad']++;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("¡No hay más stock!")));
      }
    } else {
      // Si no está, lo agregamos nuevo
      if (producto.stock > 0) {
        setState(() {
          _carrito.add({'producto': producto, 'cantidad': 1});
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Producto agotado")));
      }
    }
    _calcularTotal();
  }

  void _quitarDelCarrito(int index) {
    setState(() {
      if (_carrito[index]['cantidad'] > 1) {
        _carrito[index]['cantidad']--;
      } else {
        _carrito.removeAt(index); // Si llega a 0, lo sacamos de la lista
      }
    });
    _calcularTotal();
  }

  void _calcularTotal() {
    double tempTotal = 0;
    for (var item in _carrito) {
      Producto p = item['producto'];
      int cant = item['cantidad'];
      tempTotal += (p.precio * cant);
    }
    setState(() {
      _total = tempTotal;
    });
  }

  // --- GUARDAR EN BASE DE DATOS ---
  void _finalizarVenta() async {
    if (_clienteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Selecciona un cliente")));
      return;
    }
    if (_carrito.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("El carrito está vacío")));
      return;
    }

    // 1. Preparar la lista simple para guardar en JSON
    // Solo guardamos ID, Nombre (por si lo borran luego) y Precio (al momento de venta)
    List<Map<String, dynamic>> productosParaGuardar = _carrito.map((item) {
      Producto p = item['producto'];
      return {
        'id': p.id,
        'nombre': p.nombre,
        'cantidad': item['cantidad'],
        'precio_unitario': p.precio,
      };
    }).toList();

    // 2. Crear el objeto Cotizacion
    Cotizacion nuevaVenta = Cotizacion(
      clienteId: _clienteSeleccionado!.id!,
      vendedorId: widget.usuarioActual.id!, // El usuario que entró al login
      fecha: DateTime.now(),
      total: _total,
      productos: productosParaGuardar, // Esto se convierte a JSON solo
    );

    // 3. Guardar en DB
    await DatabaseHelper.instance.crearVenta(nuevaVenta);

    // 4. Éxito
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("¡Venta Registrada!")));
    Navigator.pop(context); // Volver al menú
  }

  // --- PANTALLA ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Nueva Venta")),
      body: Column(
        children: [
          // 1. SELECCIONAR CLIENTE
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<Cliente>(
              decoration: InputDecoration(
                labelText: "Cliente",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              items: _listaClientes.map((cliente) {
                return DropdownMenuItem(
                  value: cliente,
                  child: Text(cliente.nombre),
                );
              }).toList(),
              onChanged: (val) {
                setState(() => _clienteSeleccionado = val);
              },
            ),
          ),

          // 2. BUSCADOR DE PRODUCTOS (Botón que abre un menú)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[100],
                foregroundColor: Colors.blue[900],
                minimumSize: Size(double.infinity, 50)
              ),
              icon: Icon(Icons.search),
              label: Text("AGREGAR PRODUCTOS AL CARRITO"),
              onPressed: () {
                _mostrarSelectorProductos(context);
              },
            ),
          ),

          Divider(thickness: 2),

          // 3. LISTA DEL CARRITO (Lo que vamos comprando)
          Expanded(
            child: _carrito.isEmpty 
              ? Center(child: Text("Carrito vacío", style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: _carrito.length,
                  itemBuilder: (context, index) {
                    final item = _carrito[index];
                    final Producto p = item['producto'];
                    final int cantidad = item['cantidad'];
                    
                    return ListTile(
                      title: Text(p.nombre, style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("S/ ${p.precio} x $cantidad = S/ ${p.precio * cantidad}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () => _quitarDelCarrito(index),
                          ),
                          Text("$cantidad", style: TextStyle(fontSize: 18)),
                          IconButton(
                            icon: Icon(Icons.add_circle, color: Colors.green),
                            onPressed: () => _agregarAlCarrito(p),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          ),

          // 4. BARRA DE TOTAL Y PAGAR
          Container(
            padding: EdgeInsets.all(20),
            color: Colors.green[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Total: S/ $_total", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15)
                  ),
                  onPressed: _finalizarVenta,
                  child: Text("VENDER", style: TextStyle(fontSize: 18)),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  // FUNCION AUXILIAR: Muestra una lista de productos en una ventana flotante
  void _mostrarSelectorProductos(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.all(10),
          height: 400,
          child: Column(
            children: [
              Text("Toca un producto para agregar", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: _listaProductos.length,
                  itemBuilder: (ctx, i) {
                    final prod = _listaProductos[i];
                    return ListTile(
                      leading: Icon(Icons.inventory_2),
                      title: Text(prod.nombre),
                      subtitle: Text("Stock: ${prod.stock} | S/ ${prod.precio}"),
                      onTap: () {
                        _agregarAlCarrito(prod);
                        Navigator.pop(ctx); // Cierra la ventanita al seleccionar
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}