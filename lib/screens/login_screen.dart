import 'package:cotizaciones_app/db/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'home_screen.dart'; 

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _passwordVisible = false; 
  final _emailController = TextEditingController(); // <-- Cambiado a email
  final _passController = TextEditingController();
  
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false; 
  String _errorMessage = '';

  void _login() async {
    // Si el correo no tiene formato válido, no avanza
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true; 
      _errorMessage = '';
    });

    // --- LA CONEXIÓN AL NUEVO SISTEMA SEGURO ---
    Usuario? usuarioEncontrado = await SupabaseService.instance.login(
      _emailController.text.trim(), 
      _passController.text.trim()
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false; 
    });

    if (usuarioEncontrado != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('usuario_id', usuarioEncontrado.id!);
      
      // Guardamos el correo para mostrarlo en el menú lateral o perfil
      await prefs.setString('nombre_vendedor', usuarioEncontrado.nombreCompleto);

      // --- EL NUEVO CANDADO DE SEGURIDAD ---
      // Ahora validamos por el 'rol' de la base de datos, no por el nombre
      bool permisoAdmin = (usuarioEncontrado.rol.toLowerCase() == 'admin'); 
      
      await prefs.setBool('esAdmin', permisoAdmin);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(usuario: usuarioEncontrado, esAdmin: permisoAdmin), 
        ),
      );
    } else {
      setState(() {
        _errorMessage = 'Correo o contraseña incorrectos';
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
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20.0),
                    child: Image.asset(
                      'assets/images/launcher_icon.png', 
                      width: 120,        
                      height: 120,
                      fit: BoxFit.cover, 
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text("FA SALE", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                SizedBox(height: 40),

                // --- NUEVO CAMPO DE CORREO ---
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress, // Muestra el teclado con el '@'
                  decoration: InputDecoration(
                    labelText: 'Correo Electrónico',
                    hintText: 'ejemplo@fasale.com',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    prefixIcon: Icon(Icons.email), // Ícono actualizado
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa tu correo';
                    }
                    // Expresión regular (Regex) para validar que tenga el formato texto@texto.com
                    if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                      return 'Ingresa un correo válido';
                    }
                    return null;
                  },
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
                  validator: (value) => value!.isEmpty ? 'Ingresa la contraseña' : null,
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