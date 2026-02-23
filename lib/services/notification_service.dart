import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    tz.initializeTimeZones();
    
    // Aquí está el ícono oficial
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings, 
      onDidReceiveNotificationResponse: (NotificationResponse response) {},
    );

    // --- NUEVO: PEDIR PERMISOS A ANDROID 13+ EN PANTALLA ---
    if (Platform.isAndroid) {
      final androidImplementation = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();
    }
  }

  Future<void> programarNotificacion(int id, String titulo, String cuerpo, DateTime fechaHoraAviso) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    
    // Si la hora ya pasó, la ignoramos para evitar errores
    if (fechaHoraAviso.isBefore(DateTime.now())) return;

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: titulo,
      body: cuerpo,
      scheduledDate: tz.TZDateTime.from(fechaHoraAviso, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'canal_agenda', 
          'Notificaciones de Agenda', 
          channelDescription: 'Recordatorios de citas comerciales',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, 
    );
    
    print("🔔 Alarma de FASALE programada con éxito para: ${fechaHoraAviso.toString()}");
  }
}