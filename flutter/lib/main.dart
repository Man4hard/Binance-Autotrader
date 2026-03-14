import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/hive_init.dart';
import 'data/services/background_service_initializer.dart';
import 'data/services/notification_service.dart';
import 'presentation/providers/providers.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF141824),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await initHive();
  await initializeBackgroundService();
  await NotificationService().init();

  // Check if the trading engine survived the UI being killed by Android.
  // Thanks to android:stopWithTask="false" in the manifest, the foreground
  // service keeps running even when the user swipes the app from recents.
  // We must restore the UI's engine-running state to match reality.
  final engineWasRunning = await FlutterBackgroundService().isRunning();

  runApp(
    ProviderScope(
      overrides: [
        if (engineWasRunning)
          engineRunningProvider
              .overrideWith(() => _RestoredEngineRunningNotifier()),
      ],
      child: const CryptoBotApp(),
    ),
  );
}

/// Restores engine-running UI state to `true` when the background service
/// survived a process death. Extends the public [EngineRunningNotifier]
/// so the provider type system accepts the override.
class _RestoredEngineRunningNotifier extends EngineRunningNotifier {
  @override
  bool build() => true;
}
