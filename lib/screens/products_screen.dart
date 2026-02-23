import 'package:cotizaciones_app/db/supabase_service.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import 'product_form_screen.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductsScreen extends StatefulWidget {
  
  final bool modoSeleccion;
  final bool esAdmin;
  const ProductsScreen({Key? key, this.modoSeleccion = false, this.esAdmin = false}) : super(key: key);
  @override
  _ProductsScreenState createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late Future<List<Producto>> _listaProductos;

  // Variables para Búsqueda y Filtros
  String _queryBusqueda = '';
  String _marcaSeleccionada = 'Todas';
  String _modeloSeleccionado = 'Todos';
  int? _categoriaSeleccionadaId;

  
  // Listas para los Dropdowns
  List<Map<String, dynamic>> _listaMarcas = [];
  List<String> _listaModelos = ['Todos'];
  // Nueva lista para las categorías
  List<Map<String, dynamic>> _listaCategorias = [];

  // Función para descargar las categorías de la base de datos
  Future<void> _cargarCategorias() async {
    try {
      final data = await Supabase.instance.client.from('categorias').select();
      setState(() {
        _listaCategorias = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      debugPrint("Error cargando categorías: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _aplicarFiltrosYBusqueda();
    _cargarMarcasCatalogo();
    _cargarCategorias();
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
        categoriaId: _categoriaSeleccionadaId,
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
  void _abrirGestorCategorias() {
    TextEditingController nuevaCategoriaController = TextEditingController();
    // Asumimos que ya tienes la instancia de Supabase configurada en tu app
    final supabase = Supabase.instance.client;

    showDialog(
      context: context,
      builder: (context) {
        // StatefulBuilder es LA CLAVE para que el Dialog se actualice en tiempo real
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Gestionar Categorías", style: TextStyle(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. Buscador para agregar nueva
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: nuevaCategoriaController,
                            decoration: const InputDecoration(
                              hintText: "Nombre de nueva categoría...",
                              isDense: true,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.green, size: 30),
                          onPressed: () async {
                            final texto = nuevaCategoriaController.text.trim();
                            if (texto.isEmpty) return;

                            try {
                              // INSERTAR EN SUPABASE
                              // Asegúrate de que tu tabla se llame 'categorias' y la columna 'nombre'
                              await supabase.from('categorias').insert({'nombre': texto});
                              
                              nuevaCategoriaController.clear();
                              
                              // Volvemos a cargar tu lista global de categorías
                              await _cargarCategorias(); // <--- Llama a tu función que descarga las categorías
                              
                              // Actualizamos la pantalla del Dialog y la pantalla de fondo
                              setStateDialog(() {});
                              setState(() {});
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Categoría guardada con éxito", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
                              );
                            } catch (e) {
                              print("Error al guardar categoría: $e");
                            }
                          },
                        )
                      ],
                    ),
                    const Divider(height: 30),
                    
                    // 2. Lista de categorías actuales
                    const Text("Categorías Actuales:", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Expanded(
                      // Reemplaza 'listaCategorias' por el nombre de tu variable real (List<Map<String, dynamic>>)
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _listaCategorias.length, 
                        itemBuilder: (context, index) {
                          final categoria = _listaCategorias[index];
                          
                          return ListTile(
                            dense: true,
                            // Asegúrate de que 'nombre' sea la clave correcta en tu mapa
                            title: Text(categoria['nombre'].toString()), 
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 22),
                              onPressed: () async {
                                // Confirmación de borrado
                                bool confirmar = await showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("¿Borrar categoría?"),
                                    content: const Text("¿Estás seguro? Los productos con esta categoría podrían quedarse sin clasificación."),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
                                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Borrar", style: TextStyle(color: Colors.red))),
                                    ],
                                  ),
                                ) ?? false;

                                if (confirmar) {
                                  try {
                                    // BORRAR DE SUPABASE
                                    await supabase
                                        .from('categorias')
                                        .delete()
                                        .eq('id', categoria['id']); // Usa el ID para borrar el exacto
                                    
                                    // Recargar las listas
                                    await _cargarCategorias();
                                    
                                    setStateDialog(() {});
                                    setState(() {});
                                  } catch (e) {
                                    print("Error al borrar: $e");
                                  }
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("CERRAR", style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
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
          // Solo si esAdmin es TRUE, mostramos estos botones
          if (widget.esAdmin) ...[
            // 1. Botón para Gestionar Categorías
            IconButton(
              icon: const Icon(Icons.category, color: Colors.white),
              tooltip: "Gestionar Categorías",
              onPressed: () => _abrirGestorCategorias(), 
            ),
            // 2. Botón de Importar Excel
            IconButton(
              icon: const Icon(Icons.upload_file, color: Colors.white),
              tooltip: "Importar Excel",
              onPressed: () => _mostrarOpcionesImportacion(),
            ),
          ],
        ],
      ),
      
      body: Column(
        children: [
          // --- FILTROS EN CASCADA ---
          // --- FILTROS EN CASCADA ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                // NUEVA FILA: Dropdown CATEGORÍA
                Row(
                  children: [
                    Text("Categoría:", style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.bold)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButton<int?>(
                        isExpanded: true,
                        value: _categoriaSeleccionadaId,
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Todas las categorías', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          ..._listaCategorias.map((cat) {
                            return DropdownMenuItem<int?>(
                              value: cat['id'] as int,
                              child: Text(cat['nombre'].toString(), overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                        ],
                        onChanged: (nuevoId) {
                          setState(() {
                            _categoriaSeleccionadaId = nuevoId;
                          });
                          _aplicarFiltrosYBusqueda();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8), // Espacio entre las dos filas

                // FILA ORIGINAL: MARCA Y MODELO
                Row(
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
                              const DropdownMenuItem(value: 'Todas', child: Text('Todas')),
                              ..._listaMarcas.map((marca) {
                                return DropdownMenuItem<String>(
                                  value: marca['nombre'],
                                  child: Text(marca['nombre'], overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                            ],
                            onChanged: (nuevaMarca) {
                              if (nuevaMarca != null) {
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
                    const SizedBox(width: 16),
                    
                    // Dropdown MODELO
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
                            Text("Precio: USD ${producto.precio}", style: TextStyle(fontWeight: FontWeight.w500)),
                            if (producto.marca != null || producto.modelo != null)
                              Text("${producto.marca ?? ''} ${producto.modelo ?? ''}", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            SizedBox(height: 4),
                            Text("Stock: ${producto.stock}", style: TextStyle(color: producto.stock == 0 ? Colors.red : Colors.grey)),
                          ],
                        ),
                        trailing: widget.esAdmin 
                          ? IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await SupabaseService.instance.eliminarProducto(producto.id!);
                                _aplicarFiltrosYBusqueda(); 
                              },
                            )
                          : null,
                        onTap: () async {
                          if (widget.modoSeleccion) {
                            Navigator.pop(context, producto); 
                          } else {
                            // Abrimos el formulario, pero le pasamos el "pase VIP"
                            await Navigator.push(
                              context, 
                              MaterialPageRoute(
                                builder: (context) => ProductFormScreen(
                                  producto: producto,
                                  esAdmin: widget.esAdmin, 
                                )
                              )
                            );
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
      floatingActionButton: widget.esAdmin
    ? FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => ProductFormScreen()));
          _aplicarFiltrosYBusqueda();
        },
      )
    : null,
    );
  }
}