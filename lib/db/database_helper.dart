import 'package:cotizaciones_app/models/quote_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/client_model.dart';


class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('sewing_sales_v2.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    // Tabla USUARIOS
    await db.execute('''
      CREATE TABLE usuarios ( 
        id $idType, 
        username $textType,
        password $textType,
        rol $textType 
      )
    ''');

    // Tabla PRODUCTOS
    await db.execute('''
      CREATE TABLE productos ( 
        id $idType, 
        nombre $textType,
        descripcion TEXT,
        precio $realType,
        stock $intType,
        categoria $textType,
        url_imagen TEXT 
      )
    ''');

    // Tabla CLIENTES
    await db.execute('''
      CREATE TABLE clientes ( 
        id $idType, 
        nombre $textType,
        telefono $textType,
        dni_ruc $textType,
        direccion TEXT
      )
    ''');

    // Tabla COTIZACIONES
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

    // Tabla RECORDATORIOS 
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
    
    await db.insert('usuarios', {
      'username': 'admin',
      'password': 'contra', 
      'rol': 'admin'
    });
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }



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


  Future<int> crearVenta(Cotizacion cotizacion) async {
    final db = await instance.database;
    
    return await db.transaction((txn) async {
      int idVenta = await txn.insert('cotizaciones', cotizacion.toMap());

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

      return idVenta; 
    });
  }

  Future<List<Cotizacion>> obtenerVentas() async {
    final db = await instance.database;
    final maps = await db.query('cotizaciones', orderBy: 'fecha DESC'); 
    return maps.map((json) => Cotizacion.fromMap(json)).toList();
  }

  Future<double> obtenerTotalVentas() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT SUM(total) as total FROM cotizaciones');
    
    if (result.isNotEmpty && result.first['total'] != null) {
      return result.first['total'] as double;
    } else {
      return 0.0;
    }
  }
  Future<void> eliminarTodasLasVentas() async {
    final db = await instance.database;
    await db.delete('cotizaciones'); 
  }
}   


