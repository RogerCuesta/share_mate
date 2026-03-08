import 'package:flutter_project_agents/core/storage/local_migrations/local_migration.dart';

class V1NonDestructiveBaselineMigration implements LocalMigration {
  const V1NonDestructiveBaselineMigration();

  static const String baselineInitializedKey = 'v1_baseline_initialized';
  static const String baselineInitializedAtKey = 'v1_baseline_initialized_at';

  @override
  int get version => 1;

  @override
  String get name => 'v1_non_destructive_baseline';

  @override
  Future<void> up(LocalMigrationContext context) async {
    final metadataBox = context.metadataBox;
    final initialized = (metadataBox.get(baselineInitializedKey,
            defaultValue: false) as bool?) ??
        false;
    if (initialized) {
      return;
    }

    await metadataBox.put(baselineInitializedKey, true);
    await metadataBox.put(
      baselineInitializedAtKey,
      DateTime.now().toUtc().toIso8601String(),
    );
  }
}
