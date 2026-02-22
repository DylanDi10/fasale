import 'package:cotizaciones_app/db/supabase_service.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import 'product_form_screen.dart';
import 'dart:io';

class ProductsScreen extends StatefulWidget {
  final bool modoSeleccion; // Agregas esto
  const ProductsScreen({Key? key, this.modoSeleccion = false}) : super(key: key);
  @override
  _ProductsScreenState createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late Future<List<Producto>> _listaProductos;

  // Variables para Búsqueda y Filtros
  String _queryBusqueda = '';
  String _marcaSeleccionada = 'Todas';
  String _modeloSeleccionado = 'Todos';
  
  // Listas para los Dropdowns
  List<Map<String, dynamic>> _listaMarcas = [];
  List<String> _listaModelos = ['Todos'];

  @override
  void initState() {
    super.initState();
    _aplicarFiltrosYBusqueda();
    _cargarMarcasCatalogo();
  }

  void _cargarMarcasCatalogo() async {
    final marcas = await SupabaseService.instance.obtenerMarcasCatalogo();
    setState(() {
      _listaMarcas = marcas;
    });
  }

  void _alCambiarMarca(String nuevaMarca, int? marcaId) async {
    setState(() {
      _marcaSeleccionada = nuevaMarca;
      _modeloSeleccionado = 'Todos'; // Resetea el modelo
      _listaModelos = ['Todos'];     // Limpia la lista anterior
    });

    // Si selecciona una marca real, trae sus modelos de la base de datos
    if (marcaId != null) {
      final modelos = await SupabaseService.instance.obtenerModelosPorMarca(marcaId);
      setState(() {
        _listaModelos = ['Todos', ...modelos];
      });
    }
    
    _aplicarFiltrosYBusqueda();
  }

