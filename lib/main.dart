import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'screens/login_screen.dart';
import 'services/notification_service.dart';

ValueNotifier<ThemeMode> temaGlobal = ValueNotifier(ThemeMode.system);
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await Supabase.initialize(
    url:
        'https://zxaxozadqehyghbucwtr.supabase.co', 
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp4YXhvemFkcWVoeWdoYnVjd3RyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE0NTg5MTksImV4cCI6MjA4NzAzNDkxOX0.qJ3ENA--r8uEAo9B6L8RxFgFk2XCtH3Rm36z82GFUfQ', // Pega la llave larga
  );

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
          title: 'Cotizador Textil',
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.indigo,
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.grey[50], // Fondo claro suave
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

          // --- TEMA OSCURO 
          darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.indigo,
            brightness: Brightness.dark,
            // 1. Fondo Negro Suave 
            scaffoldBackgroundColor: const Color(0xFF121212),

            // 2. Tarjetas un poco más claras que el fondo para que resalten
            cardTheme: CardThemeData(
              elevation: 0, // En modo oscuro las sombras se ven sucias, mejor 0
              color: const Color(0xFF1E1E1E), // El color de la tarjeta
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(
                  color: Colors.white.withOpacity(
                    0.1,
                  ), // <--- ESTE ES EL BORDE DESTACADO
                  width: 1,
                ),
              ),
            ),

            // 3. AppBar oscura para que combine
            appBarTheme: AppBarTheme(
              backgroundColor: const Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
              elevation: 0,
            ),

            // 4. Ajuste de textos para que se lean bien
            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: Colors.white70), // Texto normal
              titleMedium: TextStyle(color: Colors.white), // Títulos
            ),
          ),

          themeMode: mode, // Usa el modo que diga el notificador
          home: LoginScreen(),
        );
      },
    );
  }
}
