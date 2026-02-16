import 'package:cotizaciones_app/screens/about_screen.dart';
import 'package:cotizaciones_app/screens/report_screen.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'login_screen.dart';
import 'products_screen.dart';
import 'clientes_screen.dart';
import 'nueva_venta_screen.dart';

class HomeScreen extends StatelessWidget {
  final Usuario usuario;

  const HomeScreen({Key? key, required this.usuario}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Menu FASALE'),
        backgroundColor: Colors.indigo, 
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () {
              Navigator.pushReplacement(
                context, 
                MaterialPageRoute(builder: (_) => LoginScreen())
              );
            },
          )
        ],
      ),
      
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(usuario.username.toUpperCase()),
              accountEmail: Text("Rol: ${usuario.rol}"),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(usuario.username[0].toUpperCase(), style: TextStyle(fontSize: 40)),
              ),
              decoration: BoxDecoration(color: Colors.indigo),
            ),
            ListTile(
              leading: Icon(Icons.info_rounded),
              title: Text('Información'),
              onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AboutScreen(),
                        ),
                      );},
            ),
          ],
        ),
      ),

      body: Container(
        color: Colors.grey[100], 
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hola, ${usuario.username}.",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text("¿Qué quieres hacer hoy?", style: TextStyle(color: Colors.grey[600])),
            SizedBox(height: 20),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2, 
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [
                  //  BOTÓN INVENTARIO 
                  _DashboardCard(
                    title: "Inventario",
                    icon: Icons.inventory_2,
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProductsScreen()),
                      );
                    },
                  ),

                  //  BOTÓN CLIENTES 
                  _DashboardCard(
                    title: "Clientes",
                    icon: Icons.people,
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ClientesScreen()),
                      );
                    },
                  ),

                  //  BOTÓN COTIZAR 
                  _DashboardCard(
                    title: "Nueva Cotización",
                    icon: Icons.shopping_cart,
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NuevaVentaScreen(usuarioActual: usuario),
                        ),
                      );
                    },
                  ),

                  //  BOTÓN REPORTES 
                  if (usuario.rol == 'admin') 
                    _DashboardCard(
                      title: "Reportes",
                      icon: Icons.bar_chart,
                      color: Colors.purple,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ReportsScreen()),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell( 
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withOpacity(0.2), // Color suave de fondo
              child: Icon(icon, size: 30, color: color),
            ),
            SizedBox(height: 10),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}