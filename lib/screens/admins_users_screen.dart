import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/user_model.dart';
import 'report_screen.dart'; // Importante para poder ir al detalle

class AdminUsersScreen extends StatefulWidget {
final Usuario usuarioLogueado; // <--- AGREGA ESTA LÍNEA
const AdminUsersScreen({Key? key, required this.usuarioLogueado}) : super(key: key); // <--- Y ACTUALIZA EL CONSTRUCTOR
  @override
  _AdminUsersScreenState createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<Usuario> _vendedores = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarVendedores();
  }

  void _cargarVendedores() async {
    // Usamos la función nueva que pusiste en tu DatabaseHelper
    final lista = await DatabaseHelper.instance.obtenerTodosLosUsuarios();
    if (mounted) {
      setState(() {
        _vendedores = lista;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Supervisión de Vendedores"),
        backgroundColor: Colors.indigo[900], 
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator())
          : _vendedores.isEmpty 
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 80, color: Colors.grey),
                    Text("No hay vendedores registrados (aparte de ti)"),
                  ],
                ))
              : ListView.builder(
                  padding: EdgeInsets.all(10),
                  itemCount: _vendedores.length,
                  itemBuilder: (context, index) {
                    final vendedor = _vendedores[index];
                    
                    return Card(
                      elevation: 3,
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange,
                          child: Text(
                            vendedor.username.isNotEmpty ? vendedor.username[0].toUpperCase() : "?", 
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                          ),
                        ),
                        title: Text(
                          vendedor.username, 
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
                        ),
                        subtitle: Text("Rol: ${vendedor.rol}"),
                        trailing: Icon(Icons.arrow_forward_ios, color: Colors.indigo, size: 16),
                        onTap: () {
                          Navigator.push(
                            context, 
                            MaterialPageRoute(
                              builder: (_) => ReportsScreen(
                                usuarioLogueado: widget.usuarioLogueado, // El admin 
                                usuarioIdExterno: vendedor.id,         // El vendedor
                                nombreVendedorExterno: vendedor.username, // Su nombre
                              )
                            )
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}