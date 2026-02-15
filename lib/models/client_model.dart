class Cliente {
  final int? id;
  final String nombre;
  final String telefono;
  final String dniRuc;
  final String? direccion;

  Cliente({
    this.id,
    required this.nombre,
    required this.telefono,
    required this.dniRuc,
    this.direccion,
  });

  // Para guardar en DB
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'telefono': telefono,
      'dni_ruc': dniRuc,
      'direccion': direccion,
    };
  }

  // Para leer de DB
  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      id: map['id'],
      nombre: map['nombre'],
      telefono: map['telefono'],
      dniRuc: map['dni_ruc'],
      direccion: map['direccion'],
    );
  }
}