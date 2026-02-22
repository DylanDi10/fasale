class Recordatorio {
  final int? id;
  final int usuarioId;
  final int? clienteId;
  final String? nombreCliente; // Para mostrarlo en la UI sin hacer otra consulta
  final DateTime fechaProgramada;
  final String descripcion;
  String estado;

  Recordatorio({
    this.id,
    required this.usuarioId,
    this.clienteId,
    this.nombreCliente,
    required this.fechaProgramada,
    required this.descripcion,
    this.estado = 'Pendiente',
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'usuario_id': usuarioId,
      'cliente_id': clienteId,
      'fecha_programada': fechaProgramada.toIso8601String(),
      'descripcion': descripcion,
      'estado': estado,
    };

    // Solo enviamos el ID si ya existe (para actualizaciones), 
    // si es nuevo (null), dejamos que Supabase lo genere automáticamente.
    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  factory Recordatorio.fromMap(Map<String, dynamic> map) {
    // Extraemos el nombre del cliente si viene en la consulta (Join)
    String? nombreCli;
    if (map['clientes'] != null && map['clientes']['nombre'] != null) {
      nombreCli = map['clientes']['nombre'];
    }

    return Recordatorio(
      id: map['id'],
      usuarioId: map['usuario_id'],
      clienteId: map['cliente_id'],
      nombreCliente: nombreCli,
      fechaProgramada: DateTime.parse(map['fecha_programada']),
      descripcion: map['descripcion'],
      estado: map['estado'] ?? 'Pendiente',
    );
  }
}