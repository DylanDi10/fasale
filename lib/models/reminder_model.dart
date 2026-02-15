class Recordatorio {
  final int? id;
  final String titulo;
  final DateTime fechaHora; // Ojo: Aquí usamos DateTime
  final int clienteId;
  final bool completado; // 1 es true, 0 es false

  Recordatorio({
    this.id,
    required this.titulo,
    required this.fechaHora,
    required this.clienteId,
    this.completado = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'fecha_hora': fechaHora.toIso8601String(), // Convierte Fecha -> Texto
      'cliente_id': clienteId,
      'completado': completado ? 1 : 0, // Convierte Boolean -> Número
    };
  }

  factory Recordatorio.fromMap(Map<String, dynamic> map) {
    return Recordatorio(
      id: map['id'],
      titulo: map['titulo'],
      fechaHora: DateTime.parse(map['fecha_hora']), // Convierte Texto -> Fecha
      clienteId: map['cliente_id'],
      completado: map['completado'] == 1, // Convierte Número -> Boolean
    );
  }
}