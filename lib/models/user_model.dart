class Usuario {
  final int? id;
  final String correo;
  final String rol; 
  final String nombreCompleto; // <--- 1. NUEVA VARIABLE

  Usuario({
    this.id,
    required this.correo,
    required this.rol,
    required this.nombreCompleto, // <--- 2. LA PEDIMOS AQUÍ
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'correo': correo,
      'rol': rol,
      // Cambia 'nombre_completa' por 'nombre_completo' si lo corregiste en Supabase
      'nombre_completa': nombreCompleto, 
    };
  }

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'],
      correo: map['correo'],
      rol: map['rol'],
      // Si el campo está vacío en la BD, pone un texto por defecto para no crashear
      nombreCompleto: map['nombre_completa'] ?? map['nombre_completo'] ?? 'Usuario Sin Nombre', 
    );
  }
}