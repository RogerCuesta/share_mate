import 'package:dartz/dartz.dart';
import 'package:flutter_project_agents/core/di/injection.dart';
import 'package:flutter_project_agents/features/billing_automation/domain/services/billing_automation_orchestrator.dart';
import 'package:flutter_project_agents/features/settings/domain/entities/app_settings.dart';
import 'package:flutter_project_agents/features/settings/domain/failures/settings_failure.dart';
import 'package:flutter_project_agents/features/settings/domain/repositories/settings_repository.dart';
import 'package:flutter_project_agents/features/settings/domain/usecases/get_settings.dart';
import 'package:flutter_project_agents/features/settings/domain/usecases/save_settings.dart';
import 'package:flutter_project_agents/features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockBillingAutomationOrchestrator extends Mock
    implements BillingAutomationOrchestrator {}

void main() {
  late MockSettingsRepository mockRepository;
  late MockBillingAutomationOrchestrator mockOrchestrator;

  setUpAll(() {
    registerFallbackValue(const AppSettings());
  });

  setUp(() {
    mockRepository = MockSettingsRepository();
    mockOrchestrator = MockBillingAutomationOrchestrator();

    when(() => mockOrchestrator.run(reason: any(named: 'reason'))).thenAnswer(
      (_) async => const BillingAutomationHealth.initial(),
    );
    when(() => mockOrchestrator.clearAll(reason: any(named: 'reason')))
        .thenAnswer(
      (_) async => const BillingAutomationHealth.initial(),
    );
  });

  ProviderContainer createContainer({
    Either<SettingsFailure, Unit> saveResult = const Right(unit),
  }) {
    when(() => mockRepository.getSettings()).thenAnswer(
      (_) async => const Right(AppSettings()),
    );
    when(() => mockRepository.saveSettings(any())).thenAnswer(
      (_) async => saveResult,
    );

    return ProviderContainer(
      overrides: [
        getSettingsProvider.overrideWith((ref) => GetSettings(mockRepository)),
        saveSettingsProvider.overrideWith((ref) => SaveSettings(mockRepository)),
        billingAutomationOrchestratorProvider
            .overrideWithValue(mockOrchestrator),
      ],
    );
  }

  group('Settings.togglePaymentReminders', () {
    test('runs orchestration when reminders are enabled', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      await container.read(settingsProvider.future);
      final result = await container
          .read(settingsProvider.notifier)
          .togglePaymentReminders(enabled: true);

      expect(result, isTrue);
      verify(
        () => mockOrchestrator.run(
          reason: 'settings_payment_reminders_enabled',
        ),
      ).called(1);
    });

    test('clears reminders when reminders are disabled', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      await container.read(settingsProvider.future);
      final result = await container
          .read(settingsProvider.notifier)
          .togglePaymentReminders(enabled: false);

      expect(result, isTrue);
      verify(
        () => mockOrchestrator.clearAll(
          reason: 'settings_payment_reminders_disabled',
        ),
      ).called(1);
    });

    test('returns false on save failure', () async {
      final container = createContainer(
        saveResult: const Left(
          SettingsFailure.settingsSaveError('save failed'),
        ),
      );
      addTearDown(container.dispose);

      await container.read(settingsProvider.future);
      final result = await container
          .read(settingsProvider.notifier)
          .togglePaymentReminders(enabled: true);

      expect(result, isFalse);
      verifyNever(
        () => mockOrchestrator.run(reason: any(named: 'reason')),
      );
    });
  });
}
