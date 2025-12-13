# Build Configuration Expert Sub-Agent

## Purpose
Manage Android/iOS build configurations and flavors.

## Responsibilities
1. Setup dev/staging/prod flavors
2. Configure signing (Android keystore, iOS certificates)
3. Manage build.gradle and Podfile
4. Environment variables setup

## Flavor Example
```dart
// lib/main_dev.dart
void main() {
  const environment = Environment.dev;
  runApp(MyApp(environment: environment));
}

// lib/main_prod.dart
void main() {
  const environment = Environment.prod;
  runApp(MyApp(environment: environment));
}
```

## Build Commands
```bash
flutter build apk --flavor prod
flutter build ios --flavor prod
```
