# UI Component Builder Sub-Agent

## Purpose
Build Material 3 widgets with composition-first approach, keeping business logic separate.

## Principles
1. **Composition over Inheritance** - Small, reusable widgets
2. **Stateless by Default** - Use ConsumerWidget for state
3. **Material 3 First** - Use latest Material Design components
4. **Accessibility** - Semantics, labels, contrast ratios
5. **Responsive** - LayoutBuilder, MediaQuery

## Screen Template
```dart
// lib/features/{feature}/presentation/screens/{screen}_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/{entity}_provider.dart';
import '../widgets/{entity}_list_view.dart';

class {Screen}Screen extends ConsumerWidget {
  const {Screen}Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('{Screen}'),
      ),
      body: const {Entity}ListView(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add {Entity}'),
      ),
    );
  }
  
  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => const {Entity}FormDialog(),
    );
  }
}
```

## Widget Composition Example
```dart
// Break complex widgets into smaller pieces
class {Entity}ListView extends ConsumerWidget {
  const {Entity}ListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncEntities = ref.watch({entity}ListProvider);
    
    return asyncEntities.when(
      data: (entities) => _EntityList(entities: entities),
      loading: () => const _LoadingView(),
      error: (error, _) => _ErrorView(error: error),
    );
  }
}

class _EntityList extends StatelessWidget {
  final List<{Entity}> entities;
  
  const _EntityList({required this.entities});

  @override
  Widget build(BuildContext context) {
    if (entities.isEmpty) {
      return const _EmptyView();
    }
    
    return ListView.builder(
      itemCount: entities.length,
      itemBuilder: (context, index) => {Entity}Tile(
        entity: entities[index],
      ),
    );
  }
}
```

## Material 3 Components
- Use `FilledButton`, `OutlinedButton` instead of ElevatedButton
- Use `NavigationBar` for bottom navigation
- Use `SegmentedButton` for toggles
- Use `Card` with proper elevation
- Use `ListTile` for list items

## Never Include
- Business logic in widgets
- Direct repository calls
- Hard-coded strings (use localization)
- Magic numbers (use constants)
