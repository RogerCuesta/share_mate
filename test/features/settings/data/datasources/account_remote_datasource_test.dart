import 'dart:io';

import 'package:flutter_project_agents/features/settings/data/datasources/account_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockFunctionsClient extends Mock implements FunctionsClient {}

void main() {
  late MockSupabaseClient mockSupabaseClient;
  late MockFunctionsClient mockFunctionsClient;
  late AccountRemoteDataSourceImpl dataSource;

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockFunctionsClient = MockFunctionsClient();
    dataSource = AccountRemoteDataSourceImpl(client: mockSupabaseClient);

    when(() => mockSupabaseClient.functions).thenReturn(mockFunctionsClient);
  });

  group('AccountRemoteDataSource.deleteAccount', () {
    test('invokes delete-account edge function successfully', () async {
      when(() => mockFunctionsClient.invoke('delete-account')).thenAnswer(
        (_) async => FunctionResponse(
          data: {'success': true, 'code': 'ACCOUNT_DELETED'},
          status: 200,
        ),
      );

      await dataSource.deleteAccount();

      verify(() => mockFunctionsClient.invoke('delete-account')).called(1);
    });

    test('propagates backend error payload from function response', () async {
      when(() => mockFunctionsClient.invoke('delete-account')).thenAnswer(
        (_) async => FunctionResponse(
          data: {
            'success': false,
            'code': 'ACCOUNT_DELETE_FAILED',
            'message': 'Unable to delete account at this time.',
          },
          status: 500,
        ),
      );

      expect(
        dataSource.deleteAccount,
        throwsA(
          isA<AccountRemoteException>().having(
            (error) => error.message,
            'message',
            'ACCOUNT_DELETE_FAILED: Unable to delete account at this time.',
          ),
        ),
      );
    });

    test('propagates structured FunctionException details', () async {
      when(() => mockFunctionsClient.invoke('delete-account')).thenThrow(
        const FunctionException(
          status: 401,
          details: {
            'code': 'UNAUTHORIZED',
            'message': 'Missing or invalid bearer token.',
          },
        ),
      );

      expect(
        dataSource.deleteAccount,
        throwsA(
          isA<AccountRemoteException>().having(
            (error) => error.message,
            'message',
            'UNAUTHORIZED: Missing or invalid bearer token.',
          ),
        ),
      );
    });
  });

  test('security guard: client code must not use auth.admin.deleteUser', () {
    final source = File(
      'lib/features/settings/data/datasources/account_remote_datasource.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('auth.admin.deleteUser')));
    expect(source, contains("functions.invoke('delete-account')"));
  });
}
