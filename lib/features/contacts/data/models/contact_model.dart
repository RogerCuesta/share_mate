// lib/features/contacts/data/models/contact_model.dart

import 'package:flutter_project_agents/features/contacts/domain/entities/contact.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';

part 'contact_model.freezed.dart';
part 'contact_model.g.dart';

/// Data model for Contact with Hive persistence and JSON serialization
///
/// TypeID 50 (reused from old ProfileModel)
@freezed
@HiveType(typeId: 50, adapterName: 'ContactModelAdapter')
class ContactModel with _$ContactModel {
  const factory ContactModel({
    @HiveField(0) required String id,
    @HiveField(1) required String userId,
    @HiveField(2) required String name,
    @HiveField(3) required String email,
    @HiveField(6) required DateTime createdAt, @HiveField(7) required DateTime updatedAt, @HiveField(4) String? avatar,
    @HiveField(5) String? notes,
  }) = _ContactModel;

  /// Create from domain entity
  factory ContactModel.fromDomain(Contact contact) {
    return ContactModel(
      id: contact.id,
      userId: contact.userId,
      name: contact.name,
      email: contact.email,
      avatar: contact.avatar,
      notes: contact.notes,
      createdAt: contact.createdAt,
      updatedAt: contact.updatedAt,
    );
  }

  const ContactModel._();

  /// Create from JSON (Supabase response)
  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['contact_name'] as String,
      email: json['contact_email'] as String,
      avatar: json['contact_avatar'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert to JSON (for Supabase requests)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'contact_name': name,
      'contact_email': email,
      if (avatar != null) 'contact_avatar': avatar,
      if (notes != null) 'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert to domain entity
  Contact toEntity() {
    return Contact(
      id: id,
      userId: userId,
      name: name,
      email: email,
      avatar: avatar,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
