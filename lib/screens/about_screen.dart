import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:AppBar(
        title:Text('Información')
      ),
      body:Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('FASALE - Sistema de Cotizaciones', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text('Desarrollado por Dylan', style: TextStyle(fontSize: 18)),
              SizedBox(height: 20),
              Text('Esta aplicación fue creada para facilitar la gestión de cotizaciones, productos y clientes en tu negocio. ¡Gracias por usar FASALE!', textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}