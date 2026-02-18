import 'dart:io';
import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/client_model.dart';
import '../models/product_model.dart';
import '../models/quote_model.dart';
import '../models/user_model.dart';

class NuevaVentaScreen extends StatefulWidget {
  final Usuario usuarioActual;
  final Cotizacion? cotizacionAEditar;

  const NuevaVentaScreen({
    Key? key,
    required this.usuarioActual,
    this.cotizacionAEditar,
  }) : super(key: key);

  @override
  _NuevaVentaScreenState createState() => _NuevaVentaScreenState();
}

class _NuevaVentaScreenState extends State<NuevaVentaScreen> {
  Cliente? _clienteSeleccionado;
  List<Map<String, dynamic>> _carrito = [];
  double _total = 0.0;
  List<Cliente> _listaClientes = [];
  List<Producto> _listaProductos = [];
  bool _estaCargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  void _cargarDatos() async {
    bool esAdmin = widget.usuarioActual.rol == 'admin';
    final clientes = await DatabaseHelper.instance.obtenerClientes(
      verTodo: esAdmin,
      usuarioIdEspecifico: esAdmin ? null : widget.cotizacionAEditar?.usuarioId,
    );
    final productos = await DatabaseHelper.instance.obtenerProductos();

    setState(() {
      _listaClientes = clientes;
      _listaProductos = productos;
    });

    if (widget.cotizacionAEditar != null) {
      _prepararEdicion(clientes, productos);
    }
    setState(() => _estaCargando = false);
  }

  void _prepararEdicion(List<Cliente> clientes, List<Producto> productos) {
    try {
      _clienteSeleccionado = clientes.firstWhere(
        (c) => c.id == widget.cotizacionAEditar!.clienteId,
      );
    } catch (e) {
      _clienteSeleccionado = null;
    }

    for (var item in widget.cotizacionAEditar!.productos) {
      try {
        Producto p = productos.firstWhere((prod) => prod.id == item['id']);
        _carrito.add({'producto': p, 'cantidad': item['cantidad']});
      } catch (e) {
        Producto pTemporal = Producto(
          id: item['id'],
          nombre: item['nombre'],
          descripcion: "Producto de cotización antigua",
          categoriaId: 0,
          precio: (item['precio_unitario'] as num).toDouble(),
          stock: 999,
          nombreCategoria: "Desconocida",
        );
        _carrito.add({'producto': pTemporal, 'cantidad': item['cantidad']});
      }
    }
    _calcularTotal();
  }

