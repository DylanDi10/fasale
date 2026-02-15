import 'dart:convert'; // Necesario para jsonEncode y jsonDecode

class Cotizacion {
  final int? id;
  final int clienteId;
  final int vendedorId;
  final DateTime fecha;
  final double total;
  final List<dynamic> productos; // Guardaremos la lista de items

  Cotizacion({
    this.id,
    required this.clienteId,
    required this.vendedorId,
    required this.fecha,
    required this.total,
    required this.productos,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'vendedor_id': vendedorId,
      'fecha': fecha.toIso8601String(),
      'total': total,
      // TRUCO: Convertimos la lista de productos a un TEXTO JSON
      'productos_json': jsonEncode(productos), 
    };
  }

  factory Cotizacion.fromMap(Map<String, dynamic> map) {
    return Cotizacion(
      id: map['id'],
      clienteId: map['cliente_id'],
      vendedorId: map['vendedor_id'],
      fecha: DateTime.parse(map['fecha']),
      total: map['total'],
      // TRUCO: Convertimos el TEXTO JSON de vuelta a una Lista
      productos: jsonDecode(map['productos_json']),
    );
  }
}