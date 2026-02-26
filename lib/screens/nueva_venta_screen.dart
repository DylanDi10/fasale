import 'dart:io';
import 'package:cotizaciones_app/db/supabase_service.dart';
import 'package:cotizaciones_app/screens/products_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    
    // --- LAS PAUSAS ASÍNCRONAS ---
    final clientes = await SupabaseService.instance.obtenerClientes(
      verTodo: esAdmin,
      usuarioIdEspecifico: esAdmin ? null : widget.cotizacionAEditar?.usuarioId,
    );
    final productos = await SupabaseService.instance.obtenerProductos();

    // --- 🛡️ EL ESCUDO ---
    // Si el vendedor cerró la pantalla mientras cargaban los datos, abortamos.
    if (!mounted) return;

    // --- ZONA SEGURA ---
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
  // --- NUEVA FUNCIÓN: DIÁLOGO PARA PEDIR CANTIDAD ---
  void _pedirCantidadYAgregarAlCarrito(Producto producto) {
    int cantidadElegida = 1;

    showDialog(
      context: context,
      builder: (ctx) {
        // StatefulBuilder nos permite actualizar el número dentro del diálogo en tiempo real
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text("Agregar al carrito", textAlign: TextAlign.center),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(producto.nombre, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("Stock disponible: ${producto.stock}", style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline, color: Colors.red, size: 35),
                        onPressed: () {
                          if (cantidadElegida > 1) {
                            setStateDialog(() => cantidadElegida--);
                          }
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          "$cantidadElegida", 
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline, color: Colors.green, size: 35),
                        onPressed: () {
                          // Bloqueamos para que no pueda pedir más del stock que existe
                          if (cantidadElegida < producto.stock) {
                            setStateDialog(() => cantidadElegida++);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Stock máximo alcanzado"), duration: Duration(seconds: 1)),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx), 
                  child: Text("CANCELAR", style: TextStyle(color: Colors.grey))
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                  onPressed: () {
                    Navigator.pop(ctx);
                    // Reutilizamos tu lógica, pero metiendo la cantidad exacta
                    _agregarVariasUnidadesAlCarrito(producto, cantidadElegida);
                  },
                  child: Text("AGREGAR USD ${(producto.precio * cantidadElegida).toStringAsFixed(2)}"),
                )
              ],
            );
          }
        );
      }
    );
  }

  // --- FUNCIÓN AUXILIAR PARA EL DIÁLOGO ---
  void _agregarVariasUnidadesAlCarrito(Producto producto, int cantidad) {
    int index = _carrito.indexWhere((item) => item['producto'].id == producto.id);
    setState(() {
      if (index != -1) {
        _carrito[index]['cantidad'] += cantidad;
      } else {
        _carrito.add({'producto': producto, 'cantidad': cantidad});
      }
    });
    _calcularTotal();
  }
  // --- IDEA #6: DIÁLOGO DE ÉXITO ANIMADO ---
  void _mostrarExito() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        Future.delayed(const Duration(milliseconds: 1400), () {
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
      Producto p = item['producto']; 
      return {
        'id': p.id,
        'nombre': p.nombre,
        'cantidad': item['cantidad'],
        'precio_unitario': p.precio,
        'imagen': p.urlImagen, 
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
      await SupabaseService.instance.crearVenta(cotiFinal);
    } else {
      await SupabaseService.instance.actualizarCotizacion(cotiFinal);
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
                  child: Autocomplete<Cliente>(
                    optionsBuilder: (TextEditingValue textEditingValue) async {
                      if (textEditingValue.text.length < 2) {
                        return const Iterable<Cliente>.empty();
                      }
                      // Llama a Supabase mientras el vendedor escribe
                      return await SupabaseService.instance.buscarClientesGeneral(textEditingValue.text);
                    },
                    displayStringForOption: (Cliente option) => option.nombre,
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4.0,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxHeight: 200, maxWidth: MediaQuery.of(context).size.width - 32),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: options.length,
                              itemBuilder: (BuildContext context, int index) {
                                final Cliente cliente = options.elementAt(index);
                                return ListTile(
                                  leading: Icon(Icons.person, color: Colors.indigo),
                                  title: Text(cliente.nombre),
                                  subtitle: Text("DNI/RUC: ${cliente.dniRuc}"), // ¡Aquí resolvemos el problema de los homónimos!
                                  onTap: () {
                                    onSelected(cliente);
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                    onSelected: (Cliente seleccion) {
                      setState(() {
                        _clienteSeleccionado = seleccion; // Guardas el cliente elegido para la cotización
                      });
                    },
                    fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                      return TextFormField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: 'Buscar Cliente (Nombre o DNI/RUC)',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                      );
                    },
                  )
                ),

                const SizedBox(height: 10),

                // BOTÓN AGREGAR PRODUCTOS (Actualizado al Nuevo Catálogo)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange, // Le damos un color llamativo
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    icon: const Icon(Icons.search),
                    label: const Text(
                      "BUSCAR Y AGREGAR PRODUCTO",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    onPressed: () async {
                      // 1. Navegamos al catálogo en modo selección
                      final Producto? productoElegido = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          // IMPORTANTE: Asegúrate de haber importado tu products_screen.dart arriba
                          builder: (context) => ProductsScreen(modoSeleccion: true), 
                        ),
                      );

                      // 2. Si el vendedor seleccionó una máquina...
                      if (productoElegido != null) {
                        _pedirCantidadYAgregarAlCarrito(productoElegido);
                      }
                    },
                  ),
                ),

                const Divider(
                  height: 30,
                  thickness: 1,
                  indent: 20,
                  endIndent: 20,
                ),

                // LISTADO DEL CARRITO (CORREGIDO PARA NO COLGARSE)
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
                                    child: SizedBox(
                                      width: 55,
                                      height: 55,
                                      // --- AQUÍ ESTÁ LA CORRECCIÓN ---
                                      // Verificamos si es http (internet) o archivo local
                                      child:
                                          (p.urlImagen != null &&
                                              p.urlImagen != "")
                                          ? (p.urlImagen!.startsWith('http')
                                                ? Image.network(
                                                    p.urlImagen!,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) => Container(
                                                          color:
                                                              Colors.grey[200],
                                                          child: const Icon(
                                                            Icons.broken_image,
                                                            color: Colors.grey,
                                                          ),
                                                        ),
                                                  )
                                                : Image.file(
                                                    File(p.urlImagen!),
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) => Container(
                                                          color:
                                                              Colors.grey[200],
                                                          child: const Icon(
                                                            Icons.folder_off,
                                                            color: Colors.grey,
                                                          ),
                                                        ),
                                                  ))
                                          : Container(
                                              color: Colors.grey[200],
                                              child: const Icon(
                                                Icons.inventory_2,
                                              ),
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
                                subtitle: Text("USD ${p.precio} c/u"),
                                trailing: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
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
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).cardColor,
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
                                              offset: const Offset(0, 2),
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

                // PANEL DE TOTAL
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
                            "USD ${_total.toStringAsFixed(2)}",
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
}
