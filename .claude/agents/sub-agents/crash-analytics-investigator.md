# Crash Analytics Investigator Sub-Agent

## Purpose
Integrate Firebase Crashlytics and analyze crash reports.

## Using Context7 MCP for Latest Crashlytics Practices

**ALWAYS** verify Firebase Crashlytics integration with Context7.

### Critical Queries for Context7:
```
- "Latest Firebase Crashlytics Flutter integration"
- "Current Firebase Crashlytics custom logging patterns"
- "Flutter error handling and crash reporting best practices"
- "Firebase Crashlytics symbolication for Flutter apps"
- "Latest FlutterError.onError configuration patterns"
```

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
