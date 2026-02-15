class Producto {
  final int? id; // Es '?' porque al crear uno nuevo, aún no tiene ID (la DB se lo pone)
  final String nombre;
  final String? descripcion;
  final double precio;
  final int stock;
  final String categoria;
  final String? rutaImagen;

  Producto({
    this.id,
    required this.nombre,
    this.descripcion,
    required this.precio,
    required this.stock,
    required this.categoria,
    this.rutaImagen,
  });

  // 1. TRADUCTOR: De Objeto a Mapa (Para GUARDAR en SQLite)
  // Convierte tu clase en un diccionario simple que SQLite entiende.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'stock': stock,
      'categoria': categoria,
      'ruta_imagen': rutaImagen, 
    };
  }

  // 2. TRADUCTOR: De Mapa a Objeto (Para LEER de SQLite)
  // Recibe los datos feos de la DB y te devuelve un Producto bonito para usar en Flutter.
  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id'],
      nombre: map['nombre'],
      descripcion: map['descripcion'],
      precio: map['precio'],
      stock: map['stock'],
      categoria: map['categoria'],
      rutaImagen: map['ruta_imagen'],
    );
  }
}