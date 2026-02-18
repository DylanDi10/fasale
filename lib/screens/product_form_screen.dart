import 'dart:io';
import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';

class ProductFormScreen extends StatefulWidget {
  final Producto? producto;

  const ProductFormScreen({Key? key, this.producto}) : super(key: key);

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

  int? _categoriaIdSeleccionada; 
  List<Categoria> _listaCategorias = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.producto?.nombre ?? '');
    _precioController = TextEditingController(text: widget.producto?.precio.toString() ?? '');
    _stockController = TextEditingController(text: widget.producto?.stock.toString() ?? '');
    _urlImagenController = TextEditingController(text: widget.producto?.urlImagen ?? '');
    _descripcionController = TextEditingController(text: widget.producto?.descripcion ?? '');
    
    if (widget.producto != null) {
      _categoriaIdSeleccionada = widget.producto!.categoriaId;
    }

    _cargarCategorias();
  }

  void _cargarCategorias() async {
    final categorias = await DatabaseHelper.instance.obtenerCategorias();
    setState(() {
      _listaCategorias = categorias;
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
    super.dispose();
  }

  void _guardarProducto() async {
    if (_formKey.currentState!.validate()) {
      
      if (_categoriaIdSeleccionada == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Por favor selecciona una categoría'), backgroundColor: Colors.red),
        );
        return;
      }

      final producto = Producto(
        id: widget.producto?.id,
        nombre: _nombreController.text,
        precio: double.parse(_precioController.text),
        stock: int.parse(_stockController.text),
        urlImagen: _urlImagenController.text,
        descripcion: _descripcionController.text,
        
        categoriaId: _categoriaIdSeleccionada!, 
      );

      if (widget.producto == null) {
        await DatabaseHelper.instance.insertarProducto(producto);
      } else {
        await DatabaseHelper.instance.actualizarProducto(producto);
      }

      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
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
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre del Producto', 
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.shopping_bag_outlined)
                ),
                validator: (value) => value!.isEmpty ? 'Ingresa un nombre' : null,
              ),
              SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _precioController,
                      decoration: InputDecoration(
                        labelText: 'Precio (S/)', 
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money)
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => value!.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      decoration: InputDecoration(
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
              SizedBox(height: 15),


              DropdownButtonFormField<int>(
                decoration: InputDecoration(
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
              
              SizedBox(height: 15),

              TextFormField(
                controller: _urlImagenController,
                decoration: InputDecoration(
                  labelText: 'URL de Imagen (Opcional)',
                  prefixIcon: Icon(Icons.link),
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              SizedBox(height: 10),

              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[200],
                ),
                child: _urlImagenController.text.isEmpty
                    ? Column(
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
                          errorBuilder: (c, o, s) => Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, size: 50, color: Colors.red),
                              Text("Error al cargar imagen"),
                            ],
                          ),
                        ),
                      ),
              ),
              SizedBox(height: 20),

              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _guardarProducto,
                  icon: Icon(Icons.save),
                  label: Text("GUARDAR"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}