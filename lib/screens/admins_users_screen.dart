import 'package:cotizaciones_app/db/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    final lista = await SupabaseService.instance.obtenerTodosLosUsuarios();
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
                            // Toma la primera letra del nombre
                            vendedor.nombreCompleto.isNotEmpty ? vendedor.nombreCompleto[0].toUpperCase() : "?",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                          ), 
                        ), 
                        title: Text(
                          // Mostramos el nombre completo hermoso en el título
                          vendedor.nombreCompleto,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
                        ), 
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4), // Un pequeño respiro visual
                            Text(
                              "Rol: ${vendedor.rol.toUpperCase()}", 
                              style: const TextStyle(color: Colors.indigoAccent, fontWeight: FontWeight.w500)
                            ),
                            Text(
                              vendedor.correo, 
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                              overflow: TextOverflow.ellipsis, // Si el correo es muy largo, pone "..." al final
                            ),
                          ],
                        ),
                        isThreeLine: true, // Esto obliga a la tarjeta a hacerse más alta y cómoda
                        trailing: Icon(Icons.arrow_forward_ios, color: Colors.indigo, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReportsScreen(
                                usuarioLogueado: widget.usuarioLogueado, 
                                usuarioIdExterno: vendedor.id,      
                                // Pasamos el nombre para que salga en el reporte
                                nombreVendedorExterno: vendedor.nombreCompleto, 
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