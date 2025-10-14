

import 'dart:convert';
import 'dart:io';

import 'package:supabase/supabase.dart';

// Mapping from Japanese keys to English DB columns
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

void main() async {
  // --- Configuration ---
  // IMPORTANT: Use the service_role key for admin-level access to bypass RLS.
  // The anon key might not have permission to insert data.
  // You can find the service_role key in your Supabase project settings under API.
  final supabaseUrl = 'https://odvtupoyrgtsygscvmnv.supabase.co';
  final supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9kdnR1cG95cmd0c3lnc2N2bW52Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA0MjYwNTMsImV4cCI6MjA3NjAwMjA1M30.mq0_PLP7R_nDQS99nGS2yZIPaBWiEhhl61UytQyN8o8';
  final client = SupabaseClient(supabaseUrl, supabaseKey);

  final jsonFiles = [
    'assets/villager-roles.json',
    'assets/murder-roles.json',
    'assets/3rd-roles.json',
  ];

  // --- Data Processing ---
  final List<Map<String, dynamic>> allRoles = [];
  print('Reading JSON files...');

  for (var filePath in jsonFiles) {
    final file = File(filePath);
    if (!await file.exists()) {
      print('File not found: $filePath. Skipping.');
      continue;
    }
    print('Processing file: $filePath');
    final content = await file.readAsString();
    final List<dynamic> roles = jsonDecode(content);

    for (var role in roles) {
      final newRole = <String, dynamic>{};
      role.forEach((key, value) {
        if (keyMap.containsKey(key)) {
          newRole[keyMap[key]!] = value;
        }
      });
      // Add category for 3rd party roles if missing
      if (newRole['faction'] == '第三陣営' && newRole['category'] == null) {
          newRole['category'] = '第三陣営';
      }
      allRoles.add(newRole);
    }
  }
  print('Finished processing ${allRoles.length} roles from JSON files.');

  // --- Database Insertion ---
  try {
    print('Attempting to upsert ${allRoles.length} roles to Supabase...');
    await client.from('roles').upsert(allRoles, onConflict: 'role_name');
    print('\nSuccessfully upserted roles into the database!');
  } on PostgrestException catch (e) {
    print('\n!!! Database Error !!!');
    print('A database error occurred: ${e.message}');
    print('This might be due to Row Level Security (RLS) policies.');
    print('Please check the following:');
    print("1. RLS is disabled for the 'roles' table OR a policy exists that allows insertion.");
    print('2. The key used in the script has the required permissions.');
  } catch (e) {
    print('\nAn unexpected error occurred: $e');
  } finally {
    await client.dispose();
    print('Script finished.');
  }
}

