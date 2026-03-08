import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/constants.dart';
import 'trading_engine_service.dart';

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(
        const AndroidNotificationChannel(
          AppConstants.notificationChannelId,
          AppConstants.notificationChannelName,
          description: 'CryptoBot background trading engine',
          importance: Importance.low,
        ),
      );

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onEngineStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: AppConstants.notificationChannelId,
      initialNotificationTitle: 'CryptoBot',
      initialNotificationContent: 'Engine ready…',
      foregroundServiceNotificationId: AppConstants.engineNotificationId,
    ),
    iosConfiguration: IosConfiguration(autoStart: false),
  );
}
