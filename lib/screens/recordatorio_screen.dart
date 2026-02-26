import 'package:cotizaciones_app/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart'; // Para formatear la hora (Ej: 10:00 AM)
import '../models/user_model.dart';
import '../models/recordatorio_model.dart';
import '../db/supabase_service.dart'; // Asegúrate de que esta ruta sea correcta en tu proyecto

class RecordatoriosScreen extends StatefulWidget {
  final Usuario usuarioActual;

  const RecordatoriosScreen({Key? key, required this.usuarioActual}) : super(key: key);

  @override
  _RecordatoriosScreenState createState() => _RecordatoriosScreenState();
}

class _RecordatoriosScreenState extends State<RecordatoriosScreen> {
  DateTime _diaEnfocado = DateTime.now();
  DateTime? _diaSeleccionado;
  bool _isLoading = true;
  
  // Ahora usamos TU modelo Recordatorio real
  Map<DateTime, List<Recordatorio>> _tareasPorDia = {};

  @override
  void initState() {
    super.initState();
    _diaSeleccionado = _diaEnfocado;
    _cargarRecordatoriosDesdeBD();
  }

  // --- CONEXIÓN A TU BASE DE DATOS ---
  void _cargarRecordatoriosDesdeBD() async {
    setState(() => _isLoading = true);
    
    // AQUÍ ESTÁ LA MAGIA: Llamamos a TU función 'obtenerRecordatorios'
    final datosBD = await SupabaseService.instance.obtenerRecordatorios(widget.usuarioActual.id!);
    
    final Map<DateTime, List<Recordatorio>> agrupados = {};
    
    for (var recordatorio in datosBD) {
      // Normalizamos la fecha (quitamos horas/minutos para agrupar por día)
      final fecha = DateTime(
        recordatorio.fechaProgramada.year, 
        recordatorio.fechaProgramada.month, 
        recordatorio.fechaProgramada.day
      );
      
      if (agrupados[fecha] == null) agrupados[fecha] = [];
      agrupados[fecha]!.add(recordatorio);
    }

    if (mounted) {
      setState(() {
        _tareasPorDia = agrupados;
        _isLoading = false;
      });
    }
  }

