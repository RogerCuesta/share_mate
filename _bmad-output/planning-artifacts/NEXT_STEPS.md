# Next Steps - SubMate Roadmap

**Last Updated:** 2025-01-11 20:30:00

---

## Immediate Sprint (Current - Week of Jan 11-18)

### 🎯 Priority 1: Edit Subscription Feature
**Status:** Not Started
**Estimated Time:** 4-6 hours
**Dependencies:** None
**Assigned Agent:** Flutter Feature Architect + Sub-agents
**Approach:** Extended Thinking for comprehensive planning

#### Tasks Breakdown
1. **Design Phase (1 hour)**
   - [ ] Use Extended Thinking to plan architecture
   - [ ] Design UpdateSubscription use case
   - [ ] Plan member update strategy (add/remove/update)
   - [ ] Design form state management

2. **Domain Layer (30 min)**
   - [ ] Create UpdateSubscription use case
   - [ ] Update SubscriptionFailure with update-specific errors
   - [ ] Agent: @domain-layer-specialist

3. **Data Layer (1 hour)**
   - [ ] Implement update method in SubscriptionRepositoryImpl
   - [ ] Update LocalDataSource (Hive) with atomic updates
   - [ ] Upte RemoteDataSource (Supabase)
   - [ ] Handle member changes (cascade updates)
   - [ ] Agent: @data-layer-specialist

4. **Presentation Layer (2 hours)**
   - [ ] Create SubscriptionEditProvider with form state
   - [ ] Refactor SubscriptionFormDialog to support both create/edit
     - Pass optional `Subscription? initialData`
     - Pre-populate fields in edit mode
   - [ ] Update navigation to pass subscription to edit
   - [ ] Add "Edit" button in SubscriptionDetailScreen
   - [ ] Agent: @riverpod-state-architect + @ui-component-builder

5. **Testing (1 hour)**
   - [ ] Unit tests for UpdateSubscription use case
   - [ ] Widget tests for edit form
   - [ ] Patrol integration test for full edit flow
   - [ ] Test member updates (add/remove/update)
   - [ ] Agent: @patrol-test-engineer

6. **Quality Audit (30 min)**
   - [ ] Run code quality inspector
   - [ ] Verify Hive integrity
   - [ ] Verify Supabase sync
   - [ ] Check test coverage (target: 80%+)
   - [ ] Agent: @flutter-devops-quality-guardian

#### Acceptance Criteria
- ✅ User can edit all subscription fields
- ✅ Member changes reflected immediately (offline-first)
- ✅ Changes synced to Supabase when online
- ✅ Form validation prevents invalid data
- ✅ UI shows loading/success/error states
- ✅ 80%+ test coverage
- ✅ No performance regressions (maintain 60fps)

