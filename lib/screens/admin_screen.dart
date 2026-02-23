import 'package:flutter/material.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  
  // Aquí moveremos tu función _leerExcelYSubir y _mostrarOpcionesImportacion luego

  void _mostrarDialogoNuevaCategoria() {
    TextEditingController categoriaController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nueva Categoría"),
        content: TextField(
          controller: categoriaController,
          decoration: const InputDecoration(
            labelText: "Nombre de la categoría",
            hintText: "Ej: Herramientas, Repuestos...",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              // Aquí haremos el insert a Supabase en el siguiente paso
              print("Guardar categoría: ${categoriaController.text}");
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Text(
              "Configuración del Sistema",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          
          // TARJETA 1: El Excel (Lo moveremos aquí)
          _buildAdminCard(
            icon: Icons.upload_file,
            color: Colors.green,
            title: 'Importar Inventario (Excel)',
            subtitle: 'Actualiza precios, añade stock o reemplaza la base de datos completa.',
            onTap: () {
              // _mostrarOpcionesImportacion(); <-- Lo conectaremos en un rato
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Aún debes mover la función del Excel aquí")),
              );
            },
          ),

          // TARJETA 2: Categorías
          _buildAdminCard(
            icon: Icons.category,
            color: Colors.orange,
            title: 'Gestionar Categorías',
            subtitle: 'Crea nuevas categorías para clasificar los productos.',
            onTap: _mostrarDialogoNuevaCategoria,
          ),

          // TARJETA 3: Usuarios / Vendedores (Para el futuro)
          _buildAdminCard(
            icon: Icons.people,
            color: Colors.blue,
            title: 'Gestión de Vendedores',
            subtitle: 'Activa o desactiva accesos al sistema.',
            onTap: () {
               ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Módulo en desarrollo para la Fase 2")),
              );
            },
          ),
        ],
      ),
    );
  }

  // Widget personalizado para que los botones se vean como tarjetas profesionales
  Widget _buildAdminCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          radius: 25,
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(subtitle, style: const TextStyle(fontSize: 13)),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}