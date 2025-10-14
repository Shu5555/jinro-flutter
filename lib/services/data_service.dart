import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:jinro_flutter/models/role.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RoleService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Role>> loadRoles(String category) async {
    List<Role> roles = [];

    // Load roles from asset JSON files
    if (category != 'custom') { // Only load from assets if not specifically requesting custom roles
      final jsonString = await rootBundle.loadString('assets/$category-roles.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      roles.addAll(jsonList.map((json) => Role.fromJson(json)).toList());
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
}