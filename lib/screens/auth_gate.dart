import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import '../models/user_model.dart';

class AuthGate extends StatefulWidget {
  @override
  _AuthGateState createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _verificarSesion();
  }

  Future<void> _verificarSesion() async {
    // 1. Verificamos si Supabase tiene un token activo en la memoria del celular
    final session = Supabase.instance.client.auth.currentSession;
    
    // 2. Traemos tus datos locales
    final prefs = await SharedPreferences.getInstance();
    final int? usuarioId = prefs.getInt('usuario_id');

    // (Opcional) Una pequeña pausa para que se vea el logo antes de entrar
    await Future.delayed(const Duration(milliseconds: 800));

    // Si hay token de Supabase Y tenemos tu ID guardado, lo dejamos pasar
    if (session != null && usuarioId != null) {
      
      // Reconstruimos tu objeto Usuario con los datos de memoria
      final String correo = prefs.getString('nombre_vendedor') ?? 'Usuario';
      final bool esAdmin = prefs.getBool('esAdmin') ?? false;
      
      Usuario usuarioGuardado = Usuario(
        id: usuarioId,
        correo: correo,
        rol: esAdmin ? 'admin' : 'vendedor',
        nombreCompleto: correo, // Si guardaste el nombre completo, ponlo aquí
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(usuario: usuarioGuardado, esAdmin: esAdmin),
        ),
      );
    } else {
      // Si falta algo, lo mandamos a que inicie sesión de nuevo
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        // Aquí puedes poner el logo de FA SALE en lugar del circulito
        child: CircularProgressIndicator(color: Colors.indigo), 
      ),
    );
  }
}