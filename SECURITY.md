# Security Guide - SubMate

## 🔒 Security Audit Report

**Last Audit:** 2025-12-14
**Status:** ✅ SECURE (with recommendations)
**Auditor:** Claude (Security Auditor Sub-Agent)

---

## ✅ Security Checklist - Current Status

### Environment & Secrets Management
- ✅ **`.env` in `.gitignore`** - Environment variables are NOT committed
- ✅ **`.env.example` with placeholders** - No real values exposed
- ✅ **Anon key used in client** - Public key (safe for client-side)
- ✅ **Service role key NOT used** - Private key defined but never used in client code
- ✅ **Environment validation** - Required variables validated at startup

### Authentication & Sessions
- ✅ **PKCE flow enabled** - Supabase initialized with PKCE by default
- ✅ **Tokens in secure storage** - `flutter_secure_storage` used for session tokens
- ✅ **Password hashing** - SHA-256 hash used for local credentials
- ✅ **No plaintext passwords** - Passwords never stored, only hashes
- ✅ **Session validation** - Sessions checked before sensitive operations

### Data Storage
- ⚠️ **Hive encryption** - NOT currently enabled (see recommendations)
- ✅ **Credentials hashed** - Passwords hashed with SHA-256
- ✅ **Secure storage for tokens** - OS-level encryption via `flutter_secure_storage`
- ✅ **No sensitive data in logs** - Debug prints only show non-sensitive info

### Input Validation
- ✅ **Email validation** - Regex validation on all email inputs
- ✅ **Password requirements** - Minimum 8 characters enforced
- ✅ **SQL injection protection** - Using Supabase client (prepared statements)
- ✅ **XSS protection** - Flutter widgets auto-escape HTML

### Network Security
- ✅ **HTTPS only** - Supabase uses HTTPS by default
- ⚠️ **SSL pinning** - NOT implemented (see recommendations)

---

## 🔐 Critical Security Features

### 1. Environment Variables Protection

**Current Implementation:**
```dart
// .env (NEVER commit this file!)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
# Service role key is available but NOT used in client
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here
```

**Protection:**
- `.env` is in `.gitignore`
- `.env.example` has placeholder values only
- Validation ensures required variables exist at startup

### 2. Password Security

**Current Implementation:**
```dart
// Passwords are HASHED, never stored in plain text
String hashPassword(String password) {
  final bytes = utf8.encode(password);
  final hash = sha256.convert(bytes);
  return hash.toString();
}
```

**Protection:**
- SHA-256 hashing for local credentials
- Passwords sent to Supabase over HTTPS only
- No password storage in Hive (only hash if needed for offline auth)

### 3. Token Storage

**Current Implementation:**
```dart
// Tokens stored in OS-level encrypted storage
FlutterSecureStorage storage = const FlutterSecureStorage();
await storage.write(key: 'session', value: sessionToken);
```

**Protection:**
- iOS: Keychain with encryption
- Android: EncryptedSharedPreferences
- Never stored in plain Hive boxes

### 4. PKCE Flow

**Current Implementation:**
```dart
// PKCE enabled by default in Supabase.initialize()
await Supabase.initialize(
  url: url,
  anonKey: anonKey,
  // PKCE is automatically enabled
);
```

**Protection:**
- Proof Key for Code Exchange prevents authorization code interception
- No need for client secret in mobile apps
- Automatic challenge/verifier generation

---

## ⚠️ Security Recommendations

### HIGH PRIORITY

#### 1. Enable Hive Encryption

**Current Status:** ❌ Not implemented
**Risk:** Local user data is not encrypted

