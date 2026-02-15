import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/product_model.dart';
import 'product_form_screen.dart'; 

class ProductsScreen extends StatefulWidget {
  @override
  _ProductsScreenState createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late Future<List<Producto>> _listaProductos;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  void _cargarProductos() {
    setState(() {
      _listaProductos = DatabaseHelper.instance.obtenerProductos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Inventario de Productos')),
      
      body: FutureBuilder<List<Producto>>(
        future: _listaProductos, 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No tienes productos registrados."));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final producto = snapshot.data![index];
              
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: Icon(Icons.inventory, color: Colors.blue), // Icono o foto
                  title: Text(producto.nombre, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Stock: ${producto.stock}  |  Precio: S/ ${producto.precio}"),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      // Borrar producto y actualizar lista
                      await DatabaseHelper.instance.eliminarProducto(producto.id!);
                      _cargarProductos(); 
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Producto eliminado"))
                      );
                    },
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductFormScreen(producto: producto),
                      ),
                    );
                    // Al volver, recargamos la lista por si cambió el precio o nombre
                    _cargarProductos();
                  },
                ),
              );
            },
          );
        },
      ),

      // Botón flotante para AGREGAR (+)
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProductFormScreen()),
            );
            // Al volver, recargamos la lista
            _cargarProductos();
          },
        ),
    );
  }
}