#### Files to Create/Modify
```
lib/features/subscriptions/
├── domain/usecases/
│   └── update_subscription.dart          [NEW]
├── data/repositories/
│   └── subscription_repository_impl.dart [MODIFY - add update method]
├── presentation/
│   ├── providers/
│   │   └── subscription_edit_provider.dart [NEW]
│   ├── screens/
│   │   └── subscription_detail_screen.dart [MODIFY - add Edit button]
│   └── widgets/
│       └── subscription_form_dialog.dart   [MODIFY - support edit mode]

test/features/subscriptions/
├── domain/usecases/
│   └── update_subscription_test.dart       [Niority 2: Delete Subscription
**Status:** Pending
**Estimated Time:** 2-3 hours
**Dependencies:** Edit Subscription (optional, can be done in parallel)
**Assigned Agent:** Flutter Feature Architect

#### Decision Required
- [ ] **Soft delete vs Hard delete?**
  - Soft delete: Add `deleted_at` field, filter in queries
  - Hard delete: Permanently remove from database
  - **Recommendation:** Soft delete for data recovery and audit trail

#### Tasks Breakdown
1. **Design Phase (30 min)**
   - [ ] Decide soft vs hard delete approach
   - [ ] Design cascade deletion for members
   - [ ] Plan offline deletion with sync queue

2. **Domain Layer (20 min)**
   - [ ] Create DeleteSubscription use case
   - [ ] Add deletion failure types

3. **Data Layer (1 hour)**
   - [ ] Implement delete in SubscriptionRepositoryImpl
   - [ ] Handle cascade deletion for members
   - [ ] Update Hive LocalDataSource
   - [ ] Update Supabase RemoteDataSource
   - [ ] Handle offline deletion queue

4. **Presentation Layer (40 min)**
   - [ ] Add delete button in SubscriptionDetailScreen
   - [ ] Create confirmation dialog
   - [ ] Handle delete action in provider
   - [ ] Navigate back after deletion

5. **Testing (30 min)**
   - [ ] Unit tests for DeleteSubscription
   - [ ] Integration tests for cascade deletion
   - [ ] Test offline deletion sync

#### Acceptance Criteria
- ✅ User sees confirmation dialog before deletion
- ✅ Related members deleted automatically (cascade)
- ✅ Works offline (queued for sync)
- ✅ Syncs to Supabase when online
- ✅ UI updates immediately after deletion

---

## Short Term (Sprints 2-3 - Weeks of Jan 18-Feb 1)

### 3. Notification System
**Status:** Pending
**Estimated Time:** 6-8 hours
**Priority:** Medium

#### Features
- [ ] Local notifications for upcoming renewals
  - 7 days before renewal
  - 3 days before renewal
  - 1 day before renewal
- [ ] Background job to check renewal dates
- [ ] Notification preferences UI
  - Enable/disable notifications
  - Customize notification timing
- [ ] (Opsh notifications via Supabase

#### Technical Approach
- Use `flutter_local_notifications` package
- Schedule notifications when subscription created/updated
- Cancel notifications when subscription deleted
- Background isolate for checking renewal dates

---

### 4. Search & Filter
**Status:** Pending
**Estimated Time:** 4-5 hours
**Priority:** Medium

#### Features
- [ ] Search bar in home screen
  - Search by name
  - Search by category
- [ ] Filter options:
  - Status: Active / Inactive
  - Type: Personal / Group
  - Category: All / Netflix / Spotify / etc.
- [ ] Sort options:
  - Date created (newest first / oldest first)
  - Amount (highest first / lowest first)
  - Name (A-Z / Z-A)
  - Next renewal date

#### Technical Approach
- Add search field in HomeScreen
- Create FilterProvider with Riverpod
- Filter/sort in repository or provider
- Persist filter preferences in Hive

---

## Medium Term (Sprints 4-6 - February)

### 5. Analytics Dashboard
**Status:** Pending
**Estimated Time:** 10-12 hours
**Priority:** Low

#### Features
- [ ] Monthly spending trends chart (fl_chart)
- [ ] Category breakdown pie chart
- [ ] Group vs personal comparison
- [ ] Export data as CSV
- [ ] Year-over-year comparison

---

### 6. Export & Backup
**Status:** Pending
**Estimated Time:** 5-6 hours
**Priority:** Low

#### Features
- [ ] Export subscriptions to CSV
- [ ] Generate PDF reports
- [ ] Backup Hive data to Supabase Storage
- [ ] Import subscriptions from CSV file

---

## Long Term (Q1 2025 - March+)

### 7. Multi-currency Support
**Status:** Pending
**Estimated Time:** 8-10 hours

#### Features
- [ ] Support multiple currencies (USD, EUR, GBP, etc.)
- [ ] Currency conversion with live rates
- [ ] Display total in user's preferred currency

---

### 8. Receipt Scanning (ML)
**Status:** Pending
**Estimated Time:** 12-15 hours

#### Features
- [ ] Scan receipts with camera
- [ ] Extract subscription info using ML Kit
- [ ] Auto-fill form with extracted data

---

### 9. Budget Tracking
**Status:** Pending
**Estimated Time:** 10-12 hours

#### Features
- [ ] Set monthly subscription budget
- [ ] Alert when approaching budget limit
- [ ] Budget vs actual spending chart

---

## Blockers & Dependencies

### Current Blockers
**None**

### Technical Dependencies
- All features depend on stable Hive + Supabase sync
- Notification system requires permissions handling (iOS/Android)
- Analytics requires sufficient subscription data for meaningful insights

---

## Quality Gates (Must Pass Before Production)

### Code Quality
- [ ] `flutter analyze` - 0 errors, <5 warnings
- [ ] All lint rules passing
- [ ] No `dynamic` types
- [ ] No hardcoded strings (use localization)

### Test Coverage
- [ ] Overall: ≥80%
- [ ] Domain layer: ≥90%
- [ ] Critical paths: 100%

### Security
- [ ] RLS policies enabled and tested on all Supabase tables
- [ ] No hardcoded secrets in code
- [ ] Sensitive data encrypted in Hive
- [ ] Tokens stored in flutter_secure_storage

### Performance
- [ ] Average 60fps
- [ ] Frame render time <16ms
- [ ]  start time <1000ms
- [ ] Hive queries <5ms
- [ ] No memory leaks detected

### Database
- [ ] Hive TypeAdapters properly registered
- [ ] No typeId conflicts
- [ ] Box lifecycle managed correctly
- [ ] Encryption enabled for sensitive data
- [ ] Supabase indexes optimized
- [ ] RLS policies tested with multiple users

---

## Sprint Planning Notes

### Velocity
- **Target:** 1-2 features per week
- **Actual:** TBD (track after first sprint)

### Definition of Done
A feature is "done" when:
1. ✅ Code implemented following Clean Architecture
2. ✅ Tests written (unit + widget + integration)
3. ✅ Test coverage ≥80%
4. ✅ Code reviewed (by DevOps Guardian agent)
5. ✅ QA audit passed
6. ✅ CURRENT_STATE.md updated
7. ✅ DECISIONS_LOG.md updated (if ADR created)
8. ✅ Merged to main branch

---

## How to Use This File

### Before Starting Work
1. Read this file to see Priority 1 task
2. Check Dependencies and Blockers
3. Review Acceptance Criteria

### During Work
1. Check off completed tasks
2. Upe if needed
3. Document any blockers encountered

### After Completing Feature
1. Move feature from "In Progress" to "Completed" in CURRENT_STATE.md
2. Mark all tasks as done in this file
3. Update Priority 1 to next feature
4. Update timestamp at top of file
5. Commit changes: `git commit -m "docs(bmad): Complete [Feature Name]"`

---

## References
- Agent specifications: `.claude/agents/`
- Architecture decisions: `DECISIONS_LOG.md`
- Project overview: `PROJECT_CONTEXT.md`
- Current status: `CURRENT_STATE.md`
