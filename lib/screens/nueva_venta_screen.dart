import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/client_model.dart';
import '../models/product_model.dart';
import '../models/quote_model.dart';
import '../models/user_model.dart';

class NuevaVentaScreen extends StatefulWidget {
  final Usuario usuarioActual;

  const NuevaVentaScreen({Key? key, required this.usuarioActual})
    : super(key: key);

  @override
  _NuevaVentaScreenState createState() => _NuevaVentaScreenState();
}

class _NuevaVentaScreenState extends State<NuevaVentaScreen> {
  Cliente? _clienteSeleccionado;
  List<Map<String, dynamic>> _carrito = [];
  double _total = 0.0;

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

  void _agregarAlCarrito(Producto producto) {
    int index = _carrito.indexWhere(
      (item) => item['producto'].id == producto.id,
    );

    if (index != -1) {
      if (_carrito[index]['cantidad'] < producto.stock) {
        setState(() {
          _carrito[index]['cantidad']++;
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("¡No hay más stock!")));
      }
    } else {
      if (producto.stock > 0) {
        setState(() {
          _carrito.add({'producto': producto, 'cantidad': 1});
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Producto agotado")));
      }
    }
    _calcularTotal();
  }

  void _quitarDelCarrito(int index) {
    setState(() {
      if (_carrito[index]['cantidad'] > 1) {
        _carrito[index]['cantidad']--;
      } else {
        _carrito.removeAt(index);
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

  void _finalizarVenta() async {
    if (_clienteSeleccionado == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Selecciona un cliente")));
      return;
    }
    if (_carrito.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("El carrito está vacío")));
      return;
    }

    List<Map<String, dynamic>> productosParaGuardar = _carrito.map((item) {
      Producto p = item['producto'];
      return {
        'id': p.id,
        'nombre': p.nombre,
        'cantidad': item['cantidad'],
        'precio_unitario': p.precio,
      };
    }).toList();

    Cotizacion nuevaVenta = Cotizacion(
      clienteId: _clienteSeleccionado!.id!,
      vendedorId: widget.usuarioActual.id!,
      fecha: DateTime.now(),
      total: _total,
      productos: productosParaGuardar,
    );

    await DatabaseHelper.instance.crearVenta(nuevaVenta);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("¡Venta Registrada!")));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Nueva Venta")),
      body: Column(
        children: [
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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[100],
                foregroundColor: Colors.blue[900],
                minimumSize: Size(double.infinity, 50),
              ),
              icon: Icon(Icons.search),
              label: Text("AGREGAR PRODUCTOS AL CARRITO"),
              onPressed: () {
                _mostrarSelectorProductos(context);
              },
            ),
          ),

          Divider(thickness: 2),

          Expanded(
            child: _carrito.isEmpty
                ? Center(
                    child: Text(
                      "Carrito vacío",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _carrito.length,
                    itemBuilder: (context, index) {
                      final item = _carrito[index];
                      final Producto p = item['producto'];
                      final int cantidad = item['cantidad'];

                      return ListTile(
                        title: Text(
                          p.nombre,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "S/ ${p.precio} x $cantidad = S/ ${p.precio * cantidad}",
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.remove_circle,
                                color: Colors.red,
                              ),
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

          Container(
            padding: EdgeInsets.all(20),
            color: Colors.green[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total: S/ $_total",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  onPressed: _finalizarVenta,
                  child: Text("VENDER", style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarSelectorProductos(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.all(10),
          height: 400,
          child: Column(
            children: [
              Text(
                "Toca un producto para agregar",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: _listaProductos.length,
                  itemBuilder: (ctx, i) {
                    final prod = _listaProductos[i];
                    return ListTile(
                      leading: Icon(Icons.inventory_2),
                      title: Text(prod.nombre),
                      subtitle: Text(
                        "Stock: ${prod.stock} | S/ ${prod.precio}",
                      ),
                      onTap: () {
                        _agregarAlCarrito(prod);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
