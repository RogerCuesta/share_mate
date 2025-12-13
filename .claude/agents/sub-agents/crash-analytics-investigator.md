# Crash Analytics Investigator Sub-Agent

## Purpose
Integrate Firebase Crashlytics and analyze crash reports.

## Setup
```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
  await Firebase.initializeApp();
  
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  
  runApp(const MyApp());
}
```

## Custom Error Logging
```dart
try {
  await riskyOperation();
} catch (e, stack) {
  FirebaseCrashlytics.instance.recordError(e, stack);
}
```
