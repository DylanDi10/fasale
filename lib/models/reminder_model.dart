class Recordatorio {
  final int? id;
  final String titulo;
  final DateTime fechaHora; 
  final int clienteId;
  final bool completado; 

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
      'fecha_hora': fechaHora.toIso8601String(), 
      'cliente_id': clienteId,
      'completado': completado ? 1 : 0,
    };
  }

  factory Recordatorio.fromMap(Map<String, dynamic> map) {
    return Recordatorio(
      id: map['id'],
      titulo: map['titulo'],
      fechaHora: DateTime.parse(map['fecha_hora']), 
      clienteId: map['cliente_id'],
      completado: map['completado'] == 1, 
    );
  }
}