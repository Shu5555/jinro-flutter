import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/player_assignment.dart';

class AssignmentService {
  final _supabase = Supabase.instance.client;

  // Generates a short, random, human-readable ID.
  String _generateBinId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  Future<String> saveAssignments(List<PlayerAssignment> assignments) async {
    final binId = _generateBinId();
    final List<Map<String, dynamic>> assignmentsToInsert = [];

    for (var assignment in assignments) {
      assignmentsToInsert.add({
        'bin_id': binId,
        'player_name': assignment.name,
        'role_id': assignment.role.id,
        'password': assignment.password,
      });
    }

    try {
      await _supabase.from('assignments').insert(assignmentsToInsert);
      return binId;
    } on PostgrestException catch (e) {
      print('Error saving assignments: ${e.message}');
      rethrow;
    }
  }

  Future<List<PlayerAssignment>> loadAssignments(String binId) async {
    try {
      // Join with roles table to get role details
      final response = await _supabase
          .from('assignments')
          .select('*, roles(*)')
          .eq('bin_id', binId);

      if (response.isEmpty) {
        throw Exception('データが見つかりません。共有IDが間違っている可能性があります。');
      }

      // Map the response to a list of PlayerAssignment objects
      final assignments = response
          .map((item) => PlayerAssignment.fromSupabase(item))
          .toList();
          
      return assignments;
    } on PostgrestException catch (e) {
      print('Error loading assignments: ${e.message}');
      rethrow;
    }
  }
}
