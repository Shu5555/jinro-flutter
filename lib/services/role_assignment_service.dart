import 'dart:math';
import '../models/role.dart';
import 'data_service.dart'; // For RoleService

class PlayerAssignment {
  final String name;
  final Role role;
  final String password;

  PlayerAssignment({
    required this.name,
    required this.role,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'roleName': role.roleName,
        'faction': role.faction,
        'ability': role.ability,
        'fortuneTellingResult': role.fortuneTellingResult,
        'relatedRole': role.relatedRole,
        'numberOfRelatedRoles': role.numberOfRelatedRoles,
        'victoryCondition': role.victoryCondition,
        'creator': role.creator,
        'category': role.category,
        'password': password,
      };

  factory PlayerAssignment.fromJson(Map<String, dynamic> json) {
    return PlayerAssignment(
      name: json['name'] as String,
      role: Role(
        roleName: json['roleName'] as String,
        faction: json['faction'] as String,
        ability: json['ability'] as String,
        fortuneTellingResult: json['fortuneTellingResult'] as String,
        relatedRole: json['relatedRole'] as String,
        numberOfRelatedRoles: json['numberOfRelatedRoles'] as String,
        victoryCondition: json['victoryCondition'] as String,
        creator: json['creator'] as String,
        category: json['category'] as String,
      ),
      password: json['password'] as String,
    );
  }
}

class RoleAssignmentService {
  final RoleService _roleService;
  final Random _random = Random();

  RoleAssignmentService(this._roleService);

  Future<List<PlayerAssignment>> assignRoles(
    List<String> participants,
    Map<String, int> counts,
  ) async {
    final List<Role> allRoles = await _roleService.loadAllRoles();
    print('Loaded all roles: ${allRoles.length}');

    // Helper to get roles by category
    List<Role> _getRolesByCategory(String faction, String category, int count) {
      final filteredRoles = allRoles
          .where((r) => r.faction == faction && r.category == category)
          .toList();
      if (filteredRoles.length < count) {
        throw Exception(
            '${faction}の${category}役職が不足しています。必要: ${count}件, 利用可能: ${filteredRoles.length}件');
      }
      filteredRoles.shuffle(_random);
      return filteredRoles.sublist(0, count);
    }

    // Helper to get third-party roles
    List<Role> _getThirdPartyRoles(int count) {
      final teamRoles = allRoles.where((r) => r.faction == '第三陣営').toList();
      if (teamRoles.length < count) {
        throw Exception(
            '第三陣営の役職が不足しています。必要: ${count}件, 利用可能: ${teamRoles.length}件');
      }
      teamRoles.shuffle(_random);
      return teamRoles.sublist(0, count);
    }

    try {
      // 1. Initial selection of roles based on counts
      List<Role> initialRoles = [
        ..._getRolesByCategory('村人陣営', '占い師系', counts['fortuneTeller']!),
        ..._getRolesByCategory('村人陣営', '霊媒師系', counts['medium']!),
        ..._getRolesByCategory('村人陣営', '騎士系', counts['knight']!),
        ..._getRolesByCategory('村人陣営', '一般', counts['villager']!),
        ..._getRolesByCategory('人狼陣営', '人狼', counts['werewolf']!),
        ..._getRolesByCategory('人狼陣営', '狂人', counts['madman']!),
        ..._getThirdPartyRoles(counts['thirdParty']!),
      ];

      // 2. Handle related roles
      List<Role> relatedRolesToAdd = [];
      Set<Role> rolesToRemove = {};
      List<Role> generalVillagers = initialRoles
          .where((r) => r.category == '一般')
          .toList();

      for (var role in initialRoles) {
        final String relatedRoleName = role.relatedRole;
        final int relatedRoleCount = int.tryParse(role.numberOfRelatedRoles) ?? 0;

        if (relatedRoleName.isNotEmpty && relatedRoleCount > 0) {
          final relatedRole = allRoles
              .firstWhere((r) => r.roleName == relatedRoleName);
          if (relatedRole != null) {
            for (int i = 0; i < relatedRoleCount; i++) {
              relatedRolesToAdd.add(relatedRole);
              // Remove a general villager to make space
              if (generalVillagers.isNotEmpty) {
                final toRemove = generalVillagers.removeAt(0);
                rolesToRemove.add(toRemove);
              } else {
                print('Warning: Not enough general villagers to replace for related role.');
              }
            }
          }
        }
      }

      // Filter out roles to remove and add related roles
      List<Role> finalRoles = initialRoles
          .where((r) => !rolesToRemove.contains(r))
          .toList();
      finalRoles.addAll(relatedRolesToAdd);

      // Final count check
      if (finalRoles.length != participants.length) {
        throw Exception(
            '最終的な役職数(${finalRoles.length})が参加者数(${participants.length})と一致しません。関連役職の設定を確認してください。');
      }

      finalRoles.shuffle(_random);

      // Generate passwords
      final List<String> passwords = [
        '寿司', 'ラーメン', '天ぷら', 'お好み焼き', 'たこ焼き', 'うどん', 'そば', 'カレー', 'とんかつ', '焼き鳥', 'おにぎり', '味噌汁', '刺身', '枝豆', '餃子', '唐揚げ', '焼き魚', 'すき焼き', 'しゃぶしゃぶ', 'おでん', 'もんじゃ焼き', 'カツ丼', '親子丼', '牛丼', 'うなぎ', 'とろろ', '茶碗蒸し', '漬物', '納豆', '梅干し'
      ]..shuffle(_random);

      List<String> shuffledParticipants = List.from(participants)..shuffle(_random);

      return List.generate(shuffledParticipants.length, (index) {
        final String participantName = shuffledParticipants[index];
        final Role assignedRole = finalRoles[index];
        final String password = passwords[index % passwords.length];
        return PlayerAssignment(
          name: participantName,
          role: assignedRole,
          password: password,
        );
      });
    } catch (e) {
      print('Role assignment error: $e');
      rethrow;
    }
  }
}
