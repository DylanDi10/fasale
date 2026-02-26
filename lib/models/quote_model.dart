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
      // Si por alguna razón productos fuera nulo, enviamos un array vacío
      'productos_json': jsonEncode(productos),
    };
  }

  factory Cotizacion.fromMap(Map<String, dynamic> map) {
    return Cotizacion(
      id: map['id'] as int?,
      // Si falta el cliente_id, ponemos 0 (asumiendo que manejas el error en UI)
      clienteId: (map['cliente_id'] as int?) ?? 0,
      usuarioId: map['usuario_id'] as int?,
      fecha: map['fecha']?.toString() ?? DateTime.now().toString(),
      
      // SEGURIDAD EN DINERO: Evita crash si el total es nulo
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      
      estado: map['estado']?.toString() ?? 'Pendiente', 
      
      // SEGURIDAD EN JSON: El punto más debil de las cotizaciones
      productos: _descodificarProductos(map['productos_json']),
    );
  }

  // Función privada para procesar el JSON sin riesgo de crash
  static List<Map<String, dynamic>> _descodificarProductos(dynamic fuente) {
    if (fuente == null || fuente.toString().isEmpty) return [];
    try {
      final decoded = jsonDecode(fuente.toString());
      if (decoded is List) {
        return List<Map<String, dynamic>>.from(decoded);
      }
      return [];
    } catch (e) {
      // Si el JSON está corrupto, devolvemos lista vacía en lugar de cerrar la app
      return [];
    }
  }
}