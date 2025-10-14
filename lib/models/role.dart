import 'package:json_annotation/json_annotation.dart';

part 'role.g.dart';

@JsonSerializable()
class Role {
  @JsonKey(name: '役職名')
  final String roleName;
  @JsonKey(name: '陣営')
  final String faction;
  @JsonKey(name: '能力')
  final String ability;
  @JsonKey(name: '占い結果')
  final String fortuneTellingResult;
  @JsonKey(name: '関連役職')
  final String relatedRole;
  @JsonKey(name: '関連役職人数')
  final String numberOfRelatedRoles;
  @JsonKey(name: '勝利条件')
  final String victoryCondition;
  @JsonKey(name: '制作者')
  final String creator;
  @JsonKey(name: '分類', defaultValue: '')
  final String category;

  Role({
    required this.roleName,
    required this.faction,
    required this.ability,
    required this.fortuneTellingResult,
    required this.relatedRole,
    required this.numberOfRelatedRoles,
    required this.victoryCondition,
    required this.creator,
    required this.category,
  });

  factory Role.fromJson(Map<String, dynamic> json) => _$RoleFromJson(json);
  Map<String, dynamic> toJson() => _$RoleToJson(this);
}