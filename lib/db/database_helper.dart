import 'package:cotizaciones_app/models/quote_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/client_model.dart';


class DatabaseHelper {
  // Patrón Singleton: Para que solo haya UNA conexión a la base de datos en toda la app
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Si la base de datos ya existe, la devuelve. Si no, la crea.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('sewing_sales.db');
    return _database!;
  }

  // Configuración inicial (nombre del archivo y versión)
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  // Aquí creamos las tablas. Esto se ejecuta SOLO la primera vez que abres la app.
  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    // 1. Tabla USUARIOS (Para el Login)
    await db.execute('''
      CREATE TABLE usuarios ( 
        id $idType, 
        username $textType,
        password $textType,
        rol $textType 
      )
    ''');

    // 2. Tabla PRODUCTOS (Inventario)
    await db.execute('''
      CREATE TABLE productos ( 
        id $idType, 
        nombre $textType,
        descripcion TEXT,
        precio $realType,
        stock $intType,
        categoria $textType,
        ruta_imagen TEXT 
      )
    ''');

    // 3. Tabla CLIENTES (Tu cartera)
    await db.execute('''
      CREATE TABLE clientes ( 
        id $idType, 
        nombre $textType,
        telefono $textType,
        dni_ruc $textType,
        direccion TEXT
      )
    ''');

    // 4. Tabla COTIZACIONES (Historial de Ventas)
    // Truco para ahorrar tiempo: 'productos_json' guardará toda la lista de productos
    // en formato texto (JSON) en lugar de crear otra tabla compleja de relaciones.
    await db.execute('''
      CREATE TABLE cotizaciones ( 
        id $idType, 
        cliente_id $intType,
        vendedor_id $intType,
        fecha $textType,
        total $realType,
        productos_json TEXT, 
        FOREIGN KEY (cliente_id) REFERENCES clientes (id),
        FOREIGN KEY (vendedor_id) REFERENCES usuarios (id)
      )
    ''');

    // 5. Tabla RECORDATORIOS (Para tu Calendario)
    // 'fecha_hora': Guardaremos formato ISO8601 (ej: "2026-02-13T16:00:00")
    // Es lo más fácil para que el calendario lo lea.
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
    
    // OPCIONAL: Insertar usuario Admin por defecto para poder entrar
    await db.insert('usuarios', {
      'username': 'admin',
      'password': 'contra', 
      'rol': 'admin'
    });
  }

  // Método para cerrar la base de datos (buenas prácticas)
  Future close() async {
    final db = await instance.database;
    db.close();
  }



  // --- MÉTODOS DE USUARIO ---
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

  // --- MÉTODOS DE PRODUCTOS ---
  Future<int> insertarProducto(Producto producto) async {
    final db = await instance.database;
    return await db.insert('productos', producto.toMap());
  }

  Future<List<Producto>> obtenerProductos() async {
    final db = await instance.database;
    final maps = await db.query('productos'); 
    return maps.map((json) => Producto.fromMap(json)).toList();
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
    return await db.delete(
      'productos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- MÉTODOS DE CLIENTES ---
  Future<int> insertarCliente(Cliente cliente) async {
    final db = await instance.database;
    return await db.insert('clientes', cliente.toMap());
  }

  Future<List<Cliente>> obtenerClientes() async {
    final db = await instance.database;
    final maps = await db.query('clientes', orderBy: 'nombre ASC'); 
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
    return await db.delete(
      'clientes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- MÉTODOS DE VENTAS (COTIZACIONES) ---

  // Nueva Venta con Transacción (Seguridad total)
  Future<int> crearVenta(Cotizacion cotizacion) async {
    final db = await instance.database;
    
    return await db.transaction((txn) async {
      // 1. Guardar la cabecera de la venta (Quién compró, fecha, total)
      int idVenta = await txn.insert('cotizaciones', cotizacion.toMap());

      // 2. Recorrer los productos vendidos y restar stock
      // La lista 'productos' viene así: [{'id': 1, 'cantidad': 2}, ...]
      for (var item in cotizacion.productos) {
        int idProd = item['id'];
        int cantidadVendida = item['cantidad'];

        // A. Obtener stock actual
        List<Map> resultado = await txn.query(
          'productos',
          columns: ['stock'],
          where: 'id = ?',
          whereArgs: [idProd],
        );
        
        if (resultado.isNotEmpty) {
          int stockActual = resultado.first['stock'] as int;
          int nuevoStock = stockActual - cantidadVendida;

          // B. Actualizar stock
          await txn.update(
            'productos',
            {'stock': nuevoStock},
            where: 'id = ?',
            whereArgs: [idProd],
          );
        }
      }

      return idVenta; // Si todo salió bien, devolvemos el ID
    });
  }

  // Leer historial de ventas
  Future<List<Cotizacion>> obtenerVentas() async {
    final db = await instance.database;
    final maps = await db.query('cotizaciones', orderBy: 'fecha DESC'); // Las más recientes primero
    return maps.map((json) => Cotizacion.fromMap(json)).toList();
  }
  // --- MÉTODOS DE REPORTES ---

  // Calcular el total de dinero de TODAS las ventas
  Future<double> obtenerTotalVentas() async {
    final db = await instance.database;
    // La magia de SQL: "SUM(total)" suma toda la columna automáticamente
    final result = await db.rawQuery('SELECT SUM(total) as total FROM cotizaciones');
    
    if (result.isNotEmpty && result.first['total'] != null) {
      return result.first['total'] as double;
    } else {
      return 0.0; // Si no hay ventas, devuelve 0
    }
  }
}   


