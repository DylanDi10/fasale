class Producto {
  final int? id;
  final String nombre;
  final String descripcion;
  final double precio;
  final int stock;
  final String? urlImagen;
  final int categoriaId; 
  final String? nombreCategoria;
  final String? marca;
  final String? modelo;
  final String? submodelo;
  final String? linkPdf;
  final String? linkVideo;
  final String? linkFotos;

  Producto({
    this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.stock,
    this.urlImagen,
    required this.categoriaId, 
    this.nombreCategoria,
    this.marca,
    this.modelo,
    this.submodelo,
    this.linkPdf,
    this.linkVideo,
    this.linkFotos,
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
      'marca': marca,
      'modelo': modelo,
      'submodelo': submodelo,
      'link_pdf': linkPdf,
      'link_video': linkVideo,
      'link_fotos': linkFotos,
    };
  }

  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id'] as int?,
      // Si el nombre no viene, ponemos un texto de advertencia en lugar de crashear
      nombre: map['nombre'] ?? 'Producto sin nombre',
      descripcion: map['descripcion'] ?? 'Sin descripción',
      // SEGURIDAD EN NÚMEROS: Convertimos a num primero y si es nulo, 0.0
      precio: (map['precio'] as num?)?.toDouble() ?? 0.0,
      stock: (map['stock'] as int?) ?? 0,
      urlImagen: map['url_imagen'] as String?,
      // Si falta la categoría, ponemos 0 (o un ID que sepas que no existe)
      categoriaId: (map['categoria_id'] as int?) ?? 0, 
      nombreCategoria: map['nombre_categoria'] as String?,
      marca: map['marca'] as String? ?? 'Sin marca',
      modelo: map['modelo'] as String? ?? 'Sin modelo',
      submodelo: map['submodelo'] as String?,
      linkPdf: map['link_pdf'] as String?,
      linkVideo: map['link_video'] as String?,
      linkFotos: map['link_fotos'] as String?,
    );
  }
}