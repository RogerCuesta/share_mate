// test/helpers/mocks.dart

import 'package:flutter_project_agents/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_project_agents/features/friends/domain/repositories/friendship_repository.dart';
import 'package:mocktail/mocktail.dart';

/// Mock for AuthRepository
///
/// Used in use case tests to verify business logic without
/// depending on actual data sources.
class MockAuthRepository extends Mock implements AuthRepository {}

/// Mock for FriendshipRepository
///
/// Used in use case tests to verify friendship business logic without
/// depending on actual data sources.
class MockFriendshipRepository extends Mock implements FriendshipRepository {}

/// Register fallback values for mocktail
///
/// Call this in setUpAll() for any test that uses mocks with
/// parameters that need default values.
void registerFallbackValues() {
  // Add fallback values here if needed
  // Example: registerFallbackValue(FakeUser());
}
