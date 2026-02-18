import 'dart:convert';

class Cotizacion {
  final int? id;
  final int clienteId;
  final int? usuarioId;
  final String fecha;
  final double total;
  final String estado; 
  final List<Map<String, dynamic>> productos;

  Cotizacion({
    this.id,
    required this.clienteId,
    this.usuarioId,
    required this.fecha,
    required this.total,
    this.estado = 'Pendiente', 
    required this.productos,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'usuario_id': usuarioId,
      'fecha': fecha,
      'total': total,
      'estado': estado, 
      'productos_json': jsonEncode(productos),
    };
  }

  factory Cotizacion.fromMap(Map<String, dynamic> map) {
    return Cotizacion(
      id: map['id'],
      clienteId: map['cliente_id'],
      usuarioId: map['usuario_id'],
      fecha: map['fecha'],
      total: (map['total'] as num).toDouble(),
      estado: map['estado'] ?? 'Pendiente', 
      productos: List<Map<String, dynamic>>.from(
        jsonDecode(map['productos_json']),
      ),
    );
  }
}