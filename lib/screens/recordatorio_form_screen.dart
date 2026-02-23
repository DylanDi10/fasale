import 'package:cotizaciones_app/services/notification_service.dart';
import 'package:flutter/material.dart';
import '../db/supabase_service.dart';
import '../models/client_model.dart';
import '../models/recordatorio_model.dart';
import '../models/user_model.dart';

class RecordatorioFormScreen extends StatefulWidget {
  final Usuario usuarioActual;

  const RecordatorioFormScreen({Key? key, required this.usuarioActual}) : super(key: key);

  @override
  _RecordatorioFormScreenState createState() => _RecordatorioFormScreenState();
}

class _RecordatorioFormScreenState extends State<RecordatorioFormScreen> {
  int _minutosAntes = 30; // 🔔 El valor inicial para el Dropdown
  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();

  Cliente? _clienteSeleccionado;
  DateTime _fechaSeleccionada = DateTime.now();
  TimeOfDay _horaSeleccionada = TimeOfDay.now();

  bool _isSaving = false;

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  // --- SELECTORES ---
  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? seleccion = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Colors.teal[700]!),
          ),
          child: child!,
        );
      },
    );
    if (seleccion != null) setState(() => _fechaSeleccionada = seleccion);
  }

  Future<void> _seleccionarHora(BuildContext context) async {
    final TimeOfDay? seleccion = await showTimePicker(
      context: context,
      initialTime: _horaSeleccionada,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Colors.teal[700]!),
          ),
          child: child!,
        );
      },
    );
    if (seleccion != null) setState(() => _horaSeleccionada = seleccion);
  }

  // --- LÓGICA DE GUARDADO ---
  void _guardarRecordatorio() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      final fechaFinalProgramada = DateTime(
        _fechaSeleccionada.year,
        _fechaSeleccionada.month,
        _fechaSeleccionada.day,
        _horaSeleccionada.hour,
        _horaSeleccionada.minute,
      );

      // 1. Guardar en Supabase
      await SupabaseService.instance.insertarRecordatorio(
        Recordatorio(
          usuarioId: widget.usuarioActual.id!,
          clienteId: _clienteSeleccionado?.id,
          fechaProgramada: fechaFinalProgramada,
          descripcion: _descripcionController.text.trim(),
        ),
      );

      // 2. Programar Alarma
      // --- DENTRO DE _guardarRecordatorio ---
      final horaDeLaAlarma = fechaFinalProgramada.subtract(Duration(minutes: _minutosAntes));
      final int notiId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      await NotificationService().programarNotificacion(
        notiId,
        "Cita en $_minutosAntes minutos ⏰", // Título dinámico
        _descripcionController.text.trim(),
        horaDeLaAlarma,
      );

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recordatorio y alarma programados 🔔'), backgroundColor: Colors.teal),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nuevo Recordatorio"),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("¿A qué cliente llamar? (Opcional)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    // ... Aquí va tu Autocomplete de Clientes (lo mantuve igual)
                    Autocomplete<Cliente>(
                      optionsBuilder: (textValue) async {
                        if (textValue.text.length < 2) return const Iterable<Cliente>.empty();
                        return await SupabaseService.instance.buscarClientesGeneral(textValue.text);
                      },
                      displayStringForOption: (option) => option.nombre,
                      onSelected: (seleccion) => setState(() => _clienteSeleccionado = seleccion),
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            hintText: 'Buscar cliente...',
                            prefixIcon: const Icon(Icons.search, color: Colors.teal),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 25),

                    // FECHA Y HORA
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _seleccionarFecha(context),
                            child: InputDecorator(
                              decoration: InputDecoration(labelText: 'Fecha', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), prefixIcon: const Icon(Icons.calendar_today, color: Colors.teal)),
                              child: Text("${_fechaSeleccionada.day}/${_fechaSeleccionada.month}/${_fechaSeleccionada.year}"),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: InkWell(
                            onTap: () => _seleccionarHora(context),
                            child: InputDecorator(
                              decoration: InputDecoration(labelText: 'Hora', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), prefixIcon: const Icon(Icons.access_time, color: Colors.teal)),
                              child: Text(_horaSeleccionada.format(context)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // --- 3. DESCRIPCIÓN (RESTAURADO) ---
                    const Text("Detalles de la cita:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descripcionController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Ej: Presentación de catálogo de máquinas',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.notes, color: Colors.teal),
                      ),
                      validator: (value) => value!.trim().isEmpty ? 'Ingresa una descripción' : null,
                    ),
                    const SizedBox(height: 25),

                    // --- 4. DROPDOWN DE NOTIFICACIÓN ---
                    const Text("¿Cuándo avisar?", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _minutosAntes,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.notifications_active, color: Colors.teal),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 10, child: Text('10 minutos antes')),
                        DropdownMenuItem(value: 30, child: Text('30 minutos antes')),
                        DropdownMenuItem(value: 60, child: Text('1 hora antes')),
                      ],
                      onChanged: (val) => setState(() => _minutosAntes = val!),
                    ),
                    const SizedBox(height: 40),

                    // BOTÓN GUARDAR
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[700], foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                        icon: const Icon(Icons.save),
                        label: const Text("GUARDAR RECORDATORIO", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        onPressed: _guardarRecordatorio,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}