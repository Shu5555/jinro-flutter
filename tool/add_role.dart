
import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Error: No JSON object provided.');
    print('Usage: dart run tool/add_role.dart '<json_string>'');
    exit(1);
  }

  final jsonString = args.join(' ');
  Map<String, dynamic> newRole;
  try {
    newRole = jsonDecode(jsonString);
  } catch (e) {
    print('Error: Invalid JSON format.');
    print('Please provide a single, valid JSON object string.');
    exit(1);
  }

  final faction = newRole['陣営'];
  if (faction == null) {
    print('Error: The JSON object must contain a "陣営" key.');
    exit(1);
  }

  final String targetFileName;
  switch (faction) {
    case '村人陣営':
      targetFileName = 'villager-roles.json';
      break;
    case '人狼陣営':
      targetFileName = 'murder-roles.json';
      break;
    case '第三陣営':
      targetFileName = '3rd-roles.json';
      break;
    default:
      print('Error: Unknown "陣営": $faction');
      exit(1);
  }

  final filePath = 'assets/$targetFileName';
  final file = File(filePath);

  if (!await file.exists()) {
    print('Error: Target file not found: $filePath');
    print('Creating a new file...');
    await file.writeAsString('[]', flush: true);
  }

  final content = await file.readAsString();
  List<dynamic> roles;
  try {
    roles = jsonDecode(content);
  } catch (e) {
    print('Error: Could not parse the existing JSON file: $filePath');
    print('It might be corrupted. Please check the file content.');
    exit(1);
  }
  
  // Check if role with the same name already exists
  final roleName = newRole['役職名'];
  final existingRoleIndex = roles.indexWhere((role) => role is Map && role['役職名'] == roleName);

  if (existingRoleIndex != -1) {
    print('Role "$roleName" already exists. Overwriting...');
    roles[existingRoleIndex] = newRole;
  } else {
    roles.add(newRole);
    print('Adding new role "$roleName"...');
  }


  final encoder = JsonEncoder.withIndent('    ');
  final newContent = encoder.convert(roles);

  try {
    await file.writeAsString(newContent, flush: true);
    print('Successfully updated $filePath');
  } catch (e) {
    print('Error: Failed to write to file: $filePath');
    exit(1);
  }
}
