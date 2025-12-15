# 💳 Subscriptions Feature

Comprehensive subscription management system for SubMate with shared cost tracking and payment management.

## 📋 Overview

The subscriptions feature allows users to manage shared subscription services (like Netflix, Spotify, etc.) and track payments from members who share the cost.

### Core Features
- ✅ Create and manage shared subscriptions
- ✅ Track monthly costs and split payments
- ✅ Monitor pending payments from members
- ✅ Mark payments as paid/unpaid
- ✅ View monthly statistics (total cost, pending collections)
- ✅ Identify overdue payments
- ✅ Support for monthly and yearly billing cycles

---

## 🏗️ Architecture

This feature follows **Clean Architecture** with three layers:

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Screens    │  │   Widgets    │  │   Providers  │      │
│  │              │  │              │  │  (Riverpod)  │      │
│  │ - Home       │  │ - StatsCard  │  │              │      │
│  │ - SubDetail  │  │ - SubCard    │  │ - Subs State │      │
│  │ - AddSub     │  │ - MemberCard │  │              │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                           ↓ ↑
┌─────────────────────────────────────────────────────────────┐
│                     DOMAIN LAYER                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Use Cases   │  │  Entities    │  │ Repositories │      │
│  │              │  │              │  │  (Abstract)  │      │
│  │ - GetStats   │  │ - Sub        │  │              │      │
│  │ - GetActive  │  │ - Member     │  │ - SubRepo    │      │
│  │ - MarkPaid   │  │ - Stats      │  │              │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                           ↓ ↑
┌─────────────────────────────────────────────────────────────┐
│                      DATA LAYER                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Repository  │  │    Models    │  │ Data Sources │      │
│  │     Impl     │  │              │  │              │      │
│  │              │  │ - SubModel   │  │ - SubRemote  │      │
│  │ - SubRepo    │  │ - MemberMod  │  │ - SubLocal   │      │
│  │   Impl       │  │ - StatsMod   │  │              │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
              ↓ ↑                          ↓ ↑
┌──────────────────────┐     ┌────────────────────────────────┐
│   SUPABASE BACKEND   │     │      LOCAL STORAGE             │
│  ┌────────────────┐  │     │  ┌──────────┐  ┌───────────┐ │
│  │ Subscriptions  │  │     │  │   Hive   │  │  Secure   │ │
│  │     Table      │  │     │  │ Database │  │  Storage  │ │
│  ├────────────────┤  │     │  │          │  │           │ │
│  │    Members     │  │     │  │ - Subs   │  │ - Cache   │ │
│  │     Table      │  │     │  │ - Members│  │           │ │
│  └────────────────┘  │     │  └──────────┘  └───────────┘ │
└──────────────────────┘     └────────────────────────────────┘
```

---

## 📁 Domain Layer Structure

### Entities

#### 1. **Subscription**
```dart
@freezed
class Subscription with _$Subscription {
  const factory Subscription({
    required String id,
    required String name,           // "Netflix", "Spotify"
    String? iconUrl,
    required String color,           // Hex color like "#E50914"
    required double totalCost,       // Total monthly/yearly cost
    required BillingCycle billingCycle,
    required DateTime dueDate,
    required String ownerId,         // User who pays main subscription
    @Default([]) List<String> sharedWith,  // User IDs
    @Default(SubscriptionStatus.active) SubscriptionStatus status,
    required DateTime createdAt,
  }) = _Subscription;
}
```

**Business Logic Methods:**
- `double get costPerPerson` - Cost divided by total members
- `int get totalMembers` - Total users sharing (including owner)
- `bool get isOverdue` - Check if payment is overdue
- `int get daysUntilDue` - Days until next payment (negative if overdue)
- `bool get isDueSoon` - True if due within 3 days
- `double get monthlyCost` - Convert yearly to monthly if needed

#### 2. **SubscriptionMember**
```dart
@freezed
class SubscriptionMember with _$SubscriptionMember {
  const factory SubscriptionMember({
    required String id,
    required String subscriptionId,
    required String userId,
    required String userName,
    String? userAvatar,
    required double amountToPay,
    @Default(false) bool hasPaid,
    DateTime? lastPaymentDate,
    required DateTime dueDate,
  }) = _SubscriptionMember;
}
```

**Business Logic Methods:**
- `int? get daysOverdue` - Days overdue (null if paid or not due)
- `bool get isOverdue` - Check if payment is overdue
- `bool get isDueSoon` - True if due within 3 days
- `int? get daysUntilDue` - Days until payment due
- `String get paymentStatus` - "Paid", "Overdue", "Due Soon", "Pending"

#### 3. **MonthlyStats**
```dart
@freezed
class MonthlyStats with _$MonthlyStats {
  const factory MonthlyStats({
    required double totalMonthlyCost,
    required double pendingToCollect,
    required int activeSubscriptionsCount,
    required int overduePaymentsCount,
    @Default(0.0) double collectedAmount,
    @Default(0) int paidMembersCount,
    @Default(0) int unpaidMembersCount,
  }) = _MonthlyStats;
}
```

**Business Logic Methods:**
- `double get collectionRate` - Percentage of payments collected
- `bool get hasOverduePayments` - True if any payments are overdue
- `bool get isFullyCollected` - True if all payments received
- `double get totalExpectedIncome` - Total expected (collected + pending)
- `double get averageCostPerSubscription` - Average per subscription

### Enums

```dart
enum BillingCycle {
  monthly,  // 1 month
  yearly;   // 12 months
}

