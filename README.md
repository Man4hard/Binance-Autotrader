Here is every version you need, pulled directly from the project files:

Android Studio
Tool	Version
Android Studio	Ladybug (2024.2.1) or newer
JDK	17 (must be Java 17 — Java 8/11 will fail with AGP 8.x)
Flutter & Dart
Tool	Version
Flutter SDK	3.24.0 or newer
Dart SDK	3.4.0 or newer (comes bundled with Flutter 3.24+)
Android SDK (install via SDK Manager in Android Studio)
Component	Version
compileSdk	35 (Android 15)
targetSdk	35
minSdk	21 (Android 5.0+)
NDK	27.0.12077973 (install this exact version via SDK Manager → NDK)
Build Tools	35.0.0
Gradle & AGP
Tool	Version
Gradle Wrapper	8.12
Android Gradle Plugin (AGP)	8.7.3
Kotlin	2.1.0
Flutter Packages (from pubspec.yaml)
Package	Version
flutter_riverpod	^2.6.1
hive + hive_flutter	^2.2.3 / ^1.1.0
flutter_background_service	^5.0.9
flutter_local_notifications	^18.0.1
flutter_secure_storage	^9.2.4
webview_flutter	^4.10.0
permission_handler	^11.3.1
http	^1.2.2
fl_chart	^0.70.2
intl	^0.20.2
Setup Steps in Android Studio
Install Android Studio Ladybug or newer
In Settings → Build, Execution, Deployment → Build Tools → Gradle → set Gradle JDK to JDK 17
Open SDK Manager → SDK Platforms → install Android 15 (API 35)
Open SDK Manager → SDK Tools → install NDK (Side by side) version 27.0.12077973
Install Flutter plugin in Android Studio plugins
Set Flutter SDK path to your Flutter 3.24+ installation
Open the flutter/ folder as the project root
Run flutter pub get in the terminal
Let Gradle sync — it will auto-download Gradle 8.12 and AGP 8.7.3
