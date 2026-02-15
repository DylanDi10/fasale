import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/client_model.dart';
import 'cliente_form_screen.dart'; 

class ClientesScreen extends StatefulWidget {
  @override
  _ClientesScreenState createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  late Future<List<Cliente>> _listaClientes;

  @override
  void initState() {
    super.initState();
    _cargarClientes();
  }

  void _cargarClientes() {
    setState(() {
      _listaClientes = DatabaseHelper.instance.obtenerClientes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cartera de Clientes')),
      
      body: FutureBuilder<List<Cliente>>(
        future: _listaClientes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No tienes clientes registrados."));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final cliente = snapshot.data![index];
              
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(cliente.nombre[0].toUpperCase()),
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  title: Text(cliente.nombre, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${cliente.telefono}  |  ${cliente.dniRuc}"),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await DatabaseHelper.instance.eliminarCliente(cliente.id!);
                      _cargarClientes();
                    },
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClienteFormScreen(cliente: cliente),
                      ),
                    );
                    _cargarClientes();
                  },
                ),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        child: Icon(Icons.person_add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ClienteFormScreen()),
          );
          _cargarClientes();
        },
      ),
    );
  }
}