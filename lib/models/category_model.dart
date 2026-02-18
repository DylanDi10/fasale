class Categoria {
  final int? id;
  final String nombre;

  Categoria({this.id, required this.nombre});

  Map<String, dynamic> toMap() {
    return {'id': id, 'nombre': nombre};
  }

  factory Categoria.fromMap(Map<String, dynamic> map) {
    return Categoria(
      id: map['id'],
      nombre: map['nombre'],
    );
  }
}