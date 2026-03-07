# Security Auditor Sub-Agent

## Purpose
Identify security vulnerabilities and enforce secure practices.

## Security Checklist
- [ ] No hardcoded API keys
- [ ] Sensitive data encrypted (Hive with HiveAES)
- [ ] Tokens in flutter_secure_storage
- [ ] SSL pinning for API calls
- [ ] Input validation on all forms
- [ ] No SQL injection vulnerabilities

## Hive Encryption Example
```dart
final encryptionKey = await getSecureKey();
await Hive.openBox<UserModel>(
  'users',
  encryptionCipher: HiveAesCipher(encryptionKey),
);
```
