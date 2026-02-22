import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class VisorMultimediaScreen extends StatefulWidget {
  final String url;
  final String titulo;

  const VisorMultimediaScreen({Key? key, required this.url, required this.titulo}) : super(key: key);

  @override
  _VisorMultimediaScreenState createState() => _VisorMultimediaScreenState();
}

class _VisorMultimediaScreenState extends State<VisorMultimediaScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // Permite reproducir YouTube y Drive
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false; // Oculta la bolita de carga cuando ya cargó la página
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titulo),
        backgroundColor: Colors.indigo[900],
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.indigo)),
        ],
      ),
    );
  }
}