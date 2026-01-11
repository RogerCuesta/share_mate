import 'package:dartz/dartz.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/failures/subscription_failure.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/repositories/subscription_repository.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/usecases/create_subscription.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSubscriptionRepository extends Mock implements SubscriptionRepository {}

class FakeSubscription extends Fake implements Subscription {}

void main() {
  late CreateSubscription useCase;
  late MockSubscriptionRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeSubscription());
  });

  setUp(() {
    mockRepository = MockSubscriptionRepository();
    useCase = CreateSubscription(mockRepository);
  });

  final tValidSubscription = Subscription(
    id: 'test-id',
    name: 'Netflix',
    color: '#E50914',
    totalCost: 15.99,
    billingCycle: BillingCycle.monthly,
    dueDate: DateTime.now().add(const Duration(days: 30)),
    ownerId: 'user-123',
    createdAt: DateTime.now(),
  );

  group('CreateSubscription Use Case', () {
    test('should create subscription successfully', () async {
      // Arrange
      when(() => mockRepository.createSubscription(any()))
          .thenAnswer((_) async => Right(tValidSubscription));

      // Act
      final result = await useCase(tValidSubscription);

      // Assert
      expect(result, Right(tValidSubscription));
      verify(() => mockRepository.createSubscription(tValidSubscription))
          .called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return InvalidData when name is empty', () async {
      // Arrange
      final invalidSubscription = tValidSubscription.copyWith(name: '');

      // Act
      final result = await useCase(invalidSubscription);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(
          failure,
          const SubscriptionFailure.invalidData(
            'Subscription name cannot be empty',
          ),
        ),
        (_) => fail('Should return failure'),
      );
      verifyZeroInteractions(mockRepository);
    });

    test('should return InvalidData when name is less than 2 characters',
        () async {
      // Arrange
      final invalidSubscription = tValidSubscription.copyWith(name: 'N');

      // Act
      final result = await useCase(invalidSubscription);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(
          failure,
          const SubscriptionFailure.invalidData(
            'Subscription name must be at least 2 characters',
          ),
        ),
        (_) => fail('Should return failure'),
      );
      verifyZeroInteractions(mockRepository);
    });

    test('should return InvalidData when cost is zero', () async {
      // Arrange
      final invalidSubscription = tValidSubscription.copyWith(totalCost: 0);

      // Act
      final result = await useCase(invalidSubscription);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(
          failure,
          const SubscriptionFailure.invalidData(
            'Subscription cost must be greater than zero',
          ),
        ),
        (_) => fail('Should return failure'),
      );
      verifyZeroInteractions(mockRepository);
    });

    test('should return InvalidData when cost is negative', () async {
      // Arrange
      final invalidSubscription = tValidSubscription.copyWith(totalCost: -10);

      // Act
      final result = await useCase(invalidSubscription);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(
          failure,
          const SubscriptionFailure.invalidData(
            'Subscription cost must be greater than zero',
          ),
        ),
        (_) => fail('Should return failure'),
      );
      verifyZeroInteractions(mockRepository);
    });

    test('should return InvalidData when owner ID is empty', () async {
      // Arrange
      final invalidSubscription = tValidSubscription.copyWith(ownerId: '');

      // Act
      final result = await useCase(invalidSubscription);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(
          failure,
          const SubscriptionFailure.invalidData('Owner ID cannot be empty'),
        ),
        (_) => fail('Should return failure'),
      );
      verifyZeroInteractions(mockRepository);
    });

    test('should return InvalidData when due date is in the past', () async {
      // Arrange
      final pastDate = DateTime.now().subtract(const Duration(days: 1));
      final invalidSubscription =
          tValidSubscription.copyWith(dueDate: pastDate);

      // Act
      final result = await useCase(invalidSubscription);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(
          failure,
          const SubscriptionFailure.invalidData(
            'Due date cannot be in the past',
          ),
        ),
        (_) => fail('Should return failure'),
      );
      verifyZeroInteractions(mockRepository);
    });

    test('should return InvalidData when color format is invalid', () async {
      // Arrange - Missing #
      final invalidSubscription1 = tValidSubscription.copyWith(color: 'E50914');

      // Act
      final result1 = await useCase(invalidSubscription1);

      // Assert
      expect(result1.isLeft(), true);
      result1.fold(
        (failure) => expect(
          failure,
          const SubscriptionFailure.invalidData(
            'Invalid color format (expected hex color like #FF0000)',
          ),
        ),
        (_) => fail('Should return failure'),
      );

      // Arrange - Too short
      final invalidSubscription2 = tValidSubscription.copyWith(color: '#E509');

      // Act
      final result2 = await useCase(invalidSubscription2);

      // Assert
      expect(result2.isLeft(), true);

      // Arrange - Invalid characters
      final invalidSubscription3 =
          tValidSubscription.copyWith(color: '#GGGGGG');

      // Act
      final result3 = await useCase(invalidSubscription3);

      // Assert
      expect(result3.isLeft(), true);

      verifyZeroInteractions(mockRepository);
    });

    test('should accept valid hex colors in different cases', () async {
      // Arrange
      when(() => mockRepository.createSubscription(any()))
          .thenAnswer((_) async => Right(tValidSubscription));

      // Lowercase
      final subscription1 = tValidSubscription.copyWith(color: '#e50914');
      await useCase(subscription1);

      // Uppercase
      final subscription2 = tValidSubscription.copyWith(color: '#E50914');
      await useCase(subscription2);

      // Mixed case
      final subscription3 = tValidSubscription.copyWith(color: '#E5091a');
      await useCase(subscription3);

      // Assert - All should pass validation
      verify(() => mockRepository.createSubscription(any())).called(3);
    });

    test('should return ServerError when repository throws exception',
        () async {
      // Arrange
      when(() => mockRepository.createSubscription(any())).thenAnswer(
        (_) async => const Left(
          SubscriptionFailure.serverError('Database error'),
        ),
      );

      // Act
      final result = await useCase(tValidSubscription);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(
          failure,
          const SubscriptionFailure.serverError('Database error'),
        ),
        (_) => fail('Should return failure'),
      );
      verify(() => mockRepository.createSubscription(tValidSubscription))
          .called(1);
    });

    test('should return NetworkError when there is no connection', () async {
      // Arrange
      when(() => mockRepository.createSubscription(any())).thenAnswer(
        (_) async => const Left(SubscriptionFailure.networkError()),
      );

      // Act
      final result = await useCase(tValidSubscription);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) =>
            expect(failure, const SubscriptionFailure.networkError()),
        (_) => fail('Should return failure'),
      );
    });
  });
}