  List<Recordatorio> _obtenerTareasParaElDia(DateTime dia) {
    DateTime diaNormalizado = DateTime(dia.year, dia.month, dia.day);
    return _tareasPorDia[diaNormalizado] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mi Agenda Comercial"),
        backgroundColor: Colors.teal[800],
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.teal))
        : Column(
        children: [
          // --- 1. EL CALENDARIO MENSUAL ---
          TableCalendar<Recordatorio>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _diaEnfocado,
            selectedDayPredicate: (day) => isSameDay(_diaSeleccionado, day),
            onDaySelected: (diaSeleccionado, diaEnfocado) {
              setState(() {
                _diaSeleccionado = diaSeleccionado;
                _diaEnfocado = diaEnfocado;
              });
            },
            eventLoader: _obtenerTareasParaElDia,
            
            // Estilos adaptados al modo oscuro que arreglamos antes
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: isDarkMode ? Colors.teal[700] : Colors.teal[300],
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.teal[900]!,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: Colors.redAccent, 
                shape: BoxShape.circle,
              ),
              defaultTextStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
              weekendTextStyle: TextStyle(color: isDarkMode ? Colors.teal[200] : Colors.teal[800]),
              outsideTextStyle: TextStyle(color: isDarkMode ? Colors.grey[700] : Colors.grey[400]),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false, 
              titleCentered: true,
              titleTextStyle: TextStyle(fontSize: 17, color: isDarkMode ? Colors.white : Colors.black87),
              leftChevronIcon: Icon(Icons.chevron_left, color: isDarkMode ? Colors.white : Colors.black87),
              rightChevronIcon: Icon(Icons.chevron_right, color: isDarkMode ? Colors.white : Colors.black87),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.black87),
              weekendStyle: TextStyle(color: isDarkMode ? Colors.teal[200] : Colors.teal[800]),
            ),
          ),
          
          const SizedBox(height: 10),
          
          // --- 2. LISTA DE TAREAS DEL DÍA SELECCIONADO ---
          Expanded(
            child: _obtenerTareasParaElDia(_diaSeleccionado!).isEmpty
                ? Center(
                    child: Text(
                      "No hay reuniones para este día.",
                      style: TextStyle(color: isDarkMode ? Colors.grey[500] : Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: _obtenerTareasParaElDia(_diaSeleccionado!).length,
                    itemBuilder: (context, index) {
                      final tarea = _obtenerTareasParaElDia(_diaSeleccionado!)[index];
                      
                      // Tu lógica de estado: Si es 'Completado', es true.
                      final estaCompletada = tarea.estado == 'Completado';
                      
                      // Formateamos la hora para que se vea bonita (Ej: 02:30 PM)
                      final horaFormat = DateFormat.jm().format(tarea.fechaProgramada);
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 2,
                        color: isDarkMode ? Colors.grey[850] : Colors.white,
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: estaCompletada 
                                  ? (isDarkMode ? Colors.green[900] : Colors.green[100]) 
                                  : (isDarkMode ? Colors.orange[900] : Colors.orange[100]),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              estaCompletada ? Icons.check : Icons.access_time,
                              color: estaCompletada 
                                  ? (isDarkMode ? Colors.green[300] : Colors.green) 
                                  : (isDarkMode ? Colors.orange[300] : Colors.orange),
                            ),
                          ),
                          title: Text(
                            tarea.descripcion, // Usamos la descripción de tu modelo
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              decoration: estaCompletada ? TextDecoration.lineThrough : null,
                              color: estaCompletada 
                                  ? Colors.grey 
                                  : (isDarkMode ? Colors.white : Colors.black),
                            ),
                          ),
                          // Mostramos el nombre del cliente si existe, y la hora
                          subtitle: Text(
                            tarea.nombreCliente != null 
                              ? "Cliente: ${tarea.nombreCliente}\nHora: $horaFormat" 
                              : "Hora: $horaFormat",
                            style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                          ),
                          isThreeLine: tarea.nombreCliente != null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // --- BOTÓN DE ELIMINAR ---
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () => _confirmarEliminacion(context, tarea),
                              ),
                              // --- TU CHECKBOX ACTUAL ---
                              Checkbox(
                                value: estaCompletada,
                                activeColor: Colors.teal,
                                onChanged: (bool? valorNuevo) async {
                                  final nuevoEstado = (valorNuevo == true) ? 'Completado' : 'Pendiente';
                                  setState(() => tarea.estado = nuevoEstado);
                                  if (tarea.id != null) {
                                    await SupabaseService.instance.actualizarEstadoRecordatorio(tarea.id!, nuevoEstado);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal[800],
        child: const Icon(Icons.add, color: Colors.white),
      onPressed: () {
          _mostrarFormularioNuevaTarea(context);
        },
      ),
    );
  }
  void _mostrarFormularioNuevaTarea(BuildContext context) {
    final TextEditingController _descripcionController = TextEditingController();
    final TextEditingController _detalleController = TextEditingController(); 
    DateTime _fechaSeleccionada = _diaSeleccionado ?? DateTime.now();
    TimeOfDay _horaSeleccionada = TimeOfDay.now();
    
    // 🔔 Variable para los minutos (dentro de la función)
    int _minutosDeAviso = 30; 

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder( // <--- Vital para que el Dropdown cambie visualmente
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 20, left: 20, right: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Nueva Cita Comercial", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                
                // --- CAMPO 1: TÍTULO PRINCIPAL ---
                TextField(
                  controller: _descripcionController,
                  decoration: const InputDecoration(
                    labelText: "Título de la cita (Ej: Visita a Taller)", 
                    border: OutlineInputBorder(), 
                    prefixIcon: Icon(Icons.edit)
                  ),
                ),
                const SizedBox(height: 15),
                
                // --- CAMPO 2: DESCRIPCIÓN EXTRA ---
                TextField(
                  controller: _detalleController,
                  maxLines: 2, // Permite escribir un par de líneas
                  decoration: const InputDecoration(
                    labelText: "Pequeña descripción (Opcional)", 
                    hintText: "Ej: Llevar catálogos físicos...",
                    border: OutlineInputBorder(), 
                    prefixIcon: Icon(Icons.notes)
                  ),
                ),
                const SizedBox(height: 15),
                
                
                // --- EL DROPDOWN (Selector de tiempo) ---
                const Text("Avisarme antes:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _minutosDeAviso,
                  decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.timer)),
                  items: const [
                    DropdownMenuItem(value: 10, child: Text("10 minutos antes")),
                    DropdownMenuItem(value: 30, child: Text("30 minutos antes")),
                    DropdownMenuItem(value: 60, child: Text("1 hora antes")),
                  ],
                  onChanged: (val) => setModalState(() => _minutosDeAviso = val!),
                ),
                
                const SizedBox(height: 15),
                ListTile(
                  leading: const Icon(Icons.access_time, color: Colors.teal),
                  title: Text("Hora: ${_horaSeleccionada.format(context)}"),
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: _horaSeleccionada);
                    if (picked != null) setModalState(() => _horaSeleccionada = picked);
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[800], foregroundColor: Colors.white),
                    onPressed: () async {
                      if (_descripcionController.text.isEmpty) return;

                      final navigator = Navigator.of(context);

                      final DateTime fechaFinal = DateTime(
                        _fechaSeleccionada.year, _fechaSeleccionada.month, _fechaSeleccionada.day,
                        _horaSeleccionada.hour, _horaSeleccionada.minute,
                      );

                      // 1. UNIMOS LOS TEXTOS PARA LA BASE DE DATOS
                      String textoBD = _descripcionController.text;
                      if (_detalleController.text.trim().isNotEmpty) {
                        textoBD += "\nNota: ${_detalleController.text.trim()}"; // Lo separa con un salto de línea
                      }

                      // Guardamos en Supabase
                      await SupabaseService.instance.insertarRecordatorio(Recordatorio(
                        usuarioId: widget.usuarioActual.id!,
                        fechaProgramada: fechaFinal,
                        descripcion: textoBD, // Mandamos el texto unido
                        estado: 'Pendiente',
                      ));

                      // 2. SEPARAMOS LOS TEXTOS PARA LA NOTIFICACIÓN
                      final horaAlarma = fechaFinal.subtract(Duration(minutes: _minutosDeAviso));
                      final int idNoti = DateTime.now().millisecondsSinceEpoch.remainder(100000);
                      
                      // Si no escribió descripción, le ponemos un texto genérico
                      String cuerpoNotificacion = _detalleController.text.trim().isEmpty 
                          ? "Revisa tu agenda para más detalles." 
                          : _detalleController.text.trim();

                      await NotificationService().programarNotificacion(
                        idNoti,
                        "⏰ ${_descripcionController.text}", // El título principal
                        cuerpoNotificacion, // La pequeña descripción
                        horaAlarma,
                      );

                      navigator.pop();
                      _cargarRecordatoriosDesdeBD();
                    },
                    child: const Text("AGENDAR CITA"),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        }
      ),
    );
  }
  void _confirmarEliminacion(BuildContext context, Recordatorio tarea) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("¿Eliminar cita?"),
      content: Text("¿Estás seguro de borrar: '${tarea.descripcion}'?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("CANCELAR"),
        ),
        TextButton(
          onPressed: () async {
            if (tarea.id != null) {
              await SupabaseService.instance.eliminarRecordatorio(tarea.id!);
              Navigator.pop(context);
              _cargarRecordatoriosDesdeBD(); // Refresca la lista
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Cita eliminada correctamente")),
              );
            }
          },
          child: const Text("ELIMINAR", style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}
}