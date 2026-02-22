import 'package:cotizaciones_app/models/recordatorio_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/client_model.dart';
import '../models/quote_model.dart';
import '../models/category_model.dart';
import '../models/recordatorio_model.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._init();
  SupabaseService._init();

  final _supabase = Supabase.instance.client;

  // Obtener ID del usuario logueado en SharedPreferences
  Future<int?> _getUsuarioActualId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('usuario_id');
  }

  // --- USUARIOS ---

  Future<void> registrarUsuario(Usuario user) async {
    final map = user.toMap();
    map.remove('id');
    await _supabase.from('usuarios').insert(map);
  }

  Future<Usuario?> login(String user, String password) async {
    final response = await _supabase
        .from('usuarios')
        .select()
        .eq('username', user)
        .eq('password', password)
        .maybeSingle();

    if (response != null) {
      return Usuario.fromMap(response);
    }
    return null;
  }

  // Obtener lista de todos los vendedores (para el Admin)
  Future<List<Usuario>> obtenerTodosLosUsuarios() async {
    final response = await _supabase
        .from('usuarios')
        .select()
        .neq('rol', 'admin');

    final data = response as List<dynamic>;
    return data.map((json) => Usuario.fromMap(json)).toList();
  }

  // --- PRODUCTOS ---

  Future<void> insertarProducto(Producto producto) async {
    final map = producto.toMap();
    map.remove('id');
    await _supabase.from('productos').insert(map);
  }

  Future<List<Producto>> obtenerProductos() async {
    final response = await _supabase.from('productos').select();
    final data = response as List<dynamic>;
    return data.map((json) => Producto.fromMap(json)).toList();
  }

  // Obtener productos con el nombre de su categoría asociada
  Future<List<Producto>> obtenerProductosConCategoria() async {
    final response = await _supabase.from('productos').select('*, categorias(nombre)');
    
    final data = response as List<dynamic>;
    return data.map((json) {
      // Mapeo manual para adaptar la respuesta anidada de Supabase al modelo
      final map = Map<String, dynamic>.from(json);
      if (map['categorias'] != null) {
        map['nombre_categoria'] = map['categorias']['nombre'];
      }
      return Producto.fromMap(map);
    }).toList();
  }

  // Búsqueda de productos por nombre
  Future<List<Producto>> buscarProductos(String query) async {
    final response = await _supabase
        .from('productos')
        .select()
        .ilike('nombre', '%$query%'); // ilike es case-insensitive

    final data = response as List<dynamic>;
    return data.map((json) => Producto.fromMap(json)).toList();
  }

  Future<void> actualizarProducto(Producto producto) async {
    await _supabase
        .from('productos')
        .update(producto.toMap())
        .eq('id', producto.id as Object);
  }

  Future<void> eliminarProducto(int id) async {
    await _supabase.from('productos').delete().eq('id', id);
  }

  // --- CLIENTES ---
  // Obtener un solo cliente por su ID
  Future<Cliente?> obtenerClientePorId(int id) async {
    final response = await _supabase
        .from('clientes')
        .select()
        .eq('id', id)
        .maybeSingle(); // Trae uno o null si no existe

    if (response == null) return null;
    return Cliente.fromMap(response);
  }

  Future<void> insertarCliente(Cliente cliente) async {
    final map = cliente.toMap();
    map.remove('id');
    
    final userId = await _getUsuarioActualId();
    if (userId != null) {
      map['usuario_id'] = userId;
    }

    await _supabase.from('clientes').insert(map);
  }

  Future<List<Cliente>> obtenerClientes({int? usuarioIdEspecifico, bool verTodo = false}) async {
    if (verTodo) {
      final response = await _supabase.from('clientes').select().order('nombre', ascending: true);
      final data = response as List<dynamic>;
      return data.map((json) => Cliente.fromMap(json)).toList();
    }

    int? targetId = usuarioIdEspecifico ?? await _getUsuarioActualId();
    if (targetId == null) return [];

    final response = await _supabase
        .from('clientes')
        .select()
        .eq('usuario_id', targetId)
        .order('nombre', ascending: true);

    final data = response as List<dynamic>;
    return data.map((json) => Cliente.fromMap(json)).toList();
  }

  Future<void> actualizarCliente(Cliente cliente) async {
    await _supabase
        .from('clientes')
        .update(cliente.toMap())
        .eq('id', cliente.id as Object);
  }

  Future<void> eliminarCliente(int id) async {
    await _supabase.from('clientes').delete().eq('id', id);
  }

  // --- COTIZACIONES / VENTAS ---

  Future<void> crearVenta(Cotizacion cotizacion) async {
    final mapVenta = cotizacion.toMap();
    mapVenta.remove('id');
    
    final userId = await _getUsuarioActualId();
    if (userId != null) {
      mapVenta['usuario_id'] = userId;
    }

    await _supabase.from('cotizaciones').insert(mapVenta);
  }

  Future<List<Cotizacion>> obtenerVentas({int? usuarioIdEspecifico}) async {
    int? targetId = usuarioIdEspecifico ?? await _getUsuarioActualId();
    if (targetId == null) return [];

    final response = await _supabase
        .from('cotizaciones')
        .select()
        .eq('usuario_id', targetId)
        .order('fecha', ascending: false);

    final data = response as List<dynamic>;
    return data.map((json) => Cotizacion.fromMap(json)).toList();
  }

  // Calcular total de ventas por usuario
  Future<double> obtenerTotalVentas({int? usuarioIdEspecifico}) async {
    int? targetId = usuarioIdEspecifico ?? await _getUsuarioActualId();
    if (targetId == null) return 0.0;

    final response = await _supabase
        .from('cotizaciones')
        .select('total')
        .eq('usuario_id', targetId);

    final data = response as List<dynamic>;
    if (data.isEmpty) return 0.0;

    // Sumatoria de los totales en Dart
    double totalSum = data.fold(0.0, (sum, item) {
      final value = item['total'];
      return sum + (value != null ? (value as num).toDouble() : 0.0);
    });

    return totalSum;
  }

  Future<void> eliminarTodasLasVentas() async {
    final userId = await _getUsuarioActualId();
    if (userId != null) {
      await _supabase.from('cotizaciones').delete().eq('usuario_id', userId);
    }
  }

  Future<void> actualizarCotizacion(Cotizacion coti) async {
    await _supabase
        .from('cotizaciones')
        .update(coti.toMap())
        .eq('id', coti.id as Object);
  }

  // --- CATEGORIAS ---

  Future<List<Categoria>> obtenerCategorias() async {
    final response = await _supabase.from('categorias').select().order('nombre', ascending: true);
    final data = response as List<dynamic>;
    return data.map((json) => Categoria.fromMap(json)).toList();
  }
  // --- BUSCADOR DE CLIENTES POR DNI/RUC ---
  Future<List<Cliente>> buscarClientesPorDocumento(String documento) async {
    final response = await _supabase
        .from('clientes')
        .select()
        .ilike('dni_ruc', '%$documento%'); // Búsqueda parcial

    final data = response as List<dynamic>;
    return data.map((json) => Cliente.fromMap(json)).toList();
  }

  // --- FILTRO DE INVENTARIO (MARCA, MODELO, SUBMODELO) ---
  Future<List<Producto>> obtenerInventarioFiltrado({
    String? marca,
    String? modelo,
  }) async {
    var query = _supabase.from('productos').select();

    if (marca != null && marca != 'Todas') {
      query = query.eq('marca', marca);
    }
    if (modelo != null && modelo != 'Todos') {
      query = query.eq('modelo', modelo);
    }

    final response = await query;
    final data = response as List<dynamic>;
    return data.map((json) => Producto.fromMap(json)).toList();
  }

  // Para llenar los filtros automáticos
  Future<List<String>> obtenerMarcasUnicas() async {
    final response = await _supabase.from('productos').select('marca');
    final data = response as List<dynamic>;
    final marcas = data.map((item) => item['marca']?.toString() ?? 'Sin Marca').toSet().toList();
    marcas.sort();
    return ['Todas', ...marcas];
  }
  // --- 1. CATÁLOGO DE MARCAS ---
  Future<List<Map<String, dynamic>>> obtenerMarcasCatalogo() async {
    final response = await _supabase.from('marcas').select('id, nombre').order('nombre');
    return List<Map<String, dynamic>>.from(response);
  }

  // --- 2. MODELOS DEPENDIENTES DE LA MARCA ---
  Future<List<String>> obtenerModelosPorMarca(int marcaId) async {
    final response = await _supabase
        .from('modelos')
        .select('nombre')
        .eq('marca_id', marcaId)
        .order('nombre');
    
    final data = List<Map<String, dynamic>>.from(response);
    return data.map((item) => item['nombre'].toString()).toList();
  }

  // --- 3. BUSCADOR Y FILTRO UNIFICADO ---
  Future<List<Producto>> buscarYFiltrarProductos({
    required String query,
    required String marca,
    required String modelo,
  }) async {
    var peticion = _supabase.from('productos').select();

    // Si hay texto en el buscador, filtramos por nombre exacto o parcial
    if (query.isNotEmpty) {
      peticion = peticion.ilike('nombre', '%$query%');
    }
    // Si hay marca seleccionada (y no es 'Todas')
    if (marca != 'Todas') {
      peticion = peticion.eq('marca', marca);
    }
    // Si hay modelo seleccionado (y no es 'Todos')
    if (modelo != 'Todos') {
      peticion = peticion.eq('modelo', modelo);
    }

    final response = await peticion;
    final data = response as List<dynamic>;
    return data.map((json) => Producto.fromMap(json)).toList();
  }
  Future<List<Cliente>> buscarClientesGeneral(String query) async {
    // Si está vacío, no devolvemos nada para no saturar
    if (query.isEmpty) return [];

    final response = await _supabase
        .from('clientes')
        .select()
        .or('nombre.ilike.%$query%,dni_ruc.ilike.%$query%') // Busca en ambos campos
        .limit(10); // Solo traemos los 10 mejores resultados para no gastar memoria

    final data = response as List<dynamic>;
    return data.map((json) => Cliente.fromMap(json)).toList();
  }
  // --- 1. APROBAR COTIZACIÓN Y DESCONTAR STOCK ---
  Future<void> aprobarCotizacionYDescontarStock(Cotizacion coti) async {
    // 1. Cambiamos el estado de la cotización en la nube a 'Aprobado'
    await _supabase
        .from('cotizaciones')
        .update({'estado': 'Aprobado'})
        .eq('id', coti.id as Object);

    // 2. Recorremos los productos vendidos para descontar el stock
    for (var item in coti.productos) {
      final int productoId = item['id'];
      final int cantidadVendida = item['cantidad'];

      // Traemos el stock actual de ese producto
      final response = await _supabase
          .from('productos')
          .select('stock')
          .eq('id', productoId)
          .single(); // single() porque solo buscamos un producto

      int stockActual = response['stock'] as int;
      int nuevoStock = stockActual - cantidadVendida;

      // Actualizamos el nuevo stock en la base de datos
      await _supabase
          .from('productos')
          .update({'stock': nuevoStock})
          .eq('id', productoId);
    }
  }

  // --- 2. FILTRAR VENTAS POR DÍA EXACTO ---
  Future<List<Cotizacion>> obtenerVentasPorDia(DateTime fecha, {int? usuarioId}) async {
    int? targetId = usuarioId ?? await _getUsuarioActualId();
    if (targetId == null) return [];

    // Creamos el rango de horas: Desde las 00:00:00 hasta las 23:59:59 de ese día
    final inicioDia = DateTime(fecha.year, fecha.month, fecha.day).toString();
    final finDia = DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59).toString();

    final response = await _supabase
        .from('cotizaciones')
        .select()
        .eq('usuario_id', targetId)
        .gte('fecha', inicioDia) // gte = Mayor o igual que (00:00 hrs)
        .lte('fecha', finDia)    // lte = Menor o igual que (23:59 hrs)
        .order('fecha', ascending: false);

    final data = response as List<dynamic>;
    return data.map((json) => Cotizacion.fromMap(json)).toList();
  }
  // ==========================================================
  //                MÓDULO DE RECORDATORIOS (CRM)
  // ==========================================================

  // 1. Obtener los recordatorios de un vendedor específico
  Future<List<Recordatorio>> obtenerRecordatorios(int usuarioId) async {
    // Hacemos un "Join" para traer la información del recordatorio + el nombre del cliente
    final response = await _supabase
        .from('recordatorios')
        .select('*, clientes(nombre)')
        .eq('usuario_id', usuarioId)
        .order('fecha_programada', ascending: true); // Los más próximos primero

    final data = response as List<dynamic>;
    return data.map((json) => Recordatorio.fromMap(json)).toList();
  }

  // 2. Crear un nuevo recordatorio
  Future<void> insertarRecordatorio(Recordatorio recordatorio) async {
    await _supabase.from('recordatorios').insert(recordatorio.toMap());
  }

  // 3. Actualizar el estado (Ej: Cambiar de 'Pendiente' a 'Completado')
  Future<void> actualizarEstadoRecordatorio(int id, String nuevoEstado) async {
    await _supabase
        .from('recordatorios')
        .update({'estado': nuevoEstado})
        .eq('id', id);
  }

  // 4. Eliminar un recordatorio (Por si se equivocó al crearlo)
  Future<void> eliminarRecordatorio(int id) async {
    await _supabase.from('recordatorios').delete().eq('id', id);
  }

  Future<void> importarProductosMasivos(List<Producto> productos) async {
  // Convertimos cada objeto Producto a un Mapa que Supabase entienda
  final datos = productos.map((p) => p.toMap()).toList();
  
  // Quitamos el 'id' de cada mapa para que Supabase genere IDs nuevos automáticamente
  for (var item in datos) {
    item.remove('id');
  }

  await _supabase.from('productos').insert(datos);
}
// --- VACIAR INVENTARIO (PELIGROSO) ---
  Future<void> eliminarTodosLosProductos() async {
    try {
      // El filtro 'gt' (greater than) asegura que borre todos los IDs mayores a 0
      await _supabase.from('productos').delete().gt('id', 0);
    } catch (e) {
      print("Error al vaciar productos: $e");
      throw e;
    }
  }
  
}