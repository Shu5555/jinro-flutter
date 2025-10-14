import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/role.dart';

class RoleService {
  final _supabase = Supabase.instance.client;

  Future<List<Role>> loadAllRoles() async {
    try {
      final List<dynamic> data = await _supabase.from('roles').select();
      if (data.isEmpty) {
        return [];
      }
      // The data is a List<Map<String, dynamic>>
      return data.map((json) => Role.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      print('Error loading roles from Supabase: ${e.message}');
      return []; // Or throw an exception
    } catch (e) {
      print('An unexpected error occurred loading roles: $e');
      return []; // Or throw an exception
    }
  }
}