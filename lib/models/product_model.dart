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
  // --- CAMPOS MULTIMEDIA ---
  final String? linkPdf;
  final String? linkVideo;
  final String? linkFotos; // <-- NUEVO

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
      id: map['id'],
      nombre: map['nombre'],
      descripcion: map['descripcion'] ?? '',
      precio: (map['precio'] as num).toDouble(),
      stock: map['stock'] as int,
      urlImagen: map['url_imagen'],
      categoriaId: map['categoria_id'], 
      nombreCategoria: map['nombre_categoria'],
      marca: map['marca'],
      modelo: map['modelo'],
      submodelo: map['submodelo'],
      linkPdf: map['link_pdf'],
      linkVideo: map['link_video'],
      linkFotos: map['link_fotos'],
    );
  }
}