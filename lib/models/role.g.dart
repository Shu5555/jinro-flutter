// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'role.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Role _$RoleFromJson(Map<String, dynamic> json) => Role(
  id: (json['id'] as num).toInt(),
  roleName: json['role_name'] as String,
  faction: json['faction'] as String,
  ability: json['ability'] as String,
  fortuneTellingResult: json['fortune_telling_result'] as String,
  relatedRole: json['related_role'] as String? ?? '',
  numberOfRelatedRoles: json['number_of_related_roles'] as String? ?? '0',
  victoryCondition: json['victory_condition'] as String? ?? '',
  creator: json['creator'] as String? ?? '',
  category: json['category'] as String? ?? '',
);

Map<String, dynamic> _$RoleToJson(Role instance) => <String, dynamic>{
  'id': instance.id,
  'role_name': instance.roleName,
  'faction': instance.faction,
  'ability': instance.ability,
  'fortune_telling_result': instance.fortuneTellingResult,
  'related_role': instance.relatedRole,
  'number_of_related_roles': instance.numberOfRelatedRoles,
  'victory_condition': instance.victoryCondition,
  'creator': instance.creator,
  'category': instance.category,
};
