import 'package:cotizaciones_app/models/category_model.dart';
import 'package:cotizaciones_app/models/quote_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/client_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('sewing_sales_pro_v3.db'); 
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    print(" BASE DE DATOS PRO: $path");
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    await db.execute('''
      CREATE TABLE usuarios ( 
        id $idType, 
        username $textType,
        password $textType,
        rol $textType 
      )
    ''');

    await db.execute('''
      CREATE TABLE categorias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL
      )
    ''');

    await db.insert('categorias', {'nombre': 'Recta Industrial'});
    await db.insert('categorias', {'nombre': 'Remalladora'});
    await db.insert('categorias', {'nombre': 'Recubridora'});
    await db.insert('categorias', {'nombre': 'Cortadora'});
    await db.insert('categorias', {'nombre': 'Bordadora'});
    await db.insert('categorias', {'nombre': 'Repuestos'});

    await db.execute('''
          CREATE TABLE productos ( 
            id $idType, 
            nombre $textType,
            descripcion TEXT,
            precio $realType,
            stock $intType,
            url_imagen TEXT,
            categoria_id INTEGER, 
            FOREIGN KEY (categoria_id) REFERENCES categorias (id)
          )
        ''');

    await db.execute('''
      CREATE TABLE clientes ( 
        id $idType, 
        nombre $textType,
        telefono $textType,
        dni_ruc $textType,
        direccion TEXT,
        usuario_id INTEGER, 
        FOREIGN KEY (usuario_id) REFERENCES usuarios (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE cotizaciones ( 
        id $idType, 
        cliente_id $intType,
        usuario_id $intType, 
        fecha $textType,
        total $realType,
        estado $textType,
        productos_json TEXT, 
        FOREIGN KEY (cliente_id) REFERENCES clientes (id),
        FOREIGN KEY (usuario_id) REFERENCES usuarios (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE recordatorios ( 
        id $idType, 
        titulo $textType,
        fecha_hora $textType, 
        cliente_id $intType,
        completado $intType,
        FOREIGN KEY (cliente_id) REFERENCES clientes (id)
      )
    ''');
    
    // Usuarios por defecto
    await db.insert('usuarios', {
      'username': 'admin',
      'password': '123',
      'rol': 'admin'
    });

    await db.insert('usuarios', {
      'username': 'vendedor1',
      'password': '123', 
      'rol': 'vendedor'
    });

    await db.insert('usuarios', {
      'username': 'vendedor2',
      'password': '123', 
      'rol': 'vendedor'
    });
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }

  Future<int?> _getUsuarioActualId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('usuario_id');
  }

  // --- USUARIOS ---

  Future<int> registrarUsuario(Usuario user) async {
    final db = await instance.database;
    return await db.insert('usuarios', user.toMap());
  }

  Future<Usuario?> login(String user, String password) async {
    final db = await instance.database;
    final maps = await db.query(
      'usuarios',
      where: 'username = ? AND password = ?',
      whereArgs: [user, password],
    );

    if (maps.isNotEmpty) {
      return Usuario.fromMap(maps.first);
    } else {
      return null;
    }
  }

  // NUEVO: Obtener lista de todos los vendedores (para el Admin)
  Future<List<Usuario>> obtenerTodosLosUsuarios() async {
    final db = await instance.database;
    // Traemos a todos los que NO sean admin (o todos si prefieres)
    final maps = await db.query('usuarios', where: "rol != 'admin'"); 
    return maps.map((json) => Usuario.fromMap(json)).toList();
  }

  // --- PRODUCTOS ---

  Future<int> insertarProducto(Producto producto) async {
    final db = await instance.database;
    return await db.insert('productos', producto.toMap());
  }

  Future<List<Producto>> obtenerProductos() async {
    final db = await instance.database;
    final maps = await db.query('productos'); 
    return maps.map((json) => Producto.fromMap(json)).toList();
  }

  Future<List<Producto>> obtenerProductosConCategoria() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT 
        p.*,
        c.nombre as nombre_categoria
      FROM productos p
      INNER JOIN categorias c ON p.categoria_id = c.id
    ''');

    return result.map((json) => Producto.fromMap(json)).toList();
  }

  Future<List<Producto>> buscarProductos(String query) async {
    final db = await instance.database;
    final maps = await db.query(
      'productos',
      where: 'nombre LIKE ?', 
      whereArgs: ['%$query%'], 
    );
    return maps.map((json) => Producto.fromMap(json)).toList();
  }
  
  Future<int> actualizarProducto(Producto producto) async {
    final db = await instance.database;
    return await db.update(
      'productos',
      producto.toMap(),
      where: 'id = ?',
      whereArgs: [producto.id],
    );
  }
  
  Future<int> eliminarProducto(int id) async {
    final db = await instance.database;
    return await db.delete('productos', where: 'id = ?', whereArgs: [id]);
  }

  // --- CLIENTES ---

  Future<int> insertarCliente(Cliente cliente) async {
    final db = await instance.database;
    final userId = await _getUsuarioActualId();

    final map = cliente.toMap();
    if (userId != null) {
      map['usuario_id'] = userId; 
    }

    return await db.insert('clientes', map);
  }

  Future<List<Cliente>> obtenerClientes({int? usuarioIdEspecifico, bool verTodo = false}) async {
    final db = await instance.database;
    
    // 1. Si 'verTodo' es true (para el Admin), no filtramos por ID.
    if (verTodo) {
      final maps = await db.query('clientes', orderBy: 'nombre ASC');
      return maps.map((json) => Cliente.fromMap(json)).toList();
    }

    // 2. Si no, aplicamos el filtro normal para vendedores.
    int? targetId = usuarioIdEspecifico ?? await _getUsuarioActualId();
    if (targetId == null) return [];

    final maps = await db.query(
      'clientes',
      where: 'usuario_id = ?',
      whereArgs: [targetId],
      orderBy: 'nombre ASC'
    );
    return maps.map((json) => Cliente.fromMap(json)).toList();
  }

  Future<int> actualizarCliente(Cliente cliente) async {
    final db = await instance.database;
    return await db.update(
      'clientes',
      cliente.toMap(),
      where: 'id = ?',
      whereArgs: [cliente.id],
    );
  }

  Future<int> eliminarCliente(int id) async {
    final db = await instance.database;
    return await db.delete('clientes', where: 'id = ?', whereArgs: [id]);
  }

  // --- COTIZACIONES / VENTAS ---

// MODIFICADO PARA MODO COTIZADOR (NO DESCUENTA STOCK)
  Future<int> crearVenta(Cotizacion cotizacion) async {
    final db = await instance.database;
    final userId = await _getUsuarioActualId();

    return await db.transaction((txn) async {
      final mapVenta = cotizacion.toMap();
      
      if (userId != null) {
        mapVenta['usuario_id'] = userId; 
      }

      // 1. Guardamos la Cotización
      int idVenta = await txn.insert('cotizaciones', mapVenta);

      // 2. ¿Descontar Stock?
      // El stock se mantiene intacto aunque generes mil cotizaciones.
      
      /* --- BLOQUE DESACTIVADO PARA QUE NO BAJE EL STOCK ---
      for (var item in cotizacion.productos) {
        int idProd = item['id'];
        int cantidadVendida = item['cantidad'];

        List<Map> resultado = await txn.query(
          'productos',
          columns: ['stock'],
          where: 'id = ?',
          whereArgs: [idProd],
        );
        
        if (resultado.isNotEmpty) {
          int stockActual = resultado.first['stock'] as int;
          int nuevoStock = stockActual - cantidadVendida; 

          await txn.update(
            'productos',
            {'stock': nuevoStock},
            where: 'id = ?',
            whereArgs: [idProd],
          );
        }
      }
      ----------------------------------------------------
      */

      return idVenta; 
    });
  }

  Future<List<Cotizacion>> obtenerVentas({int? usuarioIdEspecifico}) async {
    final db = await instance.database;
    
    int? targetId = usuarioIdEspecifico ?? await _getUsuarioActualId();

    if (targetId == null) return [];

    final maps = await db.query(
      'cotizaciones', 
      where: 'usuario_id = ?',
      whereArgs: [targetId],
      orderBy: 'fecha DESC'
    ); 
    return maps.map((json) => Cotizacion.fromMap(json)).toList();
  }

  // MODIFICADO: Igual aquí, acepta ID opcional para calcular total de otros
  Future<double> obtenerTotalVentas({int? usuarioIdEspecifico}) async {
    final db = await instance.database;
    int? targetId = usuarioIdEspecifico ?? await _getUsuarioActualId();

    if (targetId == null) return 0.0;

    final result = await db.rawQuery(
      'SELECT SUM(total) as total FROM cotizaciones WHERE usuario_id = ?', 
      [targetId]
    );
    
    if (result.isNotEmpty && result.first['total'] != null) {
      return result.first['total'] as double;
    } else {
      return 0.0;
    }
  }

  Future<void> eliminarTodasLasVentas() async {
    final db = await instance.database;
    final userId = await _getUsuarioActualId();
    await db.delete('cotizaciones', where: 'usuario_id = ?', whereArgs: [userId]); 
  }

  Future<List<Categoria>> obtenerCategorias() async {
    final db = await instance.database;
    final maps = await db.query('categorias', orderBy: 'nombre ASC');
    return maps.map((json) => Categoria.fromMap(json)).toList();
  }
  // --- FUNCIÓN PARA EDITAR UNA COTIZACIÓN ---
  Future<int> actualizarCotizacion(Cotizacion coti) async {
    final db = await instance.database;
    return await db.update(
      'cotizaciones',
      coti.toMap(),
      where: 'id = ?',
      whereArgs: [coti.id],
    );
  }
}