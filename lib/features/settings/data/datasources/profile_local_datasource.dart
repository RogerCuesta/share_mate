// lib/features/settings/data/datasources/profile_local_datasource.dart

import 'package:flutter_project_agents/core/storage/hive_service.dart';
import 'package:flutter_project_agents/features/settings/data/models/user_profile_model.dart';
import 'package:hive_ce/hive.dart';

/// Profile Local Data Source Interface
abstract class ProfileLocalDataSource {
  Future<void> init();
  Future<UserProfileModel?> getProfile(String userId);
  Future<void> cacheProfile(UserProfileModel profile);
  Future<void> clearProfile(String userId);
  Future<void> clearAllProfiles();
}

/// Profile Local Data Source Implementation (Hive)
class ProfileLocalDataSourceImpl implements ProfileLocalDataSource {
  static const String _boxName = 'user_profiles';
  Box<UserProfileModel>? _box;

  @override
  Future<void> init() async {
    if (_box == null || !_box!.isOpen) {
      _box = await HiveService.openBox<UserProfileModel>(_boxName, encrypted: true);
    }
  }

  @override
  Future<UserProfileModel?> getProfile(String userId) async {
    try {
      await init();
      return _box!.get(userId);
    } catch (e) {
      throw ProfileLocalException('Failed to get cached profile: $e');
    }
  }

  @override
  Future<void> cacheProfile(UserProfileModel profile) async {
    try {
      await init();
      await _box!.put(profile.userId, profile);
    } catch (e) {
      throw ProfileLocalException('Failed to cache profile: $e');
    }
  }

  @override
  Future<void> clearProfile(String userId) async {
    try {
      await init();
      await _box!.delete(userId);
    } catch (e) {
      throw ProfileLocalException('Failed to clear profile: $e');
    }
  }

  @override
  Future<void> clearAllProfiles() async {
    try {
      await init();
      await _box!.clear();
    } catch (e) {
      throw ProfileLocalException('Failed to clear all profiles: $e');
    }
  }
}

/// Exception thrown when profile local operations fail
class ProfileLocalException implements Exception {
  ProfileLocalException(this.message);
  final String message;

  @override
  String toString() => message;
}
