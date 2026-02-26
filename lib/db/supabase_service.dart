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

  // --- LOGIN HÍBRIDO PROFESIONAL ---
  Future<Usuario?> login(String correo, String password) async {
    try {
      // 1. Pasamos por el Portero de Máxima Seguridad de Supabase
      // Esto nos da el preciado Token (JWT) y el estado 'authenticated'
      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: correo,
        password: password,
      );

      // 2. Si el portero nos dejó entrar (la clave es correcta)...
      if (res.user != null) {
        
        // 3. Vamos a tu tabla 'usuarios' a buscar su ID interno y su ROL
        final response = await _supabase
            .from('usuarios')
            .select()
            .eq('correo', correo) // Compara el correo
            .maybeSingle();

        if (response != null) {
          return Usuario.fromMap(response); // Retorna tu usuario con el ID Entero (1, 2, 3...)
        }
      }
      return null;
    } catch (e) {
      // Si la contraseña está mal o el correo no existe, Supabase lanza un error
      print("Error de autenticación: $e");
      return null; 
    }
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
    try {
      await _supabase.from('clientes').delete().eq('id', id);
    } catch (e) {
      // Si el error es de Supabase y es exactamente el código de Llave Foránea
      if (e is PostgrestException && e.code == '23503') {
        throw Exception('No puedes eliminar a este cliente porque ya tiene cotizaciones registradas.');
      }
      // Para cualquier otro error (falla de internet, etc.)
      throw Exception('Error al eliminar el cliente: $e');
    }
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
  // --- BUSCADOR DE CLIENTES POR DNI/RUC (BLINDADO) ---
  Future<List<Cliente>> buscarClientesPorDocumento(String documento, {bool esAdmin = false}) async {
    int? targetId = await _getUsuarioActualId();
    if (targetId == null) return [];

    var query = _supabase
        .from('clientes')
        .select()
        .ilike('dni_ruc', '%$documento%'); // Búsqueda parcial

    // EL CANDADO: Si no es admin, solo busca en SU propia cartera
    if (!esAdmin) {
      query = query.eq('usuario_id', targetId);
    }

    final response = await query;
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

  // --- FILTROS DINÁMICOS ABSORBIDOS DE LOS PRODUCTOS ---
  Future<Map<String, List<String>>> obtenerFiltrosDinamicos() async {
    // Consultamos la vista rápida (Asegúrate de haber ejecutado el código SQL en Supabase)
    final response = await _supabase.from('vista_marcas_modelos').select();
    
    Map<String, List<String>> filtros = {};
    
    for (var fila in (response as List<dynamic>)) {
      String marca = fila['marca'].toString().trim();
      String modelo = fila['modelo'].toString().trim();
      
      if (!filtros.containsKey(marca)) {
        filtros[marca] = [];
      }
      if (!filtros[marca]!.contains(modelo)) {
        filtros[marca]!.add(modelo);
      }
    }
    return filtros;
  }

  // --- 3. BUSCADOR Y FILTRO UNIFICADO ---
  Future<List<Producto>> buscarYFiltrarProductos({
    required String query,
    required String marca,
    required String modelo,
    int? categoriaId, // <--- AÑADIMOS ESTO AQUÍ
  }) async {
    
    // Inicias tu consulta a la tabla productos
    var peticion = Supabase.instance.client.from('productos').select();
    // Filtro de Marca
    if (marca != 'Todas') {
      peticion = peticion.eq('marca', marca);
    }
    
    // Filtro de Modelo
    if (modelo != 'Todos') {
      peticion = peticion.eq('modelo', modelo);
    }

    // --- NUEVO: Filtro de Categoría ---
    if (categoriaId != null) {
      peticion = peticion.eq('categoria_id', categoriaId); // <-- Nombre exacto de la base de datos
    }

    // Buscador de texto (si lo tienes implementado con ilike)
    if (query.isNotEmpty) {
      peticion = peticion.ilike('nombre', '%$query%');
    }

    final response = await peticion;
    return (response as List).map((e) => Producto.fromMap(e)).toList();
  }
  // --- BUSCADOR GENERAL AUTOCOMPLETE (BLINDADO) ---
  Future<List<Cliente>> buscarClientesGeneral(String query, {bool esAdmin = false}) async {
    // Si está vacío, no devolvemos nada para no saturar
    if (query.isEmpty) return [];

    int? targetId = await _getUsuarioActualId();
    if (targetId == null) return [];

    var peticion = _supabase
        .from('clientes')
        .select()
        .or('nombre.ilike.%$query%,dni_ruc.ilike.%$query%'); // Busca en ambos campos

    // EL CANDADO: Filtramos estrictamente por su ID de vendedor
    if (!esAdmin) {
      peticion = peticion.eq('usuario_id', targetId);
    }

    final response = await peticion.limit(10); // Límite para no saturar memoria
    final data = response as List<dynamic>;
    return data.map((json) => Cliente.fromMap(json)).toList();
  }
  // --- 1. APROBAR COTIZACIÓN Y DESCONTAR STOCK ---
  // Añadimos el parámetro "esAdmin" a la función
Future<void> aprobarCotizacionYDescontarStock(Cotizacion coti, {required bool esAdmin}) async {
  
  // 1. Cambiamos el estado de la cotización en la nube a 'Aprobado'
  // ESTO SÍ LO PUEDEN HACER TODOS (Vendedores y Admin)
  await _supabase
      .from('cotizaciones')
      .update({'estado': 'Aprobado'})
      .eq('id', coti.id as Object);

  // 2. EL CANDADO: Solo si es Admin, entramos a descontar el stock
  if (esAdmin) {
    // Recorremos los productos vendidos para descontar el stock
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
    print("Stock descontado exitosamente por el Administrador");
  } else {
    print("Cotización aprobada por vendedor. El stock se mantiene intacto.");
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