  void _aplicarFiltrosYBusqueda() {
    setState(() {
      _listaProductos = SupabaseService.instance.buscarYFiltrarProductos(
        query: _queryBusqueda,
        marca: _marcaSeleccionada,
        modelo: _modeloSeleccionado,
      );
    });
  }
  // Ahora recibe un parámetro bool para saber si debe borrar primero
  Future<void> _leerExcelYSubir({required bool limpiarBase}) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null && result.files.single.path != null) {
        var bytes = File(result.files.single.path!).readAsBytesSync();
        var excel = Excel.decodeBytes(bytes);

        List<Producto> listaParaSubir = [];

        for (var table in excel.tables.keys) {
          var sheet = excel.tables[table];
          if (sheet == null) continue;

          for (var i = 1; i < sheet.maxRows; i++) {
            var row = sheet.rows[i];
            
            listaParaSubir.add(Producto(
              nombre: row[0]?.value.toString() ?? "Sin nombre",
              descripcion: row[1]?.value.toString() ?? "",
              precio: double.tryParse(row[2]?.value.toString() ?? "0.0") ?? 0.0,
              stock: int.tryParse(row[3]?.value.toString() ?? "0") ?? 0,
              urlImagen: row[4]?.value.toString(),
              categoriaId: int.tryParse(row[5]?.value.toString() ?? "1") ?? 1,
              marca: row[6]?.value.toString(),
              modelo: row[7]?.value.toString(),
              submodelo: row[8]?.value.toString(),
              linkPdf: row[9]?.value.toString(),
              linkVideo: row[10]?.value.toString(),
              linkFotos: row[11]?.value.toString(),
            ));
          }
        }

        if (listaParaSubir.isNotEmpty) {
          // --- AQUÍ ESTÁ LA MAGIA DEL BORRADO ---
          if (limpiarBase) {
            await SupabaseService.instance.eliminarTodosLosProductos();
          }

          // Subimos los nuevos
          await SupabaseService.instance.importarProductosMasivos(listaParaSubir);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${listaParaSubir.length} productos cargados")),
          );
          _aplicarFiltrosYBusqueda(); // Refresca la pantalla
        }
      }
    } catch (e) {
      debugPrint("Error importando Excel: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: El formato del Excel no es correcto")),
      );
    }
  }
  void _mostrarOpcionesImportacion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Importar Inventario", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          "¿Deseas añadir los productos del Excel al inventario actual, o prefieres borrar todo y reemplazarlo por completo?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCELAR", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _leerExcelYSubir(limpiarBase: true); // TRUE = Reemplaza todo
            },
            child: const Text("REEMPLAZAR TODO", style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _leerExcelYSubir(limpiarBase: false); // FALSE = Solo añade
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            child: const Text("SOLO AÑADIR"),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
    appBar: AppBar(
        backgroundColor: Colors.indigo[900],
        iconTheme: IconThemeData(color: Colors.white),
        // --- BUSCADOR EN EL APPBAR ---
        title: TextField(
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Buscar producto...",
            hintStyle: TextStyle(color: Colors.white70),
            prefixIcon: Icon(Icons.search, color: Colors.white),
            border: InputBorder.none,
          ),
          onChanged: (value) {
            _queryBusqueda = value;
            _aplicarFiltrosYBusqueda(); // Busca en tiempo real al escribir
          },
        ),
        // --- BOTÓN DE IMPORTAR EXCEL (A la derecha) ---
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file, color: Colors.white),
            tooltip: "Importar Excel",
            onPressed: () => _mostrarOpcionesImportacion(), 
          ),
        ],
      ),
      
      body: Column(
        children: [
          // --- FILTROS EN CASCADA ---
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Dropdown MARCA
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Marca", style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                      DropdownButton<String>(
                        isExpanded: true,
                        value: _marcaSeleccionada,
                        items: [
                          DropdownMenuItem(value: 'Todas', child: Text('Todas')),
                          ..._listaMarcas.map((marca) {
                            return DropdownMenuItem<String>(
                              value: marca['nombre'],
                              child: Text(marca['nombre'], overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                        ],
                        onChanged: (nuevaMarca) {
                          if (nuevaMarca != null) {
                            // Buscamos el ID de la marca para traer sus modelos
                            int? id;
                            if (nuevaMarca != 'Todas') {
                              id = _listaMarcas.firstWhere((m) => m['nombre'] == nuevaMarca)['id'];
                            }
                            _alCambiarMarca(nuevaMarca, id);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                
                // Dropdown MODELO (Dependiente de la Marca)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Modelo", style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                      DropdownButton<String>(
                        isExpanded: true,
                        value: _listaModelos.contains(_modeloSeleccionado) ? _modeloSeleccionado : 'Todos',
                        items: _listaModelos.map((String modelo) {
                          return DropdownMenuItem<String>(
                            value: modelo,
                            child: Text(modelo, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: _marcaSeleccionada == 'Todas' ? null : (nuevoModelo) {
                          if (nuevoModelo != null) {
                            setState(() {
                              _modeloSeleccionado = nuevoModelo;
                            });
                            _aplicarFiltrosYBusqueda();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- LISTA DE INVENTARIO ---
          Expanded(
            child: FutureBuilder<List<Producto>>(
              future: _listaProductos,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text("No se encontraron coincidencias."));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final producto = snapshot.data![index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          child: (producto.urlImagen != null && producto.urlImagen != "")
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: producto.urlImagen!.startsWith('http')
                                      ? Image.network(producto.urlImagen!, fit: BoxFit.cover, errorBuilder: (c, o, s) => Icon(Icons.broken_image))
                                      : Image.file(File(producto.urlImagen!), fit: BoxFit.cover, errorBuilder: (c, o, s) => Icon(Icons.image_not_supported)),
                                )
                              : Icon(Icons.inventory, color: Colors.blue),
                        ),
                        title: Text(producto.nombre, style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Precio: S/ ${producto.precio}", style: TextStyle(fontWeight: FontWeight.w500)),
                            if (producto.marca != null || producto.modelo != null)
                              Text("${producto.marca ?? ''} ${producto.modelo ?? ''}", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            SizedBox(height: 4),
                            Text("Stock: ${producto.stock}", style: TextStyle(color: producto.stock == 0 ? Colors.red : Colors.grey)),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await SupabaseService.instance.eliminarProducto(producto.id!);
                            _aplicarFiltrosYBusqueda(); 
                          },
                        ),
                        onTap: () async {
                          if (widget.modoSeleccion) {
                            // Si estamos cotizando, devolvemos el producto a la pantalla anterior
                            Navigator.pop(context, producto); 
                          } else {
                            // Si estamos administrando, abrimos el formulario para editar
                            await Navigator.push(context, MaterialPageRoute(builder: (context) => ProductFormScreen(producto: producto)));
                            _aplicarFiltrosYBusqueda(); 
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => ProductFormScreen()));
          _aplicarFiltrosYBusqueda();
        },
      ),
    );
  }
}