enum SubscriptionStatus {
  active,
  cancelled,
  paused;
}
```

### Failures

```dart
@freezed
class SubscriptionFailure with _$SubscriptionFailure {
  const factory SubscriptionFailure.serverError(String message);
  const factory SubscriptionFailure.networkError();
  const factory SubscriptionFailure.cacheError(String message);
  const factory SubscriptionFailure.notFound();
  const factory SubscriptionFailure.unauthorized();
  const factory SubscriptionFailure.invalidData(String message);
  const factory SubscriptionFailure.alreadyExists(String message);
  const factory SubscriptionFailure.paymentError(String message);
  const factory SubscriptionFailure.memberError(String message);
}
```

### Repository Interface

```dart
abstract class SubscriptionRepository {
  // Stats & Lists
  Future<Either<SubscriptionFailure, MonthlyStats>> getMonthlyStats(String userId);
  Future<Either<SubscriptionFailure, List<Subscription>>> getActiveSubscriptions(String userId);
  Future<Either<SubscriptionFailure, List<SubscriptionMember>>> getPendingPayments(String userId);

  // CRUD Operations
  Future<Either<SubscriptionFailure, Subscription>> getSubscriptionById(String id);
  Future<Either<SubscriptionFailure, Subscription>> createSubscription(Subscription sub);
  Future<Either<SubscriptionFailure, Subscription>> updateSubscription(Subscription sub);
  Future<Either<SubscriptionFailure, Unit>> deleteSubscription(String id);

  // Member Operations
  Future<Either<SubscriptionFailure, SubscriptionMember>> markPaymentAsPaid({
    required String memberId,
    required DateTime paymentDate,
  });
  Future<Either<SubscriptionFailure, SubscriptionMember>> addMemberToSubscription({
    required String subscriptionId,
    required String userId,
    required String userName,
    String? userAvatar,
  });
}
```

### Use Cases

1. **GetMonthlyStats** - Get monthly statistics
2. **GetActiveSubscriptions** - Get active subscriptions
3. **GetPendingPayments** - Get unpaid members
4. **GetSubscriptionDetails** - Get subscription by ID
5. **CreateSubscription** - Create new subscription (with validation)
6. **UpdateSubscription** - Update subscription (with validation)
7. **DeleteSubscription** - Delete subscription + members
8. **MarkPaymentAsPaid** - Mark payment as paid

**Validation Rules (in Use Cases):**
- Subscription name: min 2 characters, required
- Total cost: must be > 0
- Owner ID: required
- Due date: cannot be in past (for new subscriptions)
- Color: must be valid hex format (#RRGGBB)
- Payment date: cannot be in future

---

## 📊 Business Rules

### Cost Calculation
```dart
// Example: Netflix $15.99/month shared by 4 people
Subscription netflix = Subscription(
  totalCost: 15.99,
  sharedWith: ['user2', 'user3', 'user4'],  // 3 users + owner = 4 total
);

