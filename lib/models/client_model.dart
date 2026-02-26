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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'telefono': telefono,
      'dni_ruc': dniRuc,
      'direccion': direccion,
    };
  }

  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      // 1. Cast explícito para evitar errores de tipo
      id: map['id'] as int?, 
      
      // 2. Si el nombre es nulo en BD, evitamos que rompa el 'required String'
      nombre: map['nombre']?.toString() ?? 'Sin nombre',
      
      // 3. Lo mismo para los otros campos obligatorios
      telefono: map['telefono']?.toString() ?? 'Sin teléfono',
      
      // 4. Mantenemos el nombre de la llave de tu BD ('dni_ruc') 
      dniRuc: map['dni_ruc']?.toString() ?? 'S/D', 
      
      // 5. Dirección es opcional (String?), así que solo nos aseguramos del tipo
      direccion: map['direccion'] as String?,
    );
  }
}