import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/service_template.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/repositories/service_template_repository.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/service_template_provider.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/widgets/service_template_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Offline catalog setup flow', () {
    testWidgets(
      'cached templates stay responsive while delayed refresh fails',
      (tester) async {
        final repository = _OfflineCatalogRepository(
          initialSnapshot: _snapshot(
            templates: [
              _template(name: 'Netflix', slug: 'netflix'),
              _template(
                name: 'Notion',
                slug: 'notion',
                aliases: const ['notion ai'],
                searchTerms: const ['workspace'],
              ),
            ],
            isStale: true,
          ),
          refreshDelay: const Duration(milliseconds: 700),
          refreshError: 'network timeout while refreshing',
        );
        addTearDown(repository.dispose);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              serviceTemplateRepositoryProvider.overrideWithValue(repository),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: ServiceTemplateSheet(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Netflix'), findsOneWidget);
        expect(find.text('Notion'), findsOneWidget);
        expect(find.text('Showing cached results'), findsOneWidget);

        await tester.tap(find.byTooltip('Refresh catalog'));
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.text('Cached results · refreshing'), findsOneWidget);

        await tester.enterText(find.byType(TextField), 'notion');
        await tester.pump(const Duration(milliseconds: 80));

        expect(find.text('Notion'), findsOneWidget);
        expect(find.text('Netflix'), findsNothing);
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller?.text,
          'notion',
        );

        await tester.pump(const Duration(milliseconds: 800));
        await tester.pumpAndSettle();

        expect(find.text('network timeout while refreshing'), findsOneWidget);
        expect(find.text('Notion'), findsOneWidget);
        expect(repository.refreshCalls, 1);
      },
    );
  });
}

class _OfflineCatalogRepository implements ServiceTemplateRepository {
  _OfflineCatalogRepository({
    required ServiceTemplateCatalogSnapshot initialSnapshot,
    required this.refreshDelay,
    required this.refreshError,
  }) : _currentSnapshot = initialSnapshot;

  final Duration refreshDelay;
  final String refreshError;
  final StreamController<ServiceTemplateCatalogSnapshot> _controller =
      StreamController<ServiceTemplateCatalogSnapshot>.broadcast();
  ServiceTemplateCatalogSnapshot _currentSnapshot;
  int refreshCalls = 0;

  @override
  Future<ServiceTemplateCatalogSnapshot> refreshCatalog() async {
    refreshCalls += 1;
    await Future<void>.delayed(refreshDelay);
    _currentSnapshot = ServiceTemplateCatalogSnapshot(
      templates: _currentSnapshot.templates,
      fetchedAt: _currentSnapshot.fetchedAt,
      isStale: true,
      errorMessage: refreshError,
    );
    _controller.add(_currentSnapshot);
    return _currentSnapshot;
  }

  @override
  Stream<ServiceTemplateCatalogSnapshot> watchCatalog({
    bool forceRefresh = false,
  }) {
    return Stream<ServiceTemplateCatalogSnapshot>.multi((multi) {
      multi.add(_currentSnapshot);
      final sub = _controller.stream.listen(
        multi.add,
        onError: multi.addError,
      );
      multi.onCancel = sub.cancel;
    });
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}

ServiceTemplate _template({
  required String name,
  required String slug,
  List<String> aliases = const [],
  List<String> searchTerms = const [],
}) {
  return ServiceTemplate(
    id: '$slug-id',
    slug: slug,
    name: name,
    logoUrl: 'https://example.com/$slug.svg',
    brandColor: '#6C63FF',
    aliases: aliases,
    searchTerms: searchTerms,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
}

ServiceTemplateCatalogSnapshot _snapshot({
  required List<ServiceTemplate> templates,
  required bool isStale,
  String? errorMessage,
}) {
  return ServiceTemplateCatalogSnapshot(
    templates: templates,
    fetchedAt: DateTime.utc(2026, 3, 9),
    isStale: isStale,
    errorMessage: errorMessage,
  );
}
