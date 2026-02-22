import 'package:cotizaciones_app/db/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../db/database_helper.dart';
import '../models/client_model.dart';

class ClienteFormScreen extends StatefulWidget {
  final Cliente? cliente;

  const ClienteFormScreen({Key? key, this.cliente}) : super(key: key);

  @override
  _ClienteFormScreenState createState() => _ClienteFormScreenState();
}

class _ClienteFormScreenState extends State<ClienteFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _dniCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.cliente != null) {
      _nombreCtrl.text = widget.cliente!.nombre;
      _telefonoCtrl.text = widget.cliente!.telefono;
      _dniCtrl.text = widget.cliente!.dniRuc;
      _direccionCtrl.text = widget.cliente!.direccion ?? '';
    }
  }

  void _guardar() async {
    if (_formKey.currentState!.validate()) {
      Cliente modelo = Cliente(
        id: widget.cliente?.id,
        nombre: _nombreCtrl.text,
        telefono: _telefonoCtrl.text,
        dniRuc: _dniCtrl.text,
        direccion: _direccionCtrl.text,
      );

      if (widget.cliente == null) {
        await SupabaseService.instance.insertarCliente(modelo);
      } else {
        await SupabaseService.instance.actualizarCliente(modelo);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.cliente == null ? 'Nuevo Cliente' : 'Editar Cliente',
        ),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nombreCtrl,
                decoration: InputDecoration(
                  labelText: 'Nombre Completo',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _telefonoCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Teléfono',
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _dniCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'DNI o RUC',
                  prefixIcon: Icon(Icons.badge),
                ),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _direccionCtrl,
                decoration: InputDecoration(
                  labelText: 'Dirección (Opcional)',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  onPressed: _guardar,
                  icon: Icon(Icons.save, color: Colors.white),
                  label: Text(
                    'GUARDAR CLIENTE',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
