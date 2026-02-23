import 'package:cotizaciones_app/main.dart';
import 'package:cotizaciones_app/screens/admins_users_screen.dart';
import 'package:cotizaciones_app/screens/catalogo_screen.dart';
import 'package:cotizaciones_app/screens/recordatorio_screen.dart';
import 'package:cotizaciones_app/screens/report_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'login_screen.dart';
import 'products_screen.dart';
import 'clientes_screen.dart';
import 'nueva_venta_screen.dart';
import 'about_screen.dart';
// Módulo de Agenda

class HomeScreen extends StatelessWidget {
  final Usuario usuario;
  final bool esAdmin;

  const HomeScreen({Key? key, required this.usuario, required this.esAdmin}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cotizador Textil"),
        actions: [
          IconButton(
            icon: Icon(
              temaGlobal.value == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode
            ),
            onPressed: () {
              temaGlobal.value = temaGlobal.value == ThemeMode.light 
                  ? ThemeMode.dark 
                  : ThemeMode.light;
            },
          ),
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
                child: Text(
                  usuario.username[0].toUpperCase(),
                  style: TextStyle(fontSize: 40, color: Colors.indigo),
                ),
              ),
              decoration: BoxDecoration(color: Colors.indigo),
            ),
            
            ListTile(
              leading: Icon(Icons.info_outline, color: Colors.grey[700]),
              title: Text('Acerca de la App'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => AboutScreen())
                );
              },
            ),

            Divider(),

            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        ),
      ),

      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          Text("Hola, ${usuario.username}.", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text("¿Qué quieres hacer hoy?", style: TextStyle(color: Colors.grey[600])),
          SizedBox(height: 25),

          // --- LOS 6 BOTONES EN CUADRÍCULA SIMÉTRICA ---
          GridView.count(
            shrinkWrap: true, 
            physics: NeverScrollableScrollPhysics(), 
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            children: [
              // 1. INVENTARIO
              _DashboardCard(
                title: "Inventario",
                icon: Icons.inventory_2,
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => ProductsScreen(esAdmin: esAdmin))
                  );
                },
              ),
              // 2. CLIENTES
              _DashboardCard(
                title: "Clientes",
                icon: Icons.people,
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => ClientesScreen())
                  );
                },
              ),
              // 3. COTIZACIÓN
              _DashboardCard(
                title: "Nueva Cotización",
                icon: Icons.shopping_cart,
                color: Colors.green,
                onTap: () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => NuevaVentaScreen(usuarioActual: usuario))
                  );
                },
              ),
              // 4. REPORTES
              _DashboardCard(
                title: usuario.rol == 'admin' ? "Supervisar Ventas" : "Mis Reportes",
                icon: Icons.bar_chart,
                color: usuario.rol == 'admin' ? Colors.orange : Colors.purple,
                onTap: () {
                  if (usuario.rol == 'admin') {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => AdminUsersScreen(usuarioLogueado: usuario))
                    );
                  } else {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => ReportsScreen(usuarioLogueado: usuario))
                    );
                  }
                },
              ),
              // 5. CATÁLOGO VIRTUAL
              _DashboardCard(
                title: "Catálogo Virtual",
                icon: Icons.auto_stories,
                color: Colors.pink, 
                onTap: () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => const CatalogoScreen())
                  );
                },
              ),
              // 6. AGENDA COMERCIAL
              _DashboardCard(
                title: "Mi Agenda",
                icon: Icons.calendar_month,
                color: Colors.teal, 
                onTap: () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => RecordatoriosScreen(usuarioActual: usuario))
                  );
                },
              ),
            ],
          ),
        ],
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
    required this.onTap
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
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, size: 30, color: color),
            ),
            SizedBox(height: 10),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}