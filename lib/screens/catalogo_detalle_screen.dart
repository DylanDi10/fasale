import 'dart:io';
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import 'visor_multimedia_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

class CatalogoDetalleScreen extends StatelessWidget {
  final Producto producto;

  const CatalogoDetalleScreen({Key? key, required this.producto}) : super(key: key);

  void _abrirEnlaceInterno(BuildContext context, String? url, String titulo) async {
    if (url == null || url.trim().isEmpty) return;
    
    final String urlLimpia = url.trim();

    // --- EL ESCUDO INTELIGENTE ---
    // 1. Si es PC (Windows, Mac, Linux) o Web, delegamos al sistema operativo
    if (kIsWeb || Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      final Uri uri = Uri.parse(urlLimpia);
      try {
        // mode: LaunchMode.externalApplication obliga a usar el navegador o programa de la PC
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo abrir el enlace en la PC.'), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al abrir el archivo.'), backgroundColor: Colors.red),
        );
      }
    } 
    // 2. Si es Celular / Tablet, ejecutamos tu código original que funciona perfecto
    else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VisorMultimediaScreen(url: urlLimpia, titulo: titulo),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Detectamos si el celular/app está en modo oscuro
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // QUITAMOS el fondo forzado gris claro. Ahora respeta el tema.
      appBar: AppBar(
        title: const Text("Detalle de Máquina"),
        backgroundColor: Colors.indigo[900],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HEADER: IMAGEN PRINCIPAL Y PRECIO ---
            Container(
              width: double.infinity,
              // QUITAMOS el fondo blanco a toda la cabecera
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Column(
                children: [
                  // Le ponemos fondo blanco SOLO a la imagen para que las fotos JPG se vean bien
                  Container(
                    height: 280,
                    width: double.infinity,
                    color: Colors.white, 
                    child: (producto.urlImagen != null && producto.urlImagen!.isNotEmpty)
                        ? (producto.urlImagen!.startsWith('http')
                            ? Image.network(producto.urlImagen!, fit: BoxFit.contain)
                            : Image.file(File(producto.urlImagen!), fit: BoxFit.contain))
                        : const Icon(Icons.inventory_2, size: 100, color: Colors.indigo),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // El nombre ahora sí se verá porque tomará el color del tema automáticamente
                        Text(producto.nombre, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(
                          "Precio referencial: USD ${producto.precio.toStringAsFixed(2)}",
                          // En modo oscuro hacemos el azul un poco más claro para que resalte
                          style: TextStyle(fontSize: 20, color: isDarkMode ? Colors.blue[300] : Colors.blue[700], fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 15),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            if (producto.marca != null && producto.marca!.isNotEmpty)
                              Chip(label: Text("Marca: ${producto.marca}"), backgroundColor: isDarkMode ? Colors.indigo.withOpacity(0.3) : Colors.indigo.withOpacity(0.1)),
                            if (producto.modelo != null && producto.modelo!.isNotEmpty)
                              Chip(label: Text("Modelo: ${producto.modelo}"), backgroundColor: isDarkMode ? Colors.indigo.withOpacity(0.3) : Colors.indigo.withOpacity(0.1)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildSeccionCard(
                    titulo: "Descripción General",
                    icono: Icons.description,
                    color: isDarkMode ? Colors.grey[300]! : Colors.grey[800]!,
                    contenido: Text(
                      producto.descripcion.isNotEmpty ? producto.descripcion : "No hay detalles adicionales.",
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ),

                  _buildSeccionCard(
                    titulo: "Galería de Fotos",
                    icono: Icons.photo_library,
                    color: isDarkMode ? Colors.orange[300]! : Colors.orange[800]!,
                    contenido: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Accede a la carpeta con más ángulos de esta máquina.", style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 15),
                        _buildBotonMultimedia(
                          context: context,
                          texto: "VER FOTOS (DRIVE)",
                          color: Colors.orange[700]!,
                          icono: Icons.folder_shared,
                          url: producto.linkFotos,
                          tituloVentana: "Galería de Fotos",
                          isDarkMode: isDarkMode,
                        ),
                      ],
                    ),
                  ),

                  _buildSeccionCard(
                    titulo: "Video Demostrativo",
                    icono: Icons.play_circle_fill,
                    color: isDarkMode ? Colors.blue[300]! : Colors.blue[800]!,
                    contenido: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Mira esta máquina en pleno funcionamiento.", style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 15),
                        _buildBotonMultimedia(
                          context: context,
                          texto: "REPRODUCIR VIDEO",
                          color: Colors.blue[700]!,
                          icono: Icons.play_arrow,
                          url: producto.linkVideo,
                          tituloVentana: "Video Demostrativo",
                          isDarkMode: isDarkMode,
                        ),
                      ],
                    ),
                  ),

                  _buildSeccionCard(
                    titulo: "Ficha Técnica",
                    icono: Icons.picture_as_pdf,
                    color: isDarkMode ? Colors.red[300]! : Colors.red[800]!,
                    contenido: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Lee el manual oficial y especificaciones.", style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 15),
                        _buildBotonMultimedia(
                          context: context,
                          texto: "ABRIR PDF",
                          color: Colors.red[700]!,
                          icono: Icons.menu_book,
                          url: producto.linkPdf,
                          tituloVentana: "Ficha Técnica",
                          isDarkMode: isDarkMode,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionCard({required String titulo, required IconData icono, required Color color, required Widget contenido}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono, color: color, size: 28),
                const SizedBox(width: 10),
                Text(titulo, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            const Divider(height: 25, thickness: 1),
            contenido,
          ],
        ),
      ),
    );
  }

  Widget _buildBotonMultimedia({required BuildContext context, required String texto, required Color color, required IconData icono, required String? url, required String tituloVentana, required bool isDarkMode}) {
    bool tieneLink = url != null && url.trim().isNotEmpty;
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          // Si no tiene link, usamos un fondo gris que se adapte al modo oscuro
          backgroundColor: tieneLink ? color : (isDarkMode ? Colors.grey[800] : Colors.grey[300]),
          foregroundColor: tieneLink ? Colors.white : (isDarkMode ? Colors.grey[500] : Colors.grey[600]),
          elevation: tieneLink ? 2 : 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: Icon(icono),
        label: Text(tieneLink ? texto : "NO DISPONIBLE", style: const TextStyle(fontWeight: FontWeight.bold)),
        onPressed: tieneLink ? () => _abrirEnlaceInterno(context, url, tituloVentana) : null,
      ),
    );
  }
}