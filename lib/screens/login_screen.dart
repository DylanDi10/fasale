import 'package:flutter/material.dart';
import '../db/database_helper.dart'; 
import '../models/user_model.dart';
import 'home_screen.dart'; 

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controladores: Son como las "antenas" que leen lo que escribe el usuario
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  
  // Clave del formulario: Para validar que no estén vacíos
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false; // Para mostrar un circulito de carga
  String _errorMessage = '';

  // Función que se ejecuta al presionar "Ingresar"
  void _login() async {
    // 1. Validar que los campos no estén vacíos
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true; // Empieza a girar el circulito
      _errorMessage = '';
    });

    // 2. LLAMADA A LA BASE DE DATOS (Tu código en acción)
    // Le preguntamos al Gerente si este usuario existe
    Usuario? usuarioEncontrado = await DatabaseHelper.instance.login(
      _userController.text.trim(), 
      _passController.text.trim()
    );

    setState(() {
      _isLoading = false; // Deja de girar
    });

    // 3. Tomar decisiones
    if (usuarioEncontrado != null) {
      // ¡ÉXITO! Navegar a la pantalla principal
      // Usamos pushReplacement para que no pueda volver atrás al Login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(usuario: usuarioEncontrado),
        ),
      );
    } else {
      // ¡ERROR! Mostrar mensaje rojo
      setState(() {
        _errorMessage = 'Usuario o contraseña incorrectos';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center( // Centra todo en la pantalla
        child: SingleChildScrollView(
          padding: EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bolt, size: 100, color: Colors.indigo),
                SizedBox(height: 20),
                Text("FA SALE", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                SizedBox(height: 40),

                TextFormField(
                  controller: _userController,
                  decoration: InputDecoration(
                    labelText: 'Usuario',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) => value!.isEmpty ? 'Ingresa el usuario' : null,
                ),
                SizedBox(height: 16),

                TextFormField(
                  controller: _passController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) => value!.isEmpty ? 'Ingresa la contraseña' : null,
                ),
                SizedBox(height: 24),


                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(_errorMessage, style: TextStyle(color: Colors.red)),
                  ),

                // BOTÓN DE INGRESAR
                SizedBox(
                  width: double.infinity, // Ocupa todo el ancho
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login, // Si carga, deshabilita el botón
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