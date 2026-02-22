import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    // CORRECCIÓN 1: La etiqueta es "settings:"
    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings, 
      onDidReceiveNotificationResponse: (NotificationResponse response) {},
    );

    _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> programarNotificacion(int id, String titulo, String cuerpo, DateTime fechaHora) async {
    final fechaAviso = fechaHora.subtract(const Duration(minutes: 30));

    if (fechaAviso.isBefore(DateTime.now())) return;

    // CORRECCIÓN 2: Todos los parámetros ahora llevan su etiqueta (id:, title:, body:, etc.)
  await _flutterLocalNotificationsPlugin.zonedSchedule(
        id: id,
        title: titulo,
        body: cuerpo,
        scheduledDate: tz.TZDateTime.from(fechaAviso, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'canal_agenda', 
            'Notificaciones de Agenda', 
            channelDescription: 'Recordatorios de citas comerciales',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/launcher_icon',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, 
      ); // <-- ¡Aquí termina, sin la otra línea!
    }
}