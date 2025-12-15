# Mock Data Guide for UI Testing

This guide explains how to use mock data for developing and testing the subscriptions UI without connecting to Supabase.

## 📋 Overview

The subscriptions feature includes mock data infrastructure for UI development and testing:

- **`subscription_seed_data.dart`**: Provides realistic mock data (subscriptions, members, stats)
- **`subscription_repository_mock.dart`**: Mock repository implementation that uses seed data
- **No Supabase required**: Test the entire UI flow without backend configuration

## 🚀 Quick Start

### 1. Current Configuration

The app is **currently configured to use mock data** by default. Check `lib/core/di/injection.dart`:

```dart
@riverpod
SubscriptionRepository subscriptionRepository(Ref ref) {
  // MOCK REPOSITORY - Currently Active
  return SubscriptionRepositoryMock();

  // Real repository is commented out
}
```

### 2. Run the App

Simply run the app and you'll see realistic subscription data:

```bash
flutter run
```

### 3. What You'll See

**Home Screen:**
- ✅ 8 active subscriptions (Netflix, Spotify, Disney+, etc.)
- ✅ Monthly stats: $142.90 total cost, $45 pending to collect
- ✅ 3 overdue payments in "Action Required" section
- ✅ Colorful subscription cards with due dates

**Mock Users:**
- Sarah Jenkins (overdue 4 days on Netflix)
- Mike T. (overdue 5 days on Spotify)
- Chris Parker (overdue 2 days on YouTube Premium)
- And 8 more members with various payment statuses

## 📦 Mock Data Details

### Subscriptions (8 services)

| Service | Color | Monthly Cost | Due Date | Members |
|---------|-------|-------------|----------|---------|
| Netflix | #E50914 | $15.99 | +24 days | 3 people |
| Spotify | #1DB954 | $9.99 | +28 days | 2 people |
| Disney+ | #0063E5 | $13.99 | +15 days | 3 people |
| YouTube Premium | #FF0000 | $11.99 | +5 days | 4 people |
| Amazon Prime | #00A8E1 | $14.99 | +20 days | 2 people |
| Apple Music | #FA243C | $10.99 | +12 days | 2 people |
| HBO Max | #5D28FA | $15.99 | +8 days | 3 people |
| Adobe CC | #FF0000 | $49.99/mo | +120 days | 1 person |

### Payment Members (11 members)

**Overdue (3):**
- 🔴 Sarah Jenkins: $5.33 (4 days overdue)
- 🔴 Mike T.: $5.00 (5 days overdue)
- 🔴 Chris Parker: $3.00 (2 days overdue)

**Pending (8):**
- 🟡 Emma Wilson, David Lee, Alex Rodriguez, Jessica Chen, Rachel Green, Tom Brady, Lisa Anderson, Kevin Martinez

### Monthly Statistics

```dart
totalMonthlyCost: $142.90
pendingToCollect: $45.00
activeSubscriptionsCount: 8
overduePaymentsCount: 3
collectedAmount: $35.00
paidMembersCount: 4
unpaidMembersCount: 11
```

## 🔧 Customizing Mock Data

### Add More Subscriptions

Edit `lib/features/subscriptions/data/datasources/subscription_seed_data.dart`:

```dart
static List<Subscription> getMockSubscriptions(String currentUserId) {
  final now = DateTime.now();

  return [
    // Existing subscriptions...

    // Add your custom subscription
    Subscription(
      id: 'sub_9',
      name: 'My Custom Service',
      iconUrl: null,
      color: '#00FF00',
      totalCost: 19.99,
      billingCycle: BillingCycle.monthly,
      dueDate: now.add(const Duration(days: 30)),
      ownerId: currentUserId,
      sharedWith: ['user_2'],
      status: SubscriptionStatus.active,
      createdAt: now,
    ),
  ];
}
```

### Add More Members

```dart
static List<SubscriptionMember> getMockPendingPayments() {
  final now = DateTime.now();

  return [
    // Existing members...

    // Add your custom member
    SubscriptionMember(
      id: 'member_12',
      subscriptionId: 'sub_1',
      userId: 'user_7',
      userName: 'John Doe',
      userAvatar: null,
      amountToPay: 10.00,
      hasPaid: false,
      lastPaymentDate: null,
      dueDate: now.add(const Duration(days: 10)),
    ),
  ];
}
```

### Adjust Statistics

```dart
static MonthlyStats getMockStats() {
  return const MonthlyStats(
    totalMonthlyCost: 200.00,  // Your custom value
    pendingToCollect: 60.00,   // Your custom value
    // ...
  );
}
```

## 🧪 Testing Features

The mock repository supports all CRUD operations:

