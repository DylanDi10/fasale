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

  // NUEVAS VARIABLES: Listas dinámicas de texto simple
  Map<String, List<String>> _filtrosDisponibles = {};
  List<String> _listaMarcas = ['Todas'];
  List<String> _listaModelos = ['Todos'];
  List<Map<String, dynamic>> _listaCategorias = [];

  // Función para descargar las categorías de la base de datos
  Future<void> _cargarCategorias() async {
    try {
      final data = await Supabase.instance.client.from('categorias').select();
      if (!mounted) return;
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
    _cargarCategorias();
    _cargarFiltrosDinamicos(); // Llamamos al nuevo motor
  }

  // NUEVA FUNCIÓN: Trae todas las marcas y modelos de golpe
  void _cargarFiltrosDinamicos() async {
    final filtros = await SupabaseService.instance.obtenerFiltrosDinamicos();
    if (!mounted) return;
    setState(() {
      _filtrosDisponibles = filtros;
      _listaMarcas = ['Todas', ...filtros.keys];
    });
  }

  // NUEVA FUNCIÓN: Cambia la marca y actualiza los modelos al instante sin internet
  void _alCambiarMarca(String nuevaMarca) {
    setState(() {
      _marcaSeleccionada = nuevaMarca;
      _modeloSeleccionado = 'Todos'; 
      
      if (nuevaMarca == 'Todas') {
        _listaModelos = ['Todos'];
      } else {
        _listaModelos = ['Todos', ...(_filtrosDisponibles[nuevaMarca] ?? [])];
      }
    });
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Procesando Excel... Espere por favor."), 
            duration: Duration(seconds: 3),
            backgroundColor: Colors.indigo,
          ),
        );

        var bytes = File(result.files.single.path!).readAsBytesSync();
        var excel = Excel.decodeBytes(bytes);

        List<Producto> listaParaSubir = [];

        final resCategorias = await Supabase.instance.client.from('categorias').select();
        
        Map<String, int> mapaCategorias = {};
        for (var cat in resCategorias) {
          mapaCategorias[cat['nombre'].toString().trim().toLowerCase()] = cat['id'] as int;
        }

        for (var table in excel.tables.keys) {
          var sheet = excel.tables[table];
          if (sheet == null) continue;

          for (var i = 1; i < sheet.maxRows; i++) {
            var row = sheet.rows[i];
            
            // --- 🛡️ FUNCIÓN SALVAVIDAS ---
            // Si el Excel tiene celdas vacías al final, la fila se "acorta". Esto evita el crasheo.
            String? celda(int index) {
              if (index >= row.length) return null;
              final valor = row[index]?.value?.toString().trim();
              return (valor == null || valor.isEmpty) ? null : valor;
            }

            // Si no hay nombre, saltamos la fila
            if (celda(0) == null) continue; 

            // --- 🔍 TRADUCCIÓN DE CATEGORÍA ---
            String nombreCategoriaExcel = celda(5) ?? "Sin Categoría";
            String categoriaKey = nombreCategoriaExcel.toLowerCase();
            int categoriaIdFinal;

            if (mapaCategorias.containsKey(categoriaKey)) {
              categoriaIdFinal = mapaCategorias[categoriaKey]!;
            } else {
              final nuevaCat = await Supabase.instance.client
                  .from('categorias')
                  .insert({'nombre': nombreCategoriaExcel})
                  .select()
                  .single(); 
              
              categoriaIdFinal = nuevaCat['id'] as int;
              mapaCategorias[categoriaKey] = categoriaIdFinal; 
            }

            // Armamos el producto leyendo de forma 100% segura
            listaParaSubir.add(Producto(
              nombre: celda(0) ?? "Sin nombre",
              descripcion: celda(1) ?? "",
              precio: double.tryParse(celda(2) ?? "0") ?? 0.0,
              stock: int.tryParse(celda(3) ?? "0") ?? 0,
              urlImagen: celda(4),
              categoriaId: categoriaIdFinal, 
              marca: celda(6),
              modelo: celda(7),
              submodelo: celda(8),
              linkPdf: celda(9),
              linkVideo: celda(10),
              linkFotos: celda(11),
            ));
          }
        }

        if (listaParaSubir.isNotEmpty) {
          if (limpiarBase) {
            await SupabaseService.instance.eliminarTodosLosProductos();
          }

          await SupabaseService.instance.importarProductosMasivos(listaParaSubir);
          
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${listaParaSubir.length} productos cargados con éxito"), backgroundColor: Colors.green),
          );
          
          await _cargarCategorias(); 
          _cargarFiltrosDinamicos();
          _aplicarFiltrosYBusqueda(); 
        }
      }
    } catch (e) {
      debugPrint("Error importando Excel: $e");
      if (!mounted) return;
      // AHORA MOSTRARÁ EL ERROR REAL DE LA BASE DE DATOS PARA SABER QUÉ PASA
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error real: $e"), backgroundColor: Colors.red, duration: const Duration(seconds: 8)),
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
              _leerExcelYSubir(limpiarBase: true); 
            },
            child: const Text("REEMPLAZAR TODO", style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _leerExcelYSubir(limpiarBase: false); 
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
    final supabase = Supabase.instance.client;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Gestionar Categorías", style: TextStyle(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                              await supabase.from('categorias').insert({'nombre': texto});
                              nuevaCategoriaController.clear();
                              await _cargarCategorias(); 
                              
                              if (!mounted) return;
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
                    const Text("Categorías Actuales:", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _listaCategorias.length, 
                        itemBuilder: (context, index) {
                          final categoria = _listaCategorias[index];
                          
                          return ListTile(
                            dense: true,
                            title: Text(categoria['nombre'].toString()), 
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 22),
                              onPressed: () async {
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
                                    await supabase
                                        .from('categorias')
                                        .delete()
                                        .eq('id', categoria['id']);
                                    
                                    await _cargarCategorias();
                                    
                                    if (!mounted) return;
                                    setStateDialog(() {});
                                    setState(() {});

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Categoría eliminada"), backgroundColor: Colors.green),
                                    );
                                  } catch (e) {
                                    if (!mounted) return;
                                    String mensaje = "Error al borrar";
                                    if (e.toString().contains('23503')) {
                                      mensaje = "No puedes borrarla, tiene productos asociados";
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(mensaje), backgroundColor: Colors.red[800]),
                                    );
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
            _aplicarFiltrosYBusqueda(); 
          },
        ),
        actions: [
          if (widget.esAdmin) ...[
            IconButton(
              icon: const Icon(Icons.category, color: Colors.white),
              tooltip: "Gestionar Categorías",
              onPressed: () => _abrirGestorCategorias(), 
            ),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
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
                const SizedBox(height: 8),

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
                            items: _listaMarcas.map((String marca) {
                              return DropdownMenuItem<String>(
                                value: marca,
                                child: Text(marca, overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (nuevaMarca) {
                              if (nuevaMarca != null) {
                                _alCambiarMarca(nuevaMarca); // <-- Magia aplicada
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

          // LISTA DE INVENTARIO
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