  void _agregarAlCarrito(Producto producto) {
    int index = _carrito.indexWhere(
      (item) => item['producto'].id == producto.id,
    );
    setState(() {
      if (index != -1) {
        _carrito[index]['cantidad']++;
      } else {
        _carrito.add({'producto': producto, 'cantidad': 1});
      }
    });
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
      tempTotal += (item['producto'].precio * item['cantidad']);
    }
    setState(() => _total = tempTotal);
  }

  // --- IDEA #6: DIÁLOGO DE ÉXITO ANIMADO ---
  void _mostrarExito() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        Future.delayed(const Duration(milliseconds: 1600), () {
          Navigator.pop(ctx);
          Navigator.pop(context, true);
        });
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
              SizedBox(height: 20),
              Text(
                "¡Cotización Guardada!",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }

  void _finalizarVenta() async {
    if (_clienteSeleccionado == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Selecciona un cliente")));
      return;
    }
    if (_carrito.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("El carrito está vacío")));
      return;
    }

    List<Map<String, dynamic>> productosParaGuardar = _carrito.map((item) {
      return {
        'id': item['producto'].id,
        'nombre': item['producto'].nombre,
        'cantidad': item['cantidad'],
        'precio_unitario': item['producto'].precio,
      };
    }).toList();

    Cotizacion cotiFinal = Cotizacion(
      id: widget.cotizacionAEditar?.id,
      clienteId: _clienteSeleccionado!.id!,
      usuarioId:
          widget.cotizacionAEditar?.usuarioId ?? widget.usuarioActual.id!,
      fecha: widget.cotizacionAEditar?.fecha ?? DateTime.now().toString(),
      total: _total,
      estado: widget.cotizacionAEditar?.estado ?? 'Pendiente',
      productos: productosParaGuardar,
    );

    if (widget.cotizacionAEditar == null) {
      await DatabaseHelper.instance.crearVenta(cotiFinal);
    } else {
      await DatabaseHelper.instance.actualizarCotizacion(cotiFinal);
    }

    _mostrarExito(); // Llamamos al diálogo animado
  }

  @override
  Widget build(BuildContext context) {
    bool esModoEdicion = widget.cotizacionAEditar != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(esModoEdicion ? "Editar Cotización" : "Nueva Cotización"),
        backgroundColor: esModoEdicion
            ? Colors.orange[800]
            : Colors.indigo[900],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _estaCargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // DROPDOWN CLIENTES
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: DropdownButtonFormField<Cliente>(
                    decoration: InputDecoration(
                      labelText: "Cliente",
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.person),
                    ),
                    value: _clienteSeleccionado,
                    items: _listaClientes.map((cliente) {
                      return DropdownMenuItem(
                        value: cliente,
                        child: Text(cliente.nombre),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => _clienteSeleccionado = val),
                  ),
                ),

                const SizedBox(height: 10),

                // BOTÓN AGREGAR PRODUCTOS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text(
                      "AGREGAR PRODUCTOS",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _mostrarSelectorProductos(context),
                  ),
                ),

                const Divider(
                  height: 30,
                  thickness: 1,
                  indent: 20,
                  endIndent: 20,
                ),

                // LISTADO DEL CARRITO (IDEA #5: TARJETAS)
                Expanded(
                  child: _carrito.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.shopping_cart_outlined,
                                size: 80,
                                color: Colors.grey,
                              ),
                              Text(
                                "El carrito está vacío",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _carrito.length,
                          itemBuilder: (context, index) {
                            final item = _carrito[index];
                            final Producto p = item['producto'];
                            final int cantidad = item['cantidad'];

                            return Card(
                              elevation: 3,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(10),
                                leading: Hero(
                                  tag: 'p_${p.id}', // <--- HERO DESTINO
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child:
                                        (p.urlImagen != null &&
                                            p.urlImagen != "")
                                        ? Image.file(
                                            File(p.urlImagen!),
                                            width: 55,
                                            height: 55,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            color: Colors.grey[200],
                                            width: 55,
                                            height: 55,
                                            child: const Icon(
                                              Icons.inventory_2,
                                            ),
                                          ),
                                  ),
                                ),
                                title: Text(
                                  p.nombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text("S/ ${p.precio} c/u"),
                                trailing: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    // Un color de fondo muy suave para todo el grupo (opcional)
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white.withOpacity(0.05)
                                        : Colors.grey[100],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove,
                                          color: Colors.red,
                                        ),
                                        onPressed: () =>
                                            _quitarDelCarrito(index),
                                      ),

                                      // --- ESTE ES TU INDICADOR DE CANTIDAD FLOTANTE ---
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(
                                            context,
                                          ).cardColor, // Fondo del tema (blanco o gris oscuro)
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Theme.of(
                                              context,
                                            ).primaryColor.withOpacity(0.5),
                                            width: 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.1,
                                              ),
                                              blurRadius: 4,
                                              offset: const Offset(
                                                0,
                                                2,
                                              ), // Sombra hacia abajo para el "relieve"
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          "$cantidad",
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),

                                      // -----------------------------------------------
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add,
                                          color: Colors.green,
                                        ),
                                        onPressed: () => _agregarAlCarrito(p),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // PANEL DE TOTAL (IDEA #9: GRADIENTE)
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.indigo[900]!, Colors.indigo[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "TOTAL:",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "S/ ${_total.toStringAsFixed(2)}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.indigo[900],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 5,
                        ),
                        onPressed: _finalizarVenta,
                        child: Text(
                          esModoEdicion ? "GUARDAR" : "COTIZAR",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // SELECTOR DE PRODUCTOS (IDEA #2: HERO ORIGEN)
  void _mostrarSelectorProductos(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Selecciona Productos",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: ListView.builder(
                  itemCount: _listaProductos.length,
                  itemBuilder: (ctx, i) {
                    final prod = _listaProductos[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: Hero(
                          tag: 'p_${prod.id}', // <--- HERO ORIGEN
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child:
                                (prod.urlImagen != null && prod.urlImagen != "")
                                ? (prod.urlImagen!.startsWith('http')
                                      ? Image.network(
                                          prod.urlImagen!,
                                          width: 45,
                                          height: 45,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.file(
                                          File(prod.urlImagen!),
                                          width: 45,
                                          height: 45,
                                          fit: BoxFit.cover,
                                        ))
                                : const Icon(Icons.inventory_2),
                          ),
                        ),
                        title: Text(
                          prod.nombre,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Stock: ${prod.stock} • S/ ${prod.precio}",
                        ),
                        onTap: () {
                          _agregarAlCarrito(prod);
                          Navigator.pop(ctx);
                        },
                      ),
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