### Create Subscription
```dart
final newSub = Subscription(/* ... */);
await repository.createSubscription(newSub);
// ✅ Added to in-memory cache
```

### Update Subscription
```dart
final updated = subscription.copyWith(totalCost: 20.00);
await repository.updateSubscription(updated);
// ✅ Updated in cache, stats recalculated
```

### Mark Payment as Paid
```dart
await repository.markPaymentAsPaid(
  memberId: 'member_1',
  paymentDate: DateTime.now(),
);
// ✅ Member marked as paid, stats updated
```

### Delete Subscription
```dart
await repository.deleteSubscription('sub_1');
// ✅ Removed from cache, stats recalculated
```

## 🔄 Switching to Real Backend

When ready to use the real Supabase backend:

### Step 1: Update `lib/core/di/injection.dart`

```dart
@riverpod
SubscriptionRepository subscriptionRepository(Ref ref) {
  // Comment out the mock
  // return SubscriptionRepositoryMock();

  // Uncomment the real implementation
  return SubscriptionRepositoryImpl(
    remoteDataSource: ref.watch(subscriptionRemoteDataSourceProvider),
    localDataSource: ref.watch(subscriptionLocalDataSourceProvider),
  );
}
```

### Step 2: Configure Supabase

Follow the instructions in `SUPABASE_SETUP.md` to:
1. Set up your Supabase project
2. Create the database schema
3. Configure `.env` file
4. Initialize Supabase in `main.dart`

### Step 3: Test

```bash
flutter clean
flutter pub get
flutter run
```

## 📊 Mock vs Real Data Comparison

| Feature | Mock Repository | Real Repository |
|---------|----------------|-----------------|
| **Network** | No network calls | Connects to Supabase |
| **Persistence** | In-memory only | Supabase + Hive cache |
| **Delay** | 500ms simulated | Actual network latency |
| **Data Loss** | Resets on app restart | Persists in database |
| **Offline** | Always works | Falls back to Hive |
| **Use Case** | UI development/testing | Production |

## 🎨 UI Testing Scenarios

The mock data is designed to test all UI states:

### ✅ Happy Path
- Active subscriptions display correctly
- Payment cards show proper formatting
- Stats cards calculate totals accurately

### ⚠️ Edge Cases
- Overdue payments (red badges)
- Due soon warnings (yellow)
- Empty states (when list is empty)
- Long names (truncation)
- Various date formats

### 🔄 Interactions
- Mark payment as paid
- Create new subscription
- Update subscription details
- Delete subscription
- Add/remove members

## 📝 Development Tips

### 1. Hot Reload Works
Changes to mock data require a hot restart, but UI changes work with hot reload.

### 2. Debug Inspection
You can inspect the mock data in debug mode:

```dart
// In your provider or screen
final repo = ref.read(subscriptionRepositoryProvider) as SubscriptionRepositoryMock;
print('Current subscriptions: ${repo._cachedSubscriptions}');
```

### 3. Reset Mock Data
```dart
final repo = ref.read(subscriptionRepositoryProvider) as SubscriptionRepositoryMock;
repo.resetMockData();
```

### 4. Modify Stats Dynamically
The mock repository automatically recalculates stats after any CRUD operation.

## 🐛 Troubleshooting

### Issue: "Mock data not showing"

**Solution**: Verify `injection.dart` is using `SubscriptionRepositoryMock()`:

```bash
grep -A 5 "SubscriptionRepository subscriptionRepository" lib/core/di/injection.dart
```

### Issue: "Data resets on hot reload"

**Solution**: This is expected with mock data. Use hot restart instead.

### Issue: "Want to test with empty state"

**Solution**: Modify `getMockSubscriptions()` to return an empty list:

```dart
static List<Subscription> getMockSubscriptions(String currentUserId) {
  return []; // Empty for testing empty state
}
```

## 📚 Related Files

- **Mock Data**: `lib/features/subscriptions/data/datasources/subscription_seed_data.dart`
- **Mock Repository**: `lib/features/subscriptions/data/repositories/subscription_repository_mock.dart`
- **DI Configuration**: `lib/core/di/injection.dart`
- **Real Repository**: `lib/features/subscriptions/data/repositories/subscription_repository_impl.dart`
- **Supabase Setup**: `lib/features/subscriptions/SUPABASE_SETUP.md`

## 🎯 Next Steps

1. ✅ **You're here**: Using mock data for UI development
2. 🔄 Complete UI implementation and testing
3. 🗄️ Set up Supabase backend (follow `SUPABASE_SETUP.md`)
4. 🔌 Switch to real repository in `injection.dart`
5. 🧪 Test with real backend data
6. 🚀 Deploy to production

---

**Note**: Always switch to the real repository before deploying to production!
