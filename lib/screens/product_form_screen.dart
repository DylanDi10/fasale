import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/product_model.dart';

class ProductFormScreen extends StatefulWidget {
  final Producto? producto; // ¿Recibimos un producto? (Si es null, es NUEVO)

  const ProductFormScreen({Key? key, this.producto}) : super(key: key);

  @override
  _ProductFormScreenState createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nombreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _catCtrl = TextEditingController();
  final _imgCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.producto != null) {
      _nombreCtrl.text = widget.producto!.nombre;
      _descCtrl.text = widget.producto!.descripcion ?? ''; 
      _precioCtrl.text = widget.producto!.precio.toString();
      _stockCtrl.text = widget.producto!.stock.toString();
      _catCtrl.text = widget.producto!.categoria;
      _imgCtrl.text = widget.producto!.rutaImagen ?? '';
    }
  }

  void _guardar() async {
    if (_formKey.currentState!.validate()) {
      
      // 1. Armamos el objeto con los datos del formulario
      // OJO: Convertimos precio y stock de Texto a Número
      Producto modelo = Producto(
        id: widget.producto?.id, // Si editamos, mantenemos el ID. Si es nuevo, es null.
        nombre: _nombreCtrl.text,
        descripcion: _descCtrl.text,
        precio: double.parse(_precioCtrl.text), 
        stock: int.parse(_stockCtrl.text),
        categoria: _catCtrl.text,
        rutaImagen: _imgCtrl.text,
      );

      // 2. Decidimos: ¿Insertar o Actualizar?
      if (widget.producto == null) {
        await DatabaseHelper.instance.insertarProducto(modelo);
      } else {
        await DatabaseHelper.instance.actualizarProducto(modelo);
      }

      // 3. Cerramos la pantalla y volvemos a la lista
      Navigator.pop(context, true); // El "true" es para indicar que hubo cambios y la lista debe refrescarse
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.producto == null ? 'Nuevo Producto' : 'Editar Producto'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nombreCtrl,
                decoration: InputDecoration(labelText: 'Nombre del Producto'),
                validator: (val) => val!.isEmpty ? 'Campo obligatorio' : null,
              ),
              TextFormField(
                controller: _precioCtrl,
                keyboardType: TextInputType.number, 
                decoration: InputDecoration(labelText: 'Precio (S/.)', prefixText: 'S/ '),
                validator: (val) => val!.isEmpty ? 'Campo obligatorio' : null,
              ),
              TextFormField(
                controller: _stockCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Stock (Cantidad)'),
                validator: (val) => val!.isEmpty ? 'Campo obligatorio' : null,
              ),
              TextFormField(
                controller: _catCtrl,
                decoration: InputDecoration(labelText: 'Categoría (Ej: Industrial, Doméstica)'),
                validator: (val) => val!.isEmpty ? 'Campo obligatorio' : null,
              ),
              TextFormField(
                controller: _descCtrl,
                decoration: InputDecoration(labelText: 'Descripción (Opcional)'),
                maxLines: 2,
              ),
              TextFormField(
                controller: _imgCtrl,
                decoration: InputDecoration(labelText: 'URL de Imagen (Opcional)', prefixIcon: Icon(Icons.image)),
              ),
              SizedBox(height: 20),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _guardar,
                  icon: Icon(Icons.save),
                  label: Text('GUARDAR PRODUCTO'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}