import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:jinro_flutter/models/role.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RoleService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Role>> loadRoles(String category) async {
    List<Role> roles = [];

    // --- Key mapping for local JSON files ---
    const keyMap = {
      '役職名': 'role_name',
      '陣営': 'faction',
      '分類': 'category',
      '能力': 'ability',
      '占い結果': 'fortune_telling_result',
      '関連役職': 'related_role',
      '関連役職人数': 'number_of_related_roles',
      '勝利条件': 'victory_condition',
      '制作者': 'creator',
    };

    // Load roles from asset JSON files
    if (category != 'custom') { // Only load from assets if not specifically requesting custom roles
      final jsonString = await rootBundle.loadString('assets/$category-roles.json');
      final List<dynamic> jsonList = json.decode(jsonString);

      int idCounter = 0; // Counter for generating temporary IDs

      final transformedList = jsonList.map((role) {
        final newRole = <String, dynamic>{};
        role.forEach((key, value) {
          if (keyMap.containsKey(key)) {
            newRole[keyMap[key]!] = value;
          } else {
            newRole[key] = value; // Keep other keys if any
          }
        });
        // Add a temporary ID to prevent crashes.
        // The ID is based on category and a counter to ensure uniqueness.
        newRole['id'] = '${category.hashCode}_${idCounter++}'.hashCode;
        return newRole;
      }).toList();

      roles.addAll(transformedList.map((json) => Role.fromJson(json)).toList());
    }

    // Load custom roles from Supabase
    if (category == 'custom' || category == 'all') { // 'all' category to load all roles including custom
      try {
        final response = await _supabase.from('custom_roles').select();
        roles.addAll(response.map((json) => Role.fromJson(json)).toList());
      } catch (e) {
        print('Error loading custom roles from Supabase: $e');
        // Optionally, rethrow or handle more gracefully
      }
    }

    return roles;
  }

  Future<List<Role>> loadAllRoles() async {
    List<Role> allRoles = [];
    allRoles.addAll(await loadRoles('villager'));
    allRoles.addAll(await loadRoles('murder'));
    allRoles.addAll(await loadRoles('3rd'));
    allRoles.addAll(await loadRoles('custom')); // Loads custom roles from Supabase
    return allRoles;
  }
}