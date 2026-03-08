import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/navigation/main_shell.dart';
import 'presentation/theme/app_theme.dart';

class CryptoBotApp extends ConsumerWidget {
  const CryptoBotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'CryptoBot',
      theme: appTheme,
      home: const MainShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}
