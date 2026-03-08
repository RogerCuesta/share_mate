import 'package:flutter_project_agents/core/supabase/supabase_service.dart';
import 'package:flutter_project_agents/features/subscriptions/data/models/service_template_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ServiceTemplateRemoteException implements Exception {
  ServiceTemplateRemoteException(this.message);

  final String message;

  @override
  String toString() => 'ServiceTemplateRemoteException: $message';
}

// ignore: one_member_abstracts
abstract class ServiceTemplateRemoteDataSource {
  Future<List<ServiceTemplateModel>> fetchTemplates();
}

class ServiceTemplateRemoteDataSourceImpl
    implements ServiceTemplateRemoteDataSource {
  ServiceTemplateRemoteDataSourceImpl({
    SupabaseClient? client,
  }) : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  @override
  Future<List<ServiceTemplateModel>> fetchTemplates() async {
    try {
      final response = await _client
          .from('service_templates')
          .select()
          .eq('is_active', true)
          .order('name');

      final rows = response as List<dynamic>;
      return rows
          .map((row) => ServiceTemplateModel.fromJson(
                row as Map<String, dynamic>,
              ))
          .toList(growable: false);
    } on PostgrestException catch (error) {
      throw ServiceTemplateRemoteException(
        'Failed to fetch templates: ${error.message}',
      );
    } catch (error) {
      throw ServiceTemplateRemoteException(
        'Unexpected template fetch failure: $error',
      );
    }
  }
}
