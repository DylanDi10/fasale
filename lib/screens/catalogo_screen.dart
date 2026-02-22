import 'package:cotizaciones_app/db/supabase_service.dart';
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import 'dart:io';
import 'catalogo_detalle_screen.dart';
class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({Key? key}) : super(key: key);

  @override
  _CatalogoScreenState createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  late Future<List<Producto>> _listaProductos;

  // Variables para Búsqueda y Filtros
  String _queryBusqueda = '';
  String _marcaSeleccionada = 'Todas';
  String _modeloSeleccionado = 'Todos';
  
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
    if (mounted) {
      setState(() => _listaMarcas = marcas);
    }
  }

  void _alCambiarMarca(String nuevaMarca, int? marcaId) async {
    setState(() {
      _marcaSeleccionada = nuevaMarca;
      _modeloSeleccionado = 'Todos';
      _listaModelos = ['Todos'];    
    });

    if (marcaId != null) {
      final modelos = await SupabaseService.instance.obtenerModelosPorMarca(marcaId);
      if (mounted) {
        setState(() => _listaModelos = ['Todos', ...modelos]);
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Catálogo Digital"),
        backgroundColor: Colors.indigo[900],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // --- BUSCADOR ---
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.indigo[900],
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Buscar máquina...",
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                _queryBusqueda = value;
                _aplicarFiltrosYBusqueda();
              },
            ),
          ),

          // --- FILTROS EN CASCADA ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
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
                            int? id = nuevaMarca != 'Todas' 
                                ? _listaMarcas.firstWhere((m) => m['nombre'] == nuevaMarca)['id'] 
                                : null;
                            _alCambiarMarca(nuevaMarca, id);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
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
                            setState(() => _modeloSeleccionado = nuevoModelo);
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

          // --- LISTA DEL CATÁLOGO (SOLO LECTURA) ---
          Expanded(
            child: FutureBuilder<List<Producto>>(
              future: _listaProductos,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("No se encontraron coincidencias."));

                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final producto = snapshot.data![index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: SizedBox(
                          width: 60,
                          height: 60,
                          child: (producto.urlImagen != null && producto.urlImagen!.isNotEmpty)
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: producto.urlImagen!.startsWith('http')
                                      ? Image.network(producto.urlImagen!, fit: BoxFit.cover, errorBuilder: (c, o, s) => const Icon(Icons.broken_image))
                                      : Image.file(File(producto.urlImagen!), fit: BoxFit.cover, errorBuilder: (c, o, s) => const Icon(Icons.image_not_supported)),
                                )
                              : const Icon(Icons.inventory, color: Colors.indigo, size: 40),
                        ),
                        title: Text(producto.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 5),
                            if (producto.marca != null || producto.modelo != null)
                              Text("${producto.marca ?? ''} ${producto.modelo ?? ''}", style: TextStyle(color: Colors.grey[700])),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                if (producto.linkPdf != null && producto.linkPdf!.isNotEmpty)
                                  const Icon(Icons.picture_as_pdf, size: 16, color: Colors.red),
                                const SizedBox(width: 5),
                                if (producto.linkVideo != null && producto.linkVideo!.isNotEmpty)
                                  const Icon(Icons.play_circle_fill, size: 16, color: Colors.blue),
                              ],
                            )
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Colors.indigo),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CatalogoDetalleScreen(producto: producto),
                            ),
                          );
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
    );
  }
}