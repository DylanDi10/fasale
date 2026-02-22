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

  // --- SELECTOR DE FECHA ---
  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? seleccion = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime.now(), // No se puede programar en el pasado
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
    if (seleccion != null && seleccion != _fechaSeleccionada) {
      setState(() {
        _fechaSeleccionada = seleccion;
      });
    }
  }

  // --- SELECTOR DE HORA ---
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
    if (seleccion != null && seleccion != _horaSeleccionada) {
      setState(() {
        _horaSeleccionada = seleccion;
      });
    }
  }

  // --- GUARDAR EN LA NUBE ---
  void _guardarRecordatorio() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      // Unimos la fecha y la hora en un solo objeto DateTime
      final fechaFinalProgramada = DateTime(
        _fechaSeleccionada.year,
        _fechaSeleccionada.month,
        _fechaSeleccionada.day,
        _horaSeleccionada.hour,
        _horaSeleccionada.minute,
      );

      final nuevoRecordatorio = Recordatorio(
        usuarioId: widget.usuarioActual.id!,
        clienteId: _clienteSeleccionado?.id, // Puede ser null si es un recordatorio general
        fechaProgramada: fechaFinalProgramada,
        descripcion: _descripcionController.text.trim(),
      );

      await SupabaseService.instance.insertarRecordatorio(nuevoRecordatorio);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recordatorio guardado con éxito'), backgroundColor: Colors.teal),
        );
        Navigator.pop(context); // Regresamos a la agenda
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
                    
                    // 1. BUSCADOR DE CLIENTES (Opcional)
                    const Text(
                      "¿A qué cliente debes llamar? (Opcional)",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Autocomplete<Cliente>(
                      optionsBuilder: (TextEditingValue textEditingValue) async {
                        if (textEditingValue.text.length < 2) return const Iterable<Cliente>.empty();
                        return await SupabaseService.instance.buscarClientesGeneral(textEditingValue.text);
                      },
                      displayStringForOption: (Cliente option) => option.nombre,
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4.0,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxHeight: 200, maxWidth: MediaQuery.of(context).size.width - 40),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final Cliente cliente = options.elementAt(index);
                                  return ListTile(
                                    leading: const Icon(Icons.person, color: Colors.teal),
                                    title: Text(cliente.nombre),
                                    subtitle: Text("DNI/RUC: ${cliente.dniRuc}"),
                                    onTap: () => onSelected(cliente),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                      onSelected: (Cliente seleccion) {
                        setState(() {
                          _clienteSeleccionado = seleccion;
                        });
                      },
                      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                        return TextFormField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            hintText: 'Buscar por Nombre o DNI...',
                            prefixIcon: const Icon(Icons.search, color: Colors.teal),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.teal[700]!, width: 2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 25),

                    // 2. FECHA Y HORA
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _seleccionarFecha(context),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Fecha',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                prefixIcon: const Icon(Icons.calendar_today, color: Colors.teal),
                              ),
                              child: Text(
                                "${_fechaSeleccionada.day.toString().padLeft(2, '0')}/${_fechaSeleccionada.month.toString().padLeft(2, '0')}/${_fechaSeleccionada.year}",
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: InkWell(
                            onTap: () => _seleccionarHora(context),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Hora',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                prefixIcon: const Icon(Icons.access_time, color: Colors.teal),
                              ),
                              child: Text(_horaSeleccionada.format(context)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // 3. DESCRIPCIÓN
                    TextFormField(
                      controller: _descripcionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: '¿De qué van a hablar? / Detalles',
                        alignLabelWithHint: true,
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 40),
                          child: Icon(Icons.notes, color: Colors.teal),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.teal[700]!, width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) => value!.trim().isEmpty ? 'Ingresa una descripción o motivo' : null,
                    ),
                    const SizedBox(height: 40),

                    // 4. BOTÓN DE GUARDAR
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 3,
                        ),
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