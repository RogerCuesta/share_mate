import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SECU-03 RLS policy audit gates', () {
    final repoRoot = Directory.current.path;
    final hardeningMigration = File(
      '$repoRoot/supabase/migrations/20260308_phase1_rls_hardening.sql',
    );
    final paymentMigration = File(
      '$repoRoot/supabase/migrations/20251225_payment_history_enhancements.sql',
    );
    final auditSql = File('$repoRoot/scripts/security/rls_policy_audit.sql');
    final auditRunner = File(
      '$repoRoot/scripts/security/run_rls_policy_audit.sh',
    );

    test('phase-1 migration defines RLS + canonical policies for business tables',
        () {
      final content = hardeningMigration.readAsStringSync();

      for (final table in const [
        'subscriptions',
        'subscription_members',
        'payment_history',
        'contacts',
      ]) {
        expect(
          content.contains(
            'ALTER TABLE IF EXISTS public.$table ENABLE ROW LEVEL SECURITY;',
          ),
          isTrue,
          reason: 'Missing RLS enable statement for $table',
        );
      }

      for (final policy in const [
        'p1_subscriptions_select_own',
        'p1_subscriptions_insert_own',
        'p1_subscriptions_update_own',
        'p1_subscriptions_delete_own',
        'p1_subscription_members_select_owner_scope',
        'p1_subscription_members_insert_owner_scope',
        'p1_subscription_members_update_owner_scope',
        'p1_subscription_members_delete_owner_scope',
        'p1_payment_history_select_owner_scope',
        'p1_payment_history_insert_owner_scope',
        'p1_payment_history_update_owner_scope',
        'p1_payment_history_delete_owner_scope',
        'p1_contacts_select_own',
        'p1_contacts_insert_own',
        'p1_contacts_update_own',
        'p1_contacts_delete_own',
      ]) {
        expect(
          content.contains('CREATE POLICY "$policy"'),
          isTrue,
          reason: 'Missing canonical policy $policy',
        );
      }
    });

    test('payment-history RPC definitions include auth guards and search_path',
        () {
      for (final migrationFile in [paymentMigration, hardeningMigration]) {
        final content = migrationFile.readAsStringSync();

        for (final functionName in const [
          'mark_payment_as_paid_atomic',
          'unmark_payment_atomic',
          'get_payment_history_stats',
        ]) {
          expect(
            content.contains('CREATE OR REPLACE FUNCTION $functionName('),
            isTrue,
            reason: 'Missing function $functionName in ${migrationFile.path}',
          );
        }

        expect(
          content.contains('SECURITY DEFINER'),
          isTrue,
          reason: 'Missing SECURITY DEFINER in ${migrationFile.path}',
        );
        expect(
          content.contains('SET search_path = public, auth'),
          isTrue,
          reason: 'Missing deterministic search_path in ${migrationFile.path}',
        );
        expect(
          content.contains('auth.uid()'),
          isTrue,
          reason: 'Missing auth.uid() ownership guards in ${migrationFile.path}',
        );
      }
    });

    test('audit runner succeeds in static mode and reports SECU-03 status',
        () async {
      expect(auditSql.existsSync(), isTrue, reason: 'Missing SQL audit file');
      expect(
        auditRunner.existsSync(),
        isTrue,
        reason: 'Missing shell audit runner',
      );

      final result = await Process.run(
        'bash',
        [auditRunner.path, '--mode=static'],
        workingDirectory: repoRoot,
      );

      final output =
          '${result.stdout.toString()}\n${result.stderr.toString()}';
      expect(
        result.exitCode,
        0,
        reason: 'Static audit failed unexpectedly.\n$output',
      );
      expect(output, contains('SECU-03 static audit passed.'));
      expect(output, contains('SECU-03 audit passed.'));
    });
  });
}
