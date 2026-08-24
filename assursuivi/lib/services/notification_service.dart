import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../models/subscription_model.dart';
import '../models/vehicle_model.dart';
import '../models/client_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    try {
      tz_data.initializeTimeZones();

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(initSettings);

      // Demande explicite des permissions Android 13+ et alarmes exactes
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();

      _initialized = true;
    } catch (_) {
      // Ignoré si plateforme sans support natif immédiat
    }
  }

  /// Envoie une notification instantanée de confirmation ou de test
  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    if (!_initialized) await init();

    const NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        'assursuivi_instant',
        'Notifications AssurSuivi',
        channelDescription: 'Alertes et confirmations AssurSuivi',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _notificationsPlugin.show(
        DateTime.now().millisecond,
        title,
        body,
        details,
      );
    } catch (_) {}
  }

  /// Programme des rappels à J-15, J-7, J-3, J-1 et le jour J
  Future<void> scheduleSubscriptionAlerts({
    required SubscriptionModel subscription,
    required VehicleModel vehicle,
    required ClientModel client,
  }) async {
    if (!_initialized) await init();

    final endDate = subscription.endDate;
    final alertDaysBefore = [15, 7, 3, 1, 0];

    for (final daysBefore in alertDaysBefore) {
      final scheduledDate = endDate.subtract(Duration(days: daysBefore));
      if (scheduledDate.isAfter(DateTime.now())) {
        final notificationId = '${subscription.id.hashCode}_$daysBefore'.hashCode.abs() % 100000;

        final String title = daysBefore == 0
            ? '⚠️ Échéance aujourd\'hui : ${vehicle.registrationNumber}'
            : '🔔 Échéance dans $daysBefore jours : ${vehicle.registrationNumber}';

        final String body = 'L\'assurance de ${client.fullName} pour ${vehicle.brand} ${vehicle.model} arrive à expiration le ${endDate.day}/${endDate.month}/${endDate.year}.';

        try {
          await _notificationsPlugin.zonedSchedule(
            notificationId,
            title,
            body,
            tz.TZDateTime.from(scheduledDate, tz.local),
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'assursuivi_echeances',
                'Échéances d\'assurances',
                channelDescription: 'Alertes pour le renouvellement des souscriptions d\'assurance',
                importance: Importance.high,
                priority: Priority.high,
              ),
              iOS: DarwinNotificationDetails(),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        } catch (_) {
          // Gère les permissions sur Android 13+
        }
      }
    }
  }

  /// Annule les notifications associées à une souscription
  Future<void> cancelSubscriptionAlerts(String subscriptionId) async {
    final alertDaysBefore = [15, 7, 3, 1, 0];
    for (final daysBefore in alertDaysBefore) {
      final notificationId = '${subscriptionId.hashCode}_$daysBefore'.hashCode.abs() % 100000;
      try {
        await _notificationsPlugin.cancel(notificationId);
      } catch (_) {}
    }
  }
}
