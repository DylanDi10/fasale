import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final String mensaje;
  final IconData icono;

  const EmptyState({required this.mensaje, required this.icono});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Un icono grande con un color suave
          Icon(icono, size: 100, color: Colors.grey[300]),
          SizedBox(height: 20),
          Text(
            mensaje,
            style: TextStyle(
              fontSize: 18, 
              color: Colors.grey[500],
              fontWeight: FontWeight.w500
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}