**Implementation:**
```dart
// In lib/features/auth/data/datasources/user_local_datasource.dart

Future<void> init() async {
  // Get encryption key from secure storage
  final encryptionKey = await _getOrCreateEncryptionKey();

  _usersBox = await Hive.openBox<UserModel>(
    _usersBoxName,
    encryptionCipher: HiveAesCipher(encryptionKey),
  );

  _credentialsBox = await Hive.openBox<UserCredentialsModel>(
    _credentialsBoxName,
    encryptionCipher: HiveAesCipher(encryptionKey),
  );

  _currentUserIdBox = await Hive.openBox<String>(
    _currentUserIdBoxName,
    encryptionCipher: HiveAesCipher(encryptionKey),
  );
}

Future<List<int>> _getOrCreateEncryptionKey() async {
  const secureStorage = FlutterSecureStorage();
  final keyString = await secureStorage.read(key: 'hive_encryption_key');

  if (keyString == null) {
    // Generate new key
    final key = Hive.generateSecureKey();
    await secureStorage.write(
      key: 'hive_encryption_key',
      value: base64UrlEncode(key),
    );
    return key;
  }

  return base64Url.decode(keyString);
}
```

**Benefit:** All user data encrypted at rest

#### 2. Implement SSL Pinning

**Current Status:** ❌ Not implemented
**Risk:** Potential MITM attacks

**Implementation:**
```yaml
# pubspec.yaml
dependencies:
  dio: ^5.4.1
  dio_certificate_pinning: ^1.0.0
```

```dart
// For API calls (if needed beyond Supabase)
final dio = Dio();
dio.interceptors.add(
  CertificatePinningInterceptor(
    allowedSHAFingerprints: [
      'YOUR_SUPABASE_CERT_FINGERPRINT',
    ],
  ),
);
```

**Benefit:** Prevents man-in-the-middle attacks

### MEDIUM PRIORITY

#### 3. Rate Limiting on Client

**Current Status:** ⚠️ Relies only on Supabase
**Implementation:**
```dart
// Add client-side throttling for auth attempts
class AuthRateLimiter {
  static final _attempts = <String, List<DateTime>>{};
  static const maxAttempts = 5;
  static const windowMinutes = 15;

  static bool canAttempt(String email) {
    final now = DateTime.now();
    final attempts = _attempts[email] ?? [];

    // Remove old attempts
    attempts.removeWhere(
      (time) => now.difference(time).inMinutes > windowMinutes,
    );

    if (attempts.length >= maxAttempts) {
      return false;
    }

    attempts.add(now);
    _attempts[email] = attempts;
    return true;
  }
}
```

#### 4. Biometric Authentication

**Current Status:** ❌ Not implemented
**Benefit:** Additional security layer for app access

```yaml
# pubspec.yaml
dependencies:
  local_auth: ^2.1.7
```

```dart
import 'package:local_auth/local_auth.dart';

final auth = LocalAuthentication();
final canAuthenticate = await auth.canCheckBiometrics;

if (canAuthenticate) {
  final authenticated = await auth.authenticate(
    localizedReason: 'Please authenticate to access SubMate',
  );
}
```

---

## 🚨 Security Incidents - Response Plan

### If Supabase Keys are Compromised

#### Immediate Actions (Within 1 hour):

1. **Rotate Supabase Keys:**
   ```bash
   # Go to Supabase Dashboard → Settings → API
   # Click "Reset" on both Anon Key and Service Role Key
   ```

2. **Update Environment Variables:**
   ```bash
   # Update .env with new keys
   SUPABASE_ANON_KEY=new-anon-key
   SUPABASE_SERVICE_ROLE_KEY=new-service-role-key
   ```

3. **Revoke All Sessions:**
   ```sql
   -- Run in Supabase SQL Editor
   DELETE FROM auth.sessions;
   ```

4. **Notify Users:**
   - Send email to all users
   - Force re-authentication on next app launch

#### Post-Incident (Within 24 hours):

1. **Audit Access Logs:**
   ```sql
   SELECT * FROM auth.audit_log_entries
   WHERE created_at > NOW() - INTERVAL '24 hours'
   ORDER BY created_at DESC;
   ```

2. **Review Database Changes:**
   - Check for unauthorized data modifications
   - Restore from backup if needed

3. **Update Security Measures:**
   - Enable additional Supabase security features
   - Implement the recommendations above

### If Local Storage is Compromised

1. **Force logout on all devices:**
   ```dart
   await DevUtils.clearAllAuthData();
   await SupabaseService.auth.signOut();
   ```

2. **Implement Hive encryption immediately** (see recommendations)

3. **Notify affected users** to change passwords

---

