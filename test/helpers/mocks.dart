// test/helpers/mocks.dart

import 'package:flutter_project_agents/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_project_agents/features/contacts/domain/repositories/contact_repository.dart';
import 'package:mocktail/mocktail.dart';

/// Mock for AuthRepository
///
/// Used in use case tests to verify business logic without
/// depending on actual data sources.
class MockAuthRepository extends Mock implements AuthRepository {}

/// Mock for ContactRepository
///
/// Used in use case tests to verify contact business logic without
/// depending on actual data sources.
class MockContactRepository extends Mock implements ContactRepository {}

/// Register fallback values for mocktail
///
/// Call this in setUpAll() for any test that uses mocks with
/// parameters that need default values.
void registerFallbackValues() {
  // Add fallback values here if needed
  // Example: registerFallbackValue(FakeUser());
}
