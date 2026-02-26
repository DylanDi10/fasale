import 'package:cotizaciones_app/screens/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'screens/login_screen.dart';
import 'services/notification_service.dart';

ValueNotifier<ThemeMode> temaGlobal = ValueNotifier(ThemeMode.system);

void main() async {
  // 1. Asegurar inicialización de Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // --- 🛡️ EL ESCUDO ANTIPÁNICO (ERROR CATCHER) ---
  // Este bloque reemplaza la "Pantalla Roja" por una interfaz amigable
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 80),
                const SizedBox(height: 16),
                const Text(
                  "¡Ups! Algo no salió como esperábamos",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  "La aplicación encontró un inconveniente visual, pero puedes intentar seguir usándola o reiniciar esta pantalla.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    // Aquí no cerramos la app, dejamos que el usuario intente volver
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text("Entendido"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  };

  // 2. Inicialización de Base de Datos para Desktop (Windows/Linux)
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // 3. Inicializar Supabase
  await Supabase.initialize(
    url: 'https://zxaxozadqehyghbucwtr.supabase.co', 
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp4YXhvemFkcWVoeWdoYnVjd3RyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE0NTg5MTksImV4cCI6MjA4NzAzNDkxOX0.qJ3ENA--r8uEAo9B6L8RxFgFk2XCtH3Rm36z82GFUfQ',
  );

  // 4. Inicializar Notificaciones
  await NotificationService().init();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: temaGlobal,
      builder: (context, mode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Menu FA SALE',
          
          // --- TEMA CLARO ---
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.indigo,
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.grey[50],
            cardTheme: const CardThemeData(
              elevation: 10,
              color: Colors.white,
              shadowColor: Colors.black12,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              elevation: 10,
            ),
          ),

          // --- TEMA OSCURO ---
          darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.indigo,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardTheme: CardThemeData(
              elevation: 0,
              color: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: Colors.white70),
              titleMedium: TextStyle(color: Colors.white),
            ),
          ),

          themeMode: mode,
          home: AuthGate(), // <--- EL CAMBIO MÁGICO
        );
      },
    );
  }
}