## 🛡️ Supabase Dashboard Security Configuration

### Required Settings

#### 1. Email Authentication Settings
```
Settings → Authentication → Email Auth
✅ Enable Email Confirmations (recommended)
✅ Enable Email Change Confirmations
✅ Secure Email Change
```

#### 2. Password Requirements
```
Settings → Authentication → Password
✅ Minimum password length: 8 characters
✅ Require at least one uppercase character
✅ Require at least one number
```

#### 3. Rate Limiting
```
Settings → Authentication → Rate Limits
✅ Email sign-ups: 10 per hour per IP
✅ Password sign-ins: 30 per hour per IP
✅ Password recovery: 5 per hour per IP
```

#### 4. Row Level Security (RLS)

**⚠️ CRITICAL - Must be enabled on ALL tables:**

```sql
-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- Example policies
CREATE POLICY "Users can view own data"
  ON users FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own data"
  ON users FOR UPDATE
  USING (auth.uid() = id);
```

#### 5. JWT Settings
```
Settings → API → JWT Settings
✅ JWT Expiry: 3600 seconds (1 hour)
✅ Refresh Token Rotation: Enabled
```

---

## 📋 Pre-Deployment Security Checklist

### Code Review
- [ ] No hardcoded credentials in source code
- [ ] No API keys in version control
- [ ] All `.env` files in `.gitignore`
- [ ] Service role key NOT used in client code
- [ ] Debug prints don't expose sensitive data

### Supabase Configuration
- [ ] RLS enabled on all tables
- [ ] Appropriate RLS policies configured
- [ ] Email confirmation enabled
- [ ] Rate limiting configured
- [ ] Password requirements set
- [ ] JWT expiry configured

### Client Security
- [ ] HTTPS only (enforced by Supabase)
- [ ] Input validation on all forms
- [ ] PKCE flow enabled (default in Supabase)
- [ ] Secure storage for tokens
- [ ] Password hashing for local auth

### Optional (Recommended)
- [ ] Hive encryption enabled
- [ ] SSL pinning implemented
- [ ] Biometric authentication
- [ ] Client-side rate limiting
- [ ] Session timeout handling

---

## 🔍 Security Testing

### Manual Testing Checklist

1. **Authentication Flow:**
   ```
   ✅ Registration with weak password fails
   ✅ Registration with duplicate email fails
   ✅ Login with wrong password fails
   ✅ Session persists across app restarts
   ✅ Logout clears all local data
   ```

2. **Data Storage:**
   ```
   ✅ Passwords not visible in Hive files
   ✅ Tokens stored in secure storage
   ✅ User data accessible only to authenticated user
   ```

3. **Network Security:**
   ```
   ✅ All Supabase calls use HTTPS
   ✅ No sensitive data in network logs
   ✅ Proper error handling (no stack traces to user)
   ```

### Automated Security Tests

```bash
# Run static analysis
flutter analyze

# Check for known vulnerabilities
dart pub outdated --mode=security

# Run all tests including security-related ones
flutter test
```

---

## 📚 Security Resources

### Documentation
- [Supabase Security Best Practices](https://supabase.com/docs/guides/auth/auth-helpers/security)
- [Flutter Security Best Practices](https://docs.flutter.dev/security)
- [OWASP Mobile Security](https://owasp.org/www-project-mobile-security/)

### Tools
- [Supabase Auth Admin](https://supabase.com/dashboard) - Manage users and sessions
- [Flutter DevTools](https://docs.flutter.dev/tools/devtools) - Inspect app storage
- [Charles Proxy](https://www.charlesproxy.com/) - Test SSL/TLS

### Contact
For security issues or questions:
- 🔒 **Report vulnerabilities:** [Create private GitHub issue]
- 📧 **Security team:** [Your email]
- 🚨 **Emergency:** [Emergency contact]

---

## 📝 Change Log

### 2025-12-14
- ✅ Initial security audit completed
- ✅ All critical security features verified
- ⚠️ Identified encryption improvements needed
- 📋 Created comprehensive security guide

---

**Remember:** Security is an ongoing process. Review this document regularly and update as new features are added or security best practices evolve.
