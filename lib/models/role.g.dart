// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'role.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Role _$RoleFromJson(Map<String, dynamic> json) => Role(
  roleName: json['役職名'] as String,
  faction: json['陣営'] as String,
  ability: json['能力'] as String,
  fortuneTellingResult: json['占い結果'] as String,
  relatedRole: json['関連役職'] as String,
  numberOfRelatedRoles: json['関連役職人数'] as String,
  victoryCondition: json['勝利条件'] as String,
  creator: json['制作者'] as String,
  category: json['分類'] as String? ?? '',
);

Map<String, dynamic> _$RoleToJson(Role instance) => <String, dynamic>{
  '役職名': instance.roleName,
  '陣営': instance.faction,
  '能力': instance.ability,
  '占い結果': instance.fortuneTellingResult,
  '関連役職': instance.relatedRole,
  '関連役職人数': instance.numberOfRelatedRoles,
  '勝利条件': instance.victoryCondition,
  '制作者': instance.creator,
  '分類': instance.category,
};
