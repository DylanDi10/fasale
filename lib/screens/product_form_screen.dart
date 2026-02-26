import 'dart:io';
import 'package:cotizaciones_app/db/supabase_service.dart';
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';

class ProductFormScreen extends StatefulWidget {
  final Producto? producto;
  final bool esAdmin;
  
  const ProductFormScreen({Key? key, this.producto, this.esAdmin = true,}) : super(key: key);

  @override
  _ProductFormScreenState createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nombreController;
  late TextEditingController _precioController;
  late TextEditingController _stockController;
  late TextEditingController _urlImagenController;
  late TextEditingController _descripcionController;
  
  late TextEditingController _modeloController;
  late TextEditingController _submodeloController;

  // --- CONTROLADORES MULTIMEDIA ---
  late TextEditingController _linkPdfController;
  late TextEditingController _linkVideoController;
  late TextEditingController _linkFotosController;

  int? _categoriaIdSeleccionada; 
  List<Categoria> _listaCategorias = [];
  
  // --- NUEVO: VARIABLES PARA LA MARCA (Simplificadas a Texto) ---
  String? _marcaSeleccionada;
  List<String> _listaMarcas = []; // Ahora es una lista de textos simples

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.producto?.nombre ?? '');
    _precioController = TextEditingController(text: widget.producto?.precio.toString() ?? '');
    _stockController = TextEditingController(text: widget.producto?.stock.toString() ?? '');
    _urlImagenController = TextEditingController(text: widget.producto?.urlImagen ?? '');
    _descripcionController = TextEditingController(text: widget.producto?.descripcion ?? '');
    
    _modeloController = TextEditingController(text: widget.producto?.modelo ?? '');
    _submodeloController = TextEditingController(text: widget.producto?.submodelo ?? '');
    
    // Inicializamos los enlaces
    _linkPdfController = TextEditingController(text: widget.producto?.linkPdf ?? '');
    _linkVideoController = TextEditingController(text: widget.producto?.linkVideo ?? '');
    _linkFotosController = TextEditingController(text: widget.producto?.linkFotos ?? '');
    
    if (widget.producto != null) {
      _categoriaIdSeleccionada = widget.producto!.categoriaId;
      _marcaSeleccionada = widget.producto!.marca; // Asignamos la marca que ya tenía
    }

    _cargarDatos(); // Cargamos categorías y el nuevo motor de marcas
  }

  // --- NUEVA FUNCIÓN PARA CARGAR TODO CON EL MOTOR INTELIGENTE ---
  void _cargarDatos() async {
    // --- LAS PAUSAS ASÍNCRONAS ---
    final categorias = await SupabaseService.instance.obtenerCategorias();
    final filtros = await SupabaseService.instance.obtenerFiltrosDinamicos(); // Llamamos a la vista
    
    // --- 🛡️ EL ESCUDO ---
    if (!mounted) return;

    // --- ZONA SEGURA ---
    setState(() {
      _listaCategorias = categorias;
      // Extraemos solo los nombres de las marcas
      _listaMarcas = filtros.keys.toList();
      
      // Seguridad Anti-Crasheo: Si estamos editando un producto que tiene una marca rara o antigua,
      // la agregamos a la lista temporalmente para que el Dropdown no tire error en rojo.
      if (_marcaSeleccionada != null && _marcaSeleccionada!.isNotEmpty) {
        if (!_listaMarcas.contains(_marcaSeleccionada)) {
          _listaMarcas.add(_marcaSeleccionada!); 
        }
      }
      
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _precioController.dispose();
    _stockController.dispose();
    _urlImagenController.dispose();
    _descripcionController.dispose();
    _modeloController.dispose();
    _submodeloController.dispose();
    _linkPdfController.dispose();
    _linkVideoController.dispose();
    _linkFotosController.dispose();
    super.dispose();
  }

  void _guardarProducto() async {
    if (_formKey.currentState!.validate()) {
      
      if (_categoriaIdSeleccionada == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor selecciona una categoría'), backgroundColor: Colors.red),
        );
        return;
      }

      // 1. PARSEO SEGURO
      final precioSeguro = double.tryParse(_precioController.text) ?? 0.0;
      final stockSeguro = int.tryParse(_stockController.text) ?? 0;

      final producto = Producto(
        id: widget.producto?.id,
        nombre: _nombreController.text.trim(),
        precio: precioSeguro,
        stock: stockSeguro,
        urlImagen: _urlImagenController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        categoriaId: _categoriaIdSeleccionada!, 
        marca: _marcaSeleccionada, 
        modelo: _modeloController.text.trim().isEmpty ? null : _modeloController.text.trim(),
        submodelo: _submodeloController.text.trim().isEmpty ? null : _submodeloController.text.trim(),
        
        linkPdf: _linkPdfController.text.trim().isEmpty ? null : _linkPdfController.text.trim(),
        linkVideo: _linkVideoController.text.trim().isEmpty ? null : _linkVideoController.text.trim(),
        linkFotos: _linkFotosController.text.trim().isEmpty ? null : _linkFotosController.text.trim(),
      );

      try {
        if (widget.producto == null) {
          await SupabaseService.instance.insertarProducto(producto);
        } else {
          await SupabaseService.instance.actualizarProducto(producto);
        }

        if (!mounted) return;
        Navigator.pop(context, true);

      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'), 
            backgroundColor: Colors.red
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.producto == null ? 'Nuevo Producto' : 'Editar Producto'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // 1. NOMBRE
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Producto', 
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.shopping_bag_outlined)
                ),
                validator: (value) => value!.isEmpty ? 'Ingresa un nombre' : null,
              ),
              const SizedBox(height: 15),

              // MARCA Y MODELO
              Row(
                children: [
                  // --- NUEVO: DROPDOWN DE MARCAS SIMPLIFICADO ---
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Marca',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.branding_watermark),
                      ),
                      value: _marcaSeleccionada,
                      items: _listaMarcas.map((String marca) { // Magia aplicada aquí
                        return DropdownMenuItem<String>(
                          value: marca,
                          child: Text(marca, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (valor) {
                        setState(() {
                          _marcaSeleccionada = valor;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  // MODELO
                  Expanded(
                    child: TextFormField(
                      controller: _modeloController,
                      decoration: const InputDecoration(
                        labelText: 'Modelo' , 
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.numbers)
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // SUBMODELO
              TextFormField(
                controller: _submodeloController,
                decoration: const InputDecoration(
                  labelText: 'Submodelo (Opcional)', 
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.format_list_numbered)
                ),
              ),
              const SizedBox(height: 15),
              // CAMPO DE DESCRIPCIÓN (EL RECTÁNGULO)
              TextFormField(
                controller: _descripcionController,
                maxLines: 3, 
                decoration: const InputDecoration(
                  labelText: 'Descripción del Producto',
                  hintText: 'Ej: Máquina en excelente estado, motor monofásico...',
                  border: OutlineInputBorder(),
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.description_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // PRECIO Y STOCK
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      enabled: widget.esAdmin,
                      controller: _precioController,
                      decoration: const InputDecoration(
                        labelText: 'Precio (USD)', 
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money)
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => value!.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      enabled: widget.esAdmin,
                      controller: _stockController,
                      decoration: const InputDecoration(
                        labelText: 'Stock', 
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.inventory_2_outlined)
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => value!.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // CATEGORÍA
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                value: _categoriaIdSeleccionada,
                items: _listaCategorias.map((categoria) {
                  return DropdownMenuItem<int>(
                    value: categoria.id, 
                    child: Text(categoria.nombre),
                  );
                }).toList(),
                onChanged: (valor) {
                  setState(() {
                    _categoriaIdSeleccionada = valor;
                  });
                },
                validator: (value) => value == null ? 'Selecciona una categoría' : null,
              ),
              const SizedBox(height: 25),

              // --- SECCIÓN MULTIMEDIA (ENLACES) ---
              const Divider(thickness: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  "Material para el Catálogo Virtual (Opcional)",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo[900], fontSize: 16),
                ),
              ),
              
              TextFormField(
                controller: _linkFotosController,
                decoration: const InputDecoration(
                  labelText: 'Enlace de Fotos (Google Drive)',
                  hintText: 'Ej: https://drive.google.com/...',
                  prefixIcon: Icon(Icons.photo_library, color: Colors.orange),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _linkVideoController,
                decoration: const InputDecoration(
                  labelText: 'Enlace de Video (YouTube/Drive)',
                  hintText: 'Ej: https://youtube.com/watch?v=...',
                  prefixIcon: Icon(Icons.play_circle_fill, color: Colors.blue),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _linkPdfController,
                decoration: const InputDecoration(
                  labelText: 'Enlace de Ficha Técnica (PDF)',
                  hintText: 'Ej: https://drive.google.com/file/...',
                  prefixIcon: Icon(Icons.picture_as_pdf, color: Colors.red),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              const Divider(thickness: 1),
              const SizedBox(height: 15),

              // IMAGEN PRINCIPAL
              TextFormField(
                controller: _urlImagenController,
                decoration: const InputDecoration(
                  labelText: 'URL de Imagen Principal',
                  prefixIcon: Icon(Icons.link),
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),

              // VISTA PREVIA IMAGEN
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[200],
                ),
                child: _urlImagenController.text.isEmpty
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image, size: 50, color: Colors.grey),
                          Text("Sin imagen"),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          _urlImagenController.text,
                          fit: BoxFit.cover,
                          errorBuilder: (c, o, s) => const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, size: 50, color: Colors.red),
                              Text("Error al cargar imagen"),
                            ],
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 20),

              // BOTÓN GUARDAR
              if (widget.esAdmin)
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _guardarProducto,
                    icon: const Icon(Icons.save),
                    label: const Text("GUARDAR"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}