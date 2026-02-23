import 'package:cotizaciones_app/db/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/database_helper.dart'; 
import '../models/user_model.dart';
import 'home_screen.dart'; 

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _passwordVisible = false; 
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false; 
  String _errorMessage = '';

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true; 
      _errorMessage = '';
    });

    Usuario? usuarioEncontrado = await SupabaseService.instance.login(
      _userController.text.trim(), 
      _passController.text.trim()
    );

    setState(() {
      _isLoading = false; 
    });

    if (usuarioEncontrado != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('usuario_id', usuarioEncontrado.id!);
      await prefs.setString('nombre_vendedor', usuarioEncontrado.username);

      // --- 🔒 LA MAGIA DE LA SEGURIDAD AQUÍ ---
      // Comparamos el nombre de usuario. Si escribe "admin", le damos el poder.
      // (Si en tu modelo de BD tienes un campo de rol, sería: usuarioEncontrado.rol == 'admin')
      bool permisoAdmin = (usuarioEncontrado.username.toLowerCase() == 'admin'); 
      
      // Guardamos el permiso en caché por si cierra y abre la app
      await prefs.setBool('esAdmin', permisoAdmin);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          // Le pasamos el pase VIP a tu HomeScreen
          builder: (context) => HomeScreen(usuario: usuarioEncontrado, esAdmin: permisoAdmin), 
        ),
      );
    } else {
      setState(() {
        _errorMessage = 'Usuario o contraseña incorrectos';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center( 
        child: SingleChildScrollView(
          padding: EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                
                Container(
                  // Le damos un pequeño borde o sombra para que resalte (opcional)
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20), // El mismo radio que el ClipRRect
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    // Aquí defines qué tan redondos quieres los bordes. 
                    // Un valor de 20 suele verse moderno y elegante.
                    borderRadius: BorderRadius.circular(20.0),
                    child: Image.asset(
                      'assets/images/launcher_icon.png', // <--- ¡VERIFICA QUE ESTA RUTA SEA CORRECTA!
                      width: 120,        // Un poco más grande que el ícono anterior (era 100)
                      height: 120,
                      fit: BoxFit.cover, // Esto hace que la imagen llene el cuadro sin deformarse
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text("FA SALE", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                SizedBox(height: 40),

                TextFormField(
                  controller: _userController,
                  decoration: InputDecoration(
                    labelText: 'Usuario',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) => value!.isEmpty ? 'Ingresa el usuario' : null,
                ),
                SizedBox(height: 16),

                TextFormField(
                  controller: _passController,
                  obscureText: !_passwordVisible, 
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70 
                            : Theme.of(context).primaryColor, 
                      ),
                      onPressed: () {
                        setState(() {
                          _passwordVisible = !_passwordVisible;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(height: 24),


                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(_errorMessage, style: TextStyle(color: Colors.red)),
                  ),

                SizedBox(
                  width: double.infinity, 
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading 
                      ? CircularProgressIndicator(color: Colors.white) 
                      : Text('INGRESAR', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}