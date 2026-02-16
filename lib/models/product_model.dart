class Producto {
  final int? id; 
  final String nombre;
  final String? descripcion;
  final double precio;
  final int stock;
  final String categoria;
  final String? urlImagen;

  Producto({
    this.id,
    required this.nombre,
    this.descripcion,
    required this.precio,
    required this.stock,
    required this.categoria,
    this.urlImagen,
  });


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'stock': stock,
      'categoria': categoria,
      'url_imagen': urlImagen, 
    };
  }


  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id'],
      nombre: map['nombre'],
      descripcion: map['descripcion'],
      precio: map['precio'],
      stock: map['stock'],
      categoria: map['categoria'],
      urlImagen: map['url_imagen'],
    );
  }
}