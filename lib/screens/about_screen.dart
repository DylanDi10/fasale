import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Usamos el color del tema para que en modo oscuro se vea bien
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Información'),
        // El color ya lo maneja el main.dart
      ),
      body: SafeArea( // Evita que el contenido choque con la cámara/bordes
        child: SingleChildScrollView( // <--- LA CLAVE: Permite scroll si no cabe
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Un icono o logo le daría más presencia
                Icon(Icons.business_center, 
                  size: 80, 
                  color: Theme.of(context).colorScheme.primary
                ),
                const SizedBox(height: 20),
                Text(
                  'FASALE',
                  style: TextStyle(
                    fontSize: 32, 
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                Text(
                  'Sistema de Cotizaciones',
                  style: TextStyle(
                    fontSize: 16, 
                    color: Theme.of(context).colorScheme.secondary,
                    letterSpacing: 1.5
                  ),
                ),
                const SizedBox(height: 30),
                const Divider(),
                const SizedBox(height: 30),
                Text(
                  'Esta aplicación fue creada para facilitar la gestión de cotizaciones, productos y clientes en tu negocio. ¡Gracias por usar FASALE!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5, // Interlineado para mejor lectura
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: 40),
                // Tarjeta pequeña para el desarrollador
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.code, size: 20),
                      const SizedBox(width: 10),
                      Text('Desarrollado por Dylan', 
                        style: TextStyle(fontWeight: FontWeight.w500)
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
                Text(
                  'Versión 1.0.0',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}