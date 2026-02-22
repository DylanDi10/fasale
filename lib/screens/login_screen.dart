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

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(usuario: usuarioEncontrado),
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
                Icon(Icons.bolt, size: 100, color: Colors.indigo),
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