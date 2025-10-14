
import 'package:json_annotation/json_annotation.dart';

part 'role.g.dart';

@JsonSerializable()
class Role {
  final int id;

  @JsonKey(name: 'role_name')
  final String roleName;

  final String faction;
  final String ability;

  @JsonKey(name: 'fortune_telling_result')
  final String fortuneTellingResult;

  @JsonKey(name: 'related_role', defaultValue: '')
  final String relatedRole;

  @JsonKey(name: 'number_of_related_roles', defaultValue: '0')
  final String numberOfRelatedRoles;

  @JsonKey(name: 'victory_condition', defaultValue: '')
  final String victoryCondition;

  @JsonKey(defaultValue: '')
  final String creator;

  @JsonKey(defaultValue: '')
  final String category;

  Role({
    required this.id,
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
