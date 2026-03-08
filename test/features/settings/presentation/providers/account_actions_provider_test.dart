import 'package:dartz/dartz.dart';
import 'package:flutter_project_agents/core/di/injection.dart';
import 'package:flutter_project_agents/features/settings/domain/failures/settings_failure.dart';
import 'package:flutter_project_agents/features/settings/domain/repositories/account_repository.dart';
import 'package:flutter_project_agents/features/settings/domain/usecases/delete_account.dart';
import 'package:flutter_project_agents/features/settings/presentation/providers/account_actions_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAccountRepository extends Mock implements AccountRepository {}

void main() {
  late MockAccountRepository mockRepository;

  setUp(() {
    mockRepository = MockAccountRepository();
  });

  ProviderContainer createContainer(DeleteAccount deleteAccountUseCase) {
    return ProviderContainer(
      overrides: [
        deleteAccountProvider.overrideWith((ref) => deleteAccountUseCase),
      ],
    );
  }

  group('AccountActions.deleteAccount', () {
    test('sets success state when deletion succeeds', () async {
      when(() => mockRepository.deleteAccount()).thenAnswer(
        (_) async => const Right(unit),
      );

      final container = createContainer(DeleteAccount(mockRepository));
      addTearDown(container.dispose);

      final notifier = container.read(accountActionsProvider.notifier);
      final result = await notifier.deleteAccount();

      expect(result, isTrue);
      expect(
        container.read(accountActionsProvider),
        isA<AccountActionSuccess>().having(
          (state) => state.message,
          'message',
          'Account deleted successfully',
        ),
      );
      verify(() => mockRepository.deleteAccount()).called(1);
    });

    test('sets error state when deletion fails', () async {
      when(() => mockRepository.deleteAccount()).thenAnswer(
        (_) async => const Left(
          SettingsFailure.accountDeletionError('Deletion failed'),
        ),
      );

      final container = createContainer(DeleteAccount(mockRepository));
      addTearDown(container.dispose);

      final notifier = container.read(accountActionsProvider.notifier);
      final result = await notifier.deleteAccount();

      expect(result, isFalse);
      expect(
        container.read(accountActionsProvider),
        isA<AccountActionError>().having(
          (state) => state.message,
          'message',
          'Deletion failed',
        ),
      );
      verify(() => mockRepository.deleteAccount()).called(1);
    });
  });
}
