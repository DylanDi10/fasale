class Producto {
  final int? id;
  final String nombre;
  final String descripcion;
  final double precio;
  final int stock;
  final String? urlImagen;
  final int categoriaId; 
  final String? nombreCategoria; 

  Producto({
    this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.stock,
    this.urlImagen,
    required this.categoriaId, 
    this.nombreCategoria, 
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'stock': stock,
      'url_imagen': urlImagen,
      'categoria_id': categoriaId, 
    };
  }

  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id'],
      nombre: map['nombre'],
      descripcion: map['descripcion'],
      precio: map['precio'],
      stock: map['stock'],
      urlImagen: map['url_imagen'],
      categoriaId: map['categoria_id'], 
      nombreCategoria: map['nombre_categoria'],
    );
  }
}