print(netflix.costPerPerson);  // $3.9975 (15.99 / 4)
```

### Payment Status
- **Paid**: `hasPaid == true`
- **Pending**: `hasPaid == false` && not overdue
- **Due Soon**: Due within 3 days
- **Overdue**: `dueDate < now` && `hasPaid == false`

### Monthly Stats Calculation
```dart
// Example stats for user with 3 subscriptions:
MonthlyStats(
  totalMonthlyCost: 45.00,        // Total user is paying
  pendingToCollect: 30.00,        // Awaiting from members
  collectedAmount: 10.00,         // Already collected
  activeSubscriptionsCount: 3,
  overduePaymentsCount: 2,
  paidMembersCount: 2,
  unpaidMembersCount: 4,
);

// Derived values:
stats.totalExpectedIncome;  // 40.00 (30 + 10)
stats.collectionRate;        // 25% (10 / 40 * 100)
stats.isFullyCollected;      // false (pending > 0)
```

---

## 🎯 Use Case Examples

### Example 1: Get Home Screen Data

```dart
// Get monthly stats
final statsResult = await getMonthlyStats(currentUserId);
final stats = statsResult.fold(
  (failure) => handleFailure(failure),
  (stats) => stats,
);

// Get active subscriptions
final subsResult = await getActiveSubscriptions(currentUserId);
final subscriptions = subsResult.fold(
  (failure) => handleFailure(failure),
  (subs) => subs,
);

// Get pending payments
final paymentsResult = await getPendingPayments(currentUserId);
final pending = paymentsResult.fold(
  (failure) => handleFailure(failure),
  (payments) => payments,
);
```

### Example 2: Create New Subscription

```dart
final newSubscription = Subscription(
  id: uuid.v4(),
  name: 'Netflix',
  color: '#E50914',
  totalCost: 15.99,
  billingCycle: BillingCycle.monthly,
  dueDate: DateTime.now().add(Duration(days: 30)),
  ownerId: currentUserId,
  sharedWith: ['friend1Id', 'friend2Id'],
  status: SubscriptionStatus.active,
  createdAt: DateTime.now(),
);

final result = await createSubscription(newSubscription);
result.fold(
  (failure) => showError(failure),
  (subscription) => navigateToHome(),
);
```

### Example 3: Mark Payment as Paid

```dart
final result = await markPaymentAsPaid(
  memberId: 'member123',
  paymentDate: DateTime.now(),
);

result.fold(
  (failure) => showError('Failed to mark payment'),
  (member) => showSuccess('Payment marked as paid!'),
);
```

---

## 🗄️ Hive Type IDs

Reserved range: **30-39**

| TypeID | Model | Description |
|--------|-------|-------------|
| 30 | SubscriptionModel | Subscription data |
| 31 | SubscriptionMemberModel | Member data |
| 32 | MonthlyStatsModel | Monthly statistics |
| 33-39 | - | Reserved for future use |

---

## 🚀 Next Steps

### Data Layer (TODO)
- [ ] Create SubscriptionModel (with Hive TypeAdapter)
- [ ] Create SubscriptionMemberModel (with Hive TypeAdapter)
- [ ] Create MonthlyStatsModel (with Hive TypeAdapter)
- [ ] Create SubscriptionRemoteDataSource (Supabase)
- [ ] Create SubscriptionLocalDataSource (Hive)
- [ ] Create SubscriptionRepositoryImpl

### Presentation Layer (TODO)
- [ ] Create HomeScreen with stats cards
- [ ] Create SubscriptionCard widget
- [ ] Create MemberCard widget
- [ ] Create AddSubscriptionScreen
- [ ] Create SubscriptionDetailsScreen
- [ ] Create Riverpod providers

### Supabase Schema (TODO)
- [ ] Create subscriptions table
- [ ] Create subscription_members table
- [ ] Configure Row Level Security (RLS)
- [ ] Set up real-time subscriptions

---

## 📚 Related Documentation

- [Main README](../../README.md) - Project overview
- [Auth Feature](../auth/README.md) - Authentication system
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)

---

**Status:** 🚧 **IN PROGRESS** - Domain layer complete
**Last Updated:** 2025-12-15
**Feature Version:** v1.0.0-alpha
