# 🔐 Authentication Feature

Comprehensive authentication system for SubMate with Clean Architecture implementation.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [User Flows](#user-flows)
- [Project Structure](#project-structure)
- [Key Components](#key-components)
- [Security](#security)
- [Testing](#testing)
- [Usage Examples](#usage-examples)

---

## 🎯 Overview

The authentication feature provides a complete user authentication system including:

- ✅ User Registration with validation
- ✅ Email/Password Login
- ✅ Session Management (30-day expiration)
- ✅ Secure local storage (FlutterSecureStorage + Hive)
- ✅ Password hashing (SHA-256)
- ✅ Form validation with real-time feedback
- ✅ Beautiful Material 3 UI
- ✅ Hero animations between screens
- ✅ Auto-redirect based on auth state

---

## 🏗️ Architecture

This feature follows **Clean Architecture** principles with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Screens    │  │   Widgets    │  │   Providers  │      │
│  │              │  │              │  │  (Riverpod)  │      │
│  │ - Login      │  │ - AuthField  │  │              │      │
│  │ - Register   │  │ - AuthButton │  │ - AuthState  │      │
│  │ - Splash     │  │ - Password   │  │ - FormState  │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                           ↓ ↑
┌─────────────────────────────────────────────────────────────┐
│                     DOMAIN LAYER                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Use Cases   │  │  Entities    │  │ Repositories │      │
│  │              │  │              │  │  (Abstract)  │      │
│  │ - Register   │  │ - User       │  │              │      │
│  │ - Login      │  │ - Session    │  │ - AuthRepo   │      │
│  │ - Logout     │  │              │  │              │      │
│  │ - CheckAuth  │  │              │  │              │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                           ↓ ↑
┌─────────────────────────────────────────────────────────────┐
│                      DATA LAYER                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Repository  │  │    Models    │  │ Data Sources │      │
│  │     Impl     │  │              │  │              │      │
│  │              │  │ - UserModel  │  │ - UserLocal  │      │
│  │ - AuthRepo   │  │ - Session    │  │ - AuthLocal  │      │
│  │   Impl       │  │ - Credentials│  │              │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                           ↓ ↑
┌─────────────────────────────────────────────────────────────┐
│                   STORAGE LAYER                              │
│  ┌──────────────┐              ┌──────────────┐            │
│  │     Hive     │              │    Secure    │            │
│  │   Database   │              │   Storage    │            │
│  │              │              │              │            │
│  │ - Users      │              │ - Sessions   │            │
│  │ - Credentials│              │ - Tokens     │            │
│  └──────────────┘              └──────────────┘            │
└─────────────────────────────────────────────────────────────┘
```

### Layer Responsibilities

**🎨 Presentation Layer**
- UI rendering (Screens, Widgets)
- User interaction handling
- State management (Riverpod providers)
- Navigation (GoRouter)

**💼 Domain Layer**
- Business logic (Use Cases)
- Core entities (User, Session)
- Repository contracts (interfaces)
- Validation rules

**💾 Data Layer**
- Repository implementations
- Data models (with Freezed)
- Local data sources (Hive, SecureStorage)
- Data transformation (Model ↔ Entity)

---

## 🔄 User Flows

### 1. App Launch Flow

```
┌──────────┐
│   App    │
│  Start   │
└─────┬────┘
      │
      ▼
┌──────────────┐
│ SplashScreen │ ← Hero Animation
└──────┬───────┘
       │
       ▼
┌──────────────────┐
│ CheckAuthStatus  │
└──────┬───────────┘
       │
       ├─── Has Session? ───┐
       │                    │
       ▼ YES                ▼ NO
┌──────────┐         ┌────────────┐
│   Home   │         │   Login    │
│  Screen  │         │   Screen   │
└──────────┘         └────────────┘
```

### 2. Registration Flow

```
┌────────────┐
│   Login    │
│   Screen   │
└─────┬──────┘
      │ Click "Sign Up"
      ▼
┌────────────┐
│  Register  │
│   Screen   │
└─────┬──────┘
      │ Fill Form
      │ - Full Name
      │ - Email
      │ - Password
      │ - Confirm Password
      │ - Accept Terms
      ▼
┌────────────────┐
│   Validation   │
│                │
│ - Email format │
│ - Password >8  │
│ - Passwords =  │
│ - Terms OK     │
└────┬───────────┘
     │ Valid
     ▼
┌────────────────┐
│ RegisterUser   │
│   Use Case     │
└────┬───────────┘
     │ Success
     ▼
┌────────────────┐
│  Auto Login    │
└────┬───────────┘
     │
     ▼
┌────────────┐
│   Home     │
│  Screen    │
└────────────┘
```

### 3. Login Flow

```
┌────────────┐
│   Login    │
│   Screen   │
└─────┬──────┘
      │ Enter:
      │ - Email
      │ - Password
      ▼
┌────────────────┐
│   Validation   │
└────┬───────────┘
     │ Valid
     ▼
┌────────────────┐
│   LoginUser    │
│   Use Case     │
└────┬───────────┘
     │
     ├─── Verify Credentials ────┐
     │                            │
     ▼ SUCCESS                    ▼ FAIL
┌────────────┐           ┌─────────────┐
│   Create   │           │Show Error   │
│  Session   │           │"Invalid..."│
└─────┬──────┘           └─────────────┘
      │
      ▼
┌────────────┐
│Store Token │
│  (Secure)  │
└─────┬──────┘
      │
      ▼
┌────────────┐
│   Home     │
│  Screen    │
└────────────┘
```

---

## 📁 Project Structure

```
lib/features/auth/
├── data/
│   ├── datasources/
│   │   ├── auth_local_datasource.dart      # Session management (SecureStorage)
│   │   └── user_local_datasource.dart      # User CRUD (Hive)
│   ├── models/
│   │   ├── auth_session_model.dart         # Session data model
│   │   ├── user_model.dart                 # User data model
│   │   └── user_credentials_model.dart     # Credentials model
│   └── repositories/
│       └── auth_repository_impl.dart       # Repository implementation
│
├── domain/
│   ├── entities/
│   │   ├── auth_session.dart               # Session entity (Freezed)
│   │   └── user.dart                       # User entity (Freezed)
│   ├── repositories/
│   │   └── auth_repository.dart            # Repository contract + Failures
│   └── usecases/
│       ├── check_auth_status.dart          # Check if user is authenticated
│       ├── get_current_user.dart           # Get logged-in user
│       ├── login_user.dart                 # Login use case
│       ├── logout_user.dart                # Logout use case
│       └── register_user.dart              # Registration use case
│
└── presentation/
    ├── providers/
    │   ├── auth_provider.dart              # Global auth state
    │   ├── login_form_provider.dart        # Login form state
    │   └── register_form_provider.dart     # Register form state
    ├── screens/
    │   ├── login_screen.dart               # Login UI
    │   └── register_screen.dart            # Registration UI
    └── widgets/
        ├── auth_button.dart                # Reusable auth button
        ├── auth_text_field.dart            # Reusable text field
        └── password_strength_indicator.dart # Password strength widget
```

---

## 🔑 Key Components

### Use Cases

**RegisterUser** - Validates and creates new user accounts
**LoginUser** - Authenticates users and creates sessions
**CheckAuthStatus** - Verifies active sessions on app startup

### Providers (Riverpod)

**AuthProvider** - Global authentication state (initial/loading/authenticated/unauthenticated/error)
**LoginFormProvider** - Login form validation and submission
**RegisterFormProvider** - Registration form with password strength

### Data Sources

**UserLocalDataSource** - Hive-based user storage with SHA-256 password hashing
**AuthLocalDataSource** - SecureStorage-based session management with UUID tokens

---

## 🔒 Security

### Password Security
- SHA-256 hashing (⚠️ production should add per-user salt)
- Consider bcrypt/argon2 for production

### Session Security
- UUID v4 tokens (cryptographically secure)
- FlutterSecureStorage (OS-level encryption)
- 30-day expiration with auto-cleanup

### Data Storage
- **Sessions:** ✅ Encrypted (SecureStorage)
- **Users/Credentials:** ⚠️ Unencrypted (TODO: Enable Hive encryption)

---

## 🧪 Testing

### Current Coverage
- ✅ User Entity: 34 tests
- ✅ RegisterUser Use Case: 13 tests
- ❌ Data Layer: 0 tests (TODO)
- ❌ Presentation Layer: 0 tests (TODO)

```bash
# Run tests
flutter test

# With coverage
flutter test --coverage
```

---

## 💡 Usage Examples

### Check Auth on Startup
```dart
ref.read(authProvider.notifier).checkAuth();
```

### Watch Auth State
```dart
final authState = ref.watch(authProvider);
authState.when(
  authenticated: (user) => HomeScreen(user: user),
  unauthenticated: () => LoginScreen(),
  // ...
);
```

### Login
```dart
final success = await ref.read(loginFormProvider.notifier).submit();
```

### Logout
```dart
await ref.read(authProvider.notifier).logout();
```

---

## 🚀 Future Enhancements

- [ ] Email verification
- [ ] Password reset
- [ ] Biometric auth
- [ ] Social login
- [ ] 2FA
- [ ] Session refresh tokens

---

**Last Updated:** 2025-12-14
**Status:** ✅ Ready (except tests & encryption)
