import 'package:cotizaciones_app/db/supabase_service.dart';
import 'package:flutter/material.dart';
import '../models/client_model.dart';
import '../models/quote_model.dart'; // Importante para leer las ventas
import 'cliente_form_screen.dart'; 

class ClientesScreen extends StatefulWidget {
  @override
  _ClientesScreenState createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  // --- VARIABLES DE ESTADO LOCAL ---
  bool _cargando = true;
  List<Cliente> _clientesOriginales = [];
  List<Cliente> _clientesFiltrados = [];
  
  // Diccionarios para inteligencia de ventas
  Map<int, double> _gastosPorCliente = {};
  Map<int, int> _comprasPorCliente = {};
  
  bool _ordenarPorRanking = false; // El switch del VIP
  String _textoBusqueda = "";

  @override
  void initState() {
    super.initState();
    _cargarDatosInteligentes();
  }

  // --- LA MAGIA: CARGA Y CRUCE DE DATOS ---
  Future<void> _cargarDatosInteligentes() async {
    setState(() => _cargando = true);
    
    final db = SupabaseService.instance;
    
    // 1. Traemos la lista de clientes
    final clientes = await db.obtenerClientes();
    
    // 2. Traemos las ventas y filtramos solo las que son plata real (Aprobadas)
    final ventas = await db.obtenerVentas();
    final ventasAprobadas = ventas.where((v) => v.estado.toLowerCase().startsWith('aprobad'));

    // 3. Calculamos cuánto gastó y cuántas veces compró cada cliente
    Map<int, double> gastos = {};
    Map<int, int> compras = {};
    
    for (var venta in ventasAprobadas) {
      gastos[venta.clienteId] = (gastos[venta.clienteId] ?? 0.0) + venta.total;
      compras[venta.clienteId] = (compras[venta.clienteId] ?? 0) + 1;
    }

    if (mounted) {
      setState(() {
        _clientesOriginales = clientes;
        _gastosPorCliente = gastos;
        _comprasPorCliente = compras;
        _cargando = false;
      });
      _aplicarFiltrosYOrden();
    }
  }

  // --- BUSCADOR Y ORDENAMIENTO INSTANTÁNEO ---
  void _aplicarFiltrosYOrden() {
    List<Cliente> resultados = _clientesOriginales;

    // 1. Filtro por Nombre O por DNI (¡Soluciona tu bug de búsqueda!)
    if (_textoBusqueda.isNotEmpty) {
      resultados = resultados.where((c) {
        final coincideNombre = c.nombre.toLowerCase().contains(_textoBusqueda.toLowerCase());
        final coincideDni = c.dniRuc.contains(_textoBusqueda);
        return coincideNombre || coincideDni;
      }).toList();
    }

    // 2. Ordenamiento (A-Z vs Top Gastos)
    if (_ordenarPorRanking) {
      // Ordena del que tiene más dinero al que tiene menos
      resultados.sort((a, b) {
        double gastoA = _gastosPorCliente[a.id] ?? 0.0;
        double gastoB = _gastosPorCliente[b.id] ?? 0.0;
        return gastoB.compareTo(gastoA); 
      });
    } else {
      // Orden alfabético tradicional
      resultados.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    }

    setState(() {
      _clientesFiltrados = resultados;
    });
  }

  // --- FUNCIÓN PARA ASIGNAR MEDALLAS (BADGES) ---
  Widget _obtenerMedalla(int clienteId) {
    double totalGastado = _gastosPorCliente[clienteId] ?? 0.0;
    int totalCompras = _comprasPorCliente[clienteId] ?? 0;

    if (totalGastado == 0) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
        child: Text("⚪ Prospecto", style: TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.bold)),
      );
    } else if (totalGastado > 3000) { // Puedes cambiar este monto límite
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: Colors.amber[100], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.amber)),
        child: Text("🥇 VIP", style: TextStyle(fontSize: 10, color: Colors.amber[900], fontWeight: FontWeight.bold)),
      );
    } else if (totalCompras >= 2) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: Colors.blue[100], borderRadius: BorderRadius.circular(10)),
        child: Text("🥈 Recurrente", style: TextStyle(fontSize: 10, color: Colors.blue[800], fontWeight: FontWeight.bold)),
      );
    } else {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(10)),
        child: Text("🟢 Cliente", style: TextStyle(fontSize: 10, color: Colors.green[800], fontWeight: FontWeight.bold)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Buscar por Nombre o DNI...",
            hintStyle: TextStyle(color: Colors.white70),
            prefixIcon: Icon(Icons.search, color: Colors.white),
            border: InputBorder.none,
          ),
          onChanged: (value) {
            _textoBusqueda = value;
            _aplicarFiltrosYOrden(); // Es instantáneo porque está en la RAM
          },
        ),
      ),
      
      body: Column(
        children: [
          // --- PANEL DE RANKING ---
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).cardColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Mis Clientes (${_clientesFiltrados.length})", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                FilterChip(
                  label: Text("🏆 Ranking VIP"),
                  selected: _ordenarPorRanking,
                  selectedColor: Colors.amber[100],
                  checkmarkColor: Colors.amber[900],
                  labelStyle: TextStyle(
                    color: _ordenarPorRanking ? Colors.amber[900] : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
                    fontWeight: _ordenarPorRanking ? FontWeight.bold : FontWeight.normal
                  ),
                  onSelected: (val) {
                    setState(() => _ordenarPorRanking = val);
                    _aplicarFiltrosYOrden();
                  },
                )
              ],
            ),
          ),
          Divider(height: 1),
          
          // --- LISTA DE CLIENTES ---
          Expanded(
            child: _cargando 
              ? Center(child: CircularProgressIndicator())
              : _clientesFiltrados.isEmpty
                  ? Center(child: Text("No se encontraron clientes."))
                  : ListView.builder(
                      itemCount: _clientesFiltrados.length,
                      itemBuilder: (context, index) {
                        final cliente = _clientesFiltrados[index];
                        final gastoCliente = _gastosPorCliente[cliente.id] ?? 0.0;
                        
                        return Card(
                          margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(cliente.nombre[0].toUpperCase()),
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    cliente.nombre, 
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                ),
                                SizedBox(width: 8),
                                _obtenerMedalla(cliente.id!), // La medalla dinámica
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                "DNI/RUC: ${cliente.dniRuc}\n"
                                "Tel: ${cliente.telefono ?? 'No registrado'}",
                                style: TextStyle(height: 1.3),
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Dinero dejado por el cliente
                                Text(
                                  "\$${gastoCliente.toStringAsFixed(0)}",
                                  style: TextStyle(
                                    color: gastoCliente > 0 ? Colors.green[700] : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16
                                  ),
                                ),
                                // Botón de eliminar con escudo intacto
                                Expanded(
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: Icon(Icons.delete_outline, color: Colors.red[300], size: 20),
                                    onPressed: () async {
                                      try {
                                        await SupabaseService.instance.eliminarCliente(cliente.id!);
                                        _cargarDatosInteligentes(); 
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Cliente eliminado"), backgroundColor: Colors.green)
                                        );
                                      } catch (e) {
                                        String msg = e.toString().replaceAll('Exception: ', '');
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(msg, style: TextStyle(color: Colors.white)), backgroundColor: Colors.red[800])
                                        );
                                      }
                                    }
                                  ),
                                ),
                              ],
                            ),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ClienteFormScreen(cliente: cliente)),
                              );
                              _cargarDatosInteligentes();
                            },
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        child: Icon(Icons.person_add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ClienteFormScreen()),
          );
          _cargarDatosInteligentes();
        },
      ),
